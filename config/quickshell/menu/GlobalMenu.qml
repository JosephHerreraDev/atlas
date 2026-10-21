import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../bar" as Bar
import "../shared" as Shared

Scope {
  id: root

  property bool opened: false
  property bool requestedOpen: false
  property bool mounted: false
  property string query: ""
  property var apps: []
  property var filteredApps: []
  property string sortMode: "alphabetical"
  property string viewMode: "grid"
  property string selectedCategory: "all"
  property bool categoriesVisible: true
  readonly property real menuWidth: 640
  readonly property real menuHeight: 660
  property var appHistory: ({})
  property bool historyLoaded: false
  property bool historyInitialized: false
  property bool appsLoaded: false
  property int selectedIndex: -1
  property int transitionGeneration: 0

  readonly property int animationDuration: Theme.motionNormal - 20
  readonly property int gridColumns: Math.max(3,
    Math.min(7, Math.floor((menuWidth - 150) / 92)))
  readonly property var applicationCategories: [
    { key: "all", label: "All", icon: "../assets/grid.svg", symbol: "", matches: [] },
    { key: "development", label: "Development", icon: "../assets/code.svg", symbol: "", matches: ["Development"] },
    { key: "games", label: "Games", icon: "../assets/games.svg", symbol: "", matches: ["Game"] },
    { key: "graphics", label: "Graphics", icon: "../assets/graphics.svg", symbol: "", matches: ["Graphics"] },
    { key: "internet", label: "Internet", icon: "../assets/internet.svg", symbol: "", matches: ["Network", "WebBrowser", "Email"] },
    { key: "multimedia", label: "Multimedia", icon: "../assets/multimedia.svg", symbol: "", matches: ["AudioVideo", "Audio", "Video"] },
    { key: "office", label: "Office", icon: "../assets/office.svg", symbol: "", matches: ["Office"] },
    { key: "system", label: "System", icon: "../assets/settings.svg", symbol: "", matches: ["System", "Settings"] },
    { key: "utilities", label: "Utilities", icon: "../assets/box.svg", symbol: "", matches: ["Utility"] }
  ]
  readonly property color accentTint: Qt.rgba(
    Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
  readonly property color accentTintStrong: Qt.rgba(
    Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.24)
  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function open(): void {
    MenuState.activate(root)
    hideTimer.stop()
    requestedOpen = true
    mounted = true
    opened = false
    query = ""
    selectedCategory = "all"
    if (!appsLoaded) refresh()
    else filter()
    const generation = ++transitionGeneration
    Qt.callLater(function() {
      if (root.requestedOpen && root.mounted
          && root.transitionGeneration === generation) {
        root.opened = true
        search.forceActiveFocus()
      }
    })
  }

  function close(): void {
    MenuState.deactivate(root)
    requestedOpen = false
    transitionGeneration += 1
    opened = false
    hideTimer.restart()
  }

  function toggle(): void { requestedOpen ? close() : open() }
  function stringValue(value): string {
    return value === undefined || value === null ? "" : String(value)
  }
  function normalizeText(value): string {
    return stringValue(value).toLowerCase().normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
  }
  function iconSource(icon) {
    return icon && icon.length > 0 ? Quickshell.iconPath(icon) : ""
  }

  function refresh(): void {
    const next = []
    const entries = DesktopEntries.applications.values
    for (let i = 0; i < entries.length; ++i) {
      const entry = entries[i]
      const name = stringValue(entry.name).trim()
      if (entry.noDisplay || name.length === 0) continue
      const genericName = stringValue(entry.genericName)
      const comment = stringValue(entry.comment)
      const id = stringValue(entry.id)
      const keywords = entry.keywords ? entry.keywords.join(" ") : ""
      const categories = entry.categories ? Array.from(entry.categories) : []
      next.push({
        entry: entry, id: id, name: name, genericName: genericName,
        comment: comment, icon: stringValue(entry.icon), categories: categories,
        normalizedName: normalizeText(name),
        normalizedGenericName: normalizeText(genericName),
        normalizedComment: normalizeText(comment),
        normalizedId: normalizeText(id),
        normalizedKeywords: normalizeText(keywords)
      })
    }
    apps = next
    appsLoaded = true
    rememberApps()
    filter()
  }

  function saveState(): void {
    if (!historyLoaded) return
    stateFile.setText(JSON.stringify({
      sortMode: sortMode, viewMode: viewMode,
      categoriesVisible: categoriesVisible,
      initialized: historyInitialized, apps: appHistory
    }, null, 2) + "\n")
  }

  function rememberApps(): void {
    if (!historyLoaded || !appsLoaded) return
    const history = Object.assign({}, appHistory)
    const now = historyInitialized ? Date.now() : 0
    for (let i = 0; i < apps.length; ++i) {
      const id = apps[i].id
      if (id.length > 0 && !Object.prototype.hasOwnProperty.call(history, id))
        history[id] = { installed: now, used: 0 }
    }
    appHistory = history
    historyInitialized = true
    saveState()
  }

  function compareApps(a, b): int {
    const field = sortMode === "installed" ? "installed" : "used"
    if (sortMode !== "alphabetical") {
      const difference = (Number((appHistory[b.id] || {})[field]) || 0)
        - (Number((appHistory[a.id] || {})[field]) || 0)
      if (difference !== 0) return difference > 0 ? 1 : -1
    }
    return a.name.localeCompare(b.name) || a.id.localeCompare(b.id)
  }

  function containsAllTokens(app, tokens): bool {
    const searchable = [app.normalizedName, app.normalizedGenericName,
      app.normalizedKeywords, app.normalizedComment, app.normalizedId].join(" ")
    for (let i = 0; i < tokens.length; ++i)
      if (searchable.indexOf(tokens[i]) === -1) return false
    return true
  }

  function hasWordPrefix(value, token): bool {
    return value.startsWith(token) || value.indexOf(" " + token) !== -1
      || value.indexOf("-" + token) !== -1
  }

  function matchScore(app, needle, tokens): int {
    if (!containsAllTokens(app, tokens)) return -1
    let score = app.normalizedName === needle ? 10000
      : app.normalizedName.startsWith(needle) ? 8000 : 0
    for (let i = 0; i < tokens.length; ++i) {
      const token = tokens[i]
      if (hasWordPrefix(app.normalizedName, token)) score += 500
      else if (app.normalizedName.indexOf(token) !== -1) score += 350
      if (hasWordPrefix(app.normalizedGenericName, token)) score += 200
      else if (app.normalizedGenericName.indexOf(token) !== -1) score += 140
      if (hasWordPrefix(app.normalizedKeywords, token)) score += 120
      else if (app.normalizedKeywords.indexOf(token) !== -1) score += 90
      if (app.normalizedComment.indexOf(token) !== -1) score += 50
      if (app.normalizedId.indexOf(token) !== -1) score += 20
    }
    return score - Math.min(app.name.length, 100)
  }

  function categoryDefinition(key) {
    for (let i = 0; i < applicationCategories.length; ++i)
      if (applicationCategories[i].key === key) return applicationCategories[i]
    return applicationCategories[0]
  }

  function appMatchesCategory(app, key): bool {
    if (key === "all") return true
    const wanted = categoryDefinition(key).matches
    for (let i = 0; i < app.categories.length; ++i)
      if (wanted.indexOf(app.categories[i]) !== -1) return true
    return false
  }

  function categoryCount(key): int {
    if (key === "all") return apps.length
    let count = 0
    for (let i = 0; i < apps.length; ++i)
      if (appMatchesCategory(apps[i], key)) ++count
    return count
  }

  function filter(): void {
    const needle = normalizeText(query).trim()
    if (needle.length === 0) {
      filteredApps = apps.filter(function(app) {
        return appMatchesCategory(app, selectedCategory)
      }).sort(compareApps)
    } else {
      const tokens = needle.split(/\s+/)
      const matches = []
      for (let i = 0; i < apps.length; ++i) {
        if (!appMatchesCategory(apps[i], selectedCategory)) continue
        const score = matchScore(apps[i], needle, tokens)
        if (score >= 0) matches.push({ app: apps[i], score: score })
      }
      matches.sort(function(a, b) {
        return a.score !== b.score ? b.score - a.score
          : compareApps(a.app, b.app)
      })
      filteredApps = matches.map(function(match) { return match.app })
    }
    selectedIndex = filteredApps.length > 0 ? 0 : -1
  }

  function moveSelection(delta): void {
    if (filteredApps.length === 0) return
    selectedIndex = (selectedIndex + delta + filteredApps.length)
      % filteredApps.length
    if (viewMode === "grid") appGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
    else appList.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function selectedApp() {
    return selectedIndex >= 0 && selectedIndex < filteredApps.length
      ? filteredApps[selectedIndex] : null
  }

  function launch(app): void {
    if (!app || !app.entry || app.id.length === 0) return
    try {
      app.entry.execute()
      const history = Object.assign({}, appHistory)
      history[app.id] = Object.assign({}, history[app.id] || {},
        { used: Date.now() })
      appHistory = history
      saveState()
      close()
    } catch (error) {
      Quickshell.execDetached(["notify-send", "Could not launch " + app.name,
        stringValue(error)])
    }
  }

  function run(command): void {
    close()
    Quickshell.execDetached(command)
  }

  onQueryChanged: filter()
  onSelectedCategoryChanged: filter()
  onSortModeChanged: { filter(); saveState() }
  onViewModeChanged: saveState()
  onCategoriesVisibleChanged: saveState()
  Component.onCompleted: refresh()

  FileView {
    id: stateFile
    path: (Quickshell.env("XDG_CONFIG_HOME")
      || Quickshell.env("HOME") + "/.config") + "/atlas/start-menu-state.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (["alphabetical", "installed", "used"].indexOf(data.sortMode) !== -1)
          root.sortMode = data.sortMode
        if (["grid", "list"].indexOf(data.viewMode) !== -1)
          root.viewMode = data.viewMode
        if (typeof data.categoriesVisible === "boolean")
          root.categoriesVisible = data.categoriesVisible
        if (data.apps && typeof data.apps === "object" && !Array.isArray(data.apps))
          root.appHistory = data.apps
        root.historyInitialized = data.initialized === true
      } catch (error) {}
      root.historyLoaded = true
      root.rememberApps()
      root.filter()
    }
    onLoadFailed: {
      root.historyLoaded = true
      root.rememberApps()
      root.filter()
    }
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged(): void { root.refresh() }
  }
  IpcHandler {
    target: "global-menu"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }
  Timer {
    id: hideTimer
    interval: root.animationDuration
    onTriggered: if (!root.requestedOpen) root.mounted = false
  }

  component FooterButton: Shared.Button {
    id: footerButton
    property string label: ""
    property string symbol: ""
    property url iconPath: ""
    property bool danger: false
    accessibleName: label
    implicitHeight: 36
    horizontalPadding: Theme.spaceLg
    verticalPadding: 0
    buttonColor: pressed ? (danger ? Theme.error : Theme.selectionBackground)
      : hovered ? (danger ? Theme.error : Theme.surfaceHover) : "transparent"
    buttonBorderColor: hovered ? (danger ? Theme.error : Theme.borderFocus)
      : "transparent"
    RowLayout {
      anchors.centerIn: parent
      spacing: Theme.spaceSm
      IconImage {
        visible: footerButton.iconPath.toString() !== ""
        source: footerButton.iconPath
        Layout.preferredWidth: 16
        Layout.preferredHeight: 16
        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: footerButton.danger
            ? Theme.foreground : Theme.foregroundMuted
        }
      }
      Text {
        text: footerButton.symbol
        visible: text !== "" && footerButton.iconPath.toString() === ""
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      Text {
        text: footerButton.label
        color: Theme.foreground
        font.pixelSize: Theme.fontCaption
        font.weight: Theme.weightMedium
      }
    }
  }

  component SortSelect: Item {
    id: sortSelect

    readonly property var options: [
      { key: "alphabetical", label: "Alphabetical" },
      { key: "installed", label: "Recently installed" },
      { key: "used", label: "Recently used" }
    ]
    readonly property int selectedIndex: Math.max(0,
      ["alphabetical", "installed", "used"].indexOf(root.sortMode))

    implicitWidth: 168
    implicitHeight: 32

    function choose(index): void {
      if (index < 0 || index >= options.length) return
      root.sortMode = options[index].key
      sortPopup.close()
      search.forceActiveFocus()
    }

    Shared.Button {
      id: sortButton
      anchors.fill: parent
      accessibleName: "Sort applications by "
        + sortSelect.options[sortSelect.selectedIndex].label
      horizontalPadding: Theme.spaceLg
      verticalPadding: 0
      buttonColor: activeFocus || sortPopup.opened
        ? root.accentTint
        : hovered ? Theme.surfaceHover : "transparent"
      buttonBorderColor: activeFocus || sortPopup.opened || hovered
        ? Theme.accent : Theme.border
      onClicked: sortPopup.open()
      Keys.onDownPressed: sortPopup.open()
      Keys.onSpacePressed: sortPopup.open()

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceLg
        anchors.rightMargin: Theme.spaceLg
        spacing: Theme.spaceSm

        Text {
          Layout.fillWidth: true
          text: sortSelect.options[sortSelect.selectedIndex].label
          color: sortButton.activeFocus || sortPopup.opened
            ? Theme.accent : Theme.foreground
          font.pixelSize: Theme.fontCaption
          font.weight: Theme.weightMedium
          elide: Text.ElideRight
        }

        Canvas {
          Layout.preferredWidth: 14
          Layout.preferredHeight: 14
          property color strokeColor: sortButton.activeFocus || sortPopup.opened
            ? Theme.accent : Theme.foregroundMuted
          rotation: sortPopup.opened ? 180 : 0
          onStrokeColorChanged: requestPaint()
          onPaint: {
            const context = getContext("2d")
            context.clearRect(0, 0, width, height)
            context.beginPath()
            context.moveTo(2, 5)
            context.lineTo(7, 10)
            context.lineTo(12, 5)
            context.strokeStyle = strokeColor
            context.lineWidth = 2
            context.lineCap = "round"
            context.lineJoin = "round"
            context.stroke()
          }
          Behavior on rotation {
            SpringAnimation {
              spring: Theme.motionSpring
              damping: Theme.motionDamping
              epsilon: Theme.motionEpsilon
            }
          }
        }
      }
    }

    Popup {
      id: sortPopup
      y: sortButton.height + Theme.spaceXs
      width: sortSelect.width
      height: sortSelect.options.length * 36 + Theme.spaceSm * 2
      padding: Theme.spaceSm
      focus: true
      closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
      onOpened: {
        sortOptions.currentIndex = sortSelect.selectedIndex
        sortOptions.forceActiveFocus()
      }
      background: Rectangle {
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusMd
      }
      contentItem: ListView {
        id: sortOptions
        clip: true
        model: sortSelect.options
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        Keys.onDownPressed: currentIndex = (currentIndex + 1) % count
        Keys.onUpPressed: currentIndex = (currentIndex - 1 + count) % count
        Keys.onReturnPressed: sortSelect.choose(currentIndex)
        Keys.onEnterPressed: sortSelect.choose(currentIndex)
        Keys.onSpacePressed: sortSelect.choose(currentIndex)

        delegate: Rectangle {
          id: sortOption
          required property int index
          required property var modelData
          width: sortOptions.width
          height: 36
          radius: Theme.radiusSm
          color: index === sortOptions.currentIndex
            ? Theme.surfaceHover : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceSm
            anchors.rightMargin: Theme.spaceSm
            spacing: Theme.spaceSm
            Item {
              Layout.preferredWidth: 14
              Layout.preferredHeight: 14
              IconImage {
                anchors.fill: parent
                visible: sortOption.index === sortSelect.selectedIndex
                source: Qt.resolvedUrl("../assets/check.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                  brightness: 1
                  colorization: 1
                  colorizationColor: Theme.accent
                }
              }
            }
            Text {
              Layout.fillWidth: true
              text: sortOption.modelData.label
              color: sortOption.index === sortSelect.selectedIndex
                ? Theme.accent : Theme.foreground
              font.pixelSize: Theme.fontCaption
              font.weight: sortOption.index === sortSelect.selectedIndex
                ? Theme.weightStrong : Theme.weightMedium
              elide: Text.ElideRight
            }
          }
          HoverHandler {
            onHoveredChanged: if (hovered) sortOptions.currentIndex = sortOption.index
          }
          TapHandler { onTapped: sortSelect.choose(sortOption.index) }
        }
      }
    }
  }

  component ViewButton: Shared.Button {
    id: viewButton
    property string mode: "grid"
    property string iconPath: ""
    accessibleName: mode === "grid" ? "Grid view" : "List view"
    implicitWidth: 34
    implicitHeight: 32
    horizontalPadding: 0
    verticalPadding: 0
    buttonColor: root.viewMode === mode ? root.accentTintStrong
      : hovered ? Theme.surfaceHover : "transparent"
    buttonBorderColor: root.viewMode === mode ? Theme.borderFocus : "transparent"
    onClicked: root.viewMode = mode
    IconImage {
      anchors.centerIn: parent
      width: 17
      height: 17
      source: viewButton.iconPath
      layer.enabled: true
      layer.effect: MultiEffect {
        brightness: 1
        colorization: 1
        colorizationColor: root.viewMode === viewButton.mode
          ? Theme.accent : Theme.foregroundMuted
      }
    }
  }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: root.mounted && root.screenFocused(modelData)
      color: "transparent"
      aboveWindows: true
      focusable: true
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      WlrLayershell.namespace: "atlas-global-menu"
      anchors { top: true; bottom: true; left: true; right: true }

      function focusSearch(): void {
        Qt.callLater(function() {
          if (root.opened && window.visible) {
            search.forceActiveFocus()
            search.selectAll()
          }
        })
      }

      onVisibleChanged: if (visible) focusSearch()

      Connections {
        target: root
        function onOpenedChanged(): void {
          if (root.opened) window.focusSearch()
        }
      }

      Rectangle {
        anchors.fill: parent
        color: "#70000000"
        opacity: root.opened ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        MouseArea {
          anchors.fill: parent
          enabled: root.opened
          onClicked: root.close()
        }
      }

      Rectangle {
        id: panel
        width: Math.min(root.menuWidth, window.width - 32)
        height: Math.min(root.menuHeight, window.height - 48
          - Bar.BarStyle.topClearance - Bar.BarStyle.bottomClearance)
        x: Placement.itemX(Placement.startMenu, window.width, width, Placement.edgeMargin)
        y: Placement.itemY(Placement.startMenu, window.height, height,
          Bar.BarStyle.topClearance + Placement.edgeMargin,
          Bar.BarStyle.bottomClearance + Placement.edgeMargin)
        radius: Theme.radiusLg
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.borderFocus
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        transformOrigin: Item.Center
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        Behavior on x { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on y { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on scale {
          SpringAnimation {
            spring: Theme.motionSpring
            damping: Theme.motionDamping
            epsilon: Theme.motionEpsilon
          }
        }
        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) { mouse.accepted = true }
          onWheel: function(wheel) { wheel.accepted = true }
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Theme.spaceLg
          spacing: Theme.spaceMd

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            Shared.Button {
              id: categoriesToggle
              Layout.preferredWidth: 42
              Layout.preferredHeight: 42
              Layout.alignment: Qt.AlignVCenter
              accessibleName: root.categoriesVisible
                ? "Hide categories" : "Show categories"
              horizontalPadding: 0
              verticalPadding: 0
              buttonColor: root.categoriesVisible
                ? root.accentTintStrong
                : hovered ? Theme.surfaceHover : "transparent"
              buttonBorderColor: root.categoriesVisible
                ? Theme.borderFocus : "transparent"
              onClicked: root.categoriesVisible = !root.categoriesVisible
              IconImage {
                anchors.centerIn: parent
                width: 19
                height: 19
                source: Qt.resolvedUrl(root.categoriesVisible
                  ? "../assets/sidebar-opened.svg"
                  : "../assets/sidebar-closed.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                  brightness: 1
                  colorization: 1
                  colorizationColor: root.categoriesVisible
                    ? Theme.accent : Theme.foregroundMuted
                }
              }
            }

            TextField {
              id: search
              Layout.fillWidth: true
              Layout.preferredHeight: 42
            text: root.query
            placeholderText: "Search applications"
            color: Theme.foreground
            placeholderTextColor: Theme.foregroundMuted
            selectByMouse: true
            leftPadding: 42
            rightPadding: Theme.spaceXl
            font.pixelSize: Theme.fontBody
            Accessible.name: "Search applications"
            IconImage {
              anchors.left: parent.left
              anchors.leftMargin: Theme.spaceXl
              anchors.verticalCenter: parent.verticalCenter
              width: 18
              height: 18
              source: Qt.resolvedUrl("../assets/search.svg")
              layer.enabled: true
              layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: search.activeFocus
                  ? Theme.accent : Theme.foregroundMuted
              }
            }
            background: Rectangle {
              color: Theme.surfaceHover
              radius: Theme.radiusMd
              border.width: Theme.borderWidth
              border.color: search.activeFocus ? Theme.borderFocus : Theme.border
            }
            onTextChanged: root.query = text
            onAccepted: root.launch(root.selectedApp())
            Keys.onPressed: function(event) {
              const control = (event.modifiers & Qt.ControlModifier) !== 0
              const rowStep = root.viewMode === "grid" ? root.gridColumns : 1
              if (event.key === Qt.Key_Down || (control && event.key === Qt.Key_N)) {
                root.moveSelection(rowStep); event.accepted = true
              } else if (event.key === Qt.Key_Up || (control && event.key === Qt.Key_P)) {
                root.moveSelection(-rowStep); event.accepted = true
              } else if (event.key === Qt.Key_Right && root.viewMode === "grid") {
                root.moveSelection(1); event.accepted = true
              } else if (event.key === Qt.Key_Left && root.viewMode === "grid") {
                root.moveSelection(-1); event.accepted = true
              } else if (event.key === Qt.Key_Home) {
                root.selectedIndex = root.filteredApps.length > 0 ? 0 : -1
                event.accepted = true
              } else if (event.key === Qt.Key_End) {
                root.selectedIndex = root.filteredApps.length - 1
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close(); event.accepted = true
              }
            }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spaceLg

            Rectangle {
              visible: root.categoriesVisible
              Layout.preferredWidth: 148
              Layout.fillHeight: true
              radius: Theme.radiusMd
              color: Qt.rgba(Theme.background.r, Theme.background.g,
                Theme.background.b, 0.34)
              border.width: Theme.borderWidth
              border.color: Theme.border

              ListView {
                anchors.fill: parent
                anchors.margins: Theme.spaceXs
                spacing: 2
                clip: true
                model: root.applicationCategories
                boundsBehavior: Flickable.StopAtBounds
                delegate: Shared.Button {
                  id: categoryButton
                  required property var modelData
                  width: ListView.view.width
                  height: 36
                  accessibleName: modelData.label + " category"
                  horizontalPadding: Theme.spaceSm
                  verticalPadding: 0
                  buttonColor: root.selectedCategory === modelData.key
                    ? root.accentTintStrong
                    : hovered ? Theme.surfaceHover : "transparent"
                  buttonBorderColor: root.selectedCategory === modelData.key
                    ? Theme.accent : "transparent"
                  onClicked: {
                    root.selectedCategory = modelData.key
                    search.forceActiveFocus()
                  }
                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceSm
                    anchors.rightMargin: Theme.spaceSm
                    spacing: Theme.spaceSm
                    IconImage {
                      visible: categoryButton.modelData.icon !== ""
                      source: Qt.resolvedUrl(categoryButton.modelData.icon)
                      Layout.preferredWidth: 18
                      Layout.preferredHeight: 18
                      layer.enabled: true
                      layer.effect: MultiEffect {
                        brightness: 1
                        colorization: 1
                        colorizationColor: root.selectedCategory
                          === categoryButton.modelData.key
                          ? Theme.accent : Theme.foregroundMuted
                      }
                    }
                    Text {
                      visible: categoryButton.modelData.icon === ""
                      text: categoryButton.modelData.symbol
                      color: root.selectedCategory === categoryButton.modelData.key
                        ? Theme.accent : Theme.foregroundMuted
                      font.pixelSize: Theme.fontBody
                      font.weight: Theme.weightStrong
                      Layout.preferredWidth: 18
                      horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                      Layout.fillWidth: true
                      text: categoryButton.modelData.label
                      color: Theme.foreground
                      font.pixelSize: Theme.fontCaption
                      font.weight: root.selectedCategory === categoryButton.modelData.key
                        ? Theme.weightStrong : Theme.weightMedium
                      elide: Text.ElideRight
                    }
                    Text {
                      text: root.categoryCount(categoryButton.modelData.key)
                      color: Theme.foregroundMuted
                      font.pixelSize: 9
                    }
                  }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              Layout.fillHeight: true
              spacing: Theme.spaceMd

              RowLayout {
                Layout.fillWidth: true

                ViewButton {
                  mode: "grid"
                  iconPath: Qt.resolvedUrl("../assets/grid.svg")
                }
                ViewButton {
                  mode: "list"
                  iconPath: Qt.resolvedUrl("../assets/list.svg")
                }

                Item { Layout.fillWidth: true }
                SortSelect {
                  Layout.preferredWidth: 168
                  Layout.preferredHeight: 32
                }
              }

              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            Text {
              anchors.centerIn: parent
              visible: root.filteredApps.length === 0
              text: !root.appsLoaded ? "Loading applications…"
                : root.apps.length === 0 ? "No applications available"
                : root.query.trim().length > 0
                  ? "No applications match your search"
                  : "No applications in this category"
              color: Theme.foregroundMuted
              font.pixelSize: Theme.fontBody
            }

            GridView {
              id: appGrid
              anchors.fill: parent
              visible: root.viewMode === "grid" && root.filteredApps.length > 0
              clip: true
              cellWidth: width / root.gridColumns
              cellHeight: 96
              model: root.filteredApps
              currentIndex: root.selectedIndex
              boundsBehavior: Flickable.StopAtBounds
              ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
              delegate: Rectangle {
                id: gridCard
                required property int index
                required property var modelData
                width: appGrid.cellWidth - 4
                height: appGrid.cellHeight - 4
                radius: Theme.radiusMd
                color: GridView.isCurrentItem ? root.accentTintStrong
                  : gridMouse.containsMouse ? root.accentTint : "transparent"
                border.width: GridView.isCurrentItem || gridMouse.containsMouse
                  ? Theme.borderWidth : 0
                border.color: GridView.isCurrentItem ? Theme.accent : Theme.border
                scale: gridMouse.pressed ? 0.96 : 1
                Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
                Behavior on border.color { ColorAnimation { duration: Theme.motionQuick } }
                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: Theme.spaceSm
                  spacing: Theme.spaceXs
                  IconImage {
                    id: gridIcon
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    source: root.iconSource(gridCard.modelData.icon)
                    asynchronous: true
                    mipmap: true
                    visible: status === Image.Ready
                  }
                  Rectangle {
                    visible: !gridIcon.visible
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: Theme.radiusMd
                    color: Theme.selectionBackground
                    Text {
                      anchors.centerIn: parent
                      text: gridCard.modelData.name.charAt(0).toUpperCase()
                      color: Theme.selectionForeground
                      font.weight: Theme.weightStrong
                    }
                  }
                  Text {
                    Layout.fillWidth: true
                    text: gridCard.modelData.name
                    color: Theme.foreground
                    font.pixelSize: Theme.fontCaption
                    font.weight: GridView.isCurrentItem
                      ? Theme.weightStrong : Theme.weightMedium
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                  }
                }
                MouseArea {
                  id: gridMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selectedIndex = gridCard.index
                  onClicked: root.launch(gridCard.modelData)
                }
              }
            }

            ListView {
              id: appList
              anchors.fill: parent
              visible: root.viewMode === "list" && root.filteredApps.length > 0
              clip: true
              model: root.filteredApps
              currentIndex: root.selectedIndex
              spacing: Theme.spaceXs
              boundsBehavior: Flickable.StopAtBounds
              ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
              delegate: Rectangle {
                id: listCard
                required property int index
                required property var modelData
                width: appList.width
                height: 58
                radius: Theme.radiusMd
                color: ListView.isCurrentItem ? root.accentTintStrong
                  : listMouse.containsMouse ? root.accentTint : "transparent"
                border.width: ListView.isCurrentItem || listMouse.containsMouse
                  ? Theme.borderWidth : 0
                border.color: ListView.isCurrentItem ? Theme.accent : Theme.border
                Behavior on color { ColorAnimation { duration: Theme.motionQuick } }
                Behavior on border.color { ColorAnimation { duration: Theme.motionQuick } }
                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Theme.spaceLg
                  spacing: Theme.spaceLg
                  IconImage {
                    id: listIcon
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    source: root.iconSource(listCard.modelData.icon)
                    asynchronous: true
                    mipmap: true
                    visible: status === Image.Ready
                  }
                  Rectangle {
                    visible: !listIcon.visible
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: Theme.radiusMd
                    color: Theme.selectionBackground
                    Text {
                      anchors.centerIn: parent
                      text: listCard.modelData.name.charAt(0).toUpperCase()
                      color: Theme.selectionForeground
                      font.weight: Theme.weightStrong
                    }
                  }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                      Layout.fillWidth: true
                      text: listCard.modelData.name
                      color: Theme.foreground
                      font.pixelSize: Theme.fontBody
                      font.weight: ListView.isCurrentItem
                        ? Theme.weightStrong : Theme.weightMedium
                      elide: Text.ElideRight
                    }
                    Text {
                      Layout.fillWidth: true
                      text: listCard.modelData.comment.length > 0
                        ? listCard.modelData.comment : listCard.modelData.genericName
                      visible: text.length > 0
                      color: Theme.foregroundMuted
                      font.pixelSize: Theme.fontCaption
                      elide: Text.ElideRight
                    }
                  }
                }
                MouseArea {
                  id: listMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selectedIndex = listCard.index
                  onClicked: root.launch(listCard.modelData)
                }
              }
            }
            }

              Text {
                Layout.fillWidth: true
                text: root.filteredApps.length
                  + (root.filteredApps.length === 1
                    ? " application" : " applications")
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontCaption
                font.weight: Theme.weightMedium
                horizontalAlignment: Text.AlignRight
              }
          }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
          }
          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceXs
            Item { Layout.fillWidth: true }
            FooterButton {
              label: "Settings"
              iconPath: Qt.resolvedUrl("../assets/settings.svg")
              onClicked: {
                root.close()
                Quickshell.execDetached(["qs", "ipc", "call", "settings", "open"])
              }
            }
            FooterButton {
              label: "Power"
              symbol: "⏻"
              danger: true
              onClicked: {
                root.close()
                Quickshell.execDetached(["qs", "ipc", "call", "powermenu", "open"])
              }
            }
          }
        }
      }
      Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: root.close()
      }
    }
  }
}
