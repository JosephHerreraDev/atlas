import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "../"
import "../shared/"

Item {
  id: root

  readonly property int menuHeight: 26

  required property bool screenshotVisible
  required property bool recordingVisible
  required property bool recordingActive
  required property bool recordingPaused
  required property int elapsedSeconds
  required property bool muted
  required property var audioSink

  signal captureRequested(string mode)
  signal recordingMenuRequested()

  function formatElapsed(seconds) {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor(seconds / 60) % 60
    const remainingSeconds = seconds % 60
    const paddedMinutes = String(minutes).padStart(2, "0")
    const paddedSeconds = String(remainingSeconds).padStart(2, "0")
    return hours > 0
      ? hours + ":" + paddedMinutes + ":" + paddedSeconds
      : paddedMinutes + ":" + paddedSeconds
  }

  readonly property Item activeRow: recordingActive
    ? recordingControls
    : (recordingVisible ? recordingActions : screenshotActions)

  implicitWidth: activeRow.implicitWidth
  implicitHeight: root.menuHeight

  component MenuButton: Button {
    id: button

    required property string icon
    required property string tooltip

    implicitWidth: 22
    implicitHeight: root.menuHeight
    horizontalPadding: 0
    verticalPadding: 0
    buttonBorderColor: Theme.color2

    IconImage {
      anchors.centerIn: parent
      implicitWidth: 16
      implicitHeight: 16
      source: Qt.resolvedUrl(button.icon)

      layer.enabled: true
      layer.effect: MultiEffect {
        brightness: 1
        colorization: 1
        colorizationColor: button.hovered
          ? Theme.color8
          : Theme.foreground
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
    visible: root.screenshotVisible && !root.recordingActive
    spacing: 2

    Repeater {
      model: [
        { icon: "../assets/screenshot-region.svg", mode: "region", tooltip: "Region" },
        { icon: "../assets/screenshot-display.svg", mode: "display", tooltip: "Screen" },
        { icon: "../assets/screenshot-window.svg", mode: "window", tooltip: "Window" },
        { icon: "../assets/color-picker.svg", mode: "color", tooltip: "Color" },
        { icon: "../assets/screen-record.svg", mode: "record", tooltip: "Record" }
      ]

      MenuButton {
        required property var modelData
        icon: modelData.icon
        tooltip: modelData.tooltip
        onClicked: {
          if (modelData.mode === "record")
            Qt.callLater(root.recordingMenuRequested)
          else
            root.captureRequested(modelData.mode)
        }
      }
    }
  }

  Row {
    id: recordingActions

    anchors.centerIn: parent
    visible: root.recordingVisible && !root.recordingActive
    spacing: 2

    Repeater {
      model: [
        { icon: "../assets/screenshot-region.svg", mode: "record-region", tooltip: "Record region" },
        { icon: "../assets/screenshot-window.svg", mode: "record-window", tooltip: "Record window" },
        { icon: "../assets/screenshot-display.svg", mode: "record-display", tooltip: "Record screen" }
      ]

      MenuButton {
        required property var modelData
        icon: modelData.icon
        tooltip: modelData.tooltip
        onClicked: root.captureRequested(modelData.mode)
      }
    }
  }

  Row {
    id: recordingControls
    anchors.centerIn: parent
    visible: root.recordingActive
    spacing: 4

    Item {
      implicitWidth: 24
      implicitHeight: root.menuHeight

      IconImage {
        anchors.centerIn: parent
        implicitWidth: 16
        implicitHeight: 16
        source: Qt.resolvedUrl("../assets/screen-record.svg")

        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: "#e74856"
        }
      }
    }

    Text {
      height: root.menuHeight
      text: root.formatElapsed(root.elapsedSeconds)
      color: root.recordingPaused ? Theme.color5 : Theme.foreground
      font.family: "monospace"
      font.pixelSize: 11
      font.weight: Font.DemiBold
      verticalAlignment: Text.AlignVCenter
    }

    Repeater {
      model: [
        { icon: "../assets/pause.svg", tooltip: root.recordingPaused ? "Resume recording" : "Pause recording", action: "pause" },
        { icon: "../assets/stop.svg", tooltip: "Stop and save recording", action: "stop" },
        { icon: root.muted ? "../assets/volume-mute.svg" : "../assets/volume-max.svg", tooltip: root.muted ? "Unmute volume" : "Mute volume", action: "volume" },
        { icon: "../assets/microphone.svg", tooltip: "Toggle microphone mute", action: "microphone" }
      ]

      MenuButton {
        required property var modelData
        icon: modelData.icon
        tooltip: modelData.tooltip
        onClicked: {
          if (modelData.action === "pause")
            Quickshell.execDetached(["atlas-screenshot", "record-pause"])
          else if (modelData.action === "stop")
            Quickshell.execDetached(["atlas-screenshot", "record-stop"])
          else if (modelData.action === "volume" && root.audioSink?.audio)
            root.audioSink.audio.muted = !root.audioSink.audio.muted
          else if (modelData.action === "microphone")
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
        }
      }
    }
  }
}
