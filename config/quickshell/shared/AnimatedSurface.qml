import QtQuick
import "../"

Item {
  id: root

  required property bool shown
  property int animationDuration: Theme.motionNormal
  property real hiddenScale: 0.96
  property real hiddenOffset: -8

  readonly property Item contentItem: contentHost.children.length > 0
    ? contentHost.children[0]
    : null

  default property alias content: contentHost.data

  signal hidden()

  implicitWidth: contentItem ? contentItem.implicitWidth : 0
  implicitHeight: contentItem ? contentItem.implicitHeight : 0
  width: implicitWidth
  height: implicitHeight
  visible: shown || opacity > 0
  enabled: shown
  z: shown ? 1 : 0
  opacity: shown ? 1 : 0
  scale: shown ? 1 : hiddenScale
  transformOrigin: Item.TopRight

  transform: Translate {
    y: root.hiddenOffset * (1 - root.opacity)
  }

  Behavior on opacity {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
      onFinished: {
        if (!root.shown)
          root.hidden()
      }
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  Item {
    id: contentHost

    anchors.centerIn: parent
    width: implicitWidth
    height: implicitHeight
    implicitWidth: root.contentItem ? root.contentItem.implicitWidth : 0
    implicitHeight: root.contentItem ? root.contentItem.implicitHeight : 0
  }
}
