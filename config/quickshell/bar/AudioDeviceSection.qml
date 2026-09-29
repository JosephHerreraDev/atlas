import QtQuick
import QtQuick.Layouts
import ".."
import "../shared/"

SystemSection {
  id: root

  required property string title
  required property string direction
  required property var devices
  required property var selectedDevice

  signal backRequested()

  width: parent ? parent.width : 0
  spacing: Theme.spaceSm

  SystemSectionHeader {
    width: parent.width
    title: root.title
    onBackRequested: root.backRequested()
  }

  Rectangle {
    width: parent.width
    height: Theme.borderWidth
    color: Theme.color2
  }

  Text {
    width: parent.width
    visible: !AudioState.serviceReady
    text: "Sound devices are unavailable"
    color: Theme.color2
    font.pixelSize: Theme.fontCaption
    horizontalAlignment: Text.AlignHCenter
  }

  Column {
    width: parent.width
    spacing: Theme.spaceSm
    visible: AudioState.serviceReady

    Repeater {
      model: root.devices

      Button {
        id: deviceButton

        required property var modelData
        readonly property bool selected: modelData === root.selectedDevice

        width: root.width
        implicitHeight: Theme.listRowHeight
        enabled: modelData.ready
        accessibleName: (selected ? "Selected " : "Select ")
          + AudioState.audioDeviceName(modelData, "Unknown device")
        buttonBorderColor: selected
          ? Theme.color8
          : (hovered ? Theme.color8 : Theme.color2)
        onClicked: AudioState.selectDevice(root.direction, modelData)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Theme.spaceMd
          anchors.rightMargin: Theme.spaceMd
          spacing: Theme.spaceSm

          Text {
            Layout.fillWidth: true
            text: AudioState.audioDeviceName(modelData, "Unknown device")
            textFormat: Text.PlainText
            color: deviceButton.selected ? Theme.color8 : Theme.foreground
            font.pixelSize: Theme.fontBody
            elide: Text.ElideRight
          }

          Text {
            text: deviceButton.selected ? "Selected" : "Select"
            color: Theme.color8
            font.pixelSize: Theme.fontCaption
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: root.devices.length === 0
      text: "No " + root.direction + " devices found"
      color: Theme.color2
      font.pixelSize: Theme.fontCaption
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
