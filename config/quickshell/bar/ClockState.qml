pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property int recordingPollInterval: 750
  readonly property int idleRecordingPollInterval: 2000
  readonly property int recordingRefreshDelay: 150
  readonly property string captureRegionMode: "region"
  readonly property string captureDisplayMode: "display"
  readonly property string captureWindowMode: "window"
  readonly property string captureColorMode: "color"
  readonly property string recordRegionMode: "record-region"
  readonly property string recordWindowMode: "record-window"
  readonly property string recordDisplayMode: "record-display"

  readonly property bool operationBusy: captureBusy || recordingActionBusy

  property bool recordingActive: false
  property bool recordingPaused: false
  property int recordingElapsedSeconds: 0
  property bool captureBusy: false
  property bool recordingActionBusy: false
  property bool recordingPauseTarget: false
  property string captureModeRunning: ""
  property string recordingCommandRunning: ""
  property string operationMessage: ""

  function isValidCaptureMode(mode: string): bool {
    return mode === captureRegionMode
      || mode === captureDisplayMode
      || mode === captureWindowMode
      || mode === captureColorMode
      || mode === recordRegionMode
      || mode === recordWindowMode
      || mode === recordDisplayMode
  }

  function isRecordingMode(mode: string): bool {
    return mode === recordRegionMode
      || mode === recordWindowMode
      || mode === recordDisplayMode
  }

  function showOperationMessage(message: string): void {
    operationMessage = message
    operationMessageTimer.restart()
  }

  function notifyFailure(title: string, detail: string): void {
    Quickshell.execDetached(["notify-send", title, detail])
  }

  function startCapture(mode: string): void {
    if (!isValidCaptureMode(mode) || operationBusy)
      return
    captureBusy = true
    captureModeRunning = mode
    operationMessageTimer.stop()
    operationMessage = isRecordingMode(mode)
      ? "Starting…"
      : "Capturing…"
    captureProcess.exec(["atlas-screenshot", mode])
  }

  function performRecordingAction(action: string): void {
    if (recordingActionBusy)
      return
    if (action === "output") {
      if (!AudioState.outputAvailable) {
        showOperationMessage("Output unavailable")
        return
      }
      AudioState.toggleOutputMute()
      showOperationMessage(AudioState.muted
        ? "System output muted"
        : "System output unmuted")
      return
    }
    if (action === "microphone") {
      if (!AudioState.inputAvailable) {
        showOperationMessage("Microphone unavailable")
        return
      }
      AudioState.toggleInputMute()
      showOperationMessage(AudioState.microphoneMuted
        ? "Microphone muted"
        : "Microphone unmuted")
      return
    }
    if (action !== "pause" && action !== "stop")
      return

    recordingActionBusy = true
    recordingCommandRunning = action
    recordingPauseTarget = action === "pause" && !recordingPaused
    operationMessageTimer.stop()
    operationMessage = action === "pause"
      ? (recordingPaused ? "Resuming…" : "Pausing…")
      : "Stopping…"
    recordingControlProcess.exec([
      "atlas-screenshot",
      action === "pause" ? "record-pause" : "record-stop"
    ])
  }

  function refreshRecording(): void {
    if (!recordingStatusQuery.running)
      recordingStatusQuery.exec(["atlas-screenshot", "status"])
  }

  function refreshRecordingSoon(): void {
    recordingRefreshTimer.restart()
  }

  function toggleRecordingPause(): void {
    performRecordingAction("pause")
  }

  function stopRecording(): void {
    performRecordingAction("stop")
  }

  Process {
    id: recordingStatusQuery

    stdout: StdioCollector {
      onStreamFinished: {
        const values = text.trim().split(/\s+/)
        const status = values[0] || "stopped"
        const active = status === "recording" || status === "paused"
        const elapsed = values.length > 1 ? Number(values[1]) : NaN
        if (active && Number.isFinite(elapsed))
          root.recordingElapsedSeconds = Math.max(0, Math.floor(elapsed))
        else if (!active)
          root.recordingElapsedSeconds = 0
        root.recordingActive = active
        root.recordingPaused = status === "paused"
      }
    }
  }

  Process {
    id: captureProcess

    onExited: function(exitCode) {
      const mode = root.captureModeRunning
      const recordingMode = root.isRecordingMode(mode)
      root.captureBusy = false
      root.captureModeRunning = ""
      if (exitCode === 0) {
        if (recordingMode) {
          root.recordingElapsedSeconds = 0
          root.recordingPaused = false
          root.recordingActive = true
        }
        root.showOperationMessage(recordingMode
          ? "Recording started"
          : "Capture saved")
      } else if (exitCode === 1) {
        root.showOperationMessage("Capture canceled")
      } else {
        root.showOperationMessage("Capture failed")
        root.notifyFailure("Capture failed",
          "atlas-screenshot exited with code " + exitCode)
      }
      if (recordingMode)
        root.refreshRecordingSoon()
    }
  }

  Process {
    id: recordingControlProcess

    onExited: function(exitCode) {
      const action = root.recordingCommandRunning
      root.recordingActionBusy = false
      root.recordingCommandRunning = ""
      if (exitCode !== 0) {
        root.showOperationMessage(action === "stop"
          ? "Could not stop recording"
          : "Could not change recording state")
        root.notifyFailure("Recording control failed",
          "atlas-screenshot exited with code " + exitCode)
      } else {
        root.showOperationMessage(action === "stop"
          ? "Recording saved"
          : (root.recordingPauseTarget
            ? "Recording paused"
            : "Recording resumed"))
      }
      root.refreshRecordingSoon()
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
    interval: root.recordingActive
      ? root.recordingPollInterval
      : root.idleRecordingPollInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshRecording()
  }

  Timer {
    id: recordingRefreshTimer

    interval: root.recordingRefreshDelay
    onTriggered: root.refreshRecording()
  }

  Timer {
    id: operationMessageTimer

    interval: 2400
    onTriggered: root.operationMessage = ""
  }
}
