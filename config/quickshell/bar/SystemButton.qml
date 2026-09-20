import Quickshell
import Quickshell.Bluetooth as BluetoothService
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../shared/"
import "../"

Item {
  id: root

  required property Item popupAnchor
  required property var notifications
  property bool panelVisible: false
  property string activeSection: "settings"
  property var pendingWifiNetwork: null
  property string wifiPassword: ""
  readonly property int spaceXs: 4
  readonly property int spaceSm: 8
  readonly property int spaceMd: 8
  readonly property int spaceLg: 12
  readonly property int controlHeight: 28
  readonly property int listRowHeight: 32
  readonly property int bodyFontSize: 12
  readonly property int captionFontSize: 11
  readonly property int titleFontSize: 14
  readonly property int motionFast: 100
  readonly property int motionNormal: 160
  readonly property bool hasNotifications: notifications.history.count > 0
  readonly property var connectedNetworks: networkList("connected")
  readonly property var availableNetworks: networkList("available")
  readonly property var closeNetworks: networkList("close")
  readonly property var bluetoothAdapter: BluetoothService.Bluetooth.defaultAdapter
  readonly property var connectedBluetoothDevices: bluetoothDeviceList("connected")
  readonly property var availableBluetoothDevices: bluetoothDeviceList("available")
  readonly property var closeBluetoothDevices: bluetoothDeviceList("close")
  readonly property var audioOutputs: audioOutputList()
  implicitWidth: systemButton.implicitWidth
  implicitHeight: 20
  Layout.preferredHeight: 20

  function networkList(section) {
    const result = []
    for (const device of Networking.devices.values) {
      for (const network of device.networks.values) {
        if (section === "connected" && network.connected)
          result.push(network)
        else if (section === "available" && !network.connected && network.known)
          result.push(network)
        else if (section === "close" && !network.connected && !network.known)
          result.push(network)
      }
    }
    return result
  }

  function bluetoothDeviceList(section) {
    if (!bluetoothAdapter)
      return []

    const result = []
    for (const device of bluetoothAdapter.devices.values) {
      if (section === "connected" && device.connected)
        result.push(device)
      else if (section === "available" && !device.connected && (device.paired || device.bonded))
        result.push(device)
      else if (section === "close" && !device.connected && !device.paired && !device.bonded)
        result.push(device)
    }
    return result
  }

  function audioOutputList() {
    const result = []
    for (const node of Pipewire.nodes.values) {
      if (node.isSink && !node.isStream)
        result.push(node)
    }
    return result
  }

  function connectNetwork(network) {
    if (network.known
        || network.security === WifiSecurityType.Open
        || network.security === WifiSecurityType.Owe) {
      network.connect()
      return
    }

    pendingWifiNetwork = network
    wifiPassword = ""
    wifiPasswordInput.forceActiveFocus()
  }

  function connectPendingNetwork() {
    if (!pendingWifiNetwork || wifiPassword.length === 0)
      return

    pendingWifiNetwork.connectWithPsk(wifiPassword)
    pendingWifiNetwork = null
    wifiPassword = ""
  }

  PwObjectTracker {
    objects: root.audioOutputs
  }

  onPanelVisibleChanged: {
    if (panelVisible) {
      activeSection = "settings"
      brightness.refresh()
    } else if (bluetoothAdapter) {
      bluetoothAdapter.discovering = false
    }
  }

  onActiveSectionChanged: {
    if (activeSection === "internet") {
      for (const device of Networking.devices.values) {
        if (device.type === DeviceType.Wifi)
          device.scannerEnabled = true
      }
    }

    if (bluetoothAdapter)
      bluetoothAdapter.discovering = activeSection === "bluetooth"
        && bluetoothAdapter.enabled
  }

  Button {
    id: systemButton

    anchors.fill: parent
    implicitWidth: iconRow.implicitWidth + horizontalPadding * 2
    implicitHeight: 20
    verticalPadding: 0
    onClicked: root.panelVisible = !root.panelVisible

    RowLayout {
      id: iconRow

      anchors.centerIn: parent
      spacing: 4

      Volume {
        id: volume

        HoverHandler {
          id: volumeHoverHandler
        }
      }
      Bluetooth {
        id: bluetooth

        HoverHandler {
          id: bluetoothHoverHandler
        }
      }
      Internet {
        id: internet

        HoverHandler {
          id: internetHoverHandler
        }
      }
      Battery {
        id: battery

        HoverHandler {
          id: batteryHoverHandler
        }
      }
      Button {
        id: notificationButton

        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        horizontalPadding: 0
        verticalPadding: 0
        buttonColor: "transparent"
        buttonBorderColor: "transparent"
        onClicked: root.panelVisible = !root.panelVisible

        IconImage {
          anchors.centerIn: parent
          implicitWidth: 14
          implicitHeight: 14
          source: Qt.resolvedUrl(root.hasNotifications
            ? "../assets/bell-filled.svg"
            : "../assets/bell.svg")

          layer.enabled: true
          layer.effect: MultiEffect {
            brightness: 1
            colorization: 1
            colorizationColor: root.hasNotifications
              ? Theme.color8
              : Theme.foreground
          }
        }

        HoverHandler {
          id: notificationHoverHandler
        }
      }
    }

    Tooltip {
      target: volume
      text: Math.round(volume.volume * 100) + "%"
      shown: volumeHoverHandler.hovered
    }

    Tooltip {
      target: bluetooth
      text: bluetooth.connectedDevicesText
      shown: bluetoothHoverHandler.hovered
    }

    Tooltip {
      target: battery
      text: Math.round(battery.percentage * 100) + "%"
      shown: batteryHoverHandler.hovered
    }

    Tooltip {
      target: internet
      text: internet.networkName
      shown: internetHoverHandler.hovered
    }

    Tooltip {
      target: notificationButton
      text: root.hasNotifications
        ? notifications.history.count + " notifications"
        : "No notifications"
      shown: notificationHoverHandler.hovered
    }
  }

  Popup {
    id: systemPanel

    anchorItem: root.popupAnchor
    implicitWidth: 320
    padding: root.spaceLg
    shown: root.panelVisible

    onVisibleChanged: {
      if (!visible && root.panelVisible)
      root.panelVisible = false
    }

    Item {
      id: panelContent

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      implicitHeight: root.activeSection === "internet"
        ? internetColumn.implicitHeight
        : root.activeSection === "bluetooth"
          ? bluetoothColumn.implicitHeight
        : root.activeSection === "sound"
          ? soundColumn.implicitHeight
        : panelColumn.implicitHeight

      Column {
        id: panelColumn

        width: parent.width
        spacing: root.spaceMd
        enabled: root.activeSection === "settings"
        opacity: enabled ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
          NumberAnimation {
            duration: root.motionFast
            easing.type: Easing.OutCubic
          }
        }

        Item {
          width: parent.width
          height: 24

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Settings"
            color: Theme.foreground
            font.pixelSize: root.titleFontSize
            font.weight: Font.DemiBold
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Theme.color2
        }

        RowLayout {
          width: parent.width
          spacing: root.spaceSm

          ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            spacing: root.spaceXs

            RowLayout {
              Layout.fillWidth: true
              Layout.preferredHeight: 40
              spacing: 0

              Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 40
                topRightRadius: 0
                bottomRightRadius: 0
                enabled: Networking.wifiHardwareEnabled
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled

                Internet {
                  id: internetTileIcon

                  anchors.centerIn: parent
                  width: 20
                  height: 20
                }
              }

              Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 40
                topLeftRadius: 0
                bottomLeftRadius: 0
                horizontalPadding: 0
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: root.activeSection = "internet"

                Text {
                  anchors.centerIn: parent
                  text: "›"
                  color: Theme.foreground
                  font.pixelSize: root.titleFontSize
                }
              }
            }

            Text {
              Layout.fillWidth: true
              text: internetTileIcon.networkName
              color: Theme.color8
              font.pixelSize: root.captionFontSize
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignTop
            spacing: 0

            Button {
              Layout.fillWidth: true
              Layout.preferredWidth: 0
              Layout.preferredHeight: 40
              topRightRadius: 0
              bottomRightRadius: 0
              enabled: root.bluetoothAdapter !== null
              buttonBorderColor: hovered ? Theme.color8 : Theme.color2
              onClicked: {
                if (root.bluetoothAdapter)
                  root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled
              }

              Bluetooth {
                anchors.centerIn: parent
                width: 20
                height: 20
              }
            }

            Button {
              Layout.fillWidth: true
              Layout.preferredWidth: 0
              Layout.preferredHeight: 40
              topLeftRadius: 0
              bottomLeftRadius: 0
              horizontalPadding: 0
              buttonBorderColor: hovered ? Theme.color8 : Theme.color2
              onClicked: root.activeSection = "bluetooth"

              Text {
                anchors.centerIn: parent
                text: "›"
                color: Theme.foreground
                font.pixelSize: root.titleFontSize
              }
            }
          }
        }

        RowLayout {
          width: parent.width
          spacing: root.spaceSm

          Volume {}

          Slider {
            Layout.fillWidth: true
            value: volume.volume
            onMoved: function(value) {
              if (!volume.sink)
                return
              volume.sink.audio.volume = value
              if (value > 0)
                volume.sink.audio.muted = false
            }
          }

          Button {
            Layout.preferredWidth: 30
            Layout.preferredHeight: root.controlHeight
            horizontalPadding: 0
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: root.activeSection = "sound"

            Text {
              anchors.centerIn: parent
              text: "›"
              color: Theme.foreground
              font.pixelSize: root.titleFontSize
            }
          }
        }

        RowLayout {
          width: parent.width
          spacing: root.spaceSm

          Brightness {
            id: brightness
          }

          Slider {
            Layout.fillWidth: true
            from: 0.01
            value: brightness.brightness
            onMoved: function(value) { brightness.setBrightness(value) }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Theme.color2
        }

        RowLayout {
          width: parent.width
          height: 32
          spacing: root.spaceSm

          Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: Theme.foreground
            font.pixelSize: root.titleFontSize
            font.weight: Font.DemiBold
          }

          Button {
            Layout.preferredWidth: 84
            Layout.preferredHeight: root.controlHeight
            enabled: root.hasNotifications
            buttonBorderColor: hovered ? Theme.color11 : Theme.color2
            onClicked: notifications.history.clear()

            Text {
              anchors.centerIn: parent
              text: "Clear all"
              color: parent.enabled ? Theme.color11 : Theme.color2
              font.pixelSize: root.captionFontSize
            }
          }
        }

        RowLayout {
          width: parent.width
          height: root.controlHeight
          spacing: root.spaceSm

          Text {
            Layout.fillWidth: true
            text: "Do not disturb"
            color: Theme.foreground
            font.pixelSize: root.bodyFontSize
          }
          Toggle {
            checked: notifications.doNotDisturb
            onToggled: function(checked) {
              notifications.doNotDisturb = checked
            }
          }
        }

        ListView {
          id: notificationList

          width: parent.width
          height: Math.min(contentHeight, 240)
          visible: root.hasNotifications
          clip: true
          spacing: root.spaceSm
          boundsBehavior: Flickable.StopAtBounds
          model: notifications.history

          delegate: Rectangle {
            id: historyCard

            required property int index
            required property string summary
            required property string body
            required property string appName
            required property string time

            width: notificationList.width
            height: notificationCardColumn.implicitHeight + root.spaceLg * 2
            radius: 4
            color: Theme.background
            border.width: 1
            border.color: Theme.color2

            ColumnLayout {
              id: notificationCardColumn

              anchors.fill: parent
              anchors.margins: root.spaceLg
              spacing: root.spaceXs

              RowLayout {
                Layout.fillWidth: true
                spacing: root.spaceSm

                Text {
                  Layout.fillWidth: true
                  text: historyCard.summary
                  color: Theme.foreground
                  font.pixelSize: root.bodyFontSize
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                }

                Text {
                  text: historyCard.time
                  color: Theme.color5
                  font.pixelSize: root.captionFontSize
                }

                Button {
                  Layout.preferredWidth: 24
                  Layout.preferredHeight: 24
                  horizontalPadding: 0
                  buttonBorderColor: hovered ? Theme.color11 : Theme.color2
                  onClicked: notifications.history.remove(historyCard.index)

                  Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: parent.hovered ? Theme.color11 : Theme.foreground
                    font.pixelSize: root.bodyFontSize
                  }
                }
              }

              Text {
                Layout.fillWidth: true
                visible: historyCard.appName !== ""
                text: historyCard.appName
                color: Theme.color5
                font.pixelSize: root.captionFontSize
                elide: Text.ElideRight
              }

              Text {
                Layout.fillWidth: true
                visible: historyCard.body !== ""
                text: historyCard.body
                color: Theme.foreground
                font.pixelSize: root.bodyFontSize
                wrapMode: Text.WordWrap
              }
            }
          }
        }

        Text {
          width: parent.width
          visible: !root.hasNotifications
          text: "You're all caught up"
          color: Theme.color5
          font.pixelSize: root.captionFontSize
          horizontalAlignment: Text.AlignHCenter
        }
      }

      Column {
        id: soundColumn

        width: parent.width
        spacing: root.spaceSm
        enabled: root.activeSection === "sound"
        opacity: enabled ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
          NumberAnimation {
            duration: root.motionFast
            easing.type: Easing.OutCubic
          }
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
            onClicked: root.activeSection = "settings"

            Text {
              anchors.centerIn: parent
              text: "‹"
              color: Theme.foreground
              font.pixelSize: root.titleFontSize
            }
          }

          Text {
            Layout.fillWidth: true
            text: "Sound output"
            color: Theme.foreground
            font.pixelSize: root.titleFontSize
            font.weight: Font.DemiBold
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Theme.color2
        }

        Repeater {
          model: root.audioOutputs

          Button {
            required property var modelData

            width: soundColumn.width
            implicitHeight: root.listRowHeight
            buttonBorderColor: modelData === Pipewire.defaultAudioSink
              ? Theme.color8
              : (hovered ? Theme.color8 : Theme.color2)
            onClicked: Pipewire.preferredDefaultAudioSink = modelData

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: root.spaceMd
              anchors.rightMargin: root.spaceMd
              spacing: root.spaceSm

              Text {
                Layout.fillWidth: true
                text: modelData.description || modelData.nickname
                  || modelData.name || "Unknown output"
                color: modelData === Pipewire.defaultAudioSink
                  ? Theme.color8
                  : Theme.foreground
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
              }

              Text {
                visible: modelData === Pipewire.defaultAudioSink
                text: "✓"
                color: Theme.color8
                font.pixelSize: root.captionFontSize
              }
            }
          }
        }

        Text {
          visible: root.audioOutputs.length === 0
          text: "No sound outputs found"
          color: Theme.color2
          font.pixelSize: root.captionFontSize
        }
      }

      Column {
        id: internetColumn

        width: parent.width
        spacing: root.spaceSm
        enabled: root.activeSection === "internet"
        opacity: enabled ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
          NumberAnimation {
            duration: root.motionFast
            easing.type: Easing.OutCubic
          }
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
            onClicked: root.activeSection = "settings"

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
            font.weight: Font.DemiBold
          }

          Toggle {
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
          color: Theme.color2
        }

        Text {
          width: parent.width
          text: "Connected networks"
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
          font.weight: Font.DemiBold
        }

        Repeater {
          model: root.connectedNetworks

          Button {
            required property var modelData

            width: internetColumn.width
            implicitHeight: root.listRowHeight
            enabled: !modelData.stateChanging
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: modelData.disconnect()

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: root.spaceMd
              anchors.rightMargin: root.spaceMd

              Text {
                Layout.fillWidth: true
                text: modelData.name || "Unknown network"
                color: Theme.color8
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
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
          text: "Available networks"
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
          font.weight: Font.DemiBold
        }

        Repeater {
          model: root.availableNetworks

          Button {
            required property var modelData

            width: internetColumn.width
            implicitHeight: root.listRowHeight
            enabled: !modelData.stateChanging
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: root.connectNetwork(modelData)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: root.spaceMd
              anchors.rightMargin: root.spaceMd

              Text {
                Layout.fillWidth: true
                text: modelData.name || "Unknown network"
                color: Theme.foreground
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
              }

              Text {
                text: modelData.stateChanging ? "Working…" : "Connect"
                color: Theme.color8
                font.pixelSize: root.captionFontSize
              }
            }
          }
        }

        Text {
          visible: root.availableNetworks.length === 0
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
          text: "Nearby networks"
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
          font.weight: Font.DemiBold
        }

        Repeater {
          model: root.closeNetworks

          Button {
            required property var modelData

            width: internetColumn.width
            implicitHeight: root.listRowHeight
            enabled: !modelData.stateChanging
            buttonBorderColor: root.pendingWifiNetwork === modelData
              ? Theme.color8
              : (hovered ? Theme.color8 : Theme.color2)
            onClicked: root.connectNetwork(modelData)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: root.spaceMd
              anchors.rightMargin: root.spaceMd

              Text {
                Layout.fillWidth: true
                text: modelData.name || "Unknown network"
                color: Theme.foreground
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
              }

              Text {
                text: modelData.stateChanging ? "Working…" : "Connect"
                color: Theme.color8
                font.pixelSize: root.captionFontSize
              }
            }
          }
        }

        Column {
          width: parent.width
          spacing: root.spaceSm
          visible: root.pendingWifiNetwork !== null

          Text {
            width: parent.width
            text: "Password for " + (root.pendingWifiNetwork?.name || "network")
            color: Theme.foreground
            font.pixelSize: root.captionFontSize
            elide: Text.ElideRight
          }

          Rectangle {
            width: parent.width
            height: root.controlHeight
            radius: 4
            color: Theme.color0
            border.width: 1
            border.color: wifiPasswordInput.activeFocus ? Theme.color8 : Theme.color2

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
              onTextChanged: root.wifiPassword = text
              onAccepted: root.connectPendingNetwork()
            }
          }

          RowLayout {
            width: parent.width
            spacing: root.spaceSm

            Button {
              Layout.fillWidth: true
              Layout.preferredHeight: root.controlHeight
              onClicked: {
                root.pendingWifiNetwork = null
                root.wifiPassword = ""
              }

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
              buttonBorderColor: hovered ? Theme.color8 : Theme.color2
              onClicked: root.connectPendingNetwork()

              Text {
                anchors.centerIn: parent
                text: "Connect"
                color: Theme.color8
                font.pixelSize: root.captionFontSize
              }
            }
          }
        }

        Text {
          visible: root.closeNetworks.length === 0
          text: "None"
          color: Theme.color2
          font.pixelSize: root.captionFontSize
        }
      }

      Column {
        id: bluetoothColumn

        width: parent.width
        spacing: root.spaceSm
        enabled: root.activeSection === "bluetooth"
        opacity: enabled ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
          NumberAnimation {
            duration: root.motionFast
            easing.type: Easing.OutCubic
          }
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
            onClicked: root.activeSection = "settings"

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
            font.weight: Font.DemiBold
          }

          Toggle {
            checked: root.bluetoothAdapter?.enabled ?? false
            enabled: root.bluetoothAdapter !== null
            onToggled: function(checked) {
              if (!root.bluetoothAdapter)
                return
              root.bluetoothAdapter.enabled = checked
              root.bluetoothAdapter.discovering = checked
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
          text: "Connected devices"
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
          font.weight: Font.DemiBold
        }

        Repeater {
          model: root.connectedBluetoothDevices

          Button {
            required property var modelData

            width: bluetoothColumn.width
            implicitHeight: root.listRowHeight
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: modelData.disconnect()

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: root.spaceMd
              anchors.rightMargin: root.spaceMd

              Text {
                Layout.fillWidth: true
                text: modelData.name || modelData.deviceName || modelData.address
                color: Theme.color8
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
              }

              Text {
                text: "Disconnect"
                color: Theme.foreground
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
          text: "Available devices"
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
          font.weight: Font.DemiBold
        }

        Repeater {
          model: root.availableBluetoothDevices

          Button {
            required property var modelData

            width: bluetoothColumn.width
            implicitHeight: root.listRowHeight
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: modelData.connect()

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: root.spaceMd
              anchors.rightMargin: root.spaceMd

              Text {
                Layout.fillWidth: true
                text: modelData.name || modelData.deviceName || modelData.address
                color: Theme.foreground
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
              }

              Text {
                text: "Connect"
                color: Theme.color8
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

        Text {
          width: parent.width
          text: "Nearby devices"
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
          font.weight: Font.DemiBold
        }

        Repeater {
          model: root.closeBluetoothDevices

          Button {
            required property var modelData

            width: bluetoothColumn.width
            implicitHeight: root.listRowHeight
            enabled: !modelData.pairing
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: modelData.pair()

            Connections {
              target: modelData

              function onPairedChanged(): void {
                if (modelData.paired && !modelData.connected)
                  modelData.connect()
              }
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: root.spaceMd
              anchors.rightMargin: root.spaceMd

              Text {
                Layout.fillWidth: true
                text: modelData.name || modelData.deviceName || modelData.address
                color: Theme.foreground
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
              }

              Text {
                text: modelData.pairing ? "Pairing…" : "Pair"
                color: Theme.color8
                font.pixelSize: root.captionFontSize
              }
            }
          }
        }

        Text {
          visible: root.closeBluetoothDevices.length === 0
          text: "None"
          color: Theme.color2
          font.pixelSize: root.captionFontSize
        }
      }
    }
  }
}
