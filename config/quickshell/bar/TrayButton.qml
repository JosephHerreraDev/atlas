import QtQuick
import "../"

Item {
  id: root

  required property string accessibleName
  property bool attention: false
  property bool selected: false
  property int buttonSize: Theme.barControlHeight
  property real backgroundOpacity: 0.2

  readonly property bool hovered: mouse.containsMouse
  readonly property bool pressed: mouse.pressed

  default property alias content: contentHost.data

  signal clicked(int button)
  signal wheelMoved(int delta, bool horizontal)
  signal navigate(int direction)
  signal cancel()

  implicitWidth: buttonSize
  implicitHeight: buttonSize
  activeFocusOnTab: true
  scale: pressed ? 0.94 : 1

  Accessible.role: Accessible.Button
  Accessible.name: accessibleName
  Accessible.focusable: true

  Behavior on scale {
    NumberAnimation {
      duration: Theme.motionQuick
      easing.type: Easing.OutQuad
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusSm
    color: {
      if (root.attention)
        return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b,
          root.backgroundOpacity)
      return root.hovered || root.selected || root.activeFocus
        ? Theme.surfaceHover
        : "transparent"
    }
    border.width: root.attention || root.selected || root.activeFocus
      ? Theme.borderWidth
      : 0
    border.color: root.attention ? Theme.warning : Theme.accent

    Behavior on color {
      ColorAnimation { duration: Theme.motionFast }
    }

    Behavior on border.color {
      ColorAnimation { duration: Theme.motionFast }
    }
  }

  Item {
    id: contentHost

    anchors.fill: parent
    z: 1
  }

  Rectangle {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 2
    width: 5
    height: 5
    radius: 2.5
    visible: root.attention
    color: Theme.warning
    z: 2

    SequentialAnimation on opacity {
      running: root.attention
      loops: Animation.Infinite
      NumberAnimation {
        from: 1
        to: 0.45
        duration: Theme.motionSlow * 3
        easing.type: Easing.InOutSine
      }
      NumberAnimation {
        from: 0.45
        to: 1
        duration: Theme.motionSlow * 3
        easing.type: Easing.InOutSine
      }
    }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || event.key === Qt.Key_Space) {
      root.clicked(Qt.LeftButton)
      event.accepted = true
    } else if (event.key === Qt.Key_Menu) {
      root.clicked(Qt.RightButton)
      event.accepted = true
    } else if (event.key === Qt.Key_Left) {
      root.navigate(-1)
      event.accepted = true
    } else if (event.key === Qt.Key_Right) {
      root.navigate(1)
      event.accepted = true
    } else if (event.key === Qt.Key_Escape) {
      root.cancel()
      event.accepted = true
    }
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

    onPressed: root.forceActiveFocus()

    onClicked: function(mouseEvent) {
      root.clicked(mouseEvent.button)
    }

    onWheel: function(wheel) {
      const horizontal = Math.abs(wheel.angleDelta.x)
        > Math.abs(wheel.angleDelta.y)
      root.wheelMoved(
        horizontal ? wheel.angleDelta.x : wheel.angleDelta.y,
        horizontal)
      wheel.accepted = true
    }
  }
}
