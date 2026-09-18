import Quickshell
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

Item {
  id: root

  readonly property var device: UPower.displayDevice
  readonly property real percentage: device.ready ? device.percentage : 0
  readonly property bool charging: device.ready && (!UPower.onBattery
    || device.state === UPowerDeviceState.Charging
    || device.state === UPowerDeviceState.PendingCharge)

  Layout.preferredWidth: 18
  Layout.preferredHeight: 16

  IconImage {
    anchors.fill: parent
    source: {
      if (root.charging)
        return Qt.resolvedUrl("../assets/battery-bolt.svg")
      if (root.percentage <= 0.2)
        return Qt.resolvedUrl("../assets/battery-low.svg")
      if (root.percentage <= 0.6)
        return Qt.resolvedUrl("../assets/battery-mid.svg")
      return Qt.resolvedUrl("../assets/battery-full.svg")
    }

    layer.enabled: true
    layer.effect: MultiEffect {
      brightness: 1
      colorization: 1
      colorizationColor: {
        if (root.charging)
          return Theme.color8
        if (root.percentage <= 0.2)
          return Theme.color11
        if (root.percentage <= 0.6)
          return Theme.color13
        return Theme.color14
      }
    }
  }
}
