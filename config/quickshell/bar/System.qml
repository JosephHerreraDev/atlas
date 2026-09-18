import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  RowLayout {
    spacing: 0
    SystemButton{
      id: systemButton 
    }
    NotificationButton{
      id: notifcationButton
    }
  }
}
