import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  property QtObject systemState
  required property var notifications
  signal systemTrayToggleRequested()
  signal screenshotMenuToggleRequested()

  IpcHandler {
    target: "system-tray"

    function toggle(): void {
      root.systemTrayToggleRequested()
    }
  }

  IpcHandler {
    target: "screenshot-menu"

    function toggle(): void {
      root.screenshotMenuToggleRequested()
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      readonly property int screenGap: 2
      readonly property int barHeight: 30
      readonly property int surfaceHeight: 64

      color: "#00000000"

      required property var modelData
      screen: modelData
      focusable: clock.screenshotMenuClosable
      WlrLayershell.keyboardFocus: clock.screenshotMenuClosable
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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

      implicitHeight: surfaceHeight
      exclusiveZone: screenGap + barHeight - (10)

      mask: Region {
        Region {
          intersection: Intersection.Combine
          x: Math.floor(workspaces.x)
          y: Math.floor(workspaces.y)
          width: Math.ceil(workspaces.width)
          height: Math.ceil(workspaces.height)
        }

        Region {
          intersection: Intersection.Combine
          x: Math.floor(clock.x)
          y: Math.floor(clock.y)
          width: Math.ceil(clock.width)
          height: Math.ceil(clock.height)
        }

        Region {
          intersection: Intersection.Combine
          x: Math.floor(system.x)
          y: Math.floor(system.y)
          width: Math.ceil(system.width)
          height: Math.ceil(system.height)
        }
      }

      Item {
        anchors.fill: parent

        Workspaces{
          id: workspaces
          shellScreen: modelData
          width: implicitWidth
          height: implicitHeight

          anchors {
            left: parent.left
            top: parent.top
            topMargin: Math.max(0, (barHeight - workspaces.implicitHeight) / 2)
          }
        }

        ClockWidget {
          id: clock
          width: implicitWidth
          height: implicitHeight

          anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
          }
        }

        System {
          id: system
          notifications: root.notifications
          width: implicitWidth
          height: implicitHeight

          anchors {
            right: parent.right
            top: parent.top
            topMargin: Math.max(0, (barHeight - system.implicitHeight) / 2)
          }
        }

        Connections {
          target: root

          function onSystemTrayToggleRequested(): void {
            if (Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)
              system.togglePanel()
          }

          function onScreenshotMenuToggleRequested(): void {
            if (Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)
              clock.toggleScreenshotMenu()
          }
        }
      }
    }
  }
}
