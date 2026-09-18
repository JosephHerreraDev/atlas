import Quickshell
import QtQuick
import ".."

Item {
  id: root

  required property string text
  required property Item target
  required property bool shown
  property real gap: 8

  PopupWindow {
    id: popup

    anchor {
      item: root.target
      rect.x: Math.round(root.target.width / 2)
      rect.y: root.target.height + root.gap
      rect.width: 1
      rect.height: 1
      edges: Edges.Top
      gravity: Edges.Bottom
    }

    implicitWidth: tooltipText.implicitWidth + 12
    implicitHeight: tooltipText.implicitHeight + 6
    visible: root.shown
    color: "transparent"
    grabFocus: false

    Rectangle {
      anchors.fill: parent

      color: Theme.color1
      border.color: Theme.color8
      border.width: 1
      radius: 4

      Text {
        id: tooltipText

        anchors.centerIn: parent
        text: root.text
        color: Theme.foreground
        font.bold: true
      }
    }
  }
}
