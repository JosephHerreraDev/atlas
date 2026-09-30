import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../shared/"

Scope {
  id: root

  property bool opened: false
  property bool loading: false
  property bool saving: false
  property string currentSection: "system"
  property string operation: ""
  property string pendingJson: ""
  property string statusMessage: ""
  property bool statusError: false
  property var sections: ({})
  property var originalSections: ({})
  property var sectionErrors: ({})
  property var dirtySections: ({})
  property var detectedMonitors: []
  property bool rebuildRequired: false

  readonly property var pages: [
    { key: "system", label: "System", symbol: "󰒓" },
    { key: "displays", label: "Displays", symbol: "󰍹" }
  ]

  function clone(value) {
    return JSON.parse(JSON.stringify(value))
  }

  function open() {
    opened = true
    refresh()
    Qt.callLater(focusCurrentPage)
  }

  function close() {
    opened = false
  }

  function toggle() {
    if (opened)
      close()
    else
      open()
  }

  function currentPageIndex() {
    for (let index = 0; index < pages.length; ++index) {
      if (pages[index].key === currentSection)
        return index
    }
    return 0
  }

  function focusCurrentPage() {
    const button = categoryRepeater.itemAt(currentPageIndex())
    if (button)
      button.forceActiveFocus()
  }

  function selectPage(index) {
    const boundedIndex = Math.max(0, Math.min(index, pages.length - 1))
    currentSection = pages[boundedIndex].key
    statusMessage = ""
    const button = categoryRepeater.itemAt(boundedIndex)
    if (button)
      button.forceActiveFocus()
  }

  function cyclePage(offset) {
    const index = (currentPageIndex() + offset + pages.length) % pages.length
    selectPage(index)
  }

  function focusSettingsOption(forward) {
    let item = window.activeFocusItem
    for (let count = 0; item && count < 100; ++count) {
      item = item.nextItemInFocusChain(forward)
      if (!item)
        return
      if (item.categoryNavigationButton === true)
        continue
      item.forceActiveFocus()
      return
    }
  }

  function refresh() {
    if (backend.running)
      return
    loading = true
    statusMessage = ""
    operation = "read"
    backend.exec(["atlas", "settings", "read"])
  }

  function sectionAvailable(section) {
    return sections[section] !== undefined && sectionErrors[section] === undefined
  }

  function value(section, key, fallback) {
    if (!sectionAvailable(section) || sections[section][key] === undefined)
      return fallback
    return sections[section][key]
  }

  function setValue(section, key, value) {
    if (!sectionAvailable(section))
      return
    const next = clone(sections)
    next[section][key] = value
    sections = next
    const dirty = clone(dirtySections)
    dirty[section] = JSON.stringify(next[section]) !== JSON.stringify(originalSections[section])
    dirtySections = dirty
  }

  function updateMonitor(index, key, value) {
    const monitors = clone(root.value("displays", "monitors", []))
    if (index < 0 || index >= monitors.length)
      return
    monitors[index][key] = value
    setValue("displays", "monitors", monitors)
  }

  function removeMonitor(index) {
    const monitors = clone(value("displays", "monitors", []))
    if (monitors.length <= 1)
      return
    monitors.splice(index, 1)
    setValue("displays", "monitors", monitors)
  }

  function addMonitor() {
    const monitors = clone(value("displays", "monitors", []))
    let output = ""
    for (let i = 0; i < detectedMonitors.length; ++i) {
      const candidate = detectedMonitors[i].name || ""
      if (!monitors.some(function(item) { return item.output === candidate })) {
        output = candidate
        break
      }
    }
    monitors.push({ output: output, mode: "preferred", position: "auto", scale: "1" })
    setValue("displays", "monitors", monitors)
  }

  function resetSection() {
    if (originalSections[currentSection] === undefined)
      return
    const next = clone(sections)
    next[currentSection] = clone(originalSections[currentSection])
    sections = next
    const dirty = clone(dirtySections)
    dirty[currentSection] = false
    dirtySections = dirty
    statusMessage = "Changes discarded"
    statusError = false
  }

  function saveSection() {
    if (!sectionAvailable(currentSection) || !dirtySections[currentSection]
        || backend.running)
      return
    saving = true
    statusMessage = ""
    operation = "save:" + currentSection
    pendingJson = JSON.stringify(sections[currentSection]) + "\n"
    backend.exec(["atlas", "settings", "save", currentSection])
  }

  function handleResult(raw, exitCode) {
    let result
    try {
      result = JSON.parse(raw)
    } catch (error) {
      loading = false
      saving = false
      statusError = true
      statusMessage = raw.trim() || "Settings backend returned invalid data"
      return
    }
    if (exitCode !== 0 || result.ok !== true) {
      loading = false
      saving = false
      statusError = true
      statusMessage = result.error || "Settings operation failed"
      return
    }
    if (operation === "read") {
      sections = clone(result.sections || {})
      originalSections = clone(result.sections || {})
      sectionErrors = clone(result.errors || {})
      detectedMonitors = clone(result.detectedMonitors || [])
      rebuildRequired = result.rebuildRequired === true
      dirtySections = ({})
      loading = false
      statusError = false
      statusMessage = ""
      return
    }
    const section = operation.substring(5)
    const originals = clone(originalSections)
    originals[section] = clone(sections[section])
    originalSections = originals
    const dirty = clone(dirtySections)
    dirty[section] = false
    dirtySections = dirty
    rebuildRequired = rebuildRequired || result.rebuildRequired === true
    saving = false
    statusError = false
    statusMessage = result.changed === false ? "No changes to save" : "Settings saved"
  }

  IpcHandler {
    target: "settings"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Process {
    id: backend
    stdinEnabled: true

    stdout: StdioCollector {
      id: output
    }

    stderr: StdioCollector {
      id: errorOutput
    }

    onStarted: {
      if (root.pendingJson !== "") {
        write(root.pendingJson)
        root.pendingJson = ""
      }
    }

    onExited: function(exitCode) {
      const raw = output.text.trim() !== "" ? output.text : errorOutput.text
      root.handleResult(raw, exitCode)
    }
  }

  Process {
    id: statusProcess
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text)
          if (result.ok === true)
            root.rebuildRequired = result.rebuildRequired === true
        } catch (error) {
        }
      }
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: root.opened && root.rebuildRequired
    onTriggered: if (!statusProcess.running)
      statusProcess.exec(["atlas", "settings", "status"])
  }

  component SectionTitle: ColumnLayout {
    property string title: ""
    property string description: ""
    Layout.fillWidth: true
    spacing: Theme.spaceXs

    Text {
      text: parent.title
      color: Theme.foreground
      font.pixelSize: Theme.fontDisplay
      font.weight: Theme.weightStrong
    }
    Text {
      Layout.fillWidth: true
      text: parent.description
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontBody
      wrapMode: Text.WordWrap
    }
  }

  component LabeledField: ColumnLayout {
    id: fieldRoot
    property string label: ""
    property string fieldText: ""
    property string placeholder: ""
    property string accessibleName: label
    signal committed(string value)
    Layout.fillWidth: true
    spacing: Theme.spaceXs

    Text {
      text: fieldRoot.label
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
      font.weight: Theme.weightMedium
    }
    TextField {
      Layout.fillWidth: true
      Layout.preferredHeight: 34
      text: fieldRoot.fieldText
      placeholderText: fieldRoot.placeholder
      selectByMouse: true
      color: Theme.foreground
      placeholderTextColor: Theme.foregroundMuted
      font.pixelSize: Theme.fontBody
      leftPadding: Theme.spaceSm
      rightPadding: Theme.spaceSm
      Accessible.name: fieldRoot.accessibleName
      background: Rectangle {
        color: Theme.surfaceHover
        radius: Theme.radiusSm
        border.width: Theme.borderWidth
        border.color: parent.activeFocus ? Theme.accent : Theme.border
      }
      onEditingFinished: fieldRoot.committed(text)
    }
  }

  component ToggleRow: RowLayout {
    id: toggleRoot
    property string label: ""
    property string description: ""
    property bool checked: false
    signal changed(bool checked)
    Layout.fillWidth: true
    spacing: Theme.spaceMd

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1
      Text {
        text: toggleRoot.label
        color: Theme.foreground
        font.pixelSize: Theme.fontBody
      }
      Text {
        visible: text !== ""
        text: toggleRoot.description
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
      }
    }
    Toggle {
      checked: toggleRoot.checked
      accessibleName: toggleRoot.label
      onToggled: function(value) { toggleRoot.changed(value) }
    }
  }

  FloatingWindow {
    id: window
    visible: root.opened
    title: "Atlas Settings"
    implicitWidth: 900
    implicitHeight: 650
    minimumSize: Qt.size(720, 520)
    color: Theme.background
    onClosed: root.opened = false

    Shortcut {
      sequence: "Escape"
      onActivated: root.close()
    }

    Shortcut {
      sequence: "Up"
      onActivated: root.focusSettingsOption(false)
    }

    Shortcut {
      sequence: "Down"
      onActivated: root.focusSettingsOption(true)
    }

    Rectangle {
      anchors.fill: parent
      color: Theme.background

      RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
          Layout.fillHeight: true
          Layout.preferredWidth: 190
          color: Theme.surface
          border.width: Theme.borderWidth
          border.color: Theme.border

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceXs

            RowLayout {
              Layout.fillWidth: true
              Layout.bottomMargin: Theme.spaceLg
              spacing: Theme.spaceSm
              IconImage {
                implicitWidth: 22
                implicitHeight: 22
                source: Qt.resolvedUrl("../assets/nix-snowflake.svg")
              }
              Text {
                text: "Atlas Settings"
                color: Theme.foreground
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.weightStrong
              }
            }

            Repeater {
              id: categoryRepeater
              model: root.pages
              Button {
                id: categoryButton
                required property var modelData
                required property int index
                property bool categoryNavigationButton: true
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                horizontalPadding: Theme.spaceSm
                buttonColor: root.currentSection === modelData.key ? Theme.surfaceHover : Theme.surface
                buttonBorderColor: root.currentSection === modelData.key ? Theme.accent : Theme.surface
                accessibleName: modelData.label + " settings"
                onClicked: root.selectPage(index)
                Keys.onTabPressed: root.cyclePage(1)
                Keys.onBacktabPressed: root.cyclePage(-1)
                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: categoryButton.horizontalPadding
                  anchors.rightMargin: categoryButton.horizontalPadding
                  spacing: Theme.spaceSm
                  Text {
                    text: modelData.symbol
                    color: root.currentSection === modelData.key ? Theme.accent : Theme.foregroundMuted
                    font.pixelSize: Theme.fontTitle
                  }
                  Text {
                    Layout.fillWidth: true
                    text: modelData.label
                    color: Theme.foreground
                    font.pixelSize: Theme.fontBody
                    font.weight: root.currentSection === modelData.key ? Theme.weightStrong : Theme.weightRegular
                  }
                }
              }
            }

            Item { Layout.fillHeight: true }

            Text {
              Layout.fillWidth: true
              visible: root.rebuildRequired
              text: "NixOS rebuild required"
              color: Theme.warning
              font.pixelSize: Theme.fontCaption
              wrapMode: Text.WordWrap
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.margins: Theme.spaceXl
          spacing: Theme.spaceMd

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            visible: root.sectionErrors[root.currentSection] !== undefined
            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
            border.width: Theme.borderWidth
            border.color: Theme.error
            radius: Theme.radiusMd
            Text {
              anchors.fill: parent
              anchors.margins: Theme.spaceSm
              text: root.sectionErrors[root.currentSection]
                ? root.sectionErrors[root.currentSection].message + "\n" + root.sectionErrors[root.currentSection].path
                : ""
              color: Theme.error
              font.pixelSize: Theme.fontCaption
              wrapMode: Text.WordWrap
            }
          }

          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            Loader {
              width: parent.width
              sourceComponent: root.currentSection === "system" ? systemPage
                : displaysPage
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm
            Text {
              Layout.fillWidth: true
              text: root.loading ? "Loading settings…" : root.statusMessage
              color: root.statusError ? Theme.error : Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
              elide: Text.ElideRight
            }
            Button {
              visible: root.currentSection === "system" && root.rebuildRequired
              enabled: !root.saving
              accessibleName: "Rebuild NixOS"
              onClicked: Quickshell.execDetached(["kitty", "--class", "atlas-rebuild", "--hold", "atlas", "rebuild"])
              Text { anchors.centerIn: parent; text: "Rebuild NixOS"; color: Theme.foreground; font.pixelSize: Theme.fontBody }
            }
            Button {
              enabled: root.dirtySections[root.currentSection] === true && !root.saving
              accessibleName: "Discard changes"
              onClicked: root.resetSection()
              Text { anchors.centerIn: parent; text: "Reset"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontBody }
            }
            Button {
              enabled: root.sectionAvailable(root.currentSection)
                && root.dirtySections[root.currentSection] === true && !root.saving
              buttonColor: enabled ? Theme.accent : Theme.surfaceHover
              buttonBorderColor: enabled ? Theme.accent : Theme.border
              accessibleName: "Save current settings page"
              onClicked: root.saveSection()
              Text { anchors.centerIn: parent; text: root.saving ? "Saving…" : "Save"; color: enabled ? Theme.background : Theme.foregroundMuted; font.pixelSize: Theme.fontBody; font.weight: Theme.weightStrong }
            }
          }
        }
      }
    }
  }

  Component {
    id: systemPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceMd
      SectionTitle { title: "System"; description: "Machine identity and optional Atlas modules. Saving validates the complete NixOS configuration before changing it." }
      LabeledField { label: "Hostname"; fieldText: root.value("system", "hostname", ""); onCommitted: function(value) { root.setValue("system", "hostname", value) } }
      LabeledField { label: "Timezone"; placeholder: "America/Mexico_City"; fieldText: root.value("system", "timezone", ""); onCommitted: function(value) { root.setValue("system", "timezone", value) } }
      Text { text: "Optional modules"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
      Repeater {
        model: ["bluetooth", "development", "media", "productivity", "laptop", "nvidia"]
        ToggleRow {
          required property string modelData
          label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
          checked: root.value("system", "modules", []).indexOf(modelData) !== -1
          onChanged: function(enabled) {
            const modules = root.clone(root.value("system", "modules", []))
            const index = modules.indexOf(modelData)
            if (enabled && index === -1) modules.push(modelData)
            if (!enabled && index !== -1) modules.splice(index, 1)
            root.setValue("system", "modules", modules)
          }
        }
      }
    }
  }

  Component {
    id: displaysPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceMd
      SectionTitle { title: "Displays"; description: "Configure Hyprland monitor rules. Use an empty output as a fallback rule for every display." }
      Repeater {
        model: root.value("displays", "monitors", [])
        Rectangle {
          required property var modelData
          required property int index
          Layout.fillWidth: true
          implicitHeight: monitorLayout.implicitHeight + Theme.spaceLg * 2
          color: Theme.surface
          border.width: Theme.borderWidth
          border.color: Theme.border
          radius: Theme.radiusMd
          ColumnLayout {
            id: monitorLayout
            anchors.fill: parent
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceSm
            RowLayout {
              Layout.fillWidth: true
              Text { Layout.fillWidth: true; text: modelData.output || "Fallback monitor"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
              Button { enabled: root.value("displays", "monitors", []).length > 1; onClicked: root.removeMonitor(index); Text { anchors.centerIn: parent; text: "Remove"; color: Theme.foreground; font.pixelSize: Theme.fontCaption } }
            }
            RowLayout {
              Layout.fillWidth: true
              spacing: Theme.spaceSm
              LabeledField { Layout.fillWidth: true; label: "Output"; placeholder: "DP-1 or empty"; fieldText: modelData.output; onCommitted: function(value) { root.updateMonitor(index, "output", value) } }
              LabeledField { Layout.fillWidth: true; label: "Mode"; placeholder: "preferred"; fieldText: modelData.mode; onCommitted: function(value) { root.updateMonitor(index, "mode", value) } }
            }
            RowLayout {
              Layout.fillWidth: true
              spacing: Theme.spaceSm
              LabeledField { Layout.fillWidth: true; label: "Position"; placeholder: "auto or 0x0"; fieldText: modelData.position; onCommitted: function(value) { root.updateMonitor(index, "position", value) } }
              LabeledField { Layout.fillWidth: true; label: "Scale"; placeholder: "1"; fieldText: modelData.scale; onCommitted: function(value) { root.updateMonitor(index, "scale", value) } }
            }
          }
        }
      }
      Button { accessibleName: "Add monitor rule"; onClicked: root.addMonitor(); Text { anchors.centerIn: parent; text: "Add monitor"; color: Theme.foreground; font.pixelSize: Theme.fontBody } }
    }
  }

}
