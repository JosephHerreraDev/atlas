import Quickshell.Bluetooth as BluetoothService
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

SystemSection {
  id: root

  signal backRequested()

  readonly property int spaceXs: Theme.spaceXs
  readonly property int spaceSm: Theme.spaceSm
  readonly property int spaceMd: Theme.spaceMd
  readonly property int spaceLg: Theme.spaceLg
  readonly property int controlHeight: Theme.controlHeight
  readonly property int listRowHeight: Theme.listRowHeight
  readonly property int bodyFontSize: Theme.fontBody
  readonly property int captionFontSize: Theme.fontCaption
  readonly property int titleFontSize: Theme.fontTitle
  readonly property var bluetoothAdapter: SystemState.bluetoothAdapter
  readonly property var connectedBluetoothDevices:
    SystemState.connectedBluetoothDevices
  readonly property var availableBluetoothDevices:
    SystemState.availableBluetoothDevices
  readonly property var closeBluetoothDevices:
    SystemState.closeBluetoothDevices
  readonly property string pendingBluetoothForgetAddress:
    SystemState.pendingBluetoothForgetAddress
  readonly property string bluetoothPairingAddress:
    SystemState.bluetoothPairingAddress
  readonly property string bluetoothPairingMessage:
    SystemState.bluetoothPairingMessage
  readonly property string bluetoothPromptType:
    SystemState.bluetoothPromptType
  readonly property string bluetoothPromptText:
    SystemState.bluetoothPromptText

  width: parent ? parent.width : 0
  spacing: Theme.spaceSm

  function bluetoothDeviceName(device) {
    return SystemState.bluetoothDeviceName(device)
  }

  function bluetoothAdapterStatus() {
    return SystemState.bluetoothAdapterStatus()
  }

  function bluetoothDeviceActionText(device, action) {
    return SystemState.bluetoothDeviceActionText(device, action)
  }

  function requestBluetoothForget(device) {
    SystemState.requestBluetoothForget(device)
  }

  function pairBluetoothDevice(device) {
    SystemState.pairBluetoothDevice(device)
  }

  function connectBluetoothDevice(device) {
    SystemState.connectBluetoothDevice(device)
  }

  function cancelBluetoothPairing(device) {
    SystemState.cancelBluetoothPairing(device)
  }


  RowLayout {
    width: parent.width
    height: root.controlHeight
    spacing: root.spaceSm

    Button {
      Layout.preferredWidth: 24
      Layout.preferredHeight: root.controlHeight
      horizontalPadding: 0
      buttonBorderColor: hovered ? Theme.color8 : Theme.color2
      accessibleName: "Back to system settings"
      onClicked: root.backRequested()

      Text {
        anchors.centerIn: parent
        text: "‹"
        color: Theme.foreground
        font.pixelSize: root.titleFontSize
      }
    }

    Text {
      Layout.fillWidth: true
      text: "Bluetooth"
      color: Theme.foreground
      font.pixelSize: root.titleFontSize
      font.weight: Theme.weightStrong
    }

    Toggle {
      accessibleName: "Bluetooth"
      checked: root.bluetoothAdapter?.enabled ?? false
      enabled: root.bluetoothAdapter !== null
        && root.bluetoothAdapter.state !== BluetoothService.BluetoothAdapterState.Enabling
        && root.bluetoothAdapter.state !== BluetoothService.BluetoothAdapterState.Disabling
      onToggled: function(checked) {
        if (!root.bluetoothAdapter)
          return
        root.bluetoothAdapter.enabled = checked
        if (!checked)
          SystemState.requestBluetoothScan(false)
      }
    }
  }

  Rectangle {
    width: parent.width
    height: 1
    color: Theme.color2
  }

  Text {
    width: parent.width
    visible: !root.bluetoothAdapter || !root.bluetoothAdapter.enabled
    text: root.bluetoothAdapterStatus()
    textFormat: Text.PlainText
    color: Theme.color2
    font.pixelSize: root.captionFontSize
    horizontalAlignment: Text.AlignHCenter
  }

  Column {
    width: parent.width
    spacing: root.spaceSm
    visible: root.bluetoothAdapter?.enabled ?? false

    Text {
      width: parent.width
      text: "Connected devices"
      color: Theme.foreground
      font.pixelSize: root.captionFontSize
      font.weight: Theme.weightStrong
    }

    Repeater {
      model: root.connectedBluetoothDevices

      RowLayout {
        required property var modelData

        width: root.width
        height: root.listRowHeight + root.spaceLg
        spacing: root.spaceXs

        Button {
          Layout.fillWidth: true
          Layout.preferredHeight: root.listRowHeight + root.spaceLg
          enabled: modelData.state === BluetoothService.BluetoothDeviceState.Connected
          accessibleName: "Disconnect "
            + root.bluetoothDeviceName(modelData)
          buttonBorderColor: hovered ? Theme.color8 : Theme.color2
          onClicked: modelData.disconnect()

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.spaceLg
            anchors.rightMargin: root.spaceLg

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              Text {
                Layout.fillWidth: true
                text: root.bluetoothDeviceName(modelData)
                textFormat: Text.PlainText
                color: Theme.color8
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
              }

              Text {
                Layout.fillWidth: true
                visible: modelData.batteryAvailable
                text: Math.round(modelData.battery * 100) + "% battery"
                color: Theme.color5
                font.pixelSize: root.captionFontSize
                elide: Text.ElideRight
              }
            }

            Text {
              text: root.bluetoothDeviceActionText(modelData, "Disconnect")
              color: Theme.foreground
              font.pixelSize: root.captionFontSize
            }
          }
        }

        Button {
          readonly property bool confirming:
            root.pendingBluetoothForgetAddress === modelData.address

          Layout.preferredWidth: confirming ? 70 : 54
          Layout.preferredHeight: root.listRowHeight + root.spaceLg
          accessibleName: confirming
            ? "Confirm forgetting " + root.bluetoothDeviceName(modelData)
            : "Forget " + root.bluetoothDeviceName(modelData)
          buttonBorderColor: confirming || hovered ? Theme.color11 : Theme.color2
          onClicked: root.requestBluetoothForget(modelData)

          Text {
            anchors.centerIn: parent
            text: parent.confirming ? "Confirm?" : "Forget"
            color: Theme.color11
            font.pixelSize: root.captionFontSize
          }
        }
      }
    }

    Text {
      visible: root.connectedBluetoothDevices.length === 0
      text: "None"
      color: Theme.color2
      font.pixelSize: root.captionFontSize
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Theme.color2
    }

    Text {
      width: parent.width
      text: "Saved devices"
      color: Theme.foreground
      font.pixelSize: root.captionFontSize
      font.weight: Theme.weightStrong
    }

    Repeater {
      model: root.availableBluetoothDevices

      RowLayout {
        required property var modelData

        width: root.width
        height: root.listRowHeight
        spacing: root.spaceXs

        Button {
          Layout.fillWidth: true
          Layout.preferredHeight: root.listRowHeight
          enabled: modelData.state === BluetoothService.BluetoothDeviceState.Disconnected
            && root.bluetoothPairingAddress === ""
          accessibleName: "Connect "
            + root.bluetoothDeviceName(modelData)
          buttonBorderColor: hovered ? Theme.color8 : Theme.color2
          onClicked: root.connectBluetoothDevice(modelData)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.spaceMd
            anchors.rightMargin: root.spaceMd

            Text {
              Layout.fillWidth: true
              text: root.bluetoothDeviceName(modelData)
              textFormat: Text.PlainText
              color: Theme.foreground
              font.pixelSize: root.bodyFontSize
              elide: Text.ElideRight
            }

            Text {
              text: root.bluetoothPairingAddress === modelData.address
                ? "Connecting…"
                : root.bluetoothDeviceActionText(modelData, "Connect")
              color: Theme.color8
              font.pixelSize: root.captionFontSize
            }
          }
        }

        Button {
          readonly property bool confirming:
            root.pendingBluetoothForgetAddress === modelData.address

          Layout.preferredWidth: confirming ? 70 : 54
          Layout.preferredHeight: root.listRowHeight
          accessibleName: confirming
            ? "Confirm forgetting " + root.bluetoothDeviceName(modelData)
            : "Forget " + root.bluetoothDeviceName(modelData)
          buttonBorderColor: confirming || hovered ? Theme.color11 : Theme.color2
          onClicked: root.requestBluetoothForget(modelData)

          Text {
            anchors.centerIn: parent
            text: parent.confirming ? "Confirm?" : "Forget"
            color: Theme.color11
            font.pixelSize: root.captionFontSize
          }
        }
      }
    }

    Text {
      visible: root.availableBluetoothDevices.length === 0
      text: "None"
      color: Theme.color2
      font.pixelSize: root.captionFontSize
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Theme.color2
    }

    RowLayout {
      width: parent.width
      spacing: root.spaceSm

      Text {
        Layout.fillWidth: true
        text: "Nearby devices"
        color: Theme.foreground
        font.pixelSize: root.captionFontSize
        font.weight: Theme.weightStrong
      }

      Button {
        Layout.preferredWidth: 66
        Layout.preferredHeight: root.controlHeight
        accessibleName: SystemState.bluetoothScanRequested
          ? "Stop Bluetooth scan"
          : "Scan for Bluetooth devices"
        buttonBorderColor: hovered ? Theme.color8 : Theme.color2
        onClicked: SystemState.requestBluetoothScan(
          !SystemState.bluetoothScanRequested)

        Text {
          anchors.centerIn: parent
          text: SystemState.bluetoothScanRequested ? "Stop" : "Scan"
          color: Theme.color8
          font.pixelSize: root.captionFontSize
        }
      }
    }

    Repeater {
      model: root.closeBluetoothDevices

      Button {
        id: nearbyDeviceButton

        required property var modelData
        readonly property bool pairing:
          root.bluetoothPairingAddress === modelData.address

        width: root.width
        implicitHeight: root.listRowHeight
        enabled: root.bluetoothPairingAddress === "" || pairing
        accessibleName: pairing
          ? "Cancel pairing " + root.bluetoothDeviceName(modelData)
          : "Pair " + root.bluetoothDeviceName(modelData)
        buttonBorderColor: hovered ? Theme.color8 : Theme.color2
        onClicked: {
          if (pairing)
            root.cancelBluetoothPairing(modelData)
          else
            root.pairBluetoothDevice(modelData)
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: root.spaceMd
          anchors.rightMargin: root.spaceMd

          Text {
            Layout.fillWidth: true
            text: root.bluetoothDeviceName(modelData)
            textFormat: Text.PlainText
            color: Theme.foreground
            font.pixelSize: root.bodyFontSize
            elide: Text.ElideRight
          }

          Text {
            text: nearbyDeviceButton.pairing ? "Cancel" : "Pair"
            color: nearbyDeviceButton.pairing ? Theme.color11 : Theme.color8
            font.pixelSize: root.captionFontSize
          }
        }
      }
    }

    Rectangle {
      width: parent.width
      height: bluetoothPromptForm.implicitHeight + root.spaceLg * 2
      visible: root.bluetoothPromptType !== ""
      radius: Theme.radiusSm
      color: Theme.color0
      border.width: Theme.borderWidth
      border.color: Theme.color8

      Column {
        id: bluetoothPromptForm

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.spaceLg
        spacing: root.spaceSm

        Text {
          width: parent.width
          text: root.bluetoothPromptText
          textFormat: Text.PlainText
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
          wrapMode: Text.WordWrap
        }

        Rectangle {
          width: parent.width
          height: root.controlHeight
          visible: root.bluetoothPromptType === "input"
          radius: Theme.radiusSm
          color: Theme.background
          border.width: Theme.borderWidth
          border.color: bluetoothCodeInput.activeFocus
            ? Theme.color8
            : Theme.color2

          TextInput {
            id: bluetoothCodeInput

            anchors.fill: parent
            anchors.leftMargin: root.spaceMd
            anchors.rightMargin: root.spaceMd
            verticalAlignment: TextInput.AlignVCenter
            inputMethodHints: Qt.ImhDigitsOnly
            text: SystemState.bluetoothPromptValue
            color: Theme.foreground
            font.pixelSize: root.bodyFontSize
            onTextChanged: SystemState.bluetoothPromptValue = text
            onAccepted: SystemState.submitBluetoothPrompt(true)
          }
        }

        RowLayout {
          width: parent.width
          spacing: root.spaceSm

          Button {
            Layout.fillWidth: true
            Layout.preferredHeight: root.controlHeight
            accessibleName: "Reject Bluetooth pairing request"
            onClicked: SystemState.submitBluetoothPrompt(false)

            Text {
              anchors.centerIn: parent
              text: "Reject"
              color: Theme.color11
              font.pixelSize: root.captionFontSize
            }
          }

          Button {
            Layout.fillWidth: true
            Layout.preferredHeight: root.controlHeight
            enabled: root.bluetoothPromptType !== "input"
              || SystemState.bluetoothPromptValue.trim() !== ""
            accessibleName: root.bluetoothPromptType === "input"
              ? "Submit Bluetooth pairing code"
              : "Confirm Bluetooth pairing code"
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: SystemState.submitBluetoothPrompt(true)

            Text {
              anchors.centerIn: parent
              text: root.bluetoothPromptType === "input"
                ? "Submit"
                : "Confirm"
              color: Theme.color8
              font.pixelSize: root.captionFontSize
            }
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: root.bluetoothPairingMessage !== ""
      text: root.bluetoothPairingMessage
      textFormat: Text.PlainText
      color: Theme.color11
      font.pixelSize: root.captionFontSize
      wrapMode: Text.WordWrap
    }

    Text {
      visible: root.closeBluetoothDevices.length === 0
      text: root.bluetoothAdapter?.discovering ? "Searching…" : "None found"
      color: Theme.color2
      font.pixelSize: root.captionFontSize
    }
  }
}
