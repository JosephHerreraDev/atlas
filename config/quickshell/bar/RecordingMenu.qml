import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
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
      return "../assets/pause.svg"
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
        bottom: 12
      }

      Pill {
        id: panel

        child: Row {
          spacing: Theme.spaceXs

          RecordingButton {
            icon: "../assets/chevron-left.svg"
            tooltip: root.collapsed
              ? "Expand recording controls"
              : "Collapse recording controls"
            iconRotation: root.collapsed ? 0 : 180
            onClicked: root.collapsed = !root.collapsed
          }

          Row {
            visible: !root.collapsed
            spacing: Theme.spaceXs

            Item {
              implicitWidth: 16
              implicitHeight: 36

              Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: Theme.error
              }
            }

            Text {
              width: 64
              height: 36
              text: ClockState.operationMessage !== ""
                ? ClockState.operationMessage
                : root.formatElapsed(ClockState.recordingElapsedSeconds)
              textFormat: Text.PlainText
              color: ClockState.operationBusy || ClockState.recordingPaused
                ? Theme.foregroundMuted
                : Theme.foreground
              font.family: Qt.application.font.family
              font.pixelSize: Theme.fontCaption
              font.weight: Theme.weightStrong
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
            }

            Repeater {
              model: ["pause", "stop", "output", "microphone"]

              RecordingButton {
                required property string modelData

                icon: root.actionIcon(modelData)
                tooltip: root.actionTooltip(modelData)
                selected: root.actionSelected(modelData)
                iconColor: selected
                  ? Theme.error
                  : (hovered ? Theme.accent : Theme.foreground)
                enabled: !ClockState.operationBusy
                onClicked: ClockState.performRecordingAction(modelData)
              }
            }
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

    implicitWidth: 38
    implicitHeight: 36
    horizontalPadding: 0
    verticalPadding: 0
    accessibleName: tooltip
    buttonBorderColor: selected || hovered ? Theme.accent : Theme.border

    IconImage {
      anchors.centerIn: parent
      implicitWidth: 20
      implicitHeight: 20
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
