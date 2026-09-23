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

  readonly property int collapsedImplicitHeight: 20 + margin * 2
  readonly property int maximumImplicitHeight: Math.max(
    collapsedImplicitHeight,
    calendarMenu.implicitHeight + margin * 2,
    screenshotMenu.implicitHeight + margin * 2)

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
  readonly property bool screenshotSurfaceShown: screenshotMenuVisible
    || recordingMenuVisible || recordingActive
  readonly property bool menuSurfaceShown: calendarVisible
    || screenshotSurfaceShown
  readonly property bool menuClosable: calendarVisible
    || screenshotMenuVisible || recordingMenuVisible

  function toggleScreenshotMenu(): void {
    if (root.recordingActive)
      return
    root.calendarVisible = false
    if (screenshotMenuVisible || recordingMenuVisible) {
      screenshotMenuVisible = false
      recordingMenuVisible = false
    } else {
      screenshotMenuVisible = true
    }
  }

  function closeScreenshotMenu(): void {
    screenshotMenuVisible = false
    recordingMenuVisible = false
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

      implicitHeight: root.menuSurfaceShown
        ? (root.calendarVisible
          ? calendarMenu.implicitHeight
          : screenshotMenu.implicitHeight)
        : (OsdState.shown ? osd.implicitHeight : 20)
      buttonColor: root.menuSurfaceShown
        ? Theme.color0
        : (hovered ? Theme.color1 : Theme.color0)
      buttonBorderColor: Theme.borderFocus

      onClicked: {
        if (root.screenshotMenuVisible || root.recordingMenuVisible) {
          root.screenshotMenuVisible = false
          root.recordingMenuVisible = false
        } else if (!root.recordingActive) {
          root.calendarVisible = !root.calendarVisible
        }
      }

      Item {
        anchors.centerIn: parent
        implicitWidth: root.menuSurfaceShown
          ? (root.calendarVisible
            ? calendarMenu.implicitWidth
            : screenshotMenu.implicitWidth)
          : (OsdState.shown ? osd.implicitWidth : clockText.implicitWidth)
        implicitHeight: root.menuSurfaceShown
          ? (root.calendarVisible
            ? calendarMenu.implicitHeight
            : screenshotMenu.implicitHeight)
          : (OsdState.shown ? osd.implicitHeight : 20)

        Behavior on implicitWidth {
          NumberAnimation {
            duration: Theme.motionNormal
            easing.type: Easing.OutCubic
          }
        }

        Behavior on implicitHeight {
          NumberAnimation {
            duration: Theme.motionNormal
            easing.type: Easing.OutCubic
          }
        }

        Text {
          id: clockText
          anchors.centerIn: parent
          visible: opacity > 0
          opacity: !OsdState.shown && !root.menuSurfaceShown ? 1 : 0
          font.weight: Theme.weightStrong
          text: Time.time
          color: Theme.foreground

          Behavior on opacity {
            NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic }
          }
        }

        Osd {
          id: osd
          anchors.centerIn: parent
          visible: opacity > 0
          opacity: OsdState.shown && !root.menuSurfaceShown ? 1 : 0
          iconType: OsdState.iconType
          value: OsdState.value

          Behavior on opacity {
            NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic }
          }
        }

        ScreenshotMenu {
          id: screenshotMenu
          anchors.centerIn: parent
          visible: opacity > 0
          opacity: root.screenshotSurfaceShown ? 1 : 0
          scale: root.screenshotSurfaceShown ? 1 : 0.92
          screenshotVisible: root.screenshotMenuVisible
          recordingVisible: root.recordingMenuVisible
          recordingActive: root.recordingActive
          recordingPaused: root.recordingPaused
          elapsedSeconds: root.recordingElapsedSeconds
          muted: root.muted
          audioSink: root.audioSink
          onCaptureRequested: function(mode) { root.capture(mode) }
          onRecordingMenuRequested: root.showRecordingMenu()
          onCloseRequested: root.closeScreenshotMenu()

          Behavior on opacity {
            SequentialAnimation {
              PauseAnimation { duration: root.screenshotSurfaceShown ? 30 : 0 }
              NumberAnimation { duration: Theme.motionNormal; easing.type: Easing.OutCubic }
            }
          }

          Behavior on scale {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Easing.OutCubic }
          }
        }

        CalendarMenu {
          id: calendarMenu

          anchors.centerIn: parent
          visible: opacity > 0
          opacity: root.calendarVisible ? 1 : 0
          scale: root.calendarVisible ? 1 : 0.92
          calendarVisible: root.calendarVisible
          onCloseRequested: root.calendarVisible = false

          Behavior on opacity {
            SequentialAnimation {
              PauseAnimation { duration: root.calendarVisible ? 30 : 0 }
              NumberAnimation { duration: Theme.motionNormal; easing.type: Easing.OutCubic }
            }
          }

          Behavior on scale {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Easing.OutCubic }
          }
        }
      }
    }
  }
}
