import QtQuick
import ".."

Item {
  id: root

  property real from: 0
  property real to: 1
  property real value: 0
  property real indicatorValue: 0
  property bool indicatorVisible: false
  property color indicatorColor: Theme.color14
  property real stepSize: 0.02
  property string accessibleName: "Slider"

  signal moved(real value)
  signal wheelMoved(bool up)

  readonly property real displayValue: sliderMouse.pressed
    ? sliderMouse.previewValue
    : value
  readonly property real position: {
    const range = to - from
    if (range <= 0)
      return 0
    return Math.max(0, Math.min(1, (displayValue - from) / range))
  }
  readonly property real indicatorPosition: {
    const range = to - from
    if (range <= 0)
      return 0
    return Math.max(0, Math.min(1, (indicatorValue - from) / range))
  }

  implicitWidth: 140
  implicitHeight: 20
  activeFocusOnTab: true

  Accessible.role: Accessible.Slider
  Accessible.name: accessibleName
  Accessible.description: Math.round(root.position * 100) + "%"
  Accessible.focusable: true

  function moveBy(amount) {
    root.moved(Math.max(root.from, Math.min(root.to,
      root.value + amount)))
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
      root.moveBy(-root.stepSize)
      event.accepted = true
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
      root.moveBy(root.stepSize)
      event.accepted = true
    } else if (event.key === Qt.Key_Home) {
      root.moved(root.from)
      event.accepted = true
    } else if (event.key === Qt.Key_End) {
      root.moved(root.to)
      event.accepted = true
    }
  }

  Rectangle {
    id: track

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: handle.width / 2
    anchors.rightMargin: handle.width / 2
    height: 4
    radius: height / 2
    color: Theme.color2

    Rectangle {
      width: parent.width * root.position
      height: parent.height
      radius: parent.radius
      color: Theme.color8
    }

    Rectangle {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      width: parent.width * root.indicatorPosition
      height: parent.height
      radius: height / 2
      visible: root.indicatorVisible
      color: root.indicatorColor

      Behavior on width {
        NumberAnimation {
          duration: Theme.motionQuick
          easing.type: Easing.OutQuad
        }
      }
    }
  }

  Rectangle {
    id: handle

    x: track.x + track.width * root.position - width / 2
    anchors.verticalCenter: parent.verticalCenter
    width: 12
    height: 12
    radius: width / 2
    color: sliderMouse.pressed ? Theme.color5 : Theme.foreground
    border.width: Theme.borderWidth
    border.color: root.activeFocus ? Theme.color8 : Theme.borderFocus
  }

  MouseArea {
    id: sliderMouse

    property real previewValue: root.value

    function valueAt(pointerX) {
      const ratio = Math.max(0, Math.min(1,
        (pointerX - handle.width / 2) / track.width))
      return root.from + ratio * (root.to - root.from)
    }

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onPressed: function(mouse) {
      root.forceActiveFocus()
      previewValue = valueAt(mouse.x)
      root.moved(previewValue)
    }
    onPositionChanged: function(mouse) {
      if (pressed) {
        previewValue = valueAt(mouse.x)
        root.moved(previewValue)
      }
    }
    onWheel: function(wheel) {
      root.wheelMoved(wheel.angleDelta.y > 0)
      wheel.accepted = true
    }
  }
}
