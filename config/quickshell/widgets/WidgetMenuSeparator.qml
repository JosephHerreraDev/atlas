import QtQuick
import QtQuick.Controls as Controls
import "../"

Controls.MenuSeparator {
  id: root
  property var menuColors: null
  padding: 4
  contentItem: Rectangle {
    implicitWidth: 220
    implicitHeight: 1
    color: root.menuColors ? root.menuColors.separatorColor : Theme.border
  }
}
