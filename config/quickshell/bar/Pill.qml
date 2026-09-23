import QtQuick
import ".."

Item {
  id: wrapper

  property real margin: Theme.spaceXxs
  property bool borderEnabled: true
  required default property Item child

  implicitWidth: child.implicitWidth + margin * 2
  implicitHeight: child.implicitHeight + margin * 2

  Rectangle {
    id: bg

    anchors.fill: parent

    color: Theme.surface
    radius: Theme.radiusSm
    border.color: Theme.borderStrong
    border.width: wrapper.borderEnabled ? Theme.borderWidth : 0

    Item {
      anchors.fill: parent
      anchors.margins: wrapper.margin
      data: [child]
    }
  }
}
