pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string style: "pills"
  readonly property bool pillMode: style === "pills"
  readonly property int bottomClearance: position === "bottom" ? 34 : 0
  readonly property int topClearance: position === "top" ? 34 : 0
  readonly property int leftClearance: position === "left" ? 34 : 0
  readonly property int rightClearance: position === "right" ? 34 : 0
  property string position: "top"
  readonly property var timeFormats: [
    "time", "time-seconds", "day-time", "date-time", "day-date-time"
  ]
  property string timeFormat: "time"
  readonly property bool showDisplay: zoneFor("display") !== ""
  readonly property bool showVolume: zoneFor("volume") !== ""
  readonly property bool showInternet: zoneFor("internet") !== ""
  readonly property bool showBluetooth: zoneFor("bluetooth") !== ""
  readonly property bool showBattery: zoneFor("battery") !== ""
  readonly property bool showNotifications: zoneFor("notifications") !== ""
  // Edit mode is session-only; only the resulting layout is persisted.
  property bool editing: false
  readonly property var buttonIds: ["display", "volume", "internet", "bluetooth", "battery", "notifications"]
  readonly property var itemIds: ["workspaces", "clock", "nowPlaying", "focusTimer", "system"].concat(buttonIds)
  property var items: [
    { id: "workspaces", zone: "left" },
    { id: "clock", zone: "center" },
    { id: "nowPlaying", zone: "right" },
    { id: "focusTimer", zone: "right" },
    { id: "system", zone: "right" },
    { id: "display", zone: "right", joined: true },
    { id: "volume", zone: "right", joined: true },
    { id: "internet", zone: "right", joined: true },
    { id: "bluetooth", zone: "right", joined: true },
    { id: "battery", zone: "right", joined: true },
    { id: "notifications", zone: "right", joined: true }
  ]
  property bool initialized: false

  function itemLabel(id): string {
    return ({workspaces: "Workspaces", clock: "Time",
      nowPlaying: "Now Playing", focusTimer: "Focus Timer", system: "System tray", display: "Display", volume: "Volume",
      internet: "Network", bluetooth: "Bluetooth", battery: "Battery", notifications: "Notifications"})[id] || id
  }

  function zoneFor(id): string {
    const entry = items.find(function(item) { return item.id === id })
    return entry ? entry.zone : ""
  }

  function previousItem(id): string {
    const zone = zoneFor(id)
    const group = items.filter(function(item) { return item.zone === zone })
    const index = group.findIndex(function(item) { return item.id === id })
    return index > 0 ? group[index - 1].id : ""
  }

  function isJoined(id): bool {
    const item = items.find(function(item) { return item.id === id })
    return !!item && item.joined === true && previousItem(id) !== ""
  }

  function setJoined(id, joined): void {
    if (previousItem(id) === "") return
    items = items.map(function(item) {
      return item.id === id ? {id: item.id, zone: item.zone, joined: joined} : item
    })
  }

  function setZone(id, zone): void {
    if (itemIds.indexOf(id) === -1
        || ["left", "center", "right", ""].indexOf(zone) === -1) return
    const next = items.filter(function(item) { return item.id !== id })
    if (zone !== "") next.push({id: id, zone: zone})
    items = next
  }

  function insertItem(id, zone, beforeId): void {
    if (itemIds.indexOf(id) === -1 || ["left", "center", "right"].indexOf(zone) === -1)
      return
    const next = items.filter(function(item) { return item.id !== id })
    let index = next.findIndex(function(item) { return item.id === beforeId && item.zone === zone })
    if (index < 0) {
      index = next.length
      for (let i = next.length - 1; i >= 0; --i) {
        if (next[i].zone === zone) { index = i + 1; break }
      }
    }
    next.splice(index, 0, {id: id, zone: zone})
    items = next
  }

  function moveItem(id, offset): void {
    const next = items.slice()
    const index = next.findIndex(function(item) { return item.id === id })
    if (index < 0) return
    const zone = next[index].zone
    let target = index + offset
    while (target >= 0 && target < next.length && next[target].zone !== zone)
      target += offset
    if (target < 0 || target >= next.length) return
    const other = next[target]
    next[target] = next[index]
    next[index] = other
    items = next
  }

  function canMove(id, offset): bool {
    const group = items.filter(function(item) { return item.zone === zoneFor(id) })
    const index = group.findIndex(function(item) { return item.id === id })
    return index >= 0 && index + offset >= 0 && index + offset < group.length
  }

  function validItems(value): bool {
    if (!Array.isArray(value)) return false
    const seen = []
    return value.every(function(item) {
      if (!item || itemIds.indexOf(item.id) === -1
          || ["left", "center", "right"].indexOf(item.zone) === -1
          || seen.indexOf(item.id) !== -1
          || (item.joined !== undefined && typeof item.joined !== "boolean")) return false
      seen.push(item.id)
      return true
    })
  }

  function scheduleSave(): void {
    if (initialized)
      saveTimer.restart()
  }

  function loadSettings(text: string): void {
    let migrated = false
    try {
      const data = JSON.parse(text)
      if (validItems(data.items)) items = data.items
      // Expand the old grouped system widget, preserving hidden buttons and order.
      if (!data.layoutVersion || data.layoutVersion < 2) {
        const legacy = items.slice()
        const systemIndex = legacy.findIndex(function(item) { return item.id === "system" })
        const zone = systemIndex < 0 ? "" : legacy[systemIndex].zone
        const names = ["Display", "Volume", "Internet", "Bluetooth", "Battery", "Notifications"]
        const next = legacy.filter(function(item) { return buttonIds.indexOf(item.id) === -1 })
        if (zone !== "") {
          const index = next.findIndex(function(item) { return item.id === "system" }) + 1
          const buttons = []
          for (let i = 0; i < buttonIds.length; ++i) {
            if (data["show" + names[i]] !== false) buttons.push({id: buttonIds[i], zone: zone})
          }
          next.splice(index, 0, ...buttons)
        }
        items = next
      }
      if (!data.layoutVersion || data.layoutVersion < 3) {
        items = items.map(function(item, index, entries) {
          const group = entries.filter(function(entry) { return entry.zone === item.zone })
          const at = group.findIndex(function(entry) { return entry.id === item.id })
          const previous = at > 0 ? group[at - 1] : null
          const systemItem = function(id) { return id === "system" || buttonIds.indexOf(id) !== -1 }
          return {id: item.id, zone: item.zone,
            joined: !!previous && systemItem(item.id) && systemItem(previous.id)}
        })
      }
      if ((!data.layoutVersion || data.layoutVersion < 4)
          && !items.some(function(item) { return item.id === "focusTimer" })) {
        const next = items.slice()
        const at = next.findIndex(function(item) { return item.zone === "right" })
        next.splice(at < 0 ? next.length : at, 0, {id: "focusTimer", zone: "right"})
        items = next
        migrated = true
      }
      if (data.style === "pills" || data.style === "bar")
        style = data.style
      if (["top", "bottom", "left", "right"].indexOf(data.position) !== -1)
        position = data.position
      if (timeFormats.indexOf(data.timeFormat) !== -1)
        timeFormat = data.timeFormat
    } catch (error) {
      // Keep defaults when the file is absent, empty, or invalid.
    }
    initialized = true
    if (migrated) scheduleSave()
  }

  function saveSettings(): void {
    settingsFile.setText(JSON.stringify({
      layoutVersion: 4,
      items: items,
      style: style,
      position: position,
      timeFormat: timeFormat,
      showDisplay: showDisplay,
      showVolume: showVolume,
      showInternet: showInternet,
      showBluetooth: showBluetooth,
      showBattery: showBattery,
      showNotifications: showNotifications
    }, null, 2) + "\n")
  }

  onPositionChanged: {
    if (["top", "bottom", "left", "right"].indexOf(position) === -1)
      position = "top"
    scheduleSave()
  }
  onStyleChanged: {
    if (style !== "pills" && style !== "bar") style = "pills"
    scheduleSave()
  }
  onTimeFormatChanged: {
    if (timeFormats.indexOf(timeFormat) === -1) timeFormat = "time"
    scheduleSave()
  }
  onItemsChanged: scheduleSave()
  onShowDisplayChanged: scheduleSave()
  onShowVolumeChanged: scheduleSave()
  onShowInternetChanged: scheduleSave()
  onShowBluetoothChanged: scheduleSave()
  onShowBatteryChanged: scheduleSave()
  onShowNotificationsChanged: scheduleSave()

  FileView {
    id: settingsFile

    path: (Quickshell.env("XDG_CONFIG_HOME")
      || Quickshell.env("HOME") + "/.config") + "/atlas/bar-style.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadSettings(text())
    onLoadFailed: {
      root.initialized = true
      root.saveSettings()
    }
  }

  Timer {
    id: saveTimer
    interval: 100
    onTriggered: root.saveSettings()
  }
}
