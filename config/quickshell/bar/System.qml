import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  id: root

  required property var notifications

  function togglePanel(): void {
    systemTray.toggle()
  }

  RowLayout {
    spacing: 0
    SystemTray{
      id: systemTray
    }
    SystemButton{
      id: systemButton
      popupAnchor: root
      notifications: root.notifications
    }
  }
}
