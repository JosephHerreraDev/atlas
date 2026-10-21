import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../shared/"
import "../"

Item {
  id: root

  property var buttonHosts: null
  required property Item popupAnchor
  required property var notifications
  property string activePanel: ""
  readonly property bool panelVisible: activePanel !== ""
  readonly property int panelMaximumHeight: 680
  readonly property var audioOutputs: AudioState.audioOutputs
  readonly property var audioInputs: AudioState.audioInputs
  readonly property bool hasNotifications: notifications.history.count > 0
  readonly property bool hasUnreadNotifications: notifications.unreadCount > 0
  implicitWidth: buttonHosts ? 0 : buttonRow.implicitWidth
  implicitHeight: Theme.barControlHeight
  Layout.preferredHeight: Theme.barControlHeight

  function closePanel() {
    activePanel = ""
  }

  function togglePanel(panel) {
    activePanel = activePanel === panel ? "" : panel
  }

  function openSettingsSection(section) {
    activePanel = ""
    Quickshell.execDetached(["qs", "ipc", "call", "settings", "openSection", section])
  }

  function stateSection() {
    if (activePanel === "internet") return SystemState.internetSection
    if (activePanel === "bluetooth") return SystemState.bluetoothSection
    if (activePanel.indexOf("volume") === 0) return SystemState.settingsSection
    return ""
  }

  function audioDeviceName(node, fallback) {
    return AudioState.audioDeviceName(node, fallback)
  }

  function batteryStateText() {
    if (!battery.device.ready)
      return "Battery information unavailable"
    const state = UPowerDeviceState.toString(battery.device.state)
    if (state === "FullyCharged") return "Fully charged"
    if (state === "PendingCharge") return "Waiting to charge"
    if (state === "PendingDischarge") return "Waiting to discharge"
    return state.replace(/([a-z])([A-Z])/g, "$1 $2")
  }

  function batteryTimeText() {
    const seconds = battery.charging
      ? battery.device.timeToFull : battery.device.timeToEmpty
    if (!Number.isFinite(seconds) || seconds <= 0)
      return ""
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.round((seconds % 3600) / 60)
    const duration = (hours > 0 ? hours + " hr " : "") + minutes + " min"
    return battery.charging ? duration + " until full" : duration + " remaining"
  }

  onActivePanelChanged: {
    SystemState.clearTransientState()
    if (activePanel === "display")
      BrightnessState.refresh()
    SystemState.updateView(root, panelVisible, stateSection())
    panelContent.contentY = 0
    if (activePanel === "notifications")
      notifications.markAllRead()
  }

  Component.onDestruction: SystemState.releaseView(root)

  Connections {
    target: BarStyle

    function onEditingChanged(): void {
      if (BarStyle.editing) root.closePanel()
    }
    function onShowDisplayChanged(): void {
      if (!BarStyle.showDisplay && root.activePanel === "display")
        root.closePanel()
    }
    function onShowVolumeChanged(): void {
      if (!BarStyle.showVolume && root.activePanel.indexOf("volume") === 0)
        root.closePanel()
    }
    function onShowInternetChanged(): void {
      if (!BarStyle.showInternet && root.activePanel === "internet")
        root.closePanel()
    }
    function onShowBluetoothChanged(): void {
      if (!BarStyle.showBluetooth && root.activePanel === "bluetooth")
        root.closePanel()
    }
    function onShowBatteryChanged(): void {
      if (!BarStyle.showBattery && root.activePanel === "battery")
        root.closePanel()
    }
    function onShowNotificationsChanged(): void {
      if (!BarStyle.showNotifications && root.activePanel === "notifications")
        root.closePanel()
    }
  }

  RowLayout {
    id: buttonRow
    anchors.fill: parent
    spacing: 0

    Button {
      id: displayButton
      parent: root.buttonHosts && root.buttonHosts["display"]
        ? root.buttonHosts["display"] : buttonRow
      anchors.centerIn: root.buttonHosts && root.buttonHosts["display"] ? parent : undefined
      width: root.buttonHosts && root.buttonHosts["display"] ? parent.width : 26
      height: Theme.barControlHeight
      visible: BarStyle.showDisplay
      Layout.preferredWidth: 26
      Layout.preferredHeight: Theme.barControlHeight
      horizontalPadding: 0
      verticalPadding: 0
      buttonColor: "transparent"
      buttonBorderColor: "transparent"
      accessibleName: root.activePanel === "display" ? "Close display brightness" : "Open display brightness"
      onClicked: root.togglePanel("display")
      onWheelMoved: function(up) {
        BrightnessState.adjustBrightness(up ? 0.02 : -0.02)
      }
      IconImage {
        anchors.centerIn: parent
        width: 14
        height: 14
        source: Qt.resolvedUrl("../assets/display.svg")
        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: root.activePanel === "display"
            ? Theme.accent
            : (BrightnessState.available ? Theme.info : Theme.border)
        }
      }
      HoverHandler { id: displayHover }
    }

    Button {
      id: volumeButton
      parent: root.buttonHosts && root.buttonHosts["volume"]
        ? root.buttonHosts["volume"] : buttonRow
      anchors.centerIn: root.buttonHosts && root.buttonHosts["volume"] ? parent : undefined
      width: root.buttonHosts && root.buttonHosts["volume"] ? parent.width : 26
      height: Theme.barControlHeight
      visible: BarStyle.showVolume
      Layout.preferredWidth: 26
      Layout.preferredHeight: Theme.barControlHeight
      horizontalPadding: 0
      verticalPadding: 0
      buttonColor: "transparent"
      buttonBorderColor: "transparent"
      accessibleName: root.activePanel.indexOf("volume") === 0 ? "Close volume" : "Open volume"
      onClicked: root.togglePanel("volume")
      onWheelMoved: function(up) {
        volume.adjustVolume(up ? 0.02 : -0.02)
      }
      Volume {
        id: volume
        anchors.centerIn: parent
        width: 18
        height: 14
        highlighted: root.activePanel.indexOf("volume") === 0
      }
      HoverHandler { id: volumeHover }
    }

    Button {
      id: internetButton
      parent: root.buttonHosts && root.buttonHosts["internet"]
        ? root.buttonHosts["internet"] : buttonRow
      anchors.centerIn: root.buttonHosts && root.buttonHosts["internet"] ? parent : undefined
      width: root.buttonHosts && root.buttonHosts["internet"] ? parent.width : 26
      height: Theme.barControlHeight
      visible: BarStyle.showInternet
      Layout.preferredWidth: 26
      Layout.preferredHeight: Theme.barControlHeight
      horizontalPadding: 0
      verticalPadding: 0
      buttonColor: "transparent"
      buttonBorderColor: "transparent"
      accessibleName: root.activePanel === "internet" ? "Close internet" : "Open internet"
      onClicked: root.togglePanel("internet")
      Internet {
        id: internet
        anchors.centerIn: parent
        width: 16
        height: 16
        highlighted: root.activePanel === "internet"
      }
      HoverHandler { id: internetHover }
    }

    Button {
      id: bluetoothButton
      parent: root.buttonHosts && root.buttonHosts["bluetooth"]
        ? root.buttonHosts["bluetooth"] : buttonRow
      anchors.centerIn: root.buttonHosts && root.buttonHosts["bluetooth"] ? parent : undefined
      width: root.buttonHosts && root.buttonHosts["bluetooth"] ? parent.width : 26
      height: Theme.barControlHeight
      visible: BarStyle.showBluetooth
      Layout.preferredWidth: 26
      Layout.preferredHeight: Theme.barControlHeight
      horizontalPadding: 0
      verticalPadding: 0
      buttonColor: "transparent"
      buttonBorderColor: "transparent"
      accessibleName: root.activePanel === "bluetooth" ? "Close Bluetooth" : "Open Bluetooth"
      onClicked: root.togglePanel("bluetooth")
      Bluetooth {
        id: bluetooth
        anchors.centerIn: parent
        width: 16
        height: 16
        highlighted: root.activePanel === "bluetooth"
      }
      HoverHandler { id: bluetoothHover }
    }

    Button {
      id: batteryButton
      parent: root.buttonHosts && root.buttonHosts["battery"]
        ? root.buttonHosts["battery"] : buttonRow
      anchors.centerIn: root.buttonHosts && root.buttonHosts["battery"] ? parent : undefined
      width: root.buttonHosts && root.buttonHosts["battery"] ? parent.width : 24
      height: Theme.barControlHeight
      visible: BarStyle.showBattery
      Layout.preferredWidth: 24
      Layout.preferredHeight: Theme.barControlHeight
      horizontalPadding: 0
      verticalPadding: 0
      buttonColor: "transparent"
      buttonBorderColor: "transparent"
      accessibleName: root.activePanel === "battery" ? "Close battery status" : "Open battery status"
      onClicked: root.togglePanel("battery")
      Battery {
        id: battery
        anchors.centerIn: parent
        width: 18
        height: 16
        highlighted: root.activePanel === "battery"
      }
      HoverHandler { id: batteryHover }
    }

    Button {
      id: notificationButton
      parent: root.buttonHosts && root.buttonHosts["notifications"]
        ? root.buttonHosts["notifications"] : buttonRow
      anchors.centerIn: root.buttonHosts && root.buttonHosts["notifications"] ? parent : undefined
      width: root.buttonHosts && root.buttonHosts["notifications"] ? parent.width : 26
      height: Theme.barControlHeight
      visible: BarStyle.showNotifications
      Layout.preferredWidth: 26
      Layout.preferredHeight: Theme.barControlHeight
      horizontalPadding: 0
      verticalPadding: 0
      buttonColor: "transparent"
      buttonBorderColor: "transparent"
      accessibleName: root.activePanel === "notifications" ? "Close notifications" : "Open notifications"
      onClicked: root.togglePanel("notifications")
      IconImage {
        anchors.centerIn: parent
        implicitWidth: 14
        implicitHeight: 14
        source: Qt.resolvedUrl(root.hasUnreadNotifications ? "../assets/bell-filled.svg" : "../assets/bell.svg")
        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: root.activePanel === "notifications"
            ? Theme.accent
            : (root.hasUnreadNotifications ? Theme.accent : Theme.foreground)
        }
      }
      Rectangle {
        visible: root.hasUnreadNotifications
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 1
        anchors.topMargin: 1
        width: Math.max(10, unreadLabel.implicitWidth + 4)
        height: 10
        radius: 5
        color: Theme.error

        Text {
          id: unreadLabel
          anchors.centerIn: parent
          text: root.notifications.unreadCount > 9 ? "9+" : String(root.notifications.unreadCount)
          color: Theme.background
          font.pixelSize: 7
          font.weight: Theme.weightStrong
        }
      }
      HoverHandler { id: notificationHover }
    }
  }

  Tooltip { target: internetButton; text: internet.networkName; shown: internetHover.hovered; edge: BarStyle.position }
  Tooltip { target: bluetoothButton; text: bluetooth.connectedDevicesText; shown: bluetoothHover.hovered; edge: BarStyle.position }
  Tooltip { target: volumeButton; text: AudioState.outputDescription; shown: volumeHover.hovered; edge: BarStyle.position }
  Tooltip {
    target: displayButton
    text: BrightnessState.loading ? "Loading display brightness"
      : (BrightnessState.available
        ? "Brightness " + Math.round(BrightnessState.brightness * 100) + "%"
        : BrightnessState.errorMessage)
    shown: displayHover.hovered
    edge: BarStyle.position
  }
  Tooltip { target: batteryButton; text: Math.round(battery.percentage * 100) + "%"; shown: batteryHover.hovered; edge: BarStyle.position }
  Tooltip {
    target: notificationButton
    text: root.hasUnreadNotifications
      ? notifications.unreadCount + " unread notification"
        + (notifications.unreadCount === 1 ? "" : "s")
      : (root.hasNotifications ? notifications.history.count + " saved notifications" : "No notifications")
    shown: notificationHover.hovered
    edge: BarStyle.position
  }

  Popup {
    id: panel
    anchorItem: root.popupAnchor
    implicitWidth: 380
    padding: Theme.spaceLg
    shown: root.panelVisible
    backgroundOpacity: Theme.popupOpacity
    edge: BarStyle.position
    onVisibleChanged: if (!visible && root.panelVisible) root.closePanel()

    Flickable {
      id: panelContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      readonly property real sectionHeight:
        root.activePanel === "internet" ? internetPanel.implicitHeight
        : root.activePanel === "bluetooth" ? bluetoothPanel.implicitHeight
        : root.activePanel === "volumeOutput" ? outputPanel.implicitHeight
        : root.activePanel === "volumeInput" ? inputPanel.implicitHeight
        : root.activePanel === "volume" ? volumePanel.implicitHeight
        : root.activePanel === "display" ? displayPanel.implicitHeight
        : root.activePanel === "battery" ? batteryPanel.implicitHeight
        : notificationPanel.implicitHeight
      implicitHeight: Math.min(sectionHeight, root.panelMaximumHeight)
      contentWidth: width
      contentHeight: sectionHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick

      Controls.ScrollBar.vertical: Controls.ScrollBar {
        policy: panelContent.contentHeight > panelContent.height
          ? Controls.ScrollBar.AsNeeded : Controls.ScrollBar.AlwaysOff
      }

      InternetSection {
        id: internetPanel
        width: parent.width
        shown: root.activePanel === "internet"
        showBackButton: false
        showSettingsButton: true
      }

      BluetoothSection {
        id: bluetoothPanel
        width: parent.width
        shown: root.activePanel === "bluetooth"
        showBackButton: false
      }

      SystemSection {
        id: volumePanel
        width: parent.width
        spacing: Theme.spaceMd
        shown: root.activePanel === "volume"

        RowLayout {
          width: parent.width
          Text { Layout.fillWidth: true; text: "Volume"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
          Button {
            Layout.preferredWidth: 24
            Layout.preferredHeight: Theme.controlHeight
            horizontalPadding: 0
            accessibleName: "Open audio settings"
            onClicked: root.openSettingsSection("audio")
            IconImage {
              anchors.centerIn: parent
              implicitWidth: 16
              implicitHeight: 16
              source: Qt.resolvedUrl("../assets/settings.svg")
              layer.enabled: true
              layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: Theme.foreground
              }
            }
          }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.border }

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm
          Button {
            Layout.preferredWidth: 30; Layout.preferredHeight: Theme.controlHeight
            enabled: volume.available; horizontalPadding: 0
            accessibleName: volume.muted ? "Unmute audio output" : "Mute audio output"
            onClicked: volume.toggleMute()
            Volume { anchors.centerIn: parent; width: 18; height: 14 }
          }
          Slider {
            Layout.fillWidth: true
            accessibleName: "Output volume"
            to: AudioState.maximumVolume
            value: volume.volume
            onMoved: function(value) { volume.setVolume(value) }
            onWheelMoved: function(up) { volume.adjustVolume(up ? 0.02 : -0.02) }
          }
        }

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm
          Button {
            Layout.preferredWidth: 30; Layout.preferredHeight: Theme.controlHeight
            enabled: AudioState.inputAvailable; horizontalPadding: 0
            accessibleName: AudioState.microphoneMuted ? "Unmute microphone" : "Mute microphone"
            onClicked: AudioState.toggleInputMute()
            IconImage {
              anchors.centerIn: parent; width: 18; height: 14
              source: Qt.resolvedUrl("../assets/microphone.svg")
              layer.enabled: true
              layer.effect: MultiEffect {
                brightness: 1; colorization: 1
                colorizationColor: AudioState.microphoneMuted ? Theme.error : Theme.foreground
              }
            }
          }
          Slider {
            Layout.fillWidth: true
            accessibleName: "Microphone volume"
            enabled: AudioState.inputAvailable
            value: AudioState.inputVolume
            indicatorValue: {
              const floor = 0.12
              return SystemState.inputPeak <= floor ? 0
                : Math.min(1, (SystemState.inputPeak - floor) / (1 - floor))
            }
            indicatorVisible: SystemState.inputPeakEnabled
            indicatorColor: Theme.foreground
            opacity: enabled ? 1 : 0.5
            onMoved: function(value) { AudioState.setInputVolume(value) }
            onWheelMoved: function(up) { AudioState.adjustInputVolume(up ? 0.02 : -0.02) }
          }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.border }

        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm
          Button {
            Layout.fillWidth: true; Layout.preferredWidth: 0; Layout.preferredHeight: 46
            enabled: root.audioOutputs.length > 0
            accessibleName: "Choose audio output"
            onClicked: root.activePanel = "volumeOutput"
            Column {
              anchors.fill: parent; anchors.margins: Theme.spaceSm; spacing: 1
              Text { width: parent.width; text: "Output"; color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
              Text { width: parent.width; text: root.audioDeviceName(AudioState.audioSink, "No output device"); color: Theme.foreground; font.pixelSize: Theme.fontBody; elide: Text.ElideRight }
            }
          }
          Button {
            Layout.fillWidth: true; Layout.preferredWidth: 0; Layout.preferredHeight: 46
            enabled: root.audioInputs.length > 0
            accessibleName: "Choose audio input"
            onClicked: root.activePanel = "volumeInput"
            Column {
              anchors.fill: parent; anchors.margins: Theme.spaceSm; spacing: 1
              Text { width: parent.width; text: "Input"; color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
              Text { width: parent.width; text: root.audioDeviceName(AudioState.audioSource, "No input device"); color: Theme.foreground; font.pixelSize: Theme.fontBody; elide: Text.ElideRight }
            }
          }
        }
      }

      AudioDeviceSection {
        id: outputPanel
        shown: root.activePanel === "volumeOutput"
        title: "Output"
        direction: "output"
        devices: root.audioOutputs
        selectedDevice: AudioState.audioSink
        showSettingsButton: true
        onBackRequested: root.activePanel = "volume"
      }

      AudioDeviceSection {
        id: inputPanel
        shown: root.activePanel === "volumeInput"
        title: "Input"
        direction: "input"
        devices: root.audioInputs
        selectedDevice: AudioState.audioSource
        showSettingsButton: true
        onBackRequested: root.activePanel = "volume"
      }

      SystemSection {
        id: displayPanel
        width: parent.width
        spacing: Theme.spaceMd
        shown: root.activePanel === "display"
        RowLayout {
          width: parent.width
          Text { Layout.fillWidth: true; text: "Display"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
          Button {
            Layout.preferredWidth: 24
            Layout.preferredHeight: Theme.controlHeight
            horizontalPadding: 0
            accessibleName: "Open display settings"
            onClicked: root.openSettingsSection("displays")
            IconImage {
              anchors.centerIn: parent
              implicitWidth: 16
              implicitHeight: 16
              source: Qt.resolvedUrl("../assets/settings.svg")
              layer.enabled: true
              layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: Theme.foreground
              }
            }
          }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.border }
        RowLayout {
          width: parent.width
          spacing: Theme.spaceSm
          Brightness { id: brightnessControl; width: 18; height: 14 }
          Slider {
            Layout.fillWidth: true
            accessibleName: "Screen brightness"
            enabled: BrightnessState.available
            opacity: enabled ? 1 : 0.5
            from: BrightnessState.minimumBrightness
            value: BrightnessState.brightness < 0
              ? BrightnessState.minimumBrightness : BrightnessState.brightness
            onMoved: function(value) { BrightnessState.setBrightness(value) }
            onWheelMoved: function(up) { BrightnessState.adjustBrightness(up ? 0.02 : -0.02) }
          }
          Text {
            text: Math.round(Math.max(0, BrightnessState.brightness) * 100) + "%"
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
          }
        }
        Text {
          width: parent.width
          visible: BrightnessState.initialized && !BrightnessState.available
          text: BrightnessState.errorMessage
          color: Theme.error
          font.pixelSize: Theme.fontCaption
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }
      }

      SystemSection {
        id: batteryPanel
        width: parent.width
        spacing: Theme.spaceMd
        shown: root.activePanel === "battery"

        RowLayout {
          width: parent.width
          Text {
            Layout.fillWidth: true
            text: "Battery"
            color: Theme.foreground
            font.pixelSize: Theme.fontTitle
            font.weight: Theme.weightStrong
          }
          Button {
            Layout.preferredWidth: 24
            Layout.preferredHeight: Theme.controlHeight
            horizontalPadding: 0
            accessibleName: "Open power settings"
            onClicked: root.openSettingsSection("power")
            IconImage {
              anchors.centerIn: parent
              implicitWidth: 16
              implicitHeight: 16
              source: Qt.resolvedUrl("../assets/settings.svg")
              layer.enabled: true
              layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: Theme.foreground
              }
            }
          }
          Text {
            text: Math.round(battery.percentage * 100) + "%"
            color: battery.charging ? Theme.info : Theme.accent
            font.pixelSize: Theme.fontTitle
            font.weight: Theme.weightStrong
          }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.border }

        Rectangle {
          width: parent.width
          height: 10
          radius: height / 2
          color: Theme.border
          Rectangle {
            width: parent.width * Math.max(0, Math.min(1, battery.percentage))
            height: parent.height
            radius: parent.radius
            color: battery.charging ? Theme.info
              : (battery.percentage <= 0.2 ? Theme.error : Theme.success)
          }
        }

        RowLayout {
          width: parent.width
          Text {
            Layout.fillWidth: true
            text: root.batteryStateText()
            color: Theme.foreground
            font.pixelSize: Theme.fontBody
          }
          Text {
            visible: text !== ""
            text: root.batteryTimeText()
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
          }
        }

        Text {
          width: parent.width
          visible: battery.device.ready && battery.device.healthSupported
          text: "Battery health: "
            + Math.round(battery.device.healthPercentage * 100) + "%"
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }

        Text {
          width: parent.width
          visible: battery.device.ready && battery.device.changeRate > 0
          text: "Power draw: " + battery.device.changeRate.toFixed(1) + " W"
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
      }

      SystemSection {
        id: notificationPanel
        width: parent.width
        spacing: Theme.spaceMd
        shown: root.activePanel === "notifications"
        Text {
          width: parent.width
          text: "Notification center"
          color: Theme.foreground
          font.pixelSize: Theme.fontTitle
          font.weight: Theme.weightStrong
        }
        Rectangle {
          width: parent.width
          height: 58
          radius: Theme.radiusLg
          color: notifications.doNotDisturb
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
            : Theme.surface
          border.width: Theme.borderWidth
          border.color: notifications.doNotDisturb ? Theme.accent : Theme.border

          RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceMd
            spacing: Theme.spaceMd

            Rectangle {
              Layout.preferredWidth: 30
              Layout.preferredHeight: 30
              radius: Theme.radiusSm
              color: notifications.doNotDisturb ? Theme.accent : Theme.surfaceHover

              IconImage {
                anchors.centerIn: parent
                width: 17
                height: 17
                source: Qt.resolvedUrl("../assets/bell-off.svg")
                layer.enabled: true
                layer.effect: MultiEffect {
                  brightness: 1
                  colorization: 1
                  colorizationColor: notifications.doNotDisturb
                    ? Theme.background : Theme.foregroundMuted
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true

              Text {
                Layout.fillWidth: true
                text: "Do not disturb"
                color: Theme.foreground
                font.pixelSize: Theme.fontBody
                font.weight: Theme.weightMedium
                elide: Text.ElideRight
              }
            }

            Text {
              text: notifications.doNotDisturb ? "On" : "Off"
              color: notifications.doNotDisturb ? Theme.accent : Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
              font.weight: Theme.weightMedium
            }

            Toggle {
              Layout.preferredWidth: 40
              Layout.preferredHeight: 22
              accessibleName: "Do not disturb"
              checked: notifications.doNotDisturb
              onToggled: function(checked) {
                notifications.doNotDisturb = checked
              }
            }
          }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.border }
        NotificationList { width: parent.width; notifications: root.notifications }
      }
    }
  }
}
