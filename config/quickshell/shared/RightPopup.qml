import Quickshell
import QtQuick
import ".."

PopupWindow {
  id: root

  required property Item anchorItem
  property real gap: 8
  property real padding: 10

  readonly property Item contentItem: contentHost.children.length > 0
    ? contentHost.children[0]
    : null

  default property alias content: contentHost.data

  anchor {
    item: root.anchorItem
    rect.x: root.anchorItem ? root.anchorItem.width : 0
    rect.y: (root.anchorItem ? root.anchorItem.height : 0) + root.gap
    rect.width: 1
    rect.height: 1
    edges: Edges.Top | Edges.Right
    gravity: Edges.Bottom | Edges.Left
  }

  implicitHeight: (contentItem ? contentItem.implicitHeight : 0) + root.padding * 2
  color: "transparent"
  grabFocus: true

  Rectangle {
    anchors.fill: parent
    color: Theme.color0
    border.color: Theme.color8
    border.width: 1
    radius: 6

    Item {
      id: contentHost

      anchors.fill: parent
      anchors.margins: root.padding
    }
  }
}
