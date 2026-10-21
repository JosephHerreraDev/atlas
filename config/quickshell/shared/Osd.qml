import QtQuick
import "../"
import "../bar" as Bar

Item {
  id: root

  property string iconType: "volume"
  property real value: 0
  property bool vertical: false
  readonly property real normalizedValue: Math.max(0, Math.min(1, value))
  readonly property int percentage: Math.round(normalizedValue * 100)

  implicitWidth: vertical ? 30 : 232
  implicitHeight: vertical ? 228 : 22

  Row {
    visible: !root.vertical
    anchors.fill: parent
    spacing: Theme.spaceSm

    Loader {
      anchors.verticalCenter: parent.verticalCenter
      width: 18
      height: 16
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
      width: parent.width - 18 - percentageLabel.width - parent.spacing * 2
      height: 6
      radius: height / 2
      color: Theme.border

      Rectangle {
        width: parent.width * root.normalizedValue
        height: parent.height
        radius: parent.radius
        color: Theme.accent

        Behavior on width {
          SpringAnimation {
            spring: 12
            damping: 0.75
            epsilon: 0.01
          }
        }
      }
    }

    Text {
      id: percentageLabel

      anchors.verticalCenter: parent.verticalCenter
      width: 38
      horizontalAlignment: Text.AlignRight
      text: root.percentage + "%"
      color: Theme.foreground
      font.pixelSize: Theme.fontBody
      font.weight: Theme.weightStrong
    }
  }

  Column {
    visible: root.vertical
    anchors.fill: parent
    spacing: Theme.spaceSm

    Loader {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 18
      height: 16
      sourceComponent: root.iconType === "brightness"
        ? brightnessIcon : volumeIcon
      onLoaded: { item.width = width; item.height = height }
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 6
      height: parent.height - 16 - verticalPercentage.height - parent.spacing * 2
      radius: width / 2
      color: Theme.border

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * root.normalizedValue
        radius: parent.radius
        color: Theme.accent
        Behavior on height {
          SpringAnimation { spring: 12; damping: 0.75; epsilon: 0.01 }
        }
      }
    }

    Text {
      id: verticalPercentage
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.percentage + "%"
      color: Theme.foreground
      font.pixelSize: Theme.fontBody
      font.weight: Theme.weightStrong
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
