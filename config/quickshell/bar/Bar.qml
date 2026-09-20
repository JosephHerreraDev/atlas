import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  property QtObject systemState
  required property var notifications
  signal systemTrayToggleRequested()

  IpcHandler {
    target: "system-tray"

    function toggle(): void {
      root.systemTrayToggleRequested()
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      readonly property int screenGap: 2
      readonly property int barHeight: 30

      color: "#00000000"

      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      margins {
        top: screenGap
        left: 10
        right: 10
      }

      implicitHeight: barHeight
      exclusiveZone: screenGap + barHeight - (10)

      Item {
        anchors.fill: parent

        Workspaces{
          id: workspaces
          shellScreen: modelData

          anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
          }
        }

        ClockWidget {
          id: clock

          anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
          }
        }

        System {
          id: system
          notifications: root.notifications

          anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
          }
        }

        Connections {
          target: root

          function onSystemTrayToggleRequested(): void {
            if (Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)
              system.togglePanel()
          }
        }
      }
    }
  }
}
