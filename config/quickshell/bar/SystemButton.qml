import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../shared/"
import "../"

Item {
  id: root

  required property Item popupAnchor
  property bool panelVisible: false
  implicitWidth: systemButton.implicitWidth
  Layout.preferredHeight: 20

  onPanelVisibleChanged: {
    if (panelVisible)
      brightness.refresh()
  }

  Button {
    id: systemButton

    implicitWidth: iconRow.implicitWidth + horizontalPadding * 2
    Layout.preferredHeight: 20
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

  RightPopup {
    id: systemPanel

    anchorItem: root.popupAnchor
    implicitWidth: 300
    shown: root.panelVisible

    onVisibleChanged: {
      if (!visible && root.panelVisible)
      root.panelVisible = false
    }

    Column {
      id: panelColumn

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 6

      Item {
        width: parent.width
        height: 20

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "SETTINGS"
          color: Theme.foreground
          font.pixelSize: 11
          font.bold: true
          font.letterSpacing: 1
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Theme.color2
      }

      RowLayout {
        width: parent.width
        spacing: 6
        Button {
          Layout.fillWidth: true
          Layout.preferredWidth: 0
          Layout.preferredHeight: 40
          onClicked: root.panelVisible = !root.panelVisible
          color: Theme.color2

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
          onClicked: root.panelVisible = !root.panelVisible
          color: Theme.color2

          Bluetooth {
            anchors.centerIn: parent
            width: 20
            height: 20
          }
        }
      }

      RowLayout {
        width: parent.width
        spacing: 8

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
      }

      RowLayout {
        width: parent.width
        spacing: 8

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
    }
  }
}
