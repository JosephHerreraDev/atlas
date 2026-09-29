import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../shared/"
import "../"

Item {
  id: root

  required property Item popupAnchor
  required property var notifications
  property bool panelVisible: false
  property string activeSection: SystemState.settingsSection
  readonly property int spaceSm: Theme.spaceSm
  readonly property int spaceMd: Theme.spaceMd
  readonly property int spaceLg: Theme.spaceLg
  readonly property int controlHeight: Theme.controlHeight
  readonly property int bodyFontSize: Theme.fontBody
  readonly property int captionFontSize: Theme.fontCaption
  readonly property int titleFontSize: Theme.fontTitle
  readonly property int panelMaximumHeight: 600
  readonly property bool hasNotifications: notifications.history.count > 0
  readonly property var audioOutputs: AudioState.audioOutputs
  readonly property var audioInputs: AudioState.audioInputs
  implicitWidth: systemButton.implicitWidth
  implicitHeight: Theme.barControlHeight
  Layout.preferredHeight: Theme.barControlHeight

  function isValidSection(section) {
    return section === SystemState.settingsSection
      || section === SystemState.internetSection
      || section === SystemState.bluetoothSection
      || section === "soundOutput"
      || section === "soundInput"
  }

  function setSection(section) {
    activeSection = isValidSection(section)
      ? section
      : SystemState.settingsSection
  }

  function audioDeviceName(node, fallback) {
    return AudioState.audioDeviceName(node, fallback)
  }

  onPanelVisibleChanged: {
    if (panelVisible) {
      setSection(SystemState.settingsSection)
      BrightnessState.refresh()
    } else {
      SystemState.clearTransientState()
    }
    SystemState.updateView(root, panelVisible, activeSection)
  }

  onActiveSectionChanged: {
    if (!isValidSection(activeSection)) {
      setSection(SystemState.settingsSection)
      return
    }

    if (activeSection !== SystemState.internetSection) {
      SystemState.cancelWifiPrompt()
      SystemState.clearWifiConfirmation()
    }
    if (activeSection !== SystemState.bluetoothSection)
      SystemState.clearBluetoothConfirmation()
    panelContent.contentY = 0
    SystemState.updateView(root, panelVisible, activeSection)
  }

  Component.onDestruction: SystemState.releaseView(root)

  Shortcut {
    sequence: "Alt+Left"
    context: Qt.WindowShortcut
    enabled: root.panelVisible
      && root.activeSection !== SystemState.settingsSection
    onActivated: root.setSection(SystemState.settingsSection)
  }

  Button {
    id: systemButton

    anchors.fill: parent
    implicitWidth: iconRow.implicitWidth + horizontalPadding * 2
    implicitHeight: Theme.barControlHeight
    accessibleName: root.panelVisible
      ? "Close system menu"
      : "Open system menu"
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
        accessibleName: root.panelVisible
          ? "Close notifications"
          : "Open notifications"
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
    backgroundOpacity: Theme.popupOpacity

    onVisibleChanged: {
      if (!visible && root.panelVisible)
      root.panelVisible = false
    }

    Flickable {
      id: panelContent

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      readonly property real sectionHeight:
        root.activeSection === "internet"
        ? internetColumn.implicitHeight
        : root.activeSection === "bluetooth"
          ? bluetoothColumn.implicitHeight
        : root.activeSection === "soundOutput"
          ? outputColumn.implicitHeight
        : root.activeSection === "soundInput"
          ? inputColumn.implicitHeight
        : panelColumn.implicitHeight
      implicitHeight: Math.min(sectionHeight, root.panelMaximumHeight)
      contentWidth: width
      contentHeight: sectionHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick

      Controls.ScrollBar.vertical: Controls.ScrollBar {
        policy: panelContent.contentHeight > panelContent.height
          ? Controls.ScrollBar.AsNeeded
          : Controls.ScrollBar.AlwaysOff
      }

      SystemSection {
        id: panelColumn

        width: parent.width
        spacing: root.spaceMd
        shown: root.activeSection === SystemState.settingsSection

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
            accessibleName: "Open internet settings"
            onClicked: root.setSection(SystemState.internetSection)

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
            accessibleName: "Open Bluetooth settings"
            onClicked: root.setSection(SystemState.bluetoothSection)

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
            accessibleName: notifications.doNotDisturb
              ? "Disable do not disturb"
              : "Enable do not disturb"
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
                enabled: volume.available
                accessibleName: !volume.available
                  ? AudioState.outputError
                  : (volume.muted
                    ? "Unmute audio output"
                    : "Mute audio output")
                horizontalPadding: 0
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: volume.toggleMute()

                Volume {
                  id: volume
                  width: 18
                  height: 14
                  anchors.centerIn: parent
                }
              }

              Slider {
                Layout.fillWidth: true
                accessibleName: "Output volume"
                Accessible.description: AudioState.outputDescription
                to: AudioState.maximumVolume
                value: volume.volume
                onMoved: function(value) { volume.setVolume(value) }
                onWheelMoved: function(up) {
                  volume.adjustVolume(up ? 0.02 : -0.02)
                }
              }
            }

            RowLayout {
              width: parent.width
              spacing: root.spaceSm

              Button {
                Layout.preferredWidth: 30
                Layout.preferredHeight: root.controlHeight
                enabled: AudioState.inputAvailable
                accessibleName: !AudioState.inputAvailable
                  ? AudioState.inputError
                  : (AudioState.microphoneMuted
                    ? "Unmute microphone"
                    : "Mute microphone")
                horizontalPadding: 0
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                onClicked: AudioState.toggleInputMute()

                IconImage {
                  anchors.centerIn: parent
                  width: 18
                  height: 14
                  source: Qt.resolvedUrl("../assets/microphone.svg")

                  layer.enabled: true
                  layer.effect: MultiEffect {
                    brightness: 1
                    colorization: 1
                    colorizationColor: AudioState.microphoneMuted
                      ? Theme.color11
                      : Theme.foreground
                  }
                }
              }

              Slider {
                Layout.fillWidth: true
                accessibleName: "Microphone volume"
                Accessible.description: AudioState.inputDescription
                enabled: AudioState.inputAvailable
                value: AudioState.inputVolume
                indicatorValue: {
                  const noiseFloor = 0.12
                  if (SystemState.inputPeak <= noiseFloor)
                    return 0
                  return Math.min(1,
                    (SystemState.inputPeak - noiseFloor) / (1 - noiseFloor))
                }
                indicatorVisible: SystemState.inputPeakEnabled
                indicatorColor: Theme.foreground
                opacity: enabled ? 1 : 0.5

                onMoved: function(value) {
                  AudioState.setInputVolume(value)
                }
                onWheelMoved: function(up) {
                  AudioState.adjustInputVolume(up ? 0.02 : -0.02)
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
                enabled: AudioState.audioOutputs.length > 0
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                accessibleName: "Choose audio output"
                onClicked: root.setSection("soundOutput")

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
                      AudioState.audioSink, "No output device")
                    textFormat: Text.PlainText
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
                enabled: AudioState.audioInputs.length > 0
                buttonBorderColor: hovered ? Theme.color8 : Theme.color2
                accessibleName: "Choose audio input"
                onClicked: root.setSection("soundInput")

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
                      AudioState.audioSource, "No input device")
                    textFormat: Text.PlainText
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
            accessibleName: "Screen brightness"
            Accessible.description: brightness.accessibleDescription
            enabled: brightness.available
            opacity: enabled ? 1 : 0.5
            from: BrightnessState.minimumBrightness
            value: brightness.brightness
            onMoved: function(value) {
              brightness.setBrightness(value)
            }
            onWheelMoved: function(up) {
              brightness.adjustBrightness(up ? 0.02 : -0.02)
            }
          }
        }

        Text {
          width: parent.width
          visible: BrightnessState.initialized
            && !BrightnessState.available
          text: BrightnessState.errorMessage
          textFormat: Text.PlainText
          color: Theme.color11
          font.pixelSize: root.captionFontSize
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }

        NotificationList {
          width: parent.width
          notifications: root.notifications
        }
      }

      AudioDeviceSection {
        id: outputColumn

        shown: root.activeSection === "soundOutput"
        title: "Output"
        direction: "output"
        devices: root.audioOutputs
        selectedDevice: AudioState.audioSink
        onBackRequested: root.setSection(SystemState.settingsSection)
      }

      AudioDeviceSection {
        id: inputColumn

        shown: root.activeSection === "soundInput"
        title: "Input"
        direction: "input"
        devices: root.audioInputs
        selectedDevice: AudioState.audioSource
        onBackRequested: root.setSection(SystemState.settingsSection)
      }

      InternetSection {
        id: internetColumn

        shown: root.activeSection === SystemState.internetSection
        onBackRequested: root.setSection(SystemState.settingsSection)
      }

      BluetoothSection {
        id: bluetoothColumn

        shown: root.activeSection === SystemState.bluetoothSection
        onBackRequested: root.setSection(SystemState.settingsSection)
      }
    }
  }
}
