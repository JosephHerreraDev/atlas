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

  readonly property int animationDuration: 140
  readonly property var themes: [
    "catppuccin", "everforest", "ghost-pastel", "gotham-city", "gruvbox",
    "gruvu", "inkypinky", "lumon", "matte-black", "miasma", "nord",
    "osaka-jade", "retro-82", "ristretto", "saga", "solitude",
    "tokyo-night", "van-gogh", "windows-dark-mode"
  ]
  readonly property var themePalettes: ({
    "catppuccin": ["#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7"],
    "everforest": ["#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6"],
    "ghost-pastel": ["#b37580", "#648ed0", "#e095b5", "#979fec", "#cd9dcf"],
    "gotham-city": ["#d45a4a", "#6b8a72", "#d9b768", "#4a6b7c", "#8c6a7a"],
    "gruvbox": ["#ea6962", "#a9b665", "#d8a657", "#7daea3", "#d3869b"],
    "gruvu": ["#cc241d", "#b8bb26", "#d79921", "#83a598", "#d3869b"],
    "inkypinky": ["#ea90a8", "#a6b2c7", "#d18ba2", "#7c7ca8", "#9f859f"],
    "lumon": ["#4d86b0", "#5e95bc", "#6fa4c9", "#6fb8e3", "#8bc9eb"],
    "matte-black": ["#d35f5f", "#ffc107", "#b91c1c", "#e68e0d", "#d35f5f"],
    "miasma": ["#685742", "#5f875f", "#b36d43", "#78824b", "#bb7744"],
    "nord": ["#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead"],
    "osaka-jade": ["#ff5345", "#549e6a", "#459451", "#509475", "#d2689c"],
    "retro-82": ["#f85525", "#028391", "#e97b3c", "#faa968", "#3f8f8a"],
    "ristretto": ["#fd6883", "#adda78", "#f9cc6c", "#f38d70", "#a8a9eb"],
    "saga": ["#ff9fbc", "#baf7b5", "#fff6c3", "#b2fff3", "#dfbaff"],
    "solitude": ["#565d60", "#9fa5a9", "#d9dbdc", "#798186", "#aeaeae"],
    "tokyo-night": ["#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#ad8ee6"],
    "van-gogh": ["#d9822b", "#7fb3d5", "#f2e2a4", "#4a78a8", "#d9822b"],
    "windows-dark-mode": ["#f85149", "#2ea043", "#bb8009", "#0078d4", "#c586c0"]
  })
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
        radius: 8
        color: Theme.color0
        border.width: 1
        border.color: Theme.color2
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        Behavior on scale { NumberAnimation { duration: root.animationDuration } }
        MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

        ColumnLayout {
          id: content
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
          spacing: 10

          Text {
            text: "Themes"
            color: Theme.color6
            font.pixelSize: 18
            font.weight: Font.DemiBold
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
              radius: 6
              color: Theme.color1
              border.width: 1
              border.color: input.activeFocus ? Theme.color8 : Theme.color3
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
            spacing: 4
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
              radius: 6
              color: ListView.isCurrentItem || mouse.containsMouse ? Theme.color1 : Theme.color0
              border.width: ListView.isCurrentItem ? 1 : 0
              border.color: Theme.color8
              RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Text {
                  Layout.fillWidth: true
                  text: themeRow.modelData.replace(/-/g, " ")
                  color: themeRow.ListView.isCurrentItem ? Theme.color6 : Theme.color4
                  font.pixelSize: 13
                  font.weight: themeRow.ListView.isCurrentItem ? Font.DemiBold : Font.Medium
                  elide: Text.ElideRight
                }

                Repeater {
                  model: themeRow.palette

                  Rectangle {
                    required property string modelData
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    radius: 6
                    color: modelData
                    border.width: 1
                    border.color: Theme.color2
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
