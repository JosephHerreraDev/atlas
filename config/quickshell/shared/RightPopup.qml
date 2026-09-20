import Quickshell
import QtQuick
import ".."

PopupWindow {
  id: root

  required property Item anchorItem
  property real gap: 8
  property real padding: 10
  property bool shown: false

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
  visible: root.shown && RightPopupState.activePopup === root
  color: "transparent"
  grabFocus: true

  onShownChanged: {
    if (shown)
      RightPopupState.activePopup = root
    else if (RightPopupState.activePopup === root)
      RightPopupState.activePopup = null
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.color0
    border.color: Theme.foreground
    border.width: 1
    radius: 6

    Item {
      id: contentHost

      anchors.fill: parent
      anchors.margins: root.padding
    }
  }
}
