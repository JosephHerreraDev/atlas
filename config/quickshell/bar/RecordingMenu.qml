import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

Scope {
  id: root

  property bool collapsed: false

  function formatElapsed(seconds: int): string {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor(seconds / 60) % 60
    const remainingSeconds = seconds % 60
    const paddedMinutes = String(minutes).padStart(2, "0")
    const paddedSeconds = String(remainingSeconds).padStart(2, "0")
    return hours > 0
      ? hours + ":" + paddedMinutes + ":" + paddedSeconds
      : paddedMinutes + ":" + paddedSeconds
  }

  function actionIcon(action: string): string {
    if (action === "pause")
      return ClockState.recordingPaused ? "../assets/play.svg" : "../assets/pause.svg"
    if (action === "stop")
      return "../assets/stop.svg"
    if (action === "output")
      return AudioState.muted
        ? "../assets/volume-mute.svg"
        : "../assets/volume-max.svg"
    return "../assets/microphone.svg"
  }

  function actionTooltip(action: string): string {
    if (action === "pause")
      return ClockState.recordingPaused
        ? "Resume recording"
        : "Pause recording"
    if (action === "stop")
      return "Stop and save recording"
    if (action === "output")
      return AudioState.muted
        ? "Unmute system output"
        : "Mute system output"
    return AudioState.microphoneMuted
      ? "Unmute system microphone"
      : "Mute system microphone"
  }

  function actionSelected(action: string): bool {
    return action === "pause" && ClockState.recordingPaused
      || action === "output" && AudioState.muted
      || action === "microphone" && AudioState.microphoneMuted
  }

  Connections {
    target: ClockState

    function onRecordingActiveChanged(): void {
      if (ClockState.recordingActive)
        root.collapsed = false
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData

      screen: modelData
      visible: ClockState.recordingActive
        && Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor
      color: "transparent"
      aboveWindows: true
      focusable: false
      exclusionMode: ExclusionMode.Ignore
      exclusiveZone: 0
      implicitWidth: panel.implicitWidth
      implicitHeight: panel.implicitHeight

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.namespace: "atlas-recording-menu"

      anchors {
        right: true
        bottom: true
      }

      margins {
        right: 12
        bottom: 12 + BarStyle.bottomClearance
      }

      Rectangle {
        id: panel
        implicitWidth: strip.implicitWidth + 16
        implicitHeight: 38
        color: Theme.surface
        radius: Theme.radiusSm
        border.width: Theme.borderWidth
        border.color: Theme.borderFocus

        Row {
          id: strip
          anchors.centerIn: parent
          spacing: 2

          Item {
            width: 12
            height: 28
            Rectangle {
              anchors.centerIn: parent
              width: 6; height: 6; radius: 3
              color: ClockState.recordingPaused ? Theme.warning : Theme.error
            }
          }
          Text {
            width: implicitWidth + 8
            height: 28
            text: root.formatElapsed(ClockState.recordingElapsedSeconds)
            color: ClockState.recordingPaused ? Theme.foregroundMuted : Theme.foreground
            font.family: "monospace"
            font.pixelSize: Theme.fontCaption
            verticalAlignment: Text.AlignVCenter
          }
          Repeater {
            model: ["pause", "stop", "output", "microphone"]
            RecordingButton {
              required property string modelData
              visible: !root.collapsed || modelData === "stop"
              icon: root.actionIcon(modelData)
              tooltip: root.actionTooltip(modelData)
              selected: root.actionSelected(modelData)
              iconColor: selected ? Theme.warning : hovered ? Theme.accent : Theme.foreground
              enabled: !ClockState.operationBusy
                && (modelData === "output" ? AudioState.outputAvailable
                  : modelData === "microphone" ? AudioState.inputAvailable : true)
              onClicked: ClockState.performRecordingAction(modelData)
            }
          }
          RecordingButton {
            icon: "../assets/chevron-left.svg"
            tooltip: root.collapsed ? "Expand recording controls" : "Collapse recording controls"
            iconRotation: root.collapsed ? 0 : 180
            onClicked: root.collapsed = !root.collapsed
          }
        }
      }
    }
  }

  component RecordingButton: Button {
    id: button

    required property string icon
    required property string tooltip
    property bool selected: false
    property real iconRotation: 0
    property color iconColor: hovered ? Theme.accent : Theme.foreground

    implicitWidth: 30
    implicitHeight: 28
    horizontalPadding: 0
    verticalPadding: 0
    accessibleName: tooltip
    buttonColor: hovered || selected ? Theme.surfaceHover : "transparent"
    buttonBorderWidth: 0
    opacity: enabled ? 1 : 0.4

    IconImage {
      anchors.centerIn: parent
      width: 16
      height: 16
      source: Qt.resolvedUrl(button.icon)
      rotation: button.iconRotation
      layer.enabled: true
      layer.effect: MultiEffect {
        brightness: 1
        colorization: 1
        colorizationColor: button.iconColor
      }
    }

  }
}
