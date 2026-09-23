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

Scope {
  id: root

  property bool opened: false
  property bool mounted: false
  property int selectedIndex: 0
  property int focusRequest: 0

  readonly property int animationDuration: Theme.motionNormal - 20
  readonly property int actionSize: 76
  readonly property int actionSpacing: Theme.radiusMd
  readonly property var actions: [
    { name: "Lock", description: "Lock the current session", icon: "lock.svg", command: ["hyprlock"] },
    { name: "Log out", description: "End the current session", icon: "logout.svg", command: ["hyprctl", "dispatch", "exit"] },
    { name: "Suspend", description: "Suspend this computer", icon: "suspend.svg", command: ["systemctl", "suspend"] },
    { name: "Restart", description: "Restart this computer", icon: "restart.svg", command: ["systemctl", "reboot"] },
    { name: "Shut down", description: "Power off this computer", icon: "power.svg", command: ["systemctl", "poweroff"] }
  ]

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
    selectedIndex = 0
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

  function moveSelection(delta): void {
    selectedIndex = Math.max(0, Math.min(selectedIndex + delta, actions.length - 1))
  }

  function runAction(action): void {
    if (!action)
      return
    close()
    Quickshell.execDetached(action.command)
  }

  IpcHandler {
    target: "powermenu"
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
      WlrLayershell.namespace: "powermenu"
      anchors { top: true; bottom: true; left: true; right: true }

      function focusMenu(): void {
        Qt.callLater(function() { keyboardHandler.forceActiveFocus() })
      }

      onVisibleChanged: if (visible) focusMenu()

      Connections {
        target: root
        function onFocusRequestChanged(): void {
          if (window.visible) window.focusMenu()
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
        width: Math.min(root.actions.length * root.actionSize
                        + (root.actions.length - 1) * root.actionSpacing + 28,
                        window.width - 32)
        height: root.actionSize + 28
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
          spacing: 0

          Item {
            id: keyboardHandler
            Layout.fillWidth: true
            Layout.preferredHeight: root.actionSize
            focus: true

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                root.moveSelection(1)
                event.accepted = true
              } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                root.moveSelection(-1)
                event.accepted = true
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.runAction(root.actions[root.selectedIndex])
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              }
            }

            ListView {
              id: actionList
              anchors.fill: parent
              model: root.actions
              currentIndex: root.selectedIndex
              interactive: false
              orientation: ListView.Horizontal
              spacing: root.actionSpacing

              delegate: Rectangle {
                id: actionRow
                required property int index
                required property var modelData
                width: root.actionSize
                height: root.actionSize
                radius: Theme.radiusMd
                color: ListView.isCurrentItem || actionMouse.containsMouse ? Theme.color3 : Theme.color1
                border.width: ListView.isCurrentItem || actionMouse.containsMouse
                  ? Theme.borderWidth : 0
                border.color: ListView.isCurrentItem ? Theme.selectionForeground : Theme.color3

                Column {
                  anchors.centerIn: parent
                  width: parent.width
                  spacing: 3

                  IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 28
                    height: 28
                    source: Qt.resolvedUrl("../assets/" + actionRow.modelData.icon)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                      brightness: 1
                      colorization: 1
                      colorizationColor: actionRow.ListView.isCurrentItem || actionMouse.containsMouse
                        ? Theme.selectionForeground : Theme.foreground
                    }
                  }

                  Text {
                    width: parent.width
                    text: actionRow.modelData.name
                    color: actionRow.ListView.isCurrentItem || actionMouse.containsMouse
                      ? Theme.selectionForeground : Theme.foreground
                    font.pixelSize: Theme.fontBody
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                  }
                }

                ToolTip.visible: actionMouse.containsMouse
                ToolTip.text: actionRow.modelData.name

                MouseArea {
                  id: actionMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selectedIndex = actionRow.index
                  onClicked: root.runAction(actionRow.modelData)
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
