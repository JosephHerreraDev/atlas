import Quickshell
import Quickshell.Networking
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"

Item {
  id: root

  readonly property var device: findDevice()
  readonly property bool connected: device?.connected ?? false
  readonly property bool wired: device?.type === DeviceType.Wired
  readonly property var wifiNetwork: findWifiNetwork()
  readonly property real signalStrength: wifiNetwork?.signalStrength ?? 0
  readonly property string networkName: wired
    ? (device?.network?.name || device?.name || "Ethernet")
    : (wifiNetwork?.name || "Disconnected")
  readonly property bool limited: connected
    && (Networking.connectivity === NetworkConnectivity.None
      || Networking.connectivity === NetworkConnectivity.Portal
      || Networking.connectivity === NetworkConnectivity.Limited)

  function findDevice() {
    const devices = Networking.devices.values

    for (const candidate of devices) {
      if (candidate.type === DeviceType.Wired && candidate.connected)
        return candidate
    }
    for (const candidate of devices) {
      if (candidate.type === DeviceType.Wifi && candidate.connected)
        return candidate
    }
    for (const candidate of devices) {
      if (candidate.type === DeviceType.Wifi)
        return candidate
    }
    return devices.length > 0 ? devices[0] : null
  }

  function findWifiNetwork() {
    if (!device || device.type !== DeviceType.Wifi)
      return null

    for (const network of device.networks.values) {
      if (network.connected)
        return network
    }
    return null
  }

  Layout.preferredWidth: wired ? 16 : 14
  Layout.preferredHeight: 14

  IconImage {
    anchors.fill: parent
    source: {
      if (root.wired && root.connected)
        return Qt.resolvedUrl("../assets/ethernet.svg")
      if (!root.connected || !Networking.wifiEnabled)
        return Qt.resolvedUrl("../assets/wifi-off.svg")
      if (root.limited)
        return Qt.resolvedUrl("../assets/wifi-exclamation.svg")
      if (root.signalStrength <= 0.33)
        return Qt.resolvedUrl("../assets/wifi-low.svg")
      if (root.signalStrength <= 0.66)
        return Qt.resolvedUrl("../assets/wifi-mid.svg")
      return Qt.resolvedUrl("../assets/wifi-high.svg")
    }

    layer.enabled: true
    layer.effect: MultiEffect {
      brightness: 1
      colorization: 1
      colorizationColor: {
        if (!root.connected)
          return Theme.color11
        if (root.limited)
          return Theme.color13
        if (root.wired)
          return Theme.color8
        return Theme.color14
      }
    }
  }
}
