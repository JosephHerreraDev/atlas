import Quickshell
import QtQuick
import QtQuick.Layouts
import "../shared/"

Button {
  id: systemButton

  implicitWidth: iconRow.implicitWidth + horizontalPadding * 2
  Layout.preferredHeight: 20

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
}
