pragma Singleton

import Quickshell
import Quickshell.Bluetooth as BluetoothService
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
  id: root

  readonly property string settingsSection: "settings"
  readonly property string internetSection: "internet"
  readonly property string bluetoothSection: "bluetooth"
  readonly property int maximumCommandOutput: 16384

  property var panelOwner: null
  property string ownerSection: ""
  property bool bluetoothScanRequested: false

  property var pendingWifiNetwork: null
  property var pendingWifiForgetNetwork: null
  property string wifiPassword: ""
  property string wifiConnectionMessage: ""
  property bool wifiConnecting: false

  property string pendingBluetoothForgetAddress: ""
  property string bluetoothPairingAddress: ""
  property string bluetoothActionStage: ""
  property string bluetoothActionDeviceName: ""
  property string bluetoothPairingMessage: ""
  property string bluetoothPromptType: ""
  property string bluetoothPromptText: ""
  property string bluetoothPromptValue: ""
  property string bluetoothCommandOutput: ""
  property bool bluetoothCommandSucceeded: false
  property int bluetoothConnectChecks: 0

  property real networkDownloadSpeed: 0
  property real networkUploadSpeed: 0
  property real previousReceivedBytes: -1
  property real previousSentBytes: -1
  property double previousNetworkSampleTime: 0
  property string sampledNetworkInterface: ""

  readonly property var connectedNetworks: networkList("connected")
  readonly property var primaryConnectedNetwork: connectedNetworks.length > 0
    ? connectedNetworks[0]
    : null
  readonly property var availableNetworks: networkList("available")
  readonly property var closeNetworks: networkList("close")
  readonly property bool wifiAvailable: wifiDevice() !== null
  readonly property var bluetoothAdapter:
    BluetoothService.Bluetooth.defaultAdapter
  readonly property var connectedBluetoothDevices:
    bluetoothDeviceList("connected")
  readonly property var availableBluetoothDevices:
    bluetoothDeviceList("available")
  readonly property var closeBluetoothDevices: bluetoothDeviceList("close")
  readonly property real inputPeak: inputPeakMonitor.peak
  readonly property bool inputPeakEnabled: inputPeakMonitor.enabled

  function updateView(owner, visible: bool, section: string): void {
    const previousSection = ownerSection
    if (visible) {
      panelOwner = owner
      ownerSection = section
      if (section === bluetoothSection
          && previousSection !== bluetoothSection)
        bluetoothScanRequested = true
    } else if (panelOwner === owner) {
      panelOwner = null
      ownerSection = ""
      bluetoothScanRequested = false
    }
    updateWifiScanning()
    updateBluetoothDiscovery()
  }

  function releaseView(owner): void {
    updateView(owner, false, "")
  }

  function networkList(section: string): var {
    const candidates = []
    for (const device of Networking.devices.values) {
      for (const network of device.networks.values) {
        if (section === "connected" && network.connected)
          candidates.push(network)
        else if (section === "available"
            && !network.connected && network.known)
          candidates.push(network)
        else if (section === "close"
            && !network.connected && !network.known)
          candidates.push(network)
      }
    }

    const unique = {}
    const result = []
    for (const network of candidates) {
      const key = (network.name || "") + "|" + String(network.security)
      const existing = unique[key]
      if (!existing) {
        unique[key] = network
        result.push(network)
      } else if ((network.signalStrength || 0)
          > (existing.signalStrength || 0)) {
        const index = result.indexOf(existing)
        unique[key] = network
        result[index] = network
      }
    }

    result.sort(function(left, right) {
      if (section === "connected")
        return networkName(left).localeCompare(networkName(right))
      const signalDifference = (right.signalStrength || 0)
        - (left.signalStrength || 0)
      return signalDifference !== 0
        ? signalDifference
        : networkName(left).localeCompare(networkName(right))
    })
    return result
  }

  function wifiDevice(): var {
    for (const device of Networking.devices.values) {
      if (device.type === DeviceType.Wifi)
        return device
    }
    return null
  }

  function networkName(network): string {
    return network?.name || "Unknown network"
  }

  function formatNetworkSpeed(bytesPerSecond: real): string {
    if (bytesPerSecond >= 1024 * 1024)
      return (bytesPerSecond / (1024 * 1024)).toFixed(1) + " MB/s"
    if (bytesPerSecond >= 1024)
      return (bytesPerSecond / 1024).toFixed(0) + " KB/s"
    return Math.round(bytesPerSecond) + " B/s"
  }

  function sampleNetworkSpeed(): void {
    if (!primaryConnectedNetwork || networkSpeedReader.running)
      return
    sampledNetworkInterface = primaryConnectedNetwork.device.name
    networkSpeedReader.exec([
      "cat",
      "/sys/class/net/" + sampledNetworkInterface + "/statistics/rx_bytes",
      "/sys/class/net/" + sampledNetworkInterface + "/statistics/tx_bytes"
    ])
  }

  function updateWifiScanning(): void {
    const enabled = panelOwner !== null && ownerSection === internetSection
    for (const device of Networking.devices.values) {
      if (device.type === DeviceType.Wifi)
        device.scannerEnabled = enabled
    }
  }

  function connectNetwork(network): void {
    wifiConnectionMessage = ""
    wifiConnecting = false
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

  function connectPendingNetwork(): void {
    if (!pendingWifiNetwork || wifiPassword.length === 0 || wifiConnecting)
      return
    wifiConnecting = true
    wifiConnectionMessage = "Connecting…"
    pendingWifiNetwork.connectWithPsk(wifiPassword)
  }

  function cancelWifiPrompt(): void {
    pendingWifiNetwork = null
    wifiPassword = ""
    wifiConnectionMessage = ""
    wifiConnecting = false
  }

  function clearWifiConfirmation(): void {
    wifiForgetConfirmationTimer.stop()
    pendingWifiForgetNetwork = null
  }

  function clearBluetoothConfirmation(): void {
    bluetoothForgetConfirmationTimer.stop()
    pendingBluetoothForgetAddress = ""
  }

  function clearTransientState(): void {
    cancelWifiPrompt()
    clearWifiConfirmation()
    clearBluetoothConfirmation()
  }

  function handleWifiFailure(reason): void {
    wifiConnecting = false
    const detail = String(reason || "").trim()
    wifiConnectionMessage = detail
      ? "Could not connect: " + detail
      : "Could not connect. Check the password and try again."
  }

  function requestWifiForget(network): void {
    if (pendingWifiForgetNetwork === network) {
      pendingWifiForgetNetwork = null
      wifiForgetConfirmationTimer.stop()
      network.forget()
      return
    }
    pendingWifiForgetNetwork = network
    wifiForgetConfirmationTimer.restart()
  }

  function bluetoothDeviceList(section: string): var {
    if (!bluetoothAdapter)
      return []
    const result = []
    for (const device of bluetoothAdapter.devices.values) {
      if (section === "connected" && device.connected)
        result.push(device)
      else if (section === "available" && !device.connected
          && (device.paired || device.bonded))
        result.push(device)
      else if (section === "close" && !device.connected
          && !device.paired && !device.bonded)
        result.push(device)
    }
    result.sort(function(left, right) {
      return bluetoothDeviceName(left).localeCompare(bluetoothDeviceName(right))
    })
    return result
  }

  function bluetoothDeviceName(device): string {
    return device?.name || device?.deviceName || device?.address
      || "Unknown device"
  }

  function bluetoothAdapterStatus(): string {
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

  function bluetoothDeviceActionText(device, action: string): string {
    if (device.pairing)
      return "Pairing…"
    const state = BluetoothService.BluetoothDeviceState.toString(device.state)
    if (state === "Connecting" || state === "Disconnecting")
      return state + "…"
    return action
  }

  function requestBluetoothScan(enabled: bool): void {
    bluetoothScanRequested = enabled
    updateBluetoothDiscovery()
  }

  function updateBluetoothDiscovery(): void {
    if (!bluetoothAdapter)
      return
    const viewWantsDiscovery = panelOwner !== null
      && ownerSection === bluetoothSection
      && bluetoothScanRequested
    const pairingNeedsDiscovery = bluetoothPairingAddress !== ""
      && bluetoothActionStage === "pair"
    const shouldDiscover = bluetoothAdapter.enabled
      && (viewWantsDiscovery || pairingNeedsDiscovery)
    if (bluetoothAdapter.discovering !== shouldDiscover)
      bluetoothAdapter.discovering = shouldDiscover
  }

  function requestBluetoothForget(device): void {
    if (pendingBluetoothForgetAddress === device.address) {
      pendingBluetoothForgetAddress = ""
      bluetoothForgetConfirmationTimer.stop()
      device.forget()
      return
    }
    pendingBluetoothForgetAddress = device.address
    bluetoothForgetConfirmationTimer.restart()
  }

  function pairBluetoothDevice(device): void {
    if (bluetoothPairingAddress !== "")
      return
    bluetoothPairingAddress = device.address
    bluetoothActionDeviceName = bluetoothDeviceName(device)
    bluetoothPairingMessage = "Pairing with "
      + bluetoothActionDeviceName + "…"
    bluetoothActionStage = "pair"
    updateBluetoothDiscovery()
    bluetoothPromptType = ""
    bluetoothPromptText = ""
    bluetoothPromptValue = ""
    runBluetoothCommand(["bluetoothctl", "--agent", "KeyboardDisplay"])
  }

  function connectBluetoothDevice(device): void {
    if (bluetoothPairingAddress !== "")
      return
    bluetoothPairingAddress = device.address
    bluetoothActionDeviceName = bluetoothDeviceName(device)
    bluetoothPairingMessage = "Connecting to "
      + bluetoothActionDeviceName + "…"
    device.blocked = false
    device.trusted = true
    startBluetoothConnection(device)
  }

  function runBluetoothCommand(command): void {
    bluetoothCommandOutput = ""
    bluetoothCommandSucceeded = false
    bluetoothPairingProcess.exec(command)
  }

  function handleBluetoothCommandLine(line: string): void {
    bluetoothCommandOutput = (bluetoothCommandOutput + line + "\n")
      .slice(-maximumCommandOutput)
    const cleanLine = line.replace(
      /\x1b\[[0-9;?]*[ -/]*[@-~]/g, "")
    const confirmation = cleanLine.match(/confirm passkey\s+([0-9]+)/i)
    if (confirmation) {
      bluetoothPromptType = "confirm"
      bluetoothPromptText = "Confirm that " + confirmation[1]
        + " appears on " + bluetoothActionDeviceName
      bluetoothPromptValue = ""
    } else if (/enter (pin code|passkey)|request (pin code|passkey)/i
        .test(cleanLine)) {
      bluetoothPromptType = "input"
      bluetoothPromptText = "Enter the code shown by "
        + bluetoothActionDeviceName
      bluetoothPromptValue = ""
    } else if (/authorize service/i.test(cleanLine)) {
      bluetoothPromptType = "confirm"
      bluetoothPromptText = "Allow " + bluetoothActionDeviceName
        + " to use this service?"
      bluetoothPromptValue = ""
    }
    if (bluetoothActionStage === "pair"
        && /pairing successful/i.test(cleanLine)) {
      bluetoothCommandSucceeded = true
      bluetoothPairingQuitTimer.start()
    }
  }

  function submitBluetoothPrompt(accepted: bool): void {
    if (!bluetoothPairingProcess.running || bluetoothPromptType === "")
      return
    if (accepted) {
      const response = bluetoothPromptType === "input"
        ? bluetoothPromptValue.trim()
        : "yes"
      if (response === "")
        return
      bluetoothPairingProcess.write(response + "\n")
    } else {
      bluetoothPairingProcess.write("no\n")
    }
    bluetoothPromptType = ""
    bluetoothPromptText = ""
    bluetoothPromptValue = ""
  }

  function bluetoothCommandError(stage: string, device): string {
    const output = bluetoothCommandOutput
      .replace(/\x1b\[[0-9;?]*[ -/]*[@-~]/g, "").trim()
    const failed = /failed|not available|not connected|authentication|error/i
      .test(output)
    let succeeded = false
    if (stage === "pair")
      succeeded = (device?.paired ?? false) || (device?.bonded ?? false)
        || /pairing successful|already paired/i.test(output)
    else if (stage === "trust")
      succeeded = (device?.trusted ?? false)
        || /trust succeeded|already trusted/i.test(output)
    else if (stage === "connect")
      succeeded = (device?.connected ?? false)
        || /connection successful|already connected/i.test(output)
    if (!failed && succeeded)
      return ""
    const lines = output.split(/\r?\n/).filter(function(candidate) {
      return candidate.trim() !== "" && !/^\s*\[CHG\]/.test(candidate)
    })
    return lines.length > 0
      ? lines[lines.length - 1].trim()
      : "Bluetooth did not confirm that the operation succeeded"
  }

  function bluetoothDeviceByAddress(address: string): var {
    if (!bluetoothAdapter)
      return null
    for (const device of bluetoothAdapter.devices.values) {
      if (device.address === address)
        return device
    }
    return null
  }

  function startBluetoothConnection(device): void {
    bluetoothActionStage = "connect"
    bluetoothPairingMessage = "Connecting to "
      + bluetoothActionDeviceName + "…"
    updateBluetoothDiscovery()
    if (!device) {
      finishBluetoothAction("Could not connect to "
        + bluetoothActionDeviceName + ": device is no longer available")
      return
    }
    if (device.connected) {
      finishBluetoothAction("")
      return
    }
    bluetoothConnectChecks = 0
    bluetoothConnectionStartTimer.start()
  }

  function finishBluetoothAction(message: string): void {
    bluetoothPairingTimeoutTimer.stop()
    bluetoothPairingQuitTimer.stop()
    bluetoothConnectionStartTimer.stop()
    bluetoothConnectionTimer.stop()
    bluetoothPairingAddress = ""
    bluetoothActionStage = ""
    bluetoothActionDeviceName = ""
    bluetoothPairingMessage = message
    bluetoothPromptType = ""
    bluetoothPromptText = ""
    bluetoothPromptValue = ""
    updateBluetoothDiscovery()
  }

  function cancelBluetoothPairing(device): void {
    bluetoothPairingProcess.running = false
    if (device?.pairing ?? false)
      device.cancelPair()
    finishBluetoothAction("Pairing canceled")
  }

  PwNodePeakMonitor {
    id: inputPeakMonitor
    node: AudioState.audioSource
    enabled: root.panelOwner !== null
      && root.ownerSection === root.settingsSection
      && AudioState.audioSource !== null
  }

  Connections {
    target: root.pendingWifiNetwork
    ignoreUnknownSignals: true

    function onConnectedChanged(): void {
      if (root.pendingWifiNetwork?.connected ?? false)
        root.cancelWifiPrompt()
    }

    function onConnectionFailed(reason): void {
      root.handleWifiFailure(reason)
    }
  }

  Connections {
    target: root.bluetoothAdapter
    function onEnabledChanged(): void { root.updateBluetoothDiscovery() }
  }

  onPrimaryConnectedNetworkChanged: {
    networkDownloadSpeed = 0
    networkUploadSpeed = 0
    previousReceivedBytes = -1
    previousSentBytes = -1
    previousNetworkSampleTime = 0
  }

  Process {
    id: bluetoothPairingProcess
    stdinEnabled: true

    onStarted: {
      if (root.bluetoothActionStage === "pair") {
        bluetoothPairingTimeoutTimer.start()
        write("pair " + root.bluetoothPairingAddress + "\n")
      }
    }

    stdout: SplitParser {
      onRead: function(data) { root.handleBluetoothCommandLine(data) }
    }
    stderr: SplitParser {
      onRead: function(data) { root.handleBluetoothCommandLine(data) }
    }

    onExited: function(exitCode) {
      bluetoothPairingTimeoutTimer.stop()
      if (root.bluetoothPairingAddress === "")
        return
      const device = root.bluetoothDeviceByAddress(root.bluetoothPairingAddress)
      const commandError = root.bluetoothCommandError(
        root.bluetoothActionStage, device)
      if ((exitCode !== 0 && !root.bluetoothCommandSucceeded)
          || commandError !== "") {
        const action = root.bluetoothActionStage === "pair"
          ? "pair with " : "connect to "
        root.finishBluetoothAction("Could not " + action
          + root.bluetoothActionDeviceName + ": " + commandError)
        return
      }
      if (root.bluetoothActionStage === "pair") {
        if (device) {
          device.blocked = false
          device.trusted = true
        }
        if (device?.connected ?? false) {
          root.finishBluetoothAction("")
          return
        }
        root.startBluetoothConnection(device)
        return
      }
      root.finishBluetoothAction("")
    }
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
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.panelOwner !== null
      && root.ownerSection === root.internetSection
      && root.primaryConnectedNetwork !== null
    onTriggered: root.sampleNetworkSpeed()
  }

  Timer {
    id: bluetoothPairingTimeoutTimer
    interval: 45000
    onTriggered: bluetoothPairingProcess.running = false
  }

  Timer {
    id: bluetoothPairingQuitTimer
    interval: 500
    onTriggered: {
      if (bluetoothPairingProcess.running)
        bluetoothPairingProcess.write("quit\n")
    }
  }

  Timer {
    id: bluetoothConnectionStartTimer
    interval: 100
    repeat: true
    onTriggered: {
      root.bluetoothConnectChecks++
      if ((root.bluetoothAdapter?.discovering ?? false)
          && root.bluetoothConnectChecks < 20)
        return
      stop()
      const device = root.bluetoothDeviceByAddress(root.bluetoothPairingAddress)
      if (!device) {
        root.finishBluetoothAction("Could not connect to "
          + root.bluetoothActionDeviceName + ": device is no longer available")
        return
      }
      root.bluetoothConnectChecks = 0
      device.connect()
      bluetoothConnectionTimer.start()
    }
  }

  Timer {
    id: bluetoothConnectionTimer
    interval: 250
    repeat: true
    onTriggered: {
      root.bluetoothConnectChecks++
      const device = root.bluetoothDeviceByAddress(root.bluetoothPairingAddress)
      if (device?.connected ?? false) {
        root.finishBluetoothAction("")
        return
      }
      const disconnected = device
        && device.state === BluetoothService.BluetoothDeviceState.Disconnected
      if (root.bluetoothConnectChecks >= 40
          || (root.bluetoothConnectChecks >= 3 && disconnected)) {
        root.finishBluetoothAction("Could not connect to "
          + root.bluetoothActionDeviceName)
      }
    }
  }

  Timer {
    id: bluetoothForgetConfirmationTimer
    interval: 4000
    onTriggered: root.pendingBluetoothForgetAddress = ""
  }

  Timer {
    id: wifiForgetConfirmationTimer
    interval: 4000
    onTriggered: root.pendingWifiForgetNetwork = null
  }
}
