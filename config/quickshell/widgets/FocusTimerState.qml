pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool loaded: false
  property string phase: "focus"
  property int focusMinutes: 25
  property int shortMinutes: 5
  property int longMinutes: 15
  property int completedSessions: 0
  property bool running: false
  property real deadline: 0
  property int pausedSeconds: 1500
  property real now: Date.now()
  readonly property string phaseLabel: phase === "focus" ? "Focus"
    : phase === "short" ? "Short break" : "Long break"
  readonly property int durationSeconds: (phase === "focus" ? focusMinutes
    : phase === "short" ? shortMinutes : longMinutes) * 60
  readonly property int secondsRemaining: running
    ? Math.max(0, Math.ceil((deadline - now) / 1000)) : pausedSeconds
  readonly property real progress: Math.max(0, Math.min(1, 1 - secondsRemaining / durationSeconds))

  function save(): void {
    if (!loaded) return
    stateFile.setText(JSON.stringify({ phase: phase, focusMinutes: focusMinutes,
      shortMinutes: shortMinutes, longMinutes: longMinutes,
      completedSessions: completedSessions, running: running,
      deadline: deadline, pausedSeconds: pausedSeconds }, null, 2) + "\n")
  }

  function startPause(): void {
    if (!loaded) return
    now = Date.now()
    if (running) {
      if (deadline <= now) { finish(); return }
      pausedSeconds = secondsRemaining
      running = false
      deadline = 0
    } else {
      deadline = now + pausedSeconds * 1000
      running = true
    }
    save()
  }

  function reset(): void {
    if (!loaded) return
    running = false
    deadline = 0
    pausedSeconds = durationSeconds
    save()
  }

  function quit(): void {
    if (!loaded) return
    reset()
    WidgetState.focusTimerVisible = false
    WidgetState.focusTimerBarVisible = false
    WidgetState.save()
  }

  function selectPhase(value: string): void {
    if (!loaded || ["focus", "short", "long"].indexOf(value) < 0) return
    phase = value
    reset()
  }

  function skip(): void {
    selectPhase(phase === "focus" ? "short" : "focus")
  }

  function setDuration(value: string, minutes: int): void {
    if (!loaded || running || minutes < 1 || minutes > 180) return
    if (value === "focus") focusMinutes = minutes
    else if (value === "short") shortMinutes = minutes
    else if (value === "long") longMinutes = minutes
    else return
    if (phase === value) pausedSeconds = durationSeconds
    save()
  }

  function restoreDurations(): void {
    if (!loaded || running) return
    focusMinutes = 25
    shortMinutes = 5
    longMinutes = 15
    pausedSeconds = durationSeconds
    save()
  }

  function finish(): void {
    if (!running) return
    const finishedPhase = phase
    running = false
    deadline = 0
    if (finishedPhase === "focus") {
      completedSessions++
      phase = completedSessions % 4 === 0 ? "long" : "short"
    } else phase = "focus"
    pausedSeconds = durationSeconds
    save()
    Quickshell.execDetached(["notify-send", "--app-name=Atlas Focus Timer",
      "--urgency=normal", "--", finishedPhase === "focus" ? "Focus session complete" : "Break complete",
      finishedPhase === "focus" ? "Time for a " + phaseLabel.toLowerCase() + ". Start it when you're ready."
        : "Ready for your next focus session?"])
  }

  FileView {
    id: stateFile
    path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config")
      + "/atlas/focus-timer.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (["focus", "short", "long"].indexOf(data.phase) >= 0) root.phase = data.phase
        for (const key of ["focusMinutes", "shortMinutes", "longMinutes"]) {
          if (Number.isInteger(data[key]) && data[key] >= 1 && data[key] <= 180) root[key] = data[key]
        }
        if (Number.isInteger(data.completedSessions) && data.completedSessions >= 0)
          root.completedSessions = data.completedSessions
        root.pausedSeconds = Number.isInteger(data.pausedSeconds) && data.pausedSeconds > 0
          ? Math.min(data.pausedSeconds, root.durationSeconds) : root.durationSeconds
        root.now = Date.now()
        if (data.running === true && typeof data.deadline === "number" && Number.isFinite(data.deadline)) {
          root.deadline = data.deadline
          root.running = true
        }
      } catch (error) {}
      root.loaded = true
      if (root.running && root.deadline <= root.now) root.finish()
    }
    onLoadFailed: root.loaded = true
  }

  Timer {
    interval: 250
    repeat: true
    running: root.loaded && root.running
    onTriggered: {
      root.now = Date.now()
      if (root.deadline <= root.now) root.finish()
    }
  }
}
