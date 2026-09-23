import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  id: root

  borderEnabled: false

  property bool calendarVisible: false
  property bool screenshotMenuVisible: false
  property bool recordingMenuVisible: false
  property bool recordingActive: false
  property bool recordingPaused: false
  property int recordingElapsedSeconds: 0
  property string pendingCaptureMode: ""
  property real lastBrightness: -1
  readonly property var audioSink: Pipewire.defaultAudioSink
  readonly property real volume: audioSink?.audio.volume ?? 0
  readonly property bool muted: audioSink?.audio.muted ?? false

  function toggleScreenshotMenu(): void {
    if (root.recordingActive)
      return
    if (screenshotMenuVisible || recordingMenuVisible) {
      screenshotMenuVisible = false
      recordingMenuVisible = false
    } else {
      screenshotMenuVisible = true
    }
  }

  function showVolumeOsd() {
    OsdState.show("volume", muted ? 0 : volume)
  }

  function capture(mode) {
    pendingCaptureMode = mode
    screenshotMenuVisible = false
    recordingMenuVisible = false
    captureDelay.restart()
  }

  function showRecordingMenu() {
    screenshotMenuVisible = false
    recordingMenuVisible = true
  }

  Item {
    implicitWidth: clockButton.implicitWidth
    implicitHeight: clockButton.implicitHeight

    PwObjectTracker {
      objects: [root.audioSink]
    }

    Process {
      id: brightnessQuery
      stdout: StdioCollector {
        onStreamFinished: {
          const match = text.match(/(\d+)%/)
          if (!match)
            return
          const value = Number(match[1]) / 100
          if (root.lastBrightness >= 0
              && Math.abs(value - root.lastBrightness) >= 0.005)
            OsdState.show("brightness", value)
          root.lastBrightness = value
        }
      }
    }

    Process {
      id: recordingStatusQuery
      stdout: StdioCollector {
        onStreamFinished: {
          const status = text.trim()
          const active = status === "recording" || status === "paused"
          if (active && !root.recordingActive)
            root.recordingElapsedSeconds = 0
          else if (!active)
            root.recordingElapsedSeconds = 0
          root.recordingActive = active
          root.recordingPaused = status === "paused"
        }
      }
    }

    Timer {
      interval: 1000
      running: root.recordingActive
      repeat: true
      onTriggered: {
        if (!root.recordingPaused)
          root.recordingElapsedSeconds++
      }
    }

    Timer {
      interval: 350
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: if (!recordingStatusQuery.running)
        recordingStatusQuery.exec(["atlas-screenshot", "status"])
    }

    Timer {
      interval: 400
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!brightnessQuery.running)
          brightnessQuery.exec(["brightnessctl", "-m"])
      }
    }

    Timer {
      id: captureDelay
      interval: 180
      onTriggered: {
        Quickshell.execDetached(["atlas-screenshot", root.pendingCaptureMode])
        root.pendingCaptureMode = ""
      }
    }

    Connections {
      target: root.audioSink?.audio ?? null
      function onVolumesChanged(): void { root.showVolumeOsd() }
      function onMutedChanged(): void { root.showVolumeOsd() }
    }

    Button {
      id: clockButton

      implicitHeight: root.screenshotMenuVisible || root.recordingMenuVisible
        ? screenshotMenu.implicitHeight
        : (root.recordingActive ? screenshotMenu.implicitHeight
        : (OsdState.shown ? osd.implicitHeight : 20))
      buttonColor: root.screenshotMenuVisible || root.recordingMenuVisible
        ? Theme.color0
        : (hovered ? Theme.color1 : Theme.color0)
      buttonBorderColor: Theme.borderFocus
      onClicked: {
        if (root.screenshotMenuVisible || root.recordingMenuVisible) {
          root.screenshotMenuVisible = false
          root.recordingMenuVisible = false
        } else {
          root.calendarVisible = !root.calendarVisible
        }
      }

      Item {
        anchors.centerIn: parent
        implicitWidth: root.screenshotMenuVisible || root.recordingMenuVisible
          ? screenshotMenu.implicitWidth
          : (root.recordingActive ? screenshotMenu.implicitWidth
          : (OsdState.shown ? osd.implicitWidth : clockText.implicitWidth))
        implicitHeight: root.screenshotMenuVisible || root.recordingMenuVisible
          ? screenshotMenu.implicitHeight
          : (root.recordingActive ? screenshotMenu.implicitHeight
          : (OsdState.shown ? osd.implicitHeight : 20))

        Behavior on implicitWidth {
          NumberAnimation {
            duration: Theme.motionNormal
            easing.type: Easing.OutCubic
          }
        }

        Text {
          id: clockText
          anchors.centerIn: parent
          visible: !OsdState.shown && !root.screenshotMenuVisible
            && !root.recordingMenuVisible && !root.recordingActive
          font.weight: Theme.weightStrong
          text: Time.time
          color: Theme.foreground
        }

        Osd {
          id: osd
          anchors.centerIn: parent
          visible: OsdState.shown && !root.screenshotMenuVisible
            && !root.recordingMenuVisible && !root.recordingActive
          iconType: OsdState.iconType
          value: OsdState.value
        }

        ScreenshotMenu {
          id: screenshotMenu
          anchors.centerIn: parent
          screenshotVisible: root.screenshotMenuVisible
          recordingVisible: root.recordingMenuVisible
          recordingActive: root.recordingActive
          recordingPaused: root.recordingPaused
          elapsedSeconds: root.recordingElapsedSeconds
          muted: root.muted
          audioSink: root.audioSink
          onCaptureRequested: function(mode) { root.capture(mode) }
          onRecordingMenuRequested: root.showRecordingMenu()
        }
      }
    }

    CalendarPopup {
      id: calendarPopup

      anchorItem: clockButton
      shown: root.calendarVisible

      onVisibleChanged: {
        if (!visible && root.calendarVisible)
          root.calendarVisible = false
      }
    }
  }
}
