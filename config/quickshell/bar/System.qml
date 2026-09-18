import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  RowLayout {
    spacing: 0
    SystemTray{
      id: systemTray
    }
    SystemButton{
      id: systemButton 
    }
    NotificationButton{
      id: notifcationButton
    }
  }
}
