import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "../"
import "../shared/"

FocusScope {
  id: root

  readonly property int buttonHeight: 36
  readonly property int verticalMargin: 4
  readonly property int menuHeight: buttonHeight + verticalMargin * 2
  readonly property bool presented: screenshotVisible || recordingVisible
  readonly property Item activeRow: recordingVisible
    ? recordingActions
    : screenshotActions

  required property bool screenshotVisible
  required property bool recordingVisible
  required property bool operationBusy

  signal captureRequested(string mode)
  signal recordingMenuRequested()
  signal closeRequested()

  implicitWidth: activeRow.implicitWidth
  implicitHeight: root.menuHeight

  function activeRepeater() {
    return recordingVisible ? recordingActionRepeater : screenshotActionRepeater
  }

  function focusAction(index) {
    const repeater = activeRepeater()
    if (!repeater || repeater.count === 0)
      return
    const normalized = (index + repeater.count) % repeater.count
    const item = repeater.itemAt(normalized)
    if (item)
      item.forceActiveFocus()
  }

  Shortcut {
    sequence: "Escape"
    context: Qt.WindowShortcut
    enabled: root.presented
    onActivated: root.closeRequested()
  }

  component MenuButton: Button {
    id: button

    required property string icon
    required property string tooltip
    required property int actionIndex
    property color iconColor: button.hovered || button.activeFocus
      ? Theme.color8
      : Theme.foreground
    property bool selected: false

    implicitWidth: 38
    implicitHeight: root.buttonHeight
    horizontalPadding: 0
    verticalPadding: 0
    accessibleName: tooltip
    enabled: !root.operationBusy
    buttonBorderColor: selected || hovered || activeFocus
      ? Theme.color8
      : Theme.color2

    Shortcut {
      sequence: "Left"
      context: Qt.WindowShortcut
      enabled: button.activeFocus
      onActivated: root.focusAction(button.actionIndex - 1)
    }

    Shortcut {
      sequence: "Right"
      context: Qt.WindowShortcut
      enabled: button.activeFocus
      onActivated: root.focusAction(button.actionIndex + 1)
    }

    Shortcut {
      sequence: "Home"
      context: Qt.WindowShortcut
      enabled: button.activeFocus
      onActivated: root.focusAction(0)
    }

    Shortcut {
      sequence: "End"
      context: Qt.WindowShortcut
      enabled: button.activeFocus
      onActivated: {
        const repeater = root.activeRepeater()
        root.focusAction(repeater ? repeater.count - 1 : 0)
      }
    }

    IconImage {
      anchors.centerIn: parent
      implicitWidth: 20
      implicitHeight: 20
      source: Qt.resolvedUrl(button.icon)

      layer.enabled: true
      layer.effect: MultiEffect {
        brightness: 1
        colorization: 1
        colorizationColor: button.iconColor
      }
    }

    Tooltip {
      target: button
      text: button.tooltip
      shown: button.hovered
    }
  }

  Row {
    id: screenshotActions

    anchors.centerIn: parent
    visible: root.screenshotVisible
    spacing: Theme.spaceXxs

    Repeater {
      id: screenshotActionRepeater
      model: [
        {
          icon: "../assets/screenshot-region.svg",
          mode: ClockState.captureRegionMode,
          tooltip: "Capture region"
        },
        {
          icon: "../assets/screenshot-display.svg",
          mode: ClockState.captureDisplayMode,
          tooltip: "Choose display to capture"
        },
        {
          icon: "../assets/screenshot-window.svg",
          mode: ClockState.captureWindowMode,
          tooltip: "Capture window"
        },
        {
          icon: "../assets/color-picker.svg",
          mode: ClockState.captureColorMode,
          tooltip: "Pick color and copy it"
        },
        {
          icon: "../assets/screen-record.svg",
          mode: "record-menu",
          tooltip: "Open recording options"
        }
      ]

      MenuButton {
        required property int index
        required property var modelData

        actionIndex: index
        icon: modelData.icon
        tooltip: modelData.tooltip
        onClicked: {
          if (modelData.mode === "record-menu") {
            Qt.callLater(function() {
              root.recordingMenuRequested()
            })
          } else {
            root.captureRequested(modelData.mode)
          }
        }
      }
    }
  }

  Row {
    id: recordingActions

    anchors.centerIn: parent
    visible: root.recordingVisible
    spacing: Theme.spaceXxs

    Repeater {
      id: recordingActionRepeater
      model: [
        {
          icon: "../assets/screenshot-region.svg",
          mode: ClockState.recordRegionMode,
          tooltip: "Record region"
        },
        {
          icon: "../assets/screenshot-window.svg",
          mode: ClockState.recordWindowMode,
          tooltip: "Record window"
        },
        {
          icon: "../assets/screenshot-display.svg",
          mode: ClockState.recordDisplayMode,
          tooltip: "Choose display to record"
        }
      ]

      MenuButton {
        required property int index
        required property var modelData

        actionIndex: index
        icon: modelData.icon
        tooltip: modelData.tooltip
        onClicked: root.captureRequested(modelData.mode)
      }
    }
  }

}
