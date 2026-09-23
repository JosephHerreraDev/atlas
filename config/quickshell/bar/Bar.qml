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
  signal clipboardMenuToggleRequested(var opened)

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

  IpcHandler {
    target: "clipboard"

    function open(): void { root.clipboardMenuToggleRequested(true) }
    function close(): void { root.clipboardMenuToggleRequested(false) }
    function toggle(): void { root.clipboardMenuToggleRequested(null) }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      readonly property int screenGap: 2
      readonly property int barHeight: 30
      readonly property int clockTopMargin: Math.max(0,
        (barHeight - clock.collapsedImplicitHeight) / 2)
      readonly property int surfaceHeight: Math.max(64,
        clock.maximumImplicitHeight + clockTopMargin)

      color: "#00000000"

      required property var modelData
      screen: modelData
      focusable: clock.menuClosable
      WlrLayershell.keyboardFocus: clock.menuClosable
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      HyprlandFocusGrab {
        windows: [window]
        active: clock.calendarVisible || clock.clipboardVisible

        onCleared: {
          clock.calendarVisible = false
          clock.closeClipboardMenu()
        }
      }

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
            topMargin: clockTopMargin
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

          function onClipboardMenuToggleRequested(opened): void {
            if (Hyprland.monitorFor(modelData) !== Hyprland.focusedMonitor)
              return
            if (opened === true)
              clock.openClipboardMenu()
            else if (opened === false)
              clock.closeClipboardMenu()
            else
              clock.toggleClipboardMenu()
          }
        }
      }
    }
  }
}
