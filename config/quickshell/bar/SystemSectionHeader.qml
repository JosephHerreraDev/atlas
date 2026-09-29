import QtQuick
import QtQuick.Layouts
import ".."
import "../shared/"

RowLayout {
  id: root

  required property string title
  property bool showBackButton: true
  default property alias actions: actionHost.data

  signal backRequested()

  height: Theme.controlHeight
  spacing: Theme.spaceSm

  Button {
    visible: root.showBackButton
    Layout.preferredWidth: visible ? 24 : 0
    Layout.preferredHeight: Theme.controlHeight
    horizontalPadding: 0
    accessibleName: "Back"
    buttonBorderColor: hovered ? Theme.color8 : Theme.color2
    onClicked: root.backRequested()

    Text {
      anchors.centerIn: parent
      text: "‹"
      color: Theme.foreground
      font.pixelSize: Theme.fontTitle
    }
  }

  Text {
    Layout.fillWidth: true
    text: root.title
    textFormat: Text.PlainText
    color: Theme.foreground
    font.pixelSize: Theme.fontTitle
    font.weight: Theme.weightStrong
  }

  RowLayout {
    id: actionHost
    spacing: Theme.spaceSm
  }
}
