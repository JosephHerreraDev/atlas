import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  id: root

  required property var notifications
  required property var shellScreen

  RowLayout {
    spacing: 0
    SystemTray{
      id: systemTray
      popupAnchor: root
    }
    SystemButton{
      id: systemButton
      popupAnchor: root
    }
    NotificationButton{
      id: notifcationButton
      notifications: root.notifications
      shellScreen: root.shellScreen
    }
  }
}
