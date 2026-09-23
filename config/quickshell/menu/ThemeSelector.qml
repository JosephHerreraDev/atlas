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
  property bool mounted: false
  property string query: ""
  property int selectedIndex: -1
  property int focusRequest: 0
  property var themes: []

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
    mounted = true
    opened = false
    query = ""
    refresh()
    filter()
    Qt.callLater(function() {
      if (root.mounted) {
        opened = true
        focusRequest += 1
      }
    })
  }

  function close(): void {
    MenuState.deactivate(root)
    opened = false
    hideTimer.restart()
  }

  function toggle(): void { opened ? close() : open() }

  function refresh(): void {
    if (!listProcess.running)
      listProcess.exec(["theme-colors", "--all"])
  }

  function filter(): void {
    const needle = query.trim().toLowerCase()
    filteredThemes = themes.filter(function(name) {
      return needle.length === 0 || name.indexOf(needle) !== -1
    })
    selectedIndex = filteredThemes.length > 0 ? 0 : -1
  }

  function moveSelection(delta): void {
    if (filteredThemes.length === 0) {
      selectedIndex = -1
      return
    }
    selectedIndex = Math.max(0, Math.min(selectedIndex + delta,
      filteredThemes.length - 1))
  }

  function selectTheme(name): void {
    if (!name)
      return
    close()
    Quickshell.execDetached(["theme-set", name])
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
          names.push(name)
          palettes[name] = fields
        })
        root.themePalettes = palettes
        root.themes = names
        root.filter()
      }
    }
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
    onTriggered: if (!root.opened) root.mounted = false
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
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.namespace: "prometheus-theme-selector"
      anchors { top: true; bottom: true; left: true; right: true }

      function focusInput(): void {
        Qt.callLater(function() { input.forceActiveFocus(); input.selectAll() })
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
        width: Math.min(400, window.width - 32)
        implicitHeight: content.implicitHeight + 28
        anchors.centerIn: parent
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        radius: Theme.radiusLg
        color: Theme.color0
        border.width: Theme.borderWidth
        border.color: Theme.border
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        Behavior on scale { NumberAnimation { duration: root.animationDuration } }
        MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

        ColumnLayout {
          id: content
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
          spacing: Theme.spaceSm + Theme.spaceXxs

          Text {
            text: "Themes"
            color: Theme.color6
            font.pixelSize: Theme.fontDisplay
            font.weight: Theme.weightStrong
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
            onTextChanged: root.query = text
            onAccepted: if (root.selectedIndex >= 0)
              root.selectTheme(root.filteredThemes[root.selectedIndex])
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Down) {
                root.moveSelection(1)
                themeList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                root.moveSelection(-1)
                themeList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close(); event.accepted = true
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
            text: "No themes found"
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
            Layout.preferredHeight: Math.min(7, root.filteredThemes.length) * 46
            clip: true
            interactive: root.filteredThemes.length > 7
            model: root.filteredThemes
            currentIndex: root.selectedIndex
            spacing: Theme.spaceXs
            boundsBehavior: Flickable.StopAtBounds
            onCurrentIndexChanged: if (currentIndex >= 0)
              positionViewAtIndex(currentIndex, ListView.Contain)
            ScrollBar.vertical: ScrollBar {
              policy: root.filteredThemes.length > 7
                ? ScrollBar.AsNeeded
                : ScrollBar.AlwaysOff
            }
            delegate: Rectangle {
              id: themeRow
              required property int index
              required property string modelData
              readonly property var palette: root.themePalettes[modelData] || []
              width: themeList.width
              height: 42
              radius: Theme.radiusMd
              color: ListView.isCurrentItem || mouse.containsMouse ? Theme.color1 : Theme.color0
              border.width: ListView.isCurrentItem ? Theme.borderWidth : 0
              border.color: Theme.borderFocus
              RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: Theme.radiusMd

                Text {
                  Layout.fillWidth: true
                  text: themeRow.modelData.replace(/-/g, " ")
                  color: themeRow.ListView.isCurrentItem ? Theme.color6 : Theme.color4
                  font.pixelSize: 13
                  font.weight: themeRow.ListView.isCurrentItem
                    ? Theme.weightStrong : Theme.weightMedium
                  elide: Text.ElideRight
                }

                Repeater {
                  model: themeRow.palette

                  Rectangle {
                    required property string modelData
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    radius: Theme.radiusMd
                    color: modelData
                    border.width: Theme.borderWidth
                    border.color: Theme.border
                  }
                }
              }
              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.selectedIndex = index
                onClicked: root.selectTheme(modelData)
              }
            }
          }
        }
      }

      Shortcut { sequence: "Escape"; enabled: root.opened; onActivated: root.close() }
    }
  }
}
