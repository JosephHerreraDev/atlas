import QtQuick
import ".."

Item {
  id: root

  property real from: 0
  property real to: 1
  property real value: 0

  signal moved(real value)

  readonly property real displayValue: sliderMouse.pressed
    ? sliderMouse.previewValue
    : value
  readonly property real position: {
    const range = to - from
    if (range <= 0)
      return 0
    return Math.max(0, Math.min(1, (displayValue - from) / range))
  }

  implicitWidth: 140
  implicitHeight: 20

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
  }

  Rectangle {
    id: handle

    x: track.x + track.width * root.position - width / 2
    anchors.verticalCenter: parent.verticalCenter
    width: 12
    height: 12
    radius: width / 2
    color: sliderMouse.pressed ? Theme.color5 : Theme.foreground
    border.width: 1
    border.color: Theme.color8
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
      previewValue = valueAt(mouse.x)
    }
    onPositionChanged: function(mouse) {
      if (pressed)
        previewValue = valueAt(mouse.x)
    }
    onReleased: root.moved(previewValue)
  }
}
