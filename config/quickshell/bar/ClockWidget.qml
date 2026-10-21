import Quickshell
import Quickshell.Wayland
import QtQuick
import "../"
import "../shared/"

Pill {
  id: root

  required property var shellScreen
  // The bar's layer-shell inset is outside the clock's local coordinates.
  property real barHorizontalInset: 0
  readonly property point localPopupCenter: {
    // x/y keep this binding live when bar items are reordered.
    const geometryRevision = x + y
    return mapToItem(null, width / 2, height / 2)
  }
  readonly property bool verticalBar: BarStyle.position === "left"
    || BarStyle.position === "right"
  readonly property real popupCrossCenter: verticalBar
    ? localPopupCenter.y : localPopupCenter.x + barHorizontalInset

  borderEnabled: BarStyle.pillMode
  backgroundOpacity: 1

  readonly property string noSurface: "none"
  readonly property string calendarSurface: "calendar"
  readonly property string screenshotSurface: "screenshot"
  readonly property string recordingSurface: "recording"

  property string activeSurface: noSurface
  property string pendingCaptureMode: ""

  readonly property bool calendarVisible: activeSurface === calendarSurface
  readonly property bool screenshotMenuVisible:
    activeSurface === screenshotSurface
  readonly property bool recordingMenuVisible:
    activeSurface === recordingSurface && !ClockState.recordingActive
  // Derive visibility directly from the selected surface so switching modes
  // never briefly hides the window while the individual mode bindings update.
  readonly property bool captureMenuVisible: activeSurface === screenshotSurface
    || (activeSurface === recordingSurface && !ClockState.recordingActive)
  readonly property bool recordingActive: ClockState.recordingActive
  readonly property bool surfaceShown: activeSurface !== noSurface
  readonly property bool capturePending: pendingCaptureMode !== ""
  readonly property bool calendarAtBottom: BarStyle.position === "bottom"
  readonly property int calendarEdgeMargin: 34

  function isValidSurface(surface: string): bool {
    return surface === noSurface
      || surface === calendarSurface
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

    activeSurface = surface
  }

  function closeActiveSurface(): void {
    activateSurface(noSurface)
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

      interval: Theme.motionNormal + 20
      onTriggered: root.finishPendingCapture()
    }

    Button {
      id: clockButton
      implicitHeight: Math.max(Theme.barControlHeight,
        contentItem ? contentItem.implicitHeight : 0)

      accessibleName: "Open calendar, " + Time.time
      verticalPadding: 0
      buttonColor: !BarStyle.pillMode
        ? (hovered ? Theme.surfaceHover : "transparent")
        : (root.surfaceShown
          ? Theme.surface
          : (hovered ? Theme.surfaceHover : Theme.surface))
      buttonBorderColor: Theme.surface
      buttonBorderWidth: 0

      onClicked: {
        if (root.surfaceShown)
          root.closeActiveSurface()
        else
          root.activateSurface(root.calendarSurface)
      }

      Item {
        id: clockContent

        anchors.centerIn: parent
        implicitWidth: root.verticalBar ? clockRow.implicitHeight
          : clockRow.implicitWidth
        implicitHeight: root.verticalBar ? clockRow.implicitWidth
          : clockRow.implicitHeight

        Row {
          id: clockRow

          anchors.centerIn: parent
          spacing: Theme.spaceXs
          rotation: root.verticalBar ? -90 : 0

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            visible: root.recordingActive
            color: Theme.error
          }

          Text {
            font.weight: Theme.weightStrong
            font.pixelSize: root.verticalBar ? Theme.fontCaption : Theme.fontBody
            lineHeight: root.verticalBar ? 0.78 : 1
            lineHeightMode: Text.ProportionalHeight
            horizontalAlignment: Text.AlignHCenter
            text: root.verticalBar ? Time.sideTime : Time.time
            color: root.surfaceShown ? Theme.accent : Theme.foreground
          }
        }
      }
    }

    PanelWindow {
      id: calendarPopup

      screen: root.shellScreen
      visible: root.calendarVisible
      color: "transparent"
      focusable: true
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.namespace: "atlas-calendar"
      anchors { top: true; bottom: true; left: true; right: true }

      MouseArea {
        anchors.fill: parent
        onClicked: root.closeActiveSurface()
      }

      Rectangle {
        // Keep the overlay full-screen for outside-click handling, but place
        // the visible card explicitly. Conditional top/bottom anchors can
        // leave the card stretched when the bar position changes at runtime.
        x: BarStyle.position === "left" ? root.calendarEdgeMargin
          : BarStyle.position === "right"
            ? parent.width - width - root.calendarEdgeMargin
            : Math.max(Theme.spaceSm, Math.min(
              parent.width - width - Theme.spaceSm,
              root.popupCrossCenter - width / 2))
        y: BarStyle.position === "top" ? root.calendarEdgeMargin
          : BarStyle.position === "bottom"
            ? parent.height - height - root.calendarEdgeMargin
            : Math.round((parent.height - height) / 2)
        width: calendarMenu.implicitWidth + Theme.spaceSm * 2
        height: calendarMenu.implicitHeight + Theme.spaceSm * 2
        radius: Theme.radiusLg
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b,
          calendarMenu.backgroundOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.borderStrong

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) { mouse.accepted = true }
        }

        CalendarMenu {
          id: calendarMenu
          anchors.fill: parent
          anchors.margins: Theme.spaceSm
          calendarVisible: root.calendarVisible
          onCloseRequested: root.closeActiveSurface()
        }
      }
    }

    PanelWindow {
      id: capturePopup

      screen: root.shellScreen
      visible: root.captureMenuVisible
      color: "transparent"
      focusable: true
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.namespace: "atlas-capture-menu"
      anchors { top: true; bottom: true; left: true; right: true }

      MouseArea {
        anchors.fill: parent
        onClicked: root.closeActiveSurface()
      }

      Rectangle {
        x: Placement.itemX(Placement.screenshotMenu,
          parent.width, width, Placement.edgeMargin)
        y: Placement.itemY(Placement.screenshotMenu,
          parent.height, height,
          Placement.edgeMargin + BarStyle.topClearance,
          Placement.edgeMargin + BarStyle.bottomClearance)
        width: screenshotMenu.implicitWidth + Theme.spaceSm * 2
        height: screenshotMenu.implicitHeight + Theme.spaceSm * 2
        radius: Theme.radiusMd
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b,
          Theme.popupOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.text

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) { mouse.accepted = true }
        }

        ScreenshotMenu {
          id: screenshotMenu
          openAbove: Placement.vertical(Placement.screenshotMenu) === "bottom"
          anchors.fill: parent
          anchors.margins: Theme.spaceSm
          screenshotVisible: root.screenshotMenuVisible
          recordingVisible: root.recordingMenuVisible
          operationBusy: ClockState.operationBusy
          onCaptureRequested: function(mode) { root.capture(mode) }
          onRecordingMenuRequested: root.showRecordingMenu()
          onScreenshotMenuRequested: root.activateSurface(root.screenshotSurface)
          onCloseRequested: root.closeActiveSurface()
        }
      }
    }
  }
}
