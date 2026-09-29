import Quickshell
import QtQuick
import "../"
import "../shared/"

Pill {
  id: root

  borderEnabled: false
  backgroundOpacity: calendarVisible
    ? calendarMenu.backgroundOpacity
    : 1

  readonly property string noSurface: "none"
  readonly property string calendarSurface: "calendar"
  readonly property string clipboardSurface: "clipboard"
  readonly property string screenshotSurface: "screenshot"
  readonly property string recordingSurface: "recording"
  readonly property int collapsedContentHeight: 20
  readonly property int surfaceAnimationDuration: Theme.motionNormal

  property string activeSurface: noSurface
  property string pendingCaptureMode: ""

  readonly property bool calendarVisible: activeSurface === calendarSurface
  readonly property bool clipboardVisible: activeSurface === clipboardSurface
  readonly property bool screenshotMenuVisible:
    activeSurface === screenshotSurface
  readonly property bool recordingMenuVisible:
    activeSurface === recordingSurface && !ClockState.recordingActive
  readonly property bool screenshotSurfaceVisible: screenshotMenuVisible
    || recordingMenuVisible
  readonly property bool recordingActive: ClockState.recordingActive
  readonly property bool surfaceShown: activeSurface !== noSurface
  readonly property bool menuClosable: surfaceShown
  readonly property bool capturePending: pendingCaptureMode !== ""
  readonly property int collapsedImplicitHeight:
    collapsedContentHeight + margin * 2
  readonly property int maximumImplicitHeight: Math.max(
    collapsedImplicitHeight,
    calendarMenu.implicitHeight + margin * 2,
    clipboardMenu.implicitHeight + margin * 2,
    screenshotMenu.implicitHeight + margin * 2)

  function isValidSurface(surface: string): bool {
    return surface === noSurface
      || surface === calendarSurface
      || surface === clipboardSurface
      || surface === screenshotSurface
      || surface === recordingSurface
  }

  function activateSurface(surface: string): void {
    if (!isValidSurface(surface))
      return
    if ((capturePending || ClockState.captureBusy) && surface !== noSurface)
      return
    if (activeSurface === surface)
      return

    if (clipboardVisible)
      clipboardMenu.close()

    activeSurface = surface
    OsdState.dismiss()

    if (clipboardVisible)
      clipboardMenu.open()
  }

  function closeActiveSurface(): void {
    activateSurface(noSurface)
  }

  function openClipboardMenu(): void {
    activateSurface(clipboardSurface)
  }

  function closeClipboardMenu(): void {
    if (clipboardVisible)
      closeActiveSurface()
    else
      clipboardMenu.close()
  }

  function toggleClipboardMenu(): void {
    if (clipboardVisible)
      closeClipboardMenu()
    else
      openClipboardMenu()
  }

  function toggleScreenshotMenu(): void {
    if (screenshotMenuVisible || recordingMenuVisible)
      closeActiveSurface()
    else
      activateSurface(screenshotSurface)
  }

  function capture(mode: string): void {
    if (!ClockState.isValidCaptureMode(mode)
        || capturePending || ClockState.operationBusy)
      return
    pendingCaptureMode = mode
    closeActiveSurface()
    captureDelay.restart()
  }

  function finishPendingCapture(): void {
    if (!capturePending)
      return
    const mode = pendingCaptureMode
    pendingCaptureMode = ""
    ClockState.startCapture(mode)
  }

  function showRecordingMenu(): void {
    activateSurface(recordingSurface)
  }

  Item {
    width: implicitWidth
    height: implicitHeight
    implicitWidth: clockButton.implicitWidth
    implicitHeight: clockButton.implicitHeight

    Timer {
      id: captureDelay

      interval: root.surfaceAnimationDuration + 20
      onTriggered: root.finishPendingCapture()
    }

    Button {
      id: clockButton

      verticalPadding: 0
      buttonColor: root.surfaceShown
        ? Theme.color0
        : (hovered ? Theme.color1 : Theme.color0)
      buttonBorderColor: Theme.borderFocus

      onClicked: {
        if (root.surfaceShown)
          root.closeActiveSurface()
        else
          root.activateSurface(root.calendarSurface)
      }

      Item {
        id: surfaceHost

        anchors.centerIn: parent
        width: implicitWidth
        height: implicitHeight
        implicitWidth: {
          if (root.calendarVisible)
            return calendarLayer.implicitWidth
          if (root.clipboardVisible)
            return clipboardLayer.implicitWidth
          if (root.screenshotMenuVisible || root.recordingMenuVisible)
            return screenshotLayer.implicitWidth
          return OsdState.shown
            ? osdLayer.implicitWidth
            : clockLayer.implicitWidth
        }
        implicitHeight: {
          if (root.calendarVisible)
            return calendarLayer.implicitHeight
          if (root.clipboardVisible)
            return clipboardLayer.implicitHeight
          if (root.screenshotMenuVisible || root.recordingMenuVisible)
            return screenshotLayer.implicitHeight
          return root.collapsedContentHeight
        }

        Behavior on implicitWidth {
          NumberAnimation {
            duration: root.screenshotSurfaceVisible
              ? 0
              : root.surfaceAnimationDuration
            easing.type: Easing.OutCubic
          }
        }

        Behavior on implicitHeight {
          NumberAnimation {
            duration: root.screenshotSurfaceVisible
              ? 0
              : root.surfaceAnimationDuration
            easing.type: Easing.OutCubic
          }
        }

        AnimatedSurface {
          id: clockLayer

          anchors.centerIn: parent
          shown: !root.surfaceShown && !OsdState.shown
          animationDuration: Theme.motionFast
          hiddenScale: 1
          hiddenOffset: 0

          Row {
            spacing: Theme.spaceXs

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: 6
              height: 6
              radius: 3
              visible: root.recordingActive
              color: Theme.color11
            }

            Text {
              font.weight: Theme.weightStrong
              text: Time.time
              color: Theme.foreground
            }
          }
        }

        AnimatedSurface {
          id: osdLayer

          anchors.centerIn: parent
          shown: !root.surfaceShown && OsdState.shown
          animationDuration: Theme.motionFast
          hiddenScale: 1
          hiddenOffset: 0

          Osd {
            iconType: OsdState.iconType
            value: OsdState.value
          }
        }

        AnimatedSurface {
          id: screenshotLayer

          anchors.centerIn: parent
          shown: root.screenshotSurfaceVisible
          animationDuration: 0

          ScreenshotMenu {
            id: screenshotMenu

            screenshotVisible: root.screenshotMenuVisible
            recordingVisible: root.recordingMenuVisible
            operationBusy: ClockState.operationBusy
            onCaptureRequested: function(mode) { root.capture(mode) }
            onRecordingMenuRequested: root.showRecordingMenu()
            onCloseRequested: root.closeActiveSurface()
          }
        }

        AnimatedSurface {
          id: clipboardLayer

          anchors.centerIn: parent
          shown: root.clipboardVisible
          animationDuration: root.surfaceAnimationDuration

          ClipboardHistoryMenu {
            id: clipboardMenu

            clipboardVisible: root.clipboardVisible
            onCloseRequested: root.closeClipboardMenu()
          }
        }

        AnimatedSurface {
          id: calendarLayer

          anchors.centerIn: parent
          shown: root.calendarVisible
          animationDuration: root.surfaceAnimationDuration

          CalendarMenu {
            id: calendarMenu

            calendarVisible: root.calendarVisible
            onCloseRequested: root.closeActiveSurface()
          }
        }
      }
    }
  }
}
