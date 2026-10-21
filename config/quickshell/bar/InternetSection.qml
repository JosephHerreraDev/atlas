import Quickshell
import Quickshell.Networking
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

  readonly property int spaceXs: Theme.spaceXs
  readonly property int spaceSm: Theme.spaceSm
  readonly property int spaceMd: Theme.spaceMd
  readonly property int spaceLg: Theme.spaceLg
  readonly property int controlHeight: Theme.controlHeight
  readonly property int listRowHeight: Theme.listRowHeight
  readonly property int bodyFontSize: Theme.fontBody
  readonly property int captionFontSize: Theme.fontCaption
  readonly property int titleFontSize: Theme.fontTitle
  readonly property var connectedNetworks: SystemState.connectedNetworks
  readonly property var primaryConnectedNetwork:
    SystemState.primaryConnectedNetwork
  readonly property var availableNetworks: SystemState.availableNetworks
  readonly property var closeNetworks: SystemState.closeNetworks
  readonly property bool hasVisibleNetworks:
    connectedNetworks.length > 0
      || availableNetworks.length > 0
      || closeNetworks.length > 0
  readonly property var pendingWifiNetwork: SystemState.pendingWifiNetwork
  readonly property var pendingWifiForgetNetwork:
    SystemState.pendingWifiForgetNetwork
  readonly property string wifiPassword: SystemState.wifiPassword
  readonly property string wifiConnectionMessage:
    SystemState.wifiConnectionMessage
  readonly property bool wifiConnecting: SystemState.wifiConnecting
  readonly property real networkDownloadSpeed:
    SystemState.networkDownloadSpeed
  readonly property real networkUploadSpeed: SystemState.networkUploadSpeed

  width: parent ? parent.width : 0
  spacing: Theme.spaceSm

  function formatNetworkSpeed(bytesPerSecond) {
    return SystemState.formatNetworkSpeed(bytesPerSecond)
  }

  function requestWifiForget(network) {
    SystemState.requestWifiForget(network)
  }

  function connectNetwork(network) {
    SystemState.connectNetwork(network)
  }

  function connectPendingNetwork() {
    SystemState.connectPendingNetwork()
  }


  component NetworkButton: Button {
    id: networkButton
    required property var network
    property string statusText: ""
    property bool connected: false
    implicitHeight: 56
    radius: Theme.radiusMd
    buttonColor: hovered ? Theme.surfaceHover : Theme.surface
    buttonBorderColor: activeFocus || hovered ? Theme.accent : Theme.border
    opacity: enabled ? 1 : 0.55
    Controls.ToolTip.visible: hovered
    Controls.ToolTip.delay: 700
    Controls.ToolTip.text: (network.name || "Unknown network")

    RowLayout {
      anchors.fill: parent
      anchors.margins: root.spaceSm
      spacing: root.spaceSm

      Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: Theme.radiusSm
        color: networkButton.connected
          ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
          : Theme.surfaceHover
        IconImage {
          anchors.centerIn: parent
          implicitWidth: 20
          implicitHeight: 20
          source: Qt.resolvedUrl("../assets/" + (networkButton.network.signalStrength <= 0.33
            ? "wifi-low" : networkButton.network.signalStrength <= 0.66
              ? "wifi-mid" : "wifi-high") + ".svg")
          layer.enabled: true
          layer.effect: MultiEffect {
            brightness: 1
            colorization: 1
            colorizationColor: networkButton.connected ? Theme.accent : Theme.foregroundMuted
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 3
        Text {
          Layout.fillWidth: true
          text: (networkButton.network.name || "Unknown network")
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
            text: networkButton.statusText
            color: networkButton.connected ? Theme.accent : Theme.foregroundMuted
            font.pixelSize: root.captionFontSize
            elide: Text.ElideRight
          }

        }
      }

    }
  }

  component ForgetControl: ColumnLayout {
    id: forgetControl
    required property var network
    readonly property bool confirming:
      root.pendingWifiForgetNetwork === network
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
        + (forgetControl.network.name || "network")
      buttonColor: forgetControl.confirming || hovered
        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
      buttonBorderColor: forgetControl.confirming || hovered || activeFocus
        ? Theme.error : Theme.border
      onClicked: root.requestWifiForget(forgetControl.network)
      Controls.ToolTip.visible: hovered
      Controls.ToolTip.delay: 500
      Controls.ToolTip.text: "Forget " + (forgetControl.network.name || "network")
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
      accessibleName: "Cancel forgetting " + (forgetControl.network.name || "network")
      buttonColor: hovered ? Theme.surfaceHover : "transparent"
      buttonBorderColor: activeFocus ? Theme.borderFocus : "transparent"
      onClicked: SystemState.pendingWifiForgetNetwork = null
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
    height: root.controlHeight
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

    Text {
      Layout.fillWidth: true
      text: "Internet"
      color: Theme.foreground
      font.pixelSize: root.titleFontSize
      font.weight: Theme.weightStrong
    }

    Button {
      Layout.preferredWidth: 24
      Layout.preferredHeight: root.controlHeight
      horizontalPadding: 0
      visible: root.showSettingsButton
      accessibleName: "Open Internet settings"
      onClicked: Quickshell.execDetached(["qs", "ipc", "call", "settings", "openSection", "internet"])
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
      accessibleName: "Wi-Fi"
      checked: Networking.wifiEnabled
      enabled: Networking.wifiHardwareEnabled
      onToggled: function(checked) {
        Networking.wifiEnabled = checked
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
    visible: !Networking.wifiHardwareEnabled || !Networking.wifiEnabled
    text: Networking.wifiHardwareEnabled
      ? "Turn on Wi-Fi to search nearby networks"
      : "Wi-Fi is unavailable"
    color: Theme.border
    font.pixelSize: root.captionFontSize
    horizontalAlignment: Text.AlignHCenter
  }

  Column {
    width: parent.width
    spacing: root.spaceSm
    visible: Networking.wifiHardwareEnabled && Networking.wifiEnabled

  Text {
    width: parent.width
    text: "Networks"
    color: Theme.foreground
    font.pixelSize: root.captionFontSize
    font.weight: Theme.weightStrong
  }

  Repeater {
    model: root.connectedNetworks
    RowLayout {
      required property var modelData
      width: root.width
      height: 56
      spacing: root.spaceXs
      NetworkButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        network: modelData
        connected: true
        statusText: modelData.stateChanging ? "Working…"
          : modelData === root.primaryConnectedNetwork
            ? "↓ " + root.formatNetworkSpeed(root.networkDownloadSpeed)
              + "   ↑ " + root.formatNetworkSpeed(root.networkUploadSpeed)
            : "Connected"
        enabled: !modelData.stateChanging
        accessibleName: "Disconnect from " + (modelData.name || "unknown network")
        onClicked: modelData.disconnect()
      }
      ForgetControl { network: modelData; enabled: !modelData.stateChanging }
    }
  }

  Repeater {
    model: root.availableNetworks
    RowLayout {
      required property var modelData
      width: root.width
      height: 56
      spacing: root.spaceXs
      NetworkButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        network: modelData
        statusText: modelData.stateChanging ? "Working…"
          : "Saved · " + Math.round(modelData.signalStrength * 100) + "% signal"
        enabled: !modelData.stateChanging
        accessibleName: "Connect to " + (modelData.name || "unknown network")
        onClicked: root.connectNetwork(modelData)
      }
      ForgetControl { network: modelData; enabled: !modelData.stateChanging }
    }
  }

  Rectangle {
    width: parent.width
    height: 1
    color: Theme.border
  }

  Text {
    width: parent.width
    text: "Nearby networks"
    color: Theme.foreground
    font.pixelSize: root.captionFontSize
    font.weight: Theme.weightStrong
  }

  Text {
    width: parent.width
    visible: !root.hasVisibleNetworks
    text: "Scanning for nearby networks…"
    color: Theme.foregroundMuted
    font.pixelSize: root.captionFontSize
    horizontalAlignment: Text.AlignHCenter
  }

  Repeater {
    model: root.closeNetworks

    Column {
      required property var modelData

      width: root.width
      spacing: root.spaceXs

      NetworkButton {
        width: parent.width
        network: modelData
        statusText: modelData.stateChanging ? "Working…"
          : Math.round(modelData.signalStrength * 100) + "% signal"
        enabled: !modelData.stateChanging
        accessibleName: "Connect to " + (modelData.name || "unknown network")
        buttonBorderColor: root.pendingWifiNetwork === modelData || hovered || activeFocus
          ? Theme.accent : Theme.border
        onClicked: root.connectNetwork(modelData)
      }

      Rectangle {
        id: passwordPanel

        width: parent.width
        height: passwordForm.implicitHeight + root.spaceLg * 2
        visible: root.pendingWifiNetwork === modelData
        radius: Theme.radiusSm
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.accent

        onVisibleChanged: {
          if (visible)
            wifiPasswordInput.forceActiveFocus()
        }

        Column {
          id: passwordForm

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: root.spaceLg
          spacing: root.spaceSm

          Text {
            width: parent.width
            text: "Password for " + (modelData.name || "network")
            textFormat: Text.PlainText
            color: Theme.foreground
            font.pixelSize: root.captionFontSize
            elide: Text.ElideRight
          }

          Rectangle {
            width: parent.width
            height: root.controlHeight
            radius: Theme.radiusSm
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: wifiPasswordInput.activeFocus
              ? Theme.accent
              : Theme.border

            TextInput {
              id: wifiPasswordInput

              anchors.fill: parent
              anchors.leftMargin: root.spaceMd
              anchors.rightMargin: root.spaceMd
              verticalAlignment: TextInput.AlignVCenter
              text: root.wifiPassword
              color: Theme.foreground
              font.pixelSize: root.bodyFontSize
              echoMode: TextInput.Password
              clip: true
              enabled: !root.wifiConnecting
              onTextChanged: SystemState.wifiPassword = text
              onAccepted: root.connectPendingNetwork()
            }
          }

            Text {
              width: parent.width
              visible: root.wifiConnectionMessage !== ""
              text: root.wifiConnectionMessage
              textFormat: Text.PlainText
            color: Theme.error
            font.pixelSize: root.captionFontSize
            wrapMode: Text.WordWrap
          }

          RowLayout {
            width: parent.width
            spacing: root.spaceSm

            Button {
              Layout.fillWidth: true
              Layout.preferredHeight: root.controlHeight
              accessibleName: "Cancel Wi-Fi connection"
              onClicked: SystemState.cancelWifiPrompt()

              Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: Theme.foreground
                font.pixelSize: root.captionFontSize
              }
            }

            Button {
              Layout.fillWidth: true
              Layout.preferredHeight: root.controlHeight
              enabled: root.wifiPassword.length > 0
                && !root.wifiConnecting
              accessibleName: root.wifiConnecting
                ? "Connecting to Wi-Fi"
                : "Connect to Wi-Fi"
              buttonBorderColor: hovered ? Theme.accent : Theme.border
              onClicked: root.connectPendingNetwork()

              Text {
                anchors.centerIn: parent
                text: root.wifiConnecting ? "Connecting…" : "Connect"
                color: Theme.accent
                font.pixelSize: root.captionFontSize
              }
            }
          }
        }
      }

    }
  }

  }

}
