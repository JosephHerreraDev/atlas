pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property bool stickyNotesVisible: true
  property bool tasksVisible: false
  property bool focusTimerVisible: true
  property bool focusTimerBarVisible: true
  property bool playerVisible: true
  property bool nowPlayingVisible: true
  property string playerArtworkStyle: "square"
  property string playerColorSource: "album"
  property string tasksColor: "theme-transparent"
  property string focusTimerColor: "theme-transparent"
  property string stickyNotesColor: "theme"
  // Bar actions raise widgets for the current opening without changing saved pinning.
  property bool focusTimerRaised: false
  property bool playerRaised: false
  property bool tasksRaised: false

  function showWidget(name): void {
    if (["focusTimer", "player", "tasks"].indexOf(name) === -1) return
    root[name + "Raised"] = true
    root[name + "Visible"] = true
  }

  function toggleWidget(name): void {
    if (["focusTimer", "player", "tasks"].indexOf(name) === -1) return
    if (root[name + "Visible"] && root[name + "Raised"])
      root[name + "Visible"] = false
    else
      showWidget(name)
  }

  property bool loaded: false

  function save(): void {
    if (!loaded)
      return
    stateFile.setText(JSON.stringify({
      stickyNotesVisible: stickyNotesVisible,
      tasksVisible: tasksVisible,
      focusTimerVisible: focusTimerVisible,
      focusTimerBarVisible: focusTimerBarVisible,
      playerVisible: playerVisible,
      nowPlayingVisible: nowPlayingVisible,
      playerColorSource: playerColorSource,
      playerArtworkStyle: playerArtworkStyle,
      tasksColor: tasksColor,
      focusTimerColor: focusTimerColor,
      stickyNotesColor: stickyNotesColor
    }, null, 2) + "\n")
  }

  onStickyNotesVisibleChanged: saveTimer.restart()
  onFocusTimerVisibleChanged: {
    if (focusTimerVisible) focusTimerBarVisible = true
    else focusTimerRaised = false
    saveTimer.restart()
  }
  onFocusTimerBarVisibleChanged: saveTimer.restart()
  onTasksVisibleChanged: {
    if (!tasksVisible) tasksRaised = false
    saveTimer.restart()
  }
  onPlayerVisibleChanged: {
    if (!playerVisible) playerRaised = false
    saveTimer.restart()
  }
  onNowPlayingVisibleChanged: saveTimer.restart()
  onPlayerArtworkStyleChanged: saveTimer.restart()
  onPlayerColorSourceChanged: saveTimer.restart()
  onTasksColorChanged: saveTimer.restart()
  onFocusTimerColorChanged: saveTimer.restart()
  onStickyNotesColorChanged: saveTimer.restart()

  Timer {
    id: saveTimer
    interval: 150
    onTriggered: root.save()
  }

  FileView {
    id: stateFile
    path: (Quickshell.env("XDG_CONFIG_HOME")
      || Quickshell.env("HOME") + "/.config")
      + "/atlas/widget-state.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (typeof data.stickyNotesVisible === "boolean")
          root.stickyNotesVisible = data.stickyNotesVisible
        if (typeof data.focusTimerVisible === "boolean")
          root.focusTimerVisible = data.focusTimerVisible
        if (typeof data.focusTimerBarVisible === "boolean")
          root.focusTimerBarVisible = data.focusTimerBarVisible
        if (typeof data.tasksVisible === "boolean")
          root.tasksVisible = data.tasksVisible
        else if (typeof data.remindersVisible === "boolean")
          root.tasksVisible = data.remindersVisible
        if (typeof data.playerVisible === "boolean")
          root.playerVisible = data.playerVisible
        if (typeof data.nowPlayingVisible === "boolean")
          root.nowPlayingVisible = data.nowPlayingVisible
        if (["jewel", "reel"].indexOf(data.playerArtworkStyle) !== -1) root.playerArtworkStyle = "square"
        if (["none", "square", "poster", "cd", "vinyl", "cassette"].indexOf(data.playerArtworkStyle) !== -1)
          root.playerArtworkStyle = data.playerArtworkStyle
        if (data.playerColorSource === "album" || data.playerColorSource === "theme")
          root.playerColorSource = data.playerColorSource
        const widgetColors = ["theme-transparent", "theme-solid", "yellow", "white", "red", "blue", "green", "purple"]
        if (widgetColors.indexOf(data.tasksColor) !== -1) root.tasksColor = data.tasksColor
        if (widgetColors.indexOf(data.focusTimerColor) !== -1) root.focusTimerColor = data.focusTimerColor
        if (["theme", "yellow", "white", "red", "blue", "green", "purple"]
            .indexOf(data.stickyNotesColor) !== -1)
          root.stickyNotesColor = data.stickyNotesColor
      } catch (error) {}
      root.loaded = true
    }
    onLoadFailed: {
      root.loaded = true
      root.save()
    }
  }
}
