import QtQuick
import ".."

Item {
  id: wrapper

  property real margin: 2
  required default property Item child

  implicitWidth: child.implicitWidth + margin * 2
  implicitHeight: child.implicitHeight + margin * 2

  Rectangle {
    id: bg

    anchors.fill: parent

    color: Theme.color0
    radius: 4

    Item {
      anchors.fill: parent
      anchors.margins: wrapper.margin
      data: [child]
    }
  }
}
