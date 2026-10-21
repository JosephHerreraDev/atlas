import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import ".."
import "../shared/"

SystemSection {
  id: root

  required property string title
  required property string direction
  required property var devices
  required property var selectedDevice
  property bool showBackButton: true
  property bool showSettingsButton: false

  signal backRequested()

  width: parent ? parent.width : 0
  spacing: Theme.spaceSm

  SystemSectionHeader {
    width: parent.width
    title: root.title
    showBackButton: root.showBackButton
    onBackRequested: root.backRequested()

    Button {
      Layout.preferredWidth: 24
      Layout.preferredHeight: Theme.controlHeight
      horizontalPadding: 0
      visible: root.showSettingsButton
      accessibleName: "Open audio settings"
      onClicked: Quickshell.execDetached(["qs", "ipc", "call", "settings", "openSection", "audio"])
      IconImage {
        anchors.centerIn: parent
        implicitWidth: 16
        implicitHeight: 16
        source: Qt.resolvedUrl("../assets/settings.svg")
        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: Theme.foreground
        }
      }
    }
  }

  Rectangle {
    width: parent.width
    height: Theme.borderWidth
    color: Theme.border
  }

  Text {
    width: parent.width
    visible: !AudioState.serviceReady
    text: "Sound devices are unavailable"
    color: Theme.border
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
          ? Theme.accent
          : (hovered ? Theme.accent : Theme.border)
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
            color: deviceButton.selected ? Theme.accent : Theme.foreground
            font.pixelSize: Theme.fontBody
            elide: Text.ElideRight
          }

          Text {
            text: deviceButton.selected ? "Selected" : "Select"
            color: Theme.accent
            font.pixelSize: Theme.fontCaption
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: root.devices.length === 0
      text: "No " + root.direction + " devices found"
      color: Theme.border
      font.pixelSize: Theme.fontCaption
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
