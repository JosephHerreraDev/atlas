import Quickshell.Networking
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
  readonly property var connectedNetworks: SystemState.connectedNetworks
  readonly property var primaryConnectedNetwork:
    SystemState.primaryConnectedNetwork
  readonly property var availableNetworks: SystemState.availableNetworks
  readonly property var closeNetworks: SystemState.closeNetworks
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


  RowLayout {
    width: parent.width
    height: root.controlHeight
    spacing: root.spaceSm

    Button {
      Layout.preferredWidth: 24
      Layout.preferredHeight: root.controlHeight
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
    text: "Connected networks"
    color: Theme.foreground
    font.pixelSize: root.captionFontSize
    font.weight: Theme.weightStrong
  }

  Repeater {
    model: root.connectedNetworks

    Button {
      id: connectedNetworkButton

      required property var modelData

      width: root.width
      implicitHeight: root.listRowHeight + root.spaceLg
      enabled: !modelData.stateChanging
      accessibleName: "Disconnect from "
        + (modelData.name || "unknown network")
      buttonBorderColor: hovered ? Theme.accent : Theme.border
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
            text: modelData.name || "Unknown network"
            textFormat: Text.PlainText
            color: Theme.accent
            font.pixelSize: root.bodyFontSize
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            visible: modelData === root.primaryConnectedNetwork
            text: "↓ " + root.formatNetworkSpeed(root.networkDownloadSpeed)
              + "   ↑ " + root.formatNetworkSpeed(root.networkUploadSpeed)
            color: Theme.foregroundMuted
            font.pixelSize: root.captionFontSize
            elide: Text.ElideRight
          }
        }

        Text {
          text: modelData.stateChanging ? "Working…" : "Disconnect"
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
        }
      }
    }
  }

  Text {
    visible: root.connectedNetworks.length === 0
    text: "None"
    color: Theme.border
    font.pixelSize: root.captionFontSize
  }

  Rectangle {
    width: parent.width
    height: 1
    color: Theme.border
  }

  Text {
    width: parent.width
    text: "Saved networks"
    color: Theme.foreground
    font.pixelSize: root.captionFontSize
    font.weight: Theme.weightStrong
  }

  Repeater {
    model: root.availableNetworks

    RowLayout {
      required property var modelData

      width: root.width
      height: root.listRowHeight
      spacing: root.spaceXs

      Button {
        Layout.fillWidth: true
        Layout.preferredHeight: root.listRowHeight
        enabled: !modelData.stateChanging
        accessibleName: "Connect to "
          + (modelData.name || "unknown network")
        buttonBorderColor: hovered ? Theme.accent : Theme.border
        onClicked: root.connectNetwork(modelData)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: root.spaceMd
          anchors.rightMargin: root.spaceMd

          Text {
            Layout.fillWidth: true
            text: modelData.name || "Unknown network"
            textFormat: Text.PlainText
            color: Theme.foreground
            font.pixelSize: root.bodyFontSize
            elide: Text.ElideRight
          }

          Text {
            text: modelData.stateChanging ? "Working…" : "Connect"
            color: Theme.accent
            font.pixelSize: root.captionFontSize
          }
        }
      }

      Button {
        readonly property bool confirming:
          root.pendingWifiForgetNetwork === modelData

        Layout.preferredWidth: confirming ? 70 : 54
        Layout.preferredHeight: root.listRowHeight
        enabled: !modelData.stateChanging
        accessibleName: confirming
          ? "Confirm forgetting " + (modelData.name || "network")
          : "Forget " + (modelData.name || "network")
        buttonBorderColor: confirming || hovered
          ? Theme.error
          : Theme.border
        onClicked: root.requestWifiForget(modelData)

        Text {
          anchors.centerIn: parent
          text: parent.confirming ? "Confirm?" : "Forget"
          color: Theme.error
          font.pixelSize: root.captionFontSize
        }
      }
    }
  }

  Text {
    visible: root.availableNetworks.length === 0
    text: "None"
    color: Theme.border
    font.pixelSize: root.captionFontSize
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

  Repeater {
    model: root.closeNetworks

    Column {
      required property var modelData

      width: root.width
      spacing: root.spaceXs

      Button {
        width: parent.width
        implicitHeight: root.listRowHeight + root.spaceSm
        enabled: !modelData.stateChanging
        accessibleName: "Connect to "
          + (modelData.name || "unknown network")
        buttonBorderColor: root.pendingWifiNetwork === modelData
          ? Theme.accent
          : (hovered ? Theme.accent : Theme.border)
        onClicked: root.connectNetwork(modelData)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: root.spaceLg
          anchors.rightMargin: root.spaceLg

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
              Layout.fillWidth: true
              text: modelData.name || "Unknown network"
              textFormat: Text.PlainText
              color: Theme.foreground
              font.pixelSize: root.bodyFontSize
              elide: Text.ElideRight
            }

            Text {
              Layout.fillWidth: true
              text: Math.round(modelData.signalStrength * 100) + "% signal"
              color: Theme.foregroundMuted
              font.pixelSize: root.captionFontSize
              elide: Text.ElideRight
            }
          }

          Text {
            text: modelData.stateChanging ? "Working…" : "Connect"
            color: Theme.accent
            font.pixelSize: root.captionFontSize
          }
        }
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

  Text {
    visible: root.closeNetworks.length === 0
    text: "None"
    color: Theme.border
    font.pixelSize: root.captionFontSize
  }
  }

}
