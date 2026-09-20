import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  id: root

  required property var notifications

  function togglePanel(): void {
    systemButton.panelVisible = !systemButton.panelVisible
  }

  RowLayout {
    spacing: 0
    SystemTray{
      id: systemTray
      popupAnchor: root
    }
    SystemButton{
      id: systemButton
      popupAnchor: root
      notifications: root.notifications
    }
  }
}
