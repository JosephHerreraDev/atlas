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
  property int monthOffset: 0
  property real lastBrightness: -1
  readonly property var audioSink: Pipewire.defaultAudioSink
  readonly property real volume: audioSink?.audio.volume ?? 0
  readonly property bool muted: audioSink?.audio.muted ?? false
  readonly property date now: clock.date
  readonly property date displayedMonth: new Date(
    now.getFullYear(), now.getMonth() + monthOffset, 1)
  readonly property int firstWeekday: (displayedMonth.getDay() + 6) % 7
  readonly property int daysInMonth: new Date(
    displayedMonth.getFullYear(), displayedMonth.getMonth() + 1, 0).getDate()

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

  function isToday(day) {
    return day === now.getDate()
      && displayedMonth.getMonth() === now.getMonth()
      && displayedMonth.getFullYear() === now.getFullYear()
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

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

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
      buttonBorderColor: root.screenshotMenuVisible || root.recordingMenuVisible
        ? Theme.color0
        : (hovered ? Theme.color8 : Theme.color0)
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
            duration: 160
            easing.type: Easing.OutCubic
          }
        }

        Text {
          id: clockText
          anchors.centerIn: parent
          visible: !OsdState.shown && !root.screenshotMenuVisible
            && !root.recordingMenuVisible && !root.recordingActive
          font.weight: Font.DemiBold
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

    Popup {
      id: calendarPopup

    anchorItem: clockButton
    implicitWidth: 320
    padding: 16
    shown: root.calendarVisible

    anchor {
      rect.x: clockButton.width / 2
      edges: Edges.Top
      gravity: Edges.Bottom
    }

    onVisibleChanged: {
      if (!visible && root.calendarVisible)
        root.calendarVisible = false
    }

    Column {
      width: parent.width
      spacing: 12

      Column {
        width: parent.width
        spacing: 2

        Text {
          width: parent.width
          text: Qt.formatDate(root.now, "dddd, MMMM d")
          color: Theme.foreground
          font.pixelSize: 16
          font.weight: Font.DemiBold
        }

        Text {
          width: parent.width
          text: Qt.formatDate(root.now, "yyyy")
          color: Theme.color5
          font.pixelSize: 12
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Theme.color2
      }

      RowLayout {
        width: parent.width
        height: 28
        spacing: 8

        Text {
          Layout.fillWidth: true
          text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
          color: Theme.foreground
          font.pixelSize: 14
          font.weight: Font.DemiBold
        }

        Button {
          Layout.preferredWidth: 28
          Layout.preferredHeight: 28
          horizontalPadding: 0
          onClicked: root.monthOffset--

          Text {
            anchors.centerIn: parent
            text: "‹"
            color: Theme.foreground
            font.pixelSize: 16
          }
        }

        Button {
          Layout.preferredWidth: 28
          Layout.preferredHeight: 28
          horizontalPadding: 0
          onClicked: root.monthOffset++

          Text {
            anchors.centerIn: parent
            text: "›"
            color: Theme.foreground
            font.pixelSize: 16
          }
        }
      }

      Row {
        width: parent.width

        Repeater {
          model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

          Text {
            required property string modelData

            width: parent.width / 7
            height: 20
            text: modelData
            color: Theme.color5
            font.pixelSize: 10
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }
      }

      Grid {
        width: parent.width
        columns: 7
        spacing: 4

        Repeater {
          model: 42

          Rectangle {
            required property int index
            readonly property int day: index - root.firstWeekday + 1
            readonly property bool inMonth: day > 0 && day <= root.daysInMonth

            width: (parent.width - parent.spacing * 6) / 7
            height: 30
            radius: 4
            color: root.isToday(day) && inMonth ? Theme.color8 : "transparent"
            border.width: root.isToday(day) && inMonth ? 0 : 1
            border.color: inMonth ? Theme.color2 : "transparent"

            Text {
              anchors.centerIn: parent
              text: parent.inMonth ? parent.day : ""
              color: root.isToday(parent.day)
                ? Theme.color0
                : Theme.foreground
              font.pixelSize: 12
              font.weight: root.isToday(parent.day)
                ? Font.DemiBold
                : Font.Normal
            }
          }
        }
      }

      Button {
        width: parent.width
        implicitHeight: 28
        visible: root.monthOffset !== 0
        onClicked: root.monthOffset = 0

        Text {
          anchors.centerIn: parent
          text: "Today"
          color: Theme.color8
          font.pixelSize: 11
        }
      }
    }
  }
  }
}
