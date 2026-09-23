import QtQuick
import "../"
import "../bar" as Bar

Item {
  id: root

  property string iconType: "volume"
  property real value: 0
  readonly property real normalizedValue: Math.max(0, Math.min(1, value))

  implicitWidth: 220
  implicitHeight: 20

  Row {
    anchors.fill: parent
    spacing: Theme.spaceLg

    Loader {
      anchors.verticalCenter: parent.verticalCenter
      width: 18
      height: 14
      sourceComponent: root.iconType === "brightness"
        ? brightnessIcon
        : volumeIcon

      onLoaded: {
        item.width = width
        item.height = height
      }
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 30
      height: 7
      radius: 3.5
      color: Theme.color2

      Rectangle {
        width: parent.width * root.normalizedValue
        height: parent.height
        radius: parent.radius
        color: Theme.color8

        Behavior on width {
          NumberAnimation {
            duration: Theme.motionQuick - 10
            easing.type: Easing.OutCubic
          }
        }
      }
    }
  }

  Component {
    id: volumeIcon
    Bar.Volume {}
  }

  Component {
    id: brightnessIcon
    Bar.Brightness {}
  }
}
