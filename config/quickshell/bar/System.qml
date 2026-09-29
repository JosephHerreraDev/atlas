import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  id: root

  required property var notifications
  readonly property bool trayRevealed: systemTray.revealed

  function togglePanel(): void {
    if (!systemButton.panelVisible)
      systemTray.collapse()
    systemButton.panelVisible = !systemButton.panelVisible
  }

  function toggleTray(): void {
    if (!systemTray.revealed)
      systemButton.panelVisible = false
    systemTray.toggle()
  }

  function collapseTray(): void {
    systemTray.collapse()
  }

  RowLayout {
    spacing: 0
    SystemTray {
      id: systemTray

      onRevealedChanged: {
        if (revealed)
          systemButton.panelVisible = false
      }
    }
    SystemButton {
      id: systemButton
      popupAnchor: root
      notifications: root.notifications

      onPanelVisibleChanged: {
        if (panelVisible)
          systemTray.collapse()
      }
    }
  }
}
