import QtQuick
import "../"
import "../shared/"
import "../widgets/" as DesktopWidgets

Pill {
  id: root

  readonly property string countdown: String(Math.floor(DesktopWidgets.FocusTimerState.secondsRemaining / 60)).padStart(2, "0")
    + ":" + String(DesktopWidgets.FocusTimerState.secondsRemaining % 60).padStart(2, "0")
  readonly property string session: DesktopWidgets.FocusTimerState.phase === "focus" ? "Focus" : "Break"
  readonly property bool paused: !DesktopWidgets.FocusTimerState.running
    && DesktopWidgets.FocusTimerState.pausedSeconds < DesktopWidgets.FocusTimerState.durationSeconds
  function toggleWidget(): void {
    DesktopWidgets.WidgetState.toggleWidget("focusTimer")
  }

  borderEnabled: BarStyle.pillMode
  activeFocusOnTab: true
  Accessible.role: Accessible.Button
  Accessible.name: DesktopWidgets.FocusTimerState.phaseLabel + ", " + countdown
    + (paused ? ", paused" : "") + ". Toggle focus timer"
  Accessible.onPressAction: root.toggleWidget()
  Keys.onReturnPressed: root.toggleWidget()
  Keys.onEnterPressed: root.toggleWidget()
  Keys.onSpacePressed: DesktopWidgets.FocusTimerState.startPause()

  Item {
    implicitWidth: label.implicitWidth + 20
    implicitHeight: Theme.barControlHeight

    Text {
      id: label
      anchors.centerIn: parent
      text: (root.paused ? "Ⅱ " : "◷ ") + root.session + " " + root.countdown
      color: DesktopWidgets.FocusTimerState.running ? Theme.accent : Theme.foreground
      font.pixelSize: Theme.fontCaption
      font.weight: Theme.weightStrong
    }
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      height: 2
      radius: 1
      color: Theme.surfaceHover
      Rectangle {
        width: parent.width * DesktopWidgets.FocusTimerState.progress
        height: parent.height
        radius: 1
        color: Theme.accent
      }
    }
    MouseArea {
      id: timerMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.MiddleButton) DesktopWidgets.FocusTimerState.startPause()
        else root.toggleWidget()
      }
    }
    Tooltip {
      target: root
      shown: timerMouse.containsMouse
      edge: BarStyle.position
      text: DesktopWidgets.FocusTimerState.phaseLabel + " · " + root.countdown
        + (DesktopWidgets.FocusTimerState.running ? " · Running" : root.paused ? " · Paused" : " · Ready")
        + "\nClick to open/close · Middle-click to start/pause"
    }
  }
}
