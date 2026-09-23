import QtQuick
import QtQuick.Layouts
import "../"

Rectangle {
  id: root

  property color buttonColor: root.hovered
    ? Theme.surfaceHover
    : Theme.surface

  property color buttonBorderColor: root.hovered
    ? Theme.borderFocus
    : Theme.surface

  property int buttonBorderWidth: Theme.borderWidth
  property real horizontalPadding: Theme.radiusMd
  property real verticalPadding: Theme.spaceXxs

  readonly property bool hovered: hoverHandler.hovered
  readonly property bool pressed: mouseArea.pressed
  readonly property Item contentItem: contentHost.children.length > 0
    ? contentHost.children[0]
    : null

  default property alias content: contentHost.data

  signal clicked()
  signal middleClicked()
  signal wheelMoved(bool up)

  implicitWidth: (contentItem ? contentItem.implicitWidth : 0) + horizontalPadding * 2
  implicitHeight: (contentItem ? contentItem.implicitHeight : 0) + verticalPadding * 2

  radius: Theme.radiusSm

  color: buttonColor
  border.width: buttonBorderWidth
  border.color: buttonBorderColor

  scale: root.pressed ? 0.94 : 1.0
  opacity: root.pressed ? 0.75 : 1.0
  transformOrigin: Item.Center

  Behavior on scale {
    NumberAnimation {
      duration: Theme.motionQuick
      easing.type: Easing.OutQuad
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: Theme.motionQuick
      easing.type: Easing.OutQuad
    }
  }

  Behavior on color {
    ColorAnimation {
      duration: Theme.motionQuick
      easing.type: Easing.OutQuad
    }
  }

  Behavior on border.color {
    ColorAnimation {
      duration: Theme.motionQuick
      easing.type: Easing.OutQuad
    }
  }

  Behavior on border.width {
    NumberAnimation {
      duration: Theme.motionQuick
      easing.type: Easing.OutQuad
    }
  }

  Item {
    id: contentHost

    anchors.fill: parent
    z: 1
  }

  HoverHandler {
    id: hoverHandler

    cursorShape: Qt.PointingHandCursor
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) {
        root.middleClicked()
        return
      }

      root.clicked()
    }

    onWheel: function(wheel) {
      root.wheelMoved(wheel.angleDelta.y > 0)
      wheel.accepted = true
    }
  }
}
