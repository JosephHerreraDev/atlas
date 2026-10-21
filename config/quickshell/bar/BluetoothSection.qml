import Quickshell
import Quickshell.Bluetooth as BluetoothService
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../"
import "../shared/"

SystemSection {
  id: root

  signal backRequested()
  property bool showBackButton: true
  property bool showSettingsButton: true
  property string subtitle: ""

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


  component DeviceIcon: IconImage {
    required property var device
    property color iconColor: Theme.foreground
    Layout.preferredWidth: 20
    Layout.preferredHeight: 20
    source: {
      const type = String(device.icon || "").toLowerCase()
      let asset = "bluetooth-on"
      if (type.includes("mouse")) asset = "device-mouse"
      else if (type.includes("keyboard")) asset = "device-keyboard"
      else if (type.includes("headset") || type.includes("headphone")) asset = "device-headphones"
      else if (type.includes("display") || type.includes("monitor") || type.includes("video")) asset = "display"
      else if (type.includes("audio") || type.includes("speaker")) asset = "device-speaker"
      else if (type.includes("phone")) asset = "device-phone"
      else if (type.includes("computer")) asset = "device-computer"
      else if (type.includes("gaming") || type.includes("gamepad") || type.includes("joystick")) asset = "device-gamepad"
      else if (type.includes("watch")) asset = "device-watch"
      return Qt.resolvedUrl("../assets/" + asset + ".svg")
    }
    layer.enabled: true
    layer.effect: MultiEffect {
      brightness: 1
      colorization: 1
      colorizationColor: iconColor
    }
  }

  component DeviceButton: Button {
    id: deviceButton
    required property var device
    property string actionText: ""
    property string statusText: ""
    property bool connected: false
    implicitHeight: 56
    radius: Theme.radiusMd
    buttonColor: hovered ? Theme.surfaceHover : Theme.surface
    buttonBorderColor: activeFocus || hovered ? Theme.accent : Theme.border
    opacity: enabled ? 1 : 0.55
    Controls.ToolTip.visible: hovered
    Controls.ToolTip.delay: 700
    Controls.ToolTip.text: root.bluetoothDeviceName(device)

    RowLayout {
      anchors.fill: parent
      anchors.margins: root.spaceSm
      spacing: root.spaceSm

      Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: Theme.radiusSm
        color: deviceButton.connected
          ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
          : Theme.surfaceHover
        DeviceIcon {
          anchors.centerIn: parent
          width: 20
          height: 20
          device: deviceButton.device
          iconColor: deviceButton.connected ? Theme.accent : Theme.foregroundMuted
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 3
        Text {
          Layout.fillWidth: true
          text: root.bluetoothDeviceName(deviceButton.device)
          textFormat: Text.PlainText
          color: Theme.foreground
          font.pixelSize: root.bodyFontSize
          font.weight: Theme.weightStrong
          elide: Text.ElideRight
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: root.spaceSm
          Text {
            Layout.fillWidth: true
            text: deviceButton.statusText
            color: deviceButton.connected ? Theme.accent : Theme.foregroundMuted
            font.pixelSize: root.captionFontSize
            elide: Text.ElideRight
          }
          Text {
            visible: deviceButton.actionText !== ""
            text: deviceButton.actionText
            color: deviceButton.hovered ? Theme.accent : Theme.foregroundMuted
            font.pixelSize: root.captionFontSize
          }
        }
      }

    }
  }

  component ForgetControl: ColumnLayout {
    id: forgetControl
    required property var device
    readonly property bool confirming:
      root.pendingBluetoothForgetAddress === device.address
    Layout.preferredWidth: 64
    Layout.minimumWidth: 64
    Layout.maximumWidth: 64
    Layout.preferredHeight: 56
    spacing: 2

    Button {
      Layout.fillWidth: true
      Layout.preferredHeight: forgetControl.confirming ? 32 : 56
      radius: Theme.radiusMd
      accessibleName: (forgetControl.confirming ? "Confirm forgetting " : "Forget ")
        + root.bluetoothDeviceName(forgetControl.device)
      buttonColor: forgetControl.confirming || hovered
        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
      buttonBorderColor: forgetControl.confirming || hovered || activeFocus
        ? Theme.error : Theme.border
      onClicked: root.requestBluetoothForget(forgetControl.device)
      Controls.ToolTip.visible: hovered
      Controls.ToolTip.delay: 500
      Controls.ToolTip.text: "Forget " + root.bluetoothDeviceName(forgetControl.device)
        + " — pairing will be removed"

      IconImage {
        anchors.centerIn: parent
        visible: !forgetControl.confirming
        implicitWidth: 18
        implicitHeight: 18
        source: Qt.resolvedUrl("../assets/trash.svg")
        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: forgetControl.confirming ? Theme.error : Theme.foregroundMuted
        }
      }
      Text {
        anchors.centerIn: parent
        visible: forgetControl.confirming
        text: "Forget?"
        color: Theme.error
        font.pixelSize: root.captionFontSize
        font.weight: Theme.weightStrong
      }
    }
    Button {
      Layout.fillWidth: true
      Layout.preferredHeight: 22
      visible: forgetControl.confirming
      accessibleName: "Cancel forgetting " + root.bluetoothDeviceName(forgetControl.device)
      buttonColor: hovered ? Theme.surfaceHover : "transparent"
      buttonBorderColor: activeFocus ? Theme.borderFocus : "transparent"
      onClicked: SystemState.pendingBluetoothForgetAddress = ""
      Text {
        anchors.centerIn: parent
        text: "Cancel"
        color: Theme.foregroundMuted
        font.pixelSize: root.captionFontSize
      }
    }
  }

  RowLayout {
    width: parent.width
    height: Math.max(root.controlHeight, bluetoothHeaderText.implicitHeight)
    spacing: root.spaceSm

    Button {
      Layout.preferredWidth: root.showBackButton ? 24 : 0
      Layout.preferredHeight: root.controlHeight
      visible: root.showBackButton
      horizontalPadding: 0
      buttonBorderColor: hovered ? Theme.accent : Theme.border
      accessibleName: "Back to system settings"
      onClicked: root.backRequested()

      Text {
        anchors.centerIn: parent
        text: "‹"
        color: Theme.foreground
        font.pixelSize: root.titleFontSize
      }
    }

    ColumnLayout {
      id: bluetoothHeaderText
      Layout.fillWidth: true
      spacing: 1

      Text {
        Layout.fillWidth: true
        text: "Bluetooth"
        color: Theme.foreground
        font.pixelSize: root.titleFontSize
        font.weight: Theme.weightStrong
      }

      Text {
        Layout.fillWidth: true
        visible: root.subtitle !== ""
        text: root.subtitle
        textFormat: Text.PlainText
        color: Theme.foregroundMuted
        font.pixelSize: root.captionFontSize
        wrapMode: Text.WordWrap
      }
    }

    Button {
      Layout.preferredWidth: 24
      Layout.preferredHeight: root.controlHeight
      horizontalPadding: 0
      visible: root.showSettingsButton
      accessibleName: "Open Bluetooth settings"
      onClicked: Quickshell.execDetached(["qs", "ipc", "call", "settings", "openBluetooth"])
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
    color: Theme.border
  }

  Text {
    width: parent.width
    visible: !root.bluetoothAdapter || !root.bluetoothAdapter.enabled
    text: root.bluetoothAdapterStatus()
    textFormat: Text.PlainText
    color: Theme.border
    font.pixelSize: root.captionFontSize
    horizontalAlignment: Text.AlignHCenter
  }

  Column {
    width: parent.width
    spacing: root.spaceSm
    visible: root.bluetoothAdapter?.enabled ?? false

    Text {
      width: parent.width
      text: "Devices"
      color: Theme.foreground
      font.pixelSize: root.captionFontSize
      font.weight: Theme.weightStrong
    }

    Repeater {
      model: root.connectedBluetoothDevices
      RowLayout {
        required property var modelData
        width: root.width
        height: 56
        spacing: root.spaceXs
        DeviceButton {
          Layout.fillWidth: true
          Layout.preferredHeight: 56
          device: modelData
          connected: true
          statusText: modelData.state !== BluetoothService.BluetoothDeviceState.Connected
            ? root.bluetoothDeviceActionText(modelData, "Connected")
            : "Connected" + (modelData.batteryAvailable
            ? " · " + Math.round(modelData.battery * 100) + "%" : "")
          enabled: modelData.state === BluetoothService.BluetoothDeviceState.Connected
          accessibleName: "Disconnect " + root.bluetoothDeviceName(modelData)
          onClicked: modelData.disconnect()
        }
        ForgetControl { device: modelData }
      }
    }

    Repeater {
      model: root.availableBluetoothDevices
      RowLayout {
        required property var modelData
        width: root.width
        height: 56
        spacing: root.spaceXs
        DeviceButton {
          Layout.fillWidth: true
          Layout.preferredHeight: 56
          device: modelData
          statusText: root.bluetoothPairingAddress === modelData.address
            ? "Connecting…" : root.bluetoothDeviceActionText(modelData, "Saved device")
          enabled: modelData.state === BluetoothService.BluetoothDeviceState.Disconnected
            && root.bluetoothPairingAddress === ""
          accessibleName: "Connect " + root.bluetoothDeviceName(modelData)
          onClicked: root.connectBluetoothDevice(modelData)
        }
        ForgetControl { device: modelData }
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Theme.border
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
        buttonBorderColor: hovered ? Theme.accent : Theme.border
        onClicked: SystemState.requestBluetoothScan(
          !SystemState.bluetoothScanRequested)

        Text {
          anchors.centerIn: parent
          text: SystemState.bluetoothScanRequested ? "Stop" : "Scan"
          color: Theme.accent
          font.pixelSize: root.captionFontSize
        }
      }
    }

    Repeater {
      model: root.closeBluetoothDevices

      DeviceButton {
        required property var modelData
        readonly property bool pairing:
          root.bluetoothPairingAddress === modelData.address
        width: root.width
        device: modelData
        statusText: pairing ? "Pairing…" : "Nearby device"
        actionText: pairing ? "Cancel" : "Pair"
        enabled: root.bluetoothPairingAddress === "" || pairing
        accessibleName: (pairing ? "Cancel pairing " : "Pair ")
          + root.bluetoothDeviceName(modelData)
        onClicked: {
          if (pairing) root.cancelBluetoothPairing(modelData)
          else root.pairBluetoothDevice(modelData)
        }
      }
    }

    Rectangle {
      width: parent.width
      height: bluetoothPromptForm.implicitHeight + root.spaceLg * 2
      visible: root.bluetoothPromptType !== ""
      radius: Theme.radiusSm
      color: Theme.surface
      border.width: Theme.borderWidth
      border.color: Theme.accent

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
          color: Theme.surface
          border.width: Theme.borderWidth
          border.color: bluetoothCodeInput.activeFocus
            ? Theme.accent
            : Theme.border

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
              color: Theme.error
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
            buttonBorderColor: hovered ? Theme.accent : Theme.border
            onClicked: SystemState.submitBluetoothPrompt(true)

            Text {
              anchors.centerIn: parent
              text: root.bluetoothPromptType === "input"
                ? "Submit"
                : "Confirm"
              color: Theme.accent
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
      color: Theme.error
      font.pixelSize: root.captionFontSize
      wrapMode: Text.WordWrap
    }

    Text {
      visible: root.closeBluetoothDevices.length === 0
        && root.bluetoothAdapter?.discovering
      text: "Searching…"
      color: Theme.border
      font.pixelSize: root.captionFontSize
    }
  }
}
