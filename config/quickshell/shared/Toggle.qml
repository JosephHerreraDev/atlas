import QtQuick
import "../"

Rectangle {
  id: root

  property bool checked: false
  signal toggled(bool checked)

  implicitWidth: 34
  implicitHeight: 18
  radius: height / 2
  color: checked ? Theme.color8 : Theme.color2
  opacity: enabled ? 1 : 0.5
  border.width: 1
  border.color: hoverHandler.hovered ? Theme.foreground : color

  Behavior on color {
    ColorAnimation { duration: 100 }
  }

  Rectangle {
    width: 12
    height: 12
    radius: 6
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? root.width - width - 3 : 3
    color: root.checked ? Theme.color0 : Theme.foreground

    Behavior on x {
      NumberAnimation {
        duration: 120
        easing.type: Easing.OutCubic
      }
    }
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
  }

  TapHandler {
    enabled: root.enabled
    onTapped: root.toggled(!root.checked)
  }
}
