import Quickshell
import Quickshell.Bluetooth as BluetoothService
import Quickshell.Io
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
  property var pendingWifiForgetNetwork: null
  property string wifiPassword: ""
  property string wifiConnectionMessage: ""
  property string pendingBluetoothForgetAddress: ""
  property string bluetoothPairingAddress: ""
  property string bluetoothActionStage: ""
  property string bluetoothActionDeviceName: ""
  property string bluetoothPairingMessage: ""
  readonly property int spaceXs: Theme.spaceXs
  readonly property int spaceSm: Theme.spaceSm
  readonly property int spaceMd: Theme.spaceMd
  readonly property int spaceLg: Theme.spaceLg
  readonly property int controlHeight: Theme.controlHeight
  readonly property int listRowHeight: Theme.listRowHeight
  readonly property int bodyFontSize: Theme.fontBody
  readonly property int captionFontSize: Theme.fontCaption
  readonly property int titleFontSize: Theme.fontTitle
  readonly property int motionFast: Theme.motionFast
  readonly property int motionNormal: Theme.motionNormal
  readonly property bool hasNotifications: notifications.history.count > 0
  readonly property var connectedNetworks: networkList("connected")
  readonly property var primaryConnectedNetwork: connectedNetworks.length > 0
    ? connectedNetworks[0]
    : null
  readonly property var availableNetworks: networkList("available")
  readonly property var closeNetworks: networkList("close")
  readonly property var bluetoothAdapter: BluetoothService.Bluetooth.defaultAdapter
  readonly property var connectedBluetoothDevices: bluetoothDeviceList("connected")
  readonly property var availableBluetoothDevices: bluetoothDeviceList("available")
  readonly property var closeBluetoothDevices: bluetoothDeviceList("close")
  readonly property var audioOutputs: audioDeviceList("output")
  readonly property var audioInputs: audioDeviceList("input")
  readonly property var audioDevices: trackableAudioDeviceList()
  readonly property var defaultAudioInput: Pipewire.defaultAudioSource
  readonly property bool defaultAudioInputMuted:
    defaultAudioInput?.audio.muted ?? true
  property real networkDownloadSpeed: 0
  property real networkUploadSpeed: 0
  property real previousReceivedBytes: -1
  property real previousSentBytes: -1
  property double previousNetworkSampleTime: 0
  property string sampledNetworkInterface: ""
  implicitWidth: systemButton.implicitWidth
  implicitHeight: Theme.barControlHeight
  Layout.preferredHeight: Theme.barControlHeight

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

  function formatNetworkSpeed(bytesPerSecond) {
    if (bytesPerSecond >= 1024 * 1024)
      return (bytesPerSecond / (1024 * 1024)).toFixed(1) + " MB/s"
    if (bytesPerSecond >= 1024)
      return (bytesPerSecond / 1024).toFixed(0) + " KB/s"
    return Math.round(bytesPerSecond) + " B/s"
  }

  function sampleNetworkSpeed() {
    if (!primaryConnectedNetwork || networkSpeedReader.running)
      return

    const interfaceName = primaryConnectedNetwork.device.name
    sampledNetworkInterface = interfaceName
    networkSpeedReader.exec([
      "cat",
      "/sys/class/net/" + interfaceName + "/statistics/rx_bytes",
      "/sys/class/net/" + interfaceName + "/statistics/tx_bytes"
    ])
  }

  onPrimaryConnectedNetworkChanged: {
    networkDownloadSpeed = 0
    networkUploadSpeed = 0
    previousReceivedBytes = -1
    previousSentBytes = -1
    previousNetworkSampleTime = 0
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

  function bluetoothDeviceName(device) {
    return device.name || device.deviceName || device.address || "Unknown device"
  }

  function bluetoothAdapterStatus() {
    if (!bluetoothAdapter)
      return "No Bluetooth adapter found"

    const state = BluetoothService.BluetoothAdapterState.toString(
      bluetoothAdapter.state)
    if (state === "Blocked")
      return "Bluetooth is blocked"
    if (state === "Enabling" || state === "Disabling")
      return state + "…"
    return "Turn on Bluetooth to search nearby devices"
  }

  function bluetoothDeviceActionText(device, action) {
    if (device.pairing)
      return "Pairing…"

    const state = BluetoothService.BluetoothDeviceState.toString(device.state)
    if (state === "Connecting" || state === "Disconnecting")
      return state + "…"

    return action
  }

  function updateBluetoothDiscovery() {
    if (!bluetoothAdapter)
      return

    const shouldDiscover = panelVisible
      && activeSection === "bluetooth"
      && bluetoothAdapter.enabled
      && bluetoothPairingAddress === ""
    if (bluetoothAdapter.discovering !== shouldDiscover)
      bluetoothAdapter.discovering = shouldDiscover
  }

  function updateWifiScanning() {
    for (const device of Networking.devices.values) {
      if (device.type === DeviceType.Wifi)
        device.scannerEnabled = panelVisible && activeSection === "internet"
    }
  }

  function requestBluetoothForget(device) {
    if (pendingBluetoothForgetAddress === device.address) {
      pendingBluetoothForgetAddress = ""
      forgetConfirmationTimer.stop()
      device.forget()
      return
    }

    pendingBluetoothForgetAddress = device.address
    forgetConfirmationTimer.restart()
  }

  function requestWifiForget(network) {
    if (pendingWifiForgetNetwork === network) {
      pendingWifiForgetNetwork = null
      wifiForgetConfirmationTimer.stop()
      network.forget()
      return
    }

    pendingWifiForgetNetwork = network
    wifiForgetConfirmationTimer.restart()
  }

  function pairBluetoothDevice(device) {
    if (bluetoothPairingProcess.running)
      return

    bluetoothPairingAddress = device.address
    bluetoothActionDeviceName = bluetoothDeviceName(device)
    bluetoothPairingMessage = "Pairing with "
      + bluetoothActionDeviceName + "…"
    bluetoothActionStage = "pair"
    updateBluetoothDiscovery()
    bluetoothPairingProcess.exec([
      "bluetoothctl", "--timeout", "45", "--agent", "NoInputNoOutput",
      "pair", device.address
    ])
  }

  function connectBluetoothDevice(device) {
    if (bluetoothPairingProcess.running)
      return

    bluetoothPairingAddress = device.address
    bluetoothActionDeviceName = bluetoothDeviceName(device)
    bluetoothPairingMessage = "Connecting to "
      + bluetoothActionDeviceName + "…"
    bluetoothActionStage = "trust"
    device.blocked = false
    updateBluetoothDiscovery()
    bluetoothPairingProcess.exec([
      "bluetoothctl", "--timeout", "15", "trust", device.address
    ])
  }

  function bluetoothDeviceByAddress(address) {
    if (!bluetoothAdapter)
      return null
    for (const device of bluetoothAdapter.devices.values) {
      if (device.address === address)
        return device
    }
    return null
  }

  function finishBluetoothAction(message) {
    bluetoothPairingAddress = ""
    bluetoothActionStage = ""
    bluetoothActionDeviceName = ""
    bluetoothPairingMessage = message
    updateBluetoothDiscovery()
  }

  function cancelBluetoothPairing(device) {
    bluetoothPairingProcess.running = false
    if (device.pairing)
      device.cancelPair()
    finishBluetoothAction("Pairing canceled")
  }

  function trackableAudioDeviceList() {
    const result = []
    for (const node of Pipewire.nodes.values) {
      if (!node.isStream && node.audio !== null)
        result.push(node)
    }
    return result
  }

  function audioDeviceList(direction) {
    const result = []
    const deviceIndexes = {}
    for (const node of Pipewire.nodes.values) {
      if (node.isStream || !node.ready)
        continue

      const matchesDirection = direction === "output"
        ? node.isSink
        : (node.type & PwNodeType.AudioSource) === PwNodeType.AudioSource
      if (!matchesDirection)
        continue

      const deviceId = node.properties["device.id"]
      const identity = deviceId !== undefined
        ? "device:" + deviceId
        : "node:" + (node.name || node.description || node.nickname
          || String(node.id))
      const existingIndex = deviceIndexes[identity]
      if (existingIndex === undefined) {
        deviceIndexes[identity] = result.length
        result.push(node)
        continue
      }

      const defaultNode = direction === "output"
        ? Pipewire.defaultAudioSink
        : Pipewire.defaultAudioSource
      if (node === defaultNode)
        result[existingIndex] = node
    }
    return result
  }

  function audioDeviceName(node, fallback) {
    if (!node)
      return fallback
    return node.nickname || node.description || node.name || fallback
  }

  function connectNetwork(network) {
    wifiConnectionMessage = ""
    pendingWifiNetwork = null
    wifiPassword = ""
    if (network.known
        || network.security === WifiSecurityType.Open
        || network.security === WifiSecurityType.Owe) {
      network.connect()
      return
    }

    pendingWifiNetwork = network
  }

  function connectPendingNetwork() {
    if (!pendingWifiNetwork || wifiPassword.length === 0)
      return

    pendingWifiNetwork.connectWithPsk(wifiPassword)
    pendingWifiNetwork = null
    wifiPassword = ""
  }

  PwObjectTracker {
    objects: root.audioDevices
  }

  PwNodePeakMonitor {
    id: inputPeakMonitor

    node: root.defaultAudioInput
    enabled: root.panelVisible
      && root.activeSection === "settings"
      && root.defaultAudioInput !== null
  }

  Process {
    id: bluetoothPairingProcess

    onExited: function(exitCode) {
      if (root.bluetoothPairingAddress === "")
        return

      const address = root.bluetoothPairingAddress
      const device = root.bluetoothDeviceByAddress(address)
      if (exitCode !== 0) {
        const action = root.bluetoothActionStage === "pair"
          ? "pair with " : "connect to "
        root.finishBluetoothAction("Could not " + action
          + root.bluetoothActionDeviceName
          + ". Put the device in pairing mode and try again.")
        return
      }

      if (root.bluetoothActionStage === "pair") {
        root.bluetoothActionStage = "trust"
        root.bluetoothPairingMessage = "Trusting "
          + root.bluetoothActionDeviceName + "…"
        bluetoothPairingProcess.exec([
          "bluetoothctl", "--timeout", "15", "trust", address
        ])
        return
      }

      if (root.bluetoothActionStage === "trust") {
        if (device) {
          device.blocked = false
          device.trusted = true
        }
        if (device?.connected ?? false) {
          root.finishBluetoothAction("")
          return
        }

        root.bluetoothActionStage = "connect"
        root.bluetoothPairingMessage = "Connecting to "
          + root.bluetoothActionDeviceName + "…"
        bluetoothPairingProcess.exec([
          "bluetoothctl", "--timeout", "30", "connect", address
        ])
        return
      }

      root.finishBluetoothAction("")
    }
  }

  Timer {
    id: networkSpeedTimer

    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.panelVisible
      && root.activeSection === "internet"
      && root.primaryConnectedNetwork !== null
    onTriggered: root.sampleNetworkSpeed()
  }

  Process {
    id: networkSpeedReader

    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.primaryConnectedNetwork
            || root.primaryConnectedNetwork.device.name
              !== root.sampledNetworkInterface)
          return

        const values = text.trim().split(/\s+/)
        if (values.length < 2)
          return

        const received = Number(values[0])
        const sent = Number(values[1])
        const now = Date.now()
        if (root.previousReceivedBytes >= 0) {
          const seconds = Math.max(0.001,
            (now - root.previousNetworkSampleTime) / 1000)
          root.networkDownloadSpeed = Math.max(0,
            (received - root.previousReceivedBytes) / seconds)
          root.networkUploadSpeed = Math.max(0,
            (sent - root.previousSentBytes) / seconds)
        }

        root.previousReceivedBytes = received
        root.previousSentBytes = sent
        root.previousNetworkSampleTime = now
      }
    }
  }

  Timer {
    id: forgetConfirmationTimer

    interval: 4000
    onTriggered: root.pendingBluetoothForgetAddress = ""
  }

  Timer {
    id: wifiForgetConfirmationTimer

    interval: 4000
    onTriggered: root.pendingWifiForgetNetwork = null
  }

  Connections {
    target: root.bluetoothAdapter

    function onEnabledChanged(): void {
      root.updateBluetoothDiscovery()
    }
  }

  onPanelVisibleChanged: {
    if (panelVisible) {
      activeSection = "settings"
      brightness.refresh()
    } else {
      pendingWifiNetwork = null
      pendingWifiForgetNetwork = null
      wifiPassword = ""
      wifiConnectionMessage = ""
      wifiForgetConfirmationTimer.stop()
      pendingBluetoothForgetAddress = ""
      forgetConfirmationTimer.stop()
    }

    updateWifiScanning()
    updateBluetoothDiscovery()
  }

  onActiveSectionChanged: {
    if (activeSection !== "internet") {
      pendingWifiNetwork = null
      pendingWifiForgetNetwork = null
      wifiPassword = ""
      wifiConnectionMessage = ""
      wifiForgetConfirmationTimer.stop()
    }

    pendingBluetoothForgetAddress = ""
    forgetConfirmationTimer.stop()
    updateWifiScanning()
    updateBluetoothDiscovery()
  }

  Button {
    id: systemButton

    anchors.fill: parent
    implicitWidth: iconRow.implicitWidth + horizontalPadding * 2
    implicitHeight: Theme.barControlHeight
    verticalPadding: 0
    onClicked: root.panelVisible = !root.panelVisible

    RowLayout {
      id: iconRow

      anchors.centerIn: parent
      spacing: Theme.spaceXs

      Internet {
        id: internet

        HoverHandler {
          id: internetHoverHandler
        }
      }
      Bluetooth {
        id: bluetooth

        HoverHandler {
          id: bluetoothHoverHandler
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
        Layout.preferredHeight: Theme.barControlHeight
        horizontalPadding: 0
        verticalPadding: 0
        buttonColor: "transparent"
        buttonBorderColor: "transparent"
        onClicked: root.panelVisible = !root.panelVisible

        IconImage {
          anchors.centerIn: parent
          implicitWidth: 14
          implicitHeight: Theme.iconSize
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
        : root.activeSection === "soundOutput"
          ? outputColumn.implicitHeight
        : root.activeSection === "soundInput"
          ? inputColumn.implicitHeight
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
            font.weight: Theme.weightStrong
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

          Button {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignTop
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: root.activeSection = "internet"

            Internet {
              anchors.centerIn: parent
              width: 20
              height: 20
            }
          }

          Button {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignTop
            buttonBorderColor: hovered ? Theme.color8 : Theme.color2
            onClicked: root.activeSection = "bluetooth"

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
            Layout.alignment: Qt.AlignTop
            buttonBorderColor: notifications.doNotDisturb ? Theme.color8 : (hovered ? Theme.color8 : Theme.color2)
            onClicked: notifications.doNotDisturb = !notifications.doNotDisturb

            IconImage {
              anchors.centerIn: parent
              source: Qt.resolvedUrl("../assets/bell-off.svg")
              width: 20
              height: 20
              layer.enabled: true
              layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: notifications.doNotDisturb ? Theme.color8 : Theme.foreground
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          implicitHeight: audioSectionColumn.implicitHeight + root.spaceMd * 2
          radius: Theme.radiusSm
          color: Theme.background
          border.width: Theme.borderWidth
          border.color: Theme.color2

          Column {
            id: audioSectionColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.spaceMd
            spacing: root.spaceSm

            RowLayout {
              width: parent.width
              spacing: root.spaceSm

              Button {
                Layout.preferredWidth: 30
                Layout.preferredHeight: root.controlHeight
                enabled: volume.sink !== null
                horizontalPadding: 0
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: volume.sink.audio.muted = !volume.sink.audio.muted

                Volume {
                  id: volume
                  width: 18
                  height: 14
                  anchors.centerIn: parent
                }
              }

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
                onWheelMoved: function(up) {
                  if (!volume.sink)
                    return
                  const value = Math.max(0, Math.min(1,
                    volume.volume + (up ? 0.02 : -0.02)))
                  volume.sink.audio.volume = value
                  if (value > 0)
                    volume.sink.audio.muted = false
                }
              }
            }

            RowLayout {
              width: parent.width
              spacing: root.spaceSm

              Button {
                Layout.preferredWidth: 30
                Layout.preferredHeight: root.controlHeight
                enabled: root.defaultAudioInput !== null
                horizontalPadding: 0
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: root.defaultAudioInput.audio.muted
                  = !root.defaultAudioInput.audio.muted

                IconImage {
                  anchors.centerIn: parent
                  width: 18
                  height: 14
                  source: Qt.resolvedUrl("../assets/microphone.svg")

                  layer.enabled: true
                  layer.effect: MultiEffect {
                    brightness: 1
                    colorization: 1
                    colorizationColor: root.defaultAudioInputMuted
                      ? Theme.color11
                      : Theme.foreground
                  }
                }
              }

              Slider {
                Layout.fillWidth: true
                enabled: root.defaultAudioInput !== null
                value: root.defaultAudioInput?.audio.volume ?? 0
                indicatorValue: {
                  const noiseFloor = 0.12
                  if (inputPeakMonitor.peak <= noiseFloor)
                    return 0
                  return Math.min(1,
                    (inputPeakMonitor.peak - noiseFloor) / (1 - noiseFloor))
                }
                indicatorVisible: inputPeakMonitor.enabled
                indicatorColor: Theme.foreground
                opacity: enabled ? 1 : 0.5

                onMoved: function(value) {
                  if (!root.defaultAudioInput)
                    return
                  root.defaultAudioInput.audio.volume = value
                  if (value > 0)
                    root.defaultAudioInput.audio.muted = false
                }
                onWheelMoved: function(up) {
                  if (!root.defaultAudioInput)
                    return
                  const value = Math.max(0, Math.min(1,
                    root.defaultAudioInput.audio.volume + (up ? 0.02 : -0.02)))
                  root.defaultAudioInput.audio.volume = value
                  if (value > 0)
                    root.defaultAudioInput.audio.muted = false
                }
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

              Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 42
                enabled: Pipewire.ready
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: root.activeSection = "soundOutput"

                Column {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: root.spaceSm
                  anchors.rightMargin: root.spaceSm
                  spacing: 1

                  Text {
                    width: parent.width
                    text: "Output"
                    color: Theme.color5
                    font.pixelSize: root.captionFontSize
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: root.audioDeviceName(
                      Pipewire.defaultAudioSink, "No output device")
                    color: Theme.foreground
                    font.pixelSize: root.bodyFontSize
                    elide: Text.ElideRight
                  }
                }
              }

              Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 42
                enabled: Pipewire.ready
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: root.activeSection = "soundInput"

                Column {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: root.spaceSm
                  anchors.rightMargin: root.spaceSm
                  spacing: 1

                  Text {
                    width: parent.width
                    text: "Input"
                    color: Theme.color5
                    font.pixelSize: root.captionFontSize
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: root.audioDeviceName(
                      Pipewire.defaultAudioSource, "No input device")
                    color: Theme.foreground
                    font.pixelSize: root.bodyFontSize
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }

        RowLayout {
          width: parent.width
          spacing: root.spaceSm

          Item {
            Layout.preferredWidth: 30
            Layout.preferredHeight: root.controlHeight

            Brightness {
              id: brightness
              width: 18
              height: 14
              anchors.centerIn: parent
            }
          }

          Slider {
            Layout.fillWidth: true
            Layout.rightMargin: root.spaceSm
            from: 0.01
            value: brightness.brightness
            onMoved: function(value) {
              brightness.setBrightness(value)
              OsdState.show("brightness", value)
            }
            onWheelMoved: function(up) {
              const value = Math.max(0.01, Math.min(1,
                brightness.brightness + (up ? 0.02 : -0.02)))
              brightness.setBrightness(value)
              OsdState.show("brightness", value)
            }
          }
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
            font.weight: Theme.weightStrong
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
            radius: Theme.radiusSm
            color: Theme.background
            border.width: Theme.borderWidth
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
                  font.weight: Theme.weightStrong
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
        id: outputColumn

        width: parent.width
        spacing: root.spaceSm
        enabled: root.activeSection === "soundOutput"
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
            text: "Output"
            color: Theme.foreground
            font.pixelSize: root.titleFontSize
            font.weight: Theme.weightStrong
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Theme.color2
        }

        Text {
          width: parent.width
          visible: !Pipewire.ready
          text: "Sound devices are unavailable"
          color: Theme.color2
          font.pixelSize: root.captionFontSize
          horizontalAlignment: Text.AlignHCenter
        }

        Column {
          width: parent.width
          spacing: root.spaceSm
          visible: Pipewire.ready

          Repeater {
            model: root.audioOutputs

            Button {
              id: outputDeviceButton

              required property var modelData
              readonly property bool selected:
                modelData === Pipewire.defaultAudioSink

              width: outputColumn.width
              implicitHeight: root.listRowHeight
              enabled: modelData.ready
              buttonBorderColor: selected
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
                  text: root.audioDeviceName(modelData, "Unknown output")
                  color: outputDeviceButton.selected
                    ? Theme.color8
                    : Theme.foreground
                  font.pixelSize: root.bodyFontSize
                  elide: Text.ElideRight
                }

                Text {
                  text: outputDeviceButton.selected ? "Selected" : "Select"
                  color: Theme.color8
                  font.pixelSize: root.captionFontSize
                }
              }
            }
          }

          Text {
            width: parent.width
            visible: root.audioOutputs.length === 0
            text: "No output devices found"
            color: Theme.color2
            font.pixelSize: root.captionFontSize
            horizontalAlignment: Text.AlignHCenter
          }

        }
      }

      Column {
        id: inputColumn

        width: parent.width
        spacing: root.spaceSm
        enabled: root.activeSection === "soundInput"
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
            text: "Input"
            color: Theme.foreground
            font.pixelSize: root.titleFontSize
            font.weight: Theme.weightStrong
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Theme.color2
        }

        Text {
          width: parent.width
          visible: !Pipewire.ready
          text: "Sound devices are unavailable"
          color: Theme.color2
          font.pixelSize: root.captionFontSize
          horizontalAlignment: Text.AlignHCenter
        }

        Column {
          width: parent.width
          spacing: root.spaceSm
          visible: Pipewire.ready

          Repeater {
            model: root.audioInputs

            Button {
              id: inputDeviceButton

              required property var modelData
              readonly property bool selected:
                modelData === Pipewire.defaultAudioSource

              width: inputColumn.width
              implicitHeight: root.listRowHeight
              enabled: modelData.ready
              buttonBorderColor: selected
                ? Theme.color8
                : (hovered ? Theme.color8 : Theme.color2)
              onClicked: Pipewire.preferredDefaultAudioSource = modelData

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.spaceMd
                anchors.rightMargin: root.spaceMd
                spacing: root.spaceSm

                Text {
                  Layout.fillWidth: true
                  text: root.audioDeviceName(modelData, "Unknown input")
                  color: inputDeviceButton.selected
                    ? Theme.color8
                    : Theme.foreground
                  font.pixelSize: root.bodyFontSize
                  elide: Text.ElideRight
                }

                Text {
                  text: inputDeviceButton.selected ? "Selected" : "Select"
                  color: Theme.color8
                  font.pixelSize: root.captionFontSize
                }
              }
            }
          }

          Text {
            width: parent.width
            visible: root.audioInputs.length === 0
            text: "No input devices found"
            color: Theme.color2
            font.pixelSize: root.captionFontSize
            horizontalAlignment: Text.AlignHCenter
          }
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
            font.weight: Theme.weightStrong
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
          visible: !Networking.wifiHardwareEnabled || !Networking.wifiEnabled
          text: Networking.wifiHardwareEnabled
            ? "Turn on Wi-Fi to search nearby networks"
            : "Wi-Fi is unavailable"
          color: Theme.color2
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

            width: internetColumn.width
            implicitHeight: root.listRowHeight + root.spaceLg
            enabled: !modelData.stateChanging
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
                  text: modelData.name || "Unknown network"
                  color: Theme.color8
                  font.pixelSize: root.bodyFontSize
                  elide: Text.ElideRight
                }

                Text {
                  Layout.fillWidth: true
                  visible: modelData === root.primaryConnectedNetwork
                  text: "↓ " + root.formatNetworkSpeed(root.networkDownloadSpeed)
                    + "   ↑ " + root.formatNetworkSpeed(root.networkUploadSpeed)
                  color: Theme.color5
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
          text: "Saved networks"
          color: Theme.foreground
          font.pixelSize: root.captionFontSize
          font.weight: Theme.weightStrong
        }

        Repeater {
          model: root.availableNetworks

          RowLayout {
            required property var modelData

            width: internetColumn.width
            height: root.listRowHeight
            spacing: root.spaceXs

            Button {
              Layout.fillWidth: true
              Layout.preferredHeight: root.listRowHeight
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

            Button {
              readonly property bool confirming:
                root.pendingWifiForgetNetwork === modelData

              Layout.preferredWidth: confirming ? 70 : 54
              Layout.preferredHeight: root.listRowHeight
              enabled: !modelData.stateChanging
              buttonBorderColor: confirming || hovered
                ? Theme.color11
                : Theme.color2
              onClicked: root.requestWifiForget(modelData)

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
          font.weight: Theme.weightStrong
        }

        Repeater {
          model: root.closeNetworks

          Column {
            required property var modelData

            width: internetColumn.width
            spacing: root.spaceXs

            Button {
              width: parent.width
              implicitHeight: root.listRowHeight + root.spaceSm
              enabled: !modelData.stateChanging
              buttonBorderColor: root.pendingWifiNetwork === modelData
                ? Theme.color8
                : (hovered ? Theme.color8 : Theme.color2)
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
                    color: Theme.foreground
                    font.pixelSize: root.bodyFontSize
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    text: Math.round(modelData.signalStrength * 100) + "% signal"
                    color: Theme.color5
                    font.pixelSize: root.captionFontSize
                    elide: Text.ElideRight
                  }
                }

                Text {
                  text: modelData.stateChanging ? "Working…" : "Connect"
                  color: Theme.color8
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
              color: Theme.color0
              border.width: Theme.borderWidth
              border.color: Theme.color8

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
                  color: Theme.foreground
                  font.pixelSize: root.captionFontSize
                  elide: Text.ElideRight
                }

                Rectangle {
                  width: parent.width
                  height: root.controlHeight
                  radius: Theme.radiusSm
                  color: Theme.background
                  border.width: Theme.borderWidth
                  border.color: wifiPasswordInput.activeFocus
                    ? Theme.color8
                    : Theme.color2

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

                Text {
                  width: parent.width
                  visible: root.wifiConnectionMessage !== ""
                  text: root.wifiConnectionMessage
                  color: Theme.color11
                  font.pixelSize: root.captionFontSize
                  wrapMode: Text.WordWrap
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
                      root.wifiConnectionMessage = ""
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
            }

            Connections {
              target: modelData

              function onConnectionFailed(reason): void {
                root.pendingWifiNetwork = modelData
                root.wifiPassword = ""
                root.wifiConnectionMessage
                  = "Could not connect. Check the password and try again."
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
            font.weight: Theme.weightStrong
          }

          Toggle {
            checked: root.bluetoothAdapter?.enabled ?? false
            enabled: root.bluetoothAdapter !== null
              && root.bluetoothAdapter.state !== BluetoothService.BluetoothAdapterState.Enabling
              && root.bluetoothAdapter.state !== BluetoothService.BluetoothAdapterState.Disabling
            onToggled: function(checked) {
              if (!root.bluetoothAdapter)
                return
              root.bluetoothAdapter.enabled = checked
              if (!checked)
                root.bluetoothAdapter.discovering = false
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

              width: bluetoothColumn.width
              height: root.listRowHeight + root.spaceLg
              spacing: root.spaceXs

              Button {
                Layout.fillWidth: true
                Layout.preferredHeight: root.listRowHeight + root.spaceLg
                enabled: modelData.state === BluetoothService.BluetoothDeviceState.Connected
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

              width: bluetoothColumn.width
              height: root.listRowHeight
              spacing: root.spaceXs

              Button {
                Layout.fillWidth: true
                Layout.preferredHeight: root.listRowHeight
                enabled: modelData.state === BluetoothService.BluetoothDeviceState.Disconnected
                  && !bluetoothPairingProcess.running
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: root.connectBluetoothDevice(modelData)

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: root.spaceMd
                  anchors.rightMargin: root.spaceMd

                  Text {
                    Layout.fillWidth: true
                    text: root.bluetoothDeviceName(modelData)
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
              buttonBorderColor: hovered ? Theme.color8 : Theme.color2
              onClicked: root.bluetoothAdapter.discovering
                = !root.bluetoothAdapter.discovering

              Text {
                anchors.centerIn: parent
                text: root.bluetoothAdapter?.discovering ? "Stop" : "Scan"
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

              width: bluetoothColumn.width
              implicitHeight: root.listRowHeight
              enabled: !bluetoothPairingProcess.running || pairing
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

          Text {
            width: parent.width
            visible: root.bluetoothPairingMessage !== ""
            text: root.bluetoothPairingMessage
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
    }
  }
}
