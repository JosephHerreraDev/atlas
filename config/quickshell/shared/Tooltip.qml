import Quickshell
import QtQuick
import ".."

Item {
  id: root

  required property string text
  required property Item target
  required property bool shown
  property real gap: 8
  property real maximumWidth: 320
  property bool openAbove: false
  property string edge: openAbove ? "bottom" : "top"

  PopupWindow {
    id: popup

    anchor {
      item: root.target
      rect.x: root.edge === "left" ? root.target.width + root.gap
        : root.edge === "right" ? -root.gap
        : Math.round(root.target.width / 2)
      rect.y: root.edge === "left" || root.edge === "right"
        ? Math.round(root.target.height / 2)
        : root.edge === "bottom" ? -root.gap : root.target.height + root.gap
      rect.width: 1
      rect.height: 1
      edges: root.edge === "left" ? Edges.Left
        : root.edge === "right" ? Edges.Right
        : root.edge === "bottom" ? Edges.Bottom : Edges.Top
      gravity: root.edge === "left" ? Edges.Right
        : root.edge === "right" ? Edges.Left
        : root.edge === "bottom" ? Edges.Top : Edges.Bottom
    }

    implicitWidth: tooltipText.width + 12
    implicitHeight: tooltipText.implicitHeight + 6
    visible: root.shown
    color: "transparent"
    grabFocus: false

    Rectangle {
      anchors.fill: parent

      color: Theme.surfaceHover
      border.color: Theme.borderFocus
      border.width: Theme.borderWidth
      radius: Theme.radiusSm

      Text {
        id: tooltipText

        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.maximumWidth)
        text: root.text
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Theme.foreground
        font.bold: true
      }
    }
  }
}
