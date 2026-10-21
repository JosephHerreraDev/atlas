import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../"

Scope {
  id: root
  property bool opened: false
  property bool mounted: false

  function open(): void {
    hideTimer.stop()
    mounted = true
    opened = true
  }
  function close(): void {
    opened = false
    hideTimer.restart()
  }
  function toggle(): void { opened ? close() : open() }

  IpcHandler {
    target: "clipboard"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Timer {
    id: hideTimer
    interval: 320
    onTriggered: if (!root.opened) root.mounted = false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData
      readonly property bool focused: {
        const monitor = Hyprland.monitorFor(modelData)
        return monitor !== null && Hyprland.focusedMonitor !== null
          && monitor.name === Hyprland.focusedMonitor.name
      }

      screen: modelData
      visible: root.mounted && focused
      color: "transparent"
      focusable: root.opened
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      WlrLayershell.namespace: "atlas-clipboard"
      anchors { top: true; bottom: true; left: true; right: true }

      HyprlandFocusGrab {
        windows: [window]
        active: root.opened
        onCleared: root.close()
      }

      MouseArea {
        anchors.fill: parent
        enabled: root.opened
        onClicked: root.close()
      }

      Rectangle {
        id: card
        readonly property string horizontalPlacement: Placement.horizontal(Placement.clipboard)
        readonly property string verticalPlacement: Placement.vertical(Placement.clipboard)
        width: Math.min(640, window.width - 48)
        height: clipboardMenu.implicitHeight
        x: Placement.itemX(Placement.clipboard, window.width, width, Placement.edgeMargin)
        y: Placement.itemY(Placement.clipboard, window.height, height,
          Placement.edgeMargin + BarStyle.topClearance,
          Placement.edgeMargin + BarStyle.bottomClearance)
        radius: Theme.radiusLg
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b,
          Theme.popupOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.borderFocus
        opacity: root.opened ? 1 : 0

        transform: Translate {
          y: root.opened ? 0 : (card.verticalPlacement === "top"
            ? -card.height - 24 : card.height + 24)
          Behavior on y {
            SpringAnimation {
              spring: 12
              damping: 0.75
              epsilon: 0.01
            }
          }
        }
        Behavior on opacity {
          NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) { mouse.accepted = true }
        }

        ClipboardHistoryMenu {
          id: clipboardMenu
          anchors.fill: parent
          clipboardVisible: root.opened && window.focused
          onCloseRequested: root.close()
        }
      }

      Connections {
        target: root
        function onOpenedChanged(): void {
          if (root.opened && window.focused)
            clipboardMenu.open()
          else
            clipboardMenu.close()
        }
      }
    }
  }
}
