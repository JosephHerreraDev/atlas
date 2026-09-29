import QtQuick
import "../"

Rectangle {
  id: root

  property bool checked: false
  property string accessibleName: "Toggle"
  signal toggled(bool checked)

  implicitWidth: 34
  implicitHeight: 18
  radius: height / 2
  color: checked ? Theme.color8 : Theme.color2
  opacity: enabled ? 1 : 0.5
  border.width: Theme.borderWidth
  border.color: activeFocus || hoverHandler.hovered
    ? Theme.foreground
    : color
  activeFocusOnTab: true

  Accessible.role: Accessible.CheckBox
  Accessible.name: accessibleName
  Accessible.checked: checked
  Accessible.focusable: true

  Behavior on color {
    ColorAnimation { duration: Theme.motionFast }
  }

  Rectangle {
    width: 12
    height: 12
    radius: Theme.radiusMd
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? root.width - width - 3 : 3
    color: root.checked ? Theme.color0 : Theme.foreground

    Behavior on x {
      NumberAnimation {
        duration: Theme.motionFast + 20
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
    onTapped: {
      root.forceActiveFocus()
      root.toggled(!root.checked)
    }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return
        || event.key === Qt.Key_Enter) {
      root.toggled(!root.checked)
      event.accepted = true
    }
  }
}
