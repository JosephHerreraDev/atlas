import Quickshell
import Quickshell.Bluetooth as BluetoothService
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

IconImage {
  id: root

  readonly property var adapter: BluetoothService.Bluetooth.defaultAdapter
  readonly property var connectedDevices: {
    const devices = []
    for (const device of BluetoothService.Bluetooth.devices.values) {
      if (device.connected)
        devices.push(device)
    }
    return devices
  }
  readonly property string connectedDevicesText: {
    if (!adapter || !adapter.enabled)
      return "Bluetooth off"

    const names = []
    for (const device of connectedDevices)
      names.push(device.name || device.deviceName || device.address)
    return names.length > 0 ? names.join("\n") : "No connected devices"
  }

  Layout.preferredWidth: 14
  Layout.preferredHeight: 14
  source: Qt.resolvedUrl(adapter?.enabled
    ? "../assets/bluetooth-on.svg"
    : "../assets/bluetooth-off.svg")

  layer.enabled: true
  layer.effect: MultiEffect {
    brightness: 1
    colorization: 1
    colorizationColor: {
      if (!root.adapter || !root.adapter.enabled)
        return Theme.color11
      if (root.connectedDevices.length > 0)
        return Theme.color8
      return Theme.color2
    }
  }
}
