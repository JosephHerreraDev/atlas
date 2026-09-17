import QtQuick
import ".."

Item {
  id: wrapper

  property real margin: 2
  property bool borderEnabled: true
  required default property Item child

  implicitWidth: child.implicitWidth + margin * 2
  implicitHeight: child.implicitHeight + margin * 2

  Rectangle {
    id: bg

    anchors.fill: parent

    color: Theme.color0
    radius: 4
    border.color: Theme.color9
    border.width: wrapper.borderEnabled ? 1 : 0

    Item {
      anchors.fill: parent
      anchors.margins: wrapper.margin
      data: [child]
    }
  }
}
