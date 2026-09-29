pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../shared/"

Singleton {
  id: root

  property real minimumBrightness: 0.01
  property real brightness: -1
  property string deviceName: ""
  property int maximumRawBrightness: 0
  property bool available: false
  property bool initialized: false
  property string errorMessage: ""
  property real pendingBrightness: -1
  property real dispatchedBrightness: -1

  readonly property bool loading: !initialized && errorMessage === ""
  readonly property bool writeBusy: writeDebounce.running
    || brightnessSetter.running || pendingBrightness >= 0
  readonly property string brightnessPath: deviceName === ""
    ? ""
    : "/sys/class/backlight/" + deviceName + "/brightness"

  function clamp(value) {
    const numeric = Number(value)
    if (!Number.isFinite(numeric))
      return minimumBrightness
    return Math.max(minimumBrightness, Math.min(1, numeric))
  }

  function refresh() {
    if (deviceName === "") {
      discover()
      return
    }
    brightnessFile.reload()
  }

  function discover() {
    if (!brightnessDiscovery.running)
      brightnessDiscovery.exec(["brightnessctl", "-c", "backlight", "-m"])
  }

  function updateFromRaw(rawValue) {
    if (maximumRawBrightness <= 0 || writeBusy)
      return
    const raw = Number(String(rawValue).trim())
    if (!Number.isFinite(raw))
      return
    const normalized = Math.max(0, Math.min(1,
      raw / maximumRawBrightness))
    const changed = brightness >= 0
      && Math.abs(normalized - brightness) >= 0.005
    brightness = normalized
    available = true
    errorMessage = ""
    if (initialized && changed)
      OsdState.show("brightness", normalized)
    initialized = true
  }

  function setBrightness(value, showOsd = true) {
    if (!available)
      return
    const normalized = clamp(value)
    brightness = normalized
    pendingBrightness = normalized
    errorMessage = ""
    if (showOsd)
      OsdState.show("brightness", normalized)
    writeDebounce.restart()
  }

  function adjustBrightness(delta) {
    setBrightness((brightness >= 0 ? brightness : minimumBrightness) + delta)
  }

  function dispatchPending() {
    if (brightnessSetter.running || pendingBrightness < 0
        || deviceName === "" || maximumRawBrightness <= 0)
      return
    dispatchedBrightness = pendingBrightness
    pendingBrightness = -1
    const raw = Math.round(dispatchedBrightness * maximumRawBrightness)
    brightnessSetter.exec([
      "brightnessctl", "-q", "-d", deviceName, "set", String(raw)
    ])
  }

  FileView {
    id: brightnessFile

    path: root.brightnessPath
    preload: root.deviceName !== ""
    watchChanges: true
    printErrors: false
    onLoaded: root.updateFromRaw(text())
    onTextChanged: root.updateFromRaw(text())
    onFileChanged: reload()
    onLoadFailed: {
      root.available = false
      root.initialized = true
      root.errorMessage = "Unable to read display brightness"
    }
  }

  Process {
    id: brightnessDiscovery

    stdout: StdioCollector {
      onStreamFinished: {
        const line = text.trim().split(/\r?\n/)[0] || ""
        const fields = line.split(",")
        if (fields.length < 5) {
          root.available = false
          root.initialized = true
          root.errorMessage = "No backlight device is available"
          return
        }
        const maximum = Number(fields[4])
        if (!Number.isFinite(maximum) || maximum <= 0) {
          root.available = false
          root.initialized = true
          root.errorMessage = "Invalid backlight device"
          return
        }
        root.deviceName = fields[0]
        root.maximumRawBrightness = maximum
        root.available = true
        root.errorMessage = ""
        root.updateFromRaw(fields[2])
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0 && root.deviceName === "") {
        root.available = false
        root.initialized = true
        root.errorMessage = "brightnessctl could not find a backlight"
      }
    }
  }

  Process {
    id: brightnessSetter

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.errorMessage = "Could not change display brightness"
        root.pendingBrightness = -1
      }
      if (root.pendingBrightness >= 0)
        root.dispatchPending()
      else
        brightnessFile.reload()
    }
  }

  Timer {
    id: writeDebounce

    interval: 45
    onTriggered: root.dispatchPending()
  }

  Timer {
    interval: 1000
    running: root.available
    repeat: true
    onTriggered: {
      if (!root.writeBusy)
        brightnessFile.reload()
    }
  }

  Component.onCompleted: discover()
}
