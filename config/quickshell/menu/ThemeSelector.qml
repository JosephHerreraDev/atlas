import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

Scope {
  id: root

  property bool opened: false
  property bool requestedOpen: false
  property bool mounted: false
  property string query: ""
  property int selectedIndex: -1
  property int focusRequest: 0
  property int transitionGeneration: 0
  property var themes: []
  property bool loading: false
  property string listError: ""
  property string activeTheme: ""
  property string applyingTheme: ""
  property var pendingThemes: []
  property var pendingPalettes: ({})
  property bool listOutputReady: false
  property int listExitCode: -1

  readonly property int animationDuration: Theme.motionNormal - 20
  property var themePalettes: ({})
  property var filteredThemes: []

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
    const queryChanged = query.length > 0
    query = ""
    refresh()
    if (!queryChanged)
      filter()
    const generation = ++transitionGeneration
    Qt.callLater(function() {
      if (root.requestedOpen && root.mounted
          && root.transitionGeneration === generation) {
        opened = true
        focusRequest += 1
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

  function refresh(): void {
    if (!listProcess.running) {
      loading = true
      listError = ""
      pendingThemes = []
      pendingPalettes = ({})
      listOutputReady = false
      listExitCode = -1
      listProcess.exec(["theme-colors", "--all"])
    }
  }

  function filter(): void {
    const previousTheme = selectedTheme()
    const needle = normalizeName(query)
    filteredThemes = themes.filter(function(name) {
      return needle.length === 0 || normalizeName(name).indexOf(needle) !== -1
    })
    const previousIndex = previousTheme
      ? filteredThemes.indexOf(previousTheme)
      : -1
    const activeIndex = activeTheme
      ? filteredThemes.indexOf(activeTheme)
      : -1
    selectedIndex = previousIndex >= 0
      ? previousIndex
      : (activeIndex >= 0
        ? activeIndex
        : (filteredThemes.length > 0 ? 0 : -1))
  }

  function normalizeName(value): string {
    return String(value || "").toLowerCase().normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[-_]+/g, " ")
      .replace(/\s+/g, " ")
      .trim()
  }

  function displayName(name): string {
    return String(name || "").replace(/[-_]+/g, " ")
  }

  function selectedTheme(): string {
    return selectedIndex >= 0 && selectedIndex < filteredThemes.length
      ? filteredThemes[selectedIndex]
      : ""
  }

  function moveSelection(delta, wrap): void {
    if (filteredThemes.length === 0) {
      selectedIndex = -1
      return
    }
    if (wrap === false) {
      selectedIndex = Math.max(0, Math.min(selectedIndex + delta,
        filteredThemes.length - 1))
      return
    }
    selectedIndex = (selectedIndex + delta + filteredThemes.length)
      % filteredThemes.length
  }

  function selectTheme(name): void {
    if (!name || applyProcess.running || themes.indexOf(name) === -1)
      return
    applyingTheme = name
    close()
    applyProcess.exec(["theme-set", name])
  }

  function validColor(value): bool {
    return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value || "")
  }

  function finishRefresh(): void {
    if (!listOutputReady || listExitCode < 0)
      return

    loading = false
    if (listExitCode !== 0) {
      listError = "Could not load themes"
      Quickshell.execDetached([
        "notify-send",
        "Theme list failed",
        "theme-colors exited with code " + listExitCode
      ])
    } else {
      const previousTheme = selectedTheme()
      themes = pendingThemes
      themePalettes = pendingPalettes
      filter()
      const preservedIndex = filteredThemes.indexOf(previousTheme)
      if (preservedIndex >= 0)
        selectedIndex = preservedIndex
    }

    pendingThemes = []
    pendingPalettes = ({})
    listOutputReady = false
    listExitCode = -1
  }

  onQueryChanged: filter()

  Process {
    id: listProcess

    stdout: StdioCollector {
      onStreamFinished: {
        const palettes = {}
        const names = []
        text.split("\n").forEach(function(line) {
          if (line.length === 0)
            return
          const fields = line.split("|")
          const name = fields.shift()
          if (!name || fields.length !== 7
              || !fields.every(root.validColor))
            return
          names.push(name)
          palettes[name] = {
            background: fields.shift(),
            foreground: fields.shift(),
            accents: fields
          }
        })
        root.pendingPalettes = palettes
        root.pendingThemes = names
        root.listOutputReady = true
        root.finishRefresh()
      }
    }

    onExited: function(exitCode) {
      root.listExitCode = exitCode
      root.finishRefresh()
    }
  }

  Process {
    id: applyProcess

    onExited: function(exitCode) {
      const name = root.applyingTheme
      root.applyingTheme = ""
      if (exitCode !== 0) {
        Quickshell.execDetached([
          "notify-send",
          "Could not apply theme",
          root.displayName(name) + " failed with code " + exitCode
        ])
      } else {
        activeThemeFile.reload()
      }
    }
  }

  FileView {
    id: activeThemeFile

    path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config")
      + "/atlas/style/current/theme"
    preload: true
    watchChanges: true
    printErrors: false
    onLoaded: root.activeTheme = text().trim()
    onTextChanged: root.activeTheme = text().trim()
    onFileChanged: reload()
    onLoadFailed: root.activeTheme = ""
  }

  IpcHandler {
    target: "theme"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Timer {
    id: hideTimer
    interval: root.animationDuration
    onTriggered: if (!root.requestedOpen) root.mounted = false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: root.mounted && root.screenFocused(modelData)
      color: "#00000000"
      aboveWindows: true
      focusable: true
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None
      WlrLayershell.namespace: "prometheus-theme-selector"
      anchors { top: true; bottom: true; left: true; right: true }

      function focusInput(): void {
        Qt.callLater(function() {
          if (root.requestedOpen && window.visible) {
            input.forceActiveFocus()
            input.selectAll()
          }
        })
      }
      onVisibleChanged: if (visible) focusInput()

      Connections {
        target: root
        function onFocusRequestChanged(): void {
          if (window.visible) window.focusInput()
        }
      }

      Rectangle {
        anchors.fill: parent
        color: "#66000000"
        opacity: root.opened ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        MouseArea { anchors.fill: parent; enabled: root.opened; onClicked: root.close() }
      }

      Rectangle {
        id: panel

        readonly property int visibleRows: Math.max(1, Math.min(7,
          Math.floor((window.height - 160) / 46)))

        width: Math.max(1, Math.min(400, window.width - 32))
        implicitHeight: content.implicitHeight + 28
        anchors.centerIn: parent
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        radius: Theme.radiusLg
        color: Qt.rgba(
          Theme.color0.r,
          Theme.color0.g,
          Theme.color0.b,
          Theme.popupOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.border
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        Behavior on scale { NumberAnimation { duration: root.animationDuration } }
        MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

        ColumnLayout {
          id: content
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
          spacing: Theme.spaceSm + Theme.spaceXxs

          RowLayout {
            Layout.fillWidth: true

            Text {
              Layout.fillWidth: true
              text: "Themes"
              color: Theme.color6
              font.pixelSize: Theme.fontDisplay
              font.weight: Theme.weightStrong
            }

            Text {
              text: {
                if (root.loading)
                  return root.themes.length > 0 ? "Refreshing…" : "Loading…"
                if (root.listError.length > 0)
                  return "Unavailable"
                const searching = root.query.trim().length > 0
                const count = searching
                  ? root.filteredThemes.length
                  : root.themes.length
                return count + (searching
                  ? (count === 1 ? " match" : " matches")
                  : (count === 1 ? " theme" : " themes"))
              }
              color: Theme.color4
              font.pixelSize: Theme.fontBody
            }
          }

          TextField {
            id: input
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            text: root.query
            placeholderText: "Search themes"
            color: Theme.color6
            placeholderTextColor: Theme.color4
            leftPadding: 12
            rightPadding: 12

            Accessible.name: "Search themes"
            Accessible.description: root.filteredThemes.length > 0
              ? root.filteredThemes.length + " results"
              : "No results"

            onTextChanged: root.query = text
            onAccepted: if (root.selectedIndex >= 0)
              root.selectTheme(root.filteredThemes[root.selectedIndex])
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Down) {
                root.moveSelection(1)
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                root.moveSelection(-1)
                event.accepted = true
              } else if (event.key === Qt.Key_Home
                         && root.filteredThemes.length > 0) {
                root.selectedIndex = 0
                event.accepted = true
              } else if (event.key === Qt.Key_End
                         && root.filteredThemes.length > 0) {
                root.selectedIndex = root.filteredThemes.length - 1
                event.accepted = true
              } else if (event.key === Qt.Key_PageDown) {
                root.moveSelection(panel.visibleRows, false)
                event.accepted = true
              } else if (event.key === Qt.Key_PageUp) {
                root.moveSelection(-panel.visibleRows, false)
                event.accepted = true
              }
            }
            background: Rectangle {
              radius: Theme.radiusMd
              color: Theme.color1
              border.width: Theme.borderWidth
              border.color: input.activeFocus ? Theme.borderFocus : Theme.color3
            }
          }

          Text {
            visible: root.filteredThemes.length === 0
            text: {
              if (root.loading && root.themes.length === 0)
                return "Loading themes…"
              if (root.listError.length > 0)
                return root.listError
              return root.themes.length === 0
                ? "No themes installed"
                : "No matching themes"
            }
            color: Theme.color4
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          ListView {
            id: themeList
            visible: root.filteredThemes.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(panel.visibleRows,
              root.filteredThemes.length) * 46
            clip: true
            interactive: root.filteredThemes.length > panel.visibleRows
            model: root.filteredThemes
            currentIndex: root.selectedIndex
            spacing: Theme.spaceXs
            boundsBehavior: Flickable.StopAtBounds
            onCurrentIndexChanged: if (currentIndex >= 0)
              positionViewAtIndex(currentIndex, ListView.Contain)

            Accessible.role: Accessible.List
            Accessible.name: "Theme results"

            ScrollBar.vertical: ScrollBar {
              policy: root.filteredThemes.length > panel.visibleRows
                ? ScrollBar.AsNeeded
                : ScrollBar.AlwaysOff
            }
            delegate: Rectangle {
              id: themeRow
              required property int index
              required property string modelData
              readonly property var palette: root.themePalettes[modelData] || ({})
              readonly property var accentColors: palette.accents || []
              readonly property bool selected: index === root.selectedIndex
              readonly property bool hovered: mouse.containsMouse
              readonly property bool active: modelData === root.activeTheme
              width: themeList.width
              height: 42
              radius: Theme.radiusMd
              color: palette.background || Theme.color0
              border.width: selected || hovered || active
                ? Theme.borderWidth : 0
              border.color: active
                ? Theme.color10
                : (selected
                  ? (palette.foreground || Theme.borderFocus)
                  : Theme.color3)

              Accessible.role: Accessible.Button
              Accessible.name: root.displayName(modelData)
              Accessible.description: active ? "Current theme" : "Apply theme"
              Accessible.focusable: true
              Accessible.selected: selected
              Accessible.onPressAction: root.selectTheme(modelData)

              RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: Theme.radiusMd

                Text {
                  Layout.fillWidth: true
                  text: root.displayName(themeRow.modelData)
                  color: themeRow.palette.foreground || Theme.color4
                  font.pixelSize: 13
                  font.weight: themeRow.selected || themeRow.active
                    ? Theme.weightStrong : Theme.weightMedium
                  elide: Text.ElideRight
                }

                Text {
                  visible: themeRow.active
                  text: "Current"
                  color: themeRow.palette.foreground || Theme.color4
                  font.pixelSize: Theme.fontCaption
                  font.weight: Theme.weightStrong
                }

                Repeater {
                  model: themeRow.accentColors

                  Rectangle {
                    required property string modelData
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    radius: Theme.radiusMd
                    color: modelData
                    border.width: Theme.borderWidth
                    border.color: themeRow.palette.foreground || Theme.border
                  }
                }
              }
              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.selectedIndex = index
                  root.selectTheme(modelData)
                }
              }
            }
          }
        }
      }

      Shortcut { sequence: "Escape"; enabled: root.opened; onActivated: root.close() }
    }
  }
}
