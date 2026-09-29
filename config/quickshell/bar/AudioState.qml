pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../shared/"

Singleton {
  id: root

  property real maximumVolume: 1
  readonly property real audibleFloor: 0.005
  readonly property var audioSink: Pipewire.defaultAudioSink
  readonly property var audioSource: Pipewire.defaultAudioSource
  readonly property bool serviceReady: Pipewire.ready
  readonly property bool outputAvailable:
    serviceReady && (audioSink?.audio ?? null) !== null
  readonly property bool inputAvailable:
    serviceReady && (audioSource?.audio ?? null) !== null
  readonly property real volume: outputAvailable
    ? clamp(audioSink.audio.volume, 0, maximumVolume)
    : 0
  readonly property real inputVolume: inputAvailable
    ? clamp(audioSource.audio.volume, 0, 1)
    : 0
  readonly property bool muted: !outputAvailable
    || audioSink.audio.muted
  readonly property bool microphoneMuted: !inputAvailable
    || audioSource.audio.muted
  readonly property string outputError: outputAvailable
    ? ""
    : "No audio output is available"
  readonly property string inputError: inputAvailable
    ? ""
    : "No microphone is available"
  readonly property string outputDescription: !outputAvailable
    ? outputError
    : (muted
      ? "Audio output muted"
      : "Volume " + Math.round(volume * 100) + "%")
  readonly property string inputDescription: !inputAvailable
    ? inputError
    : (microphoneMuted
      ? "Microphone muted"
      : "Microphone volume " + Math.round(inputVolume * 100) + "%")
  readonly property var audioDevices: trackableAudioDeviceList()
  readonly property var audioOutputs: audioDeviceList("output")
  readonly property var audioInputs: audioDeviceList("input")

  property real lastAudibleVolume: 0.5
  property real lastAudibleInputVolume: 0.5
  property double outputMutationTime: 0
  property bool outputInitialized: false

  onAudioSinkChanged: {
    outputInitialized = false
    outputInitializeTimer.restart()
  }

  function clamp(value, minimum, maximum) {
    const numeric = Number(value)
    if (!Number.isFinite(numeric))
      return minimum
    return Math.max(minimum, Math.min(maximum, numeric))
  }

  function setOutputVolume(value, showOsd = true) {
    if (!outputAvailable)
      return
    const normalized = clamp(value, 0, maximumVolume)
    outputMutationTime = Date.now()
    audioSink.audio.volume = normalized
    if (normalized > audibleFloor) {
      lastAudibleVolume = normalized
      audioSink.audio.muted = false
    }
    if (showOsd)
      OsdState.show("volume", audioSink.audio.muted ? 0 : normalized)
  }

  function adjustOutputVolume(delta) {
    setOutputVolume(volume + delta)
  }

  function toggleOutputMute() {
    if (!outputAvailable)
      return
    outputMutationTime = Date.now()
    if (muted || volume <= audibleFloor) {
      if (volume <= audibleFloor)
        audioSink.audio.volume = clamp(lastAudibleVolume, 0.05, maximumVolume)
      audioSink.audio.muted = false
    } else {
      lastAudibleVolume = volume
      audioSink.audio.muted = true
    }
    OsdState.show("volume", audioSink.audio.muted ? 0 : audioSink.audio.volume)
  }

  function setInputVolume(value) {
    if (!inputAvailable)
      return
    const normalized = clamp(value, 0, 1)
    audioSource.audio.volume = normalized
    if (normalized > audibleFloor) {
      lastAudibleInputVolume = normalized
      audioSource.audio.muted = false
    }
  }

  function adjustInputVolume(delta) {
    setInputVolume(inputVolume + delta)
  }

  function toggleInputMute() {
    if (!inputAvailable)
      return
    if (microphoneMuted || inputVolume <= audibleFloor) {
      if (inputVolume <= audibleFloor)
        audioSource.audio.volume = clamp(lastAudibleInputVolume, 0.05, 1)
      audioSource.audio.muted = false
    } else {
      lastAudibleInputVolume = inputVolume
      audioSource.audio.muted = true
    }
  }

  function selectDevice(direction, node) {
    if (!node?.ready)
      return
    if (direction === "output")
      Pipewire.preferredDefaultAudioSink = node
    else if (direction === "input")
      Pipewire.preferredDefaultAudioSource = node
  }

  function trackableAudioDeviceList() {
    const result = []
    for (const node of Pipewire.nodes.values) {
      if (!node.isStream && node.audio !== null)
        result.push(node)
    }
    return result
  }

  function audioDeviceList(direction) {
    const result = []
    const indexes = {}
    for (const node of Pipewire.nodes.values) {
      if (node.isStream || !node.ready)
        continue
      const matches = direction === "output"
        ? node.isSink
        : (node.type & PwNodeType.AudioSource) === PwNodeType.AudioSource
      if (!matches)
        continue
      const deviceId = node.properties["device.id"]
      const identity = deviceId !== undefined
        ? "device:" + deviceId
        : "node:" + (node.name || node.description || node.nickname
          || String(node.id))
      const existingIndex = indexes[identity]
      if (existingIndex === undefined) {
        indexes[identity] = result.length
        result.push(node)
      } else {
        const defaultNode = direction === "output"
          ? audioSink
          : audioSource
        if (node === defaultNode)
          result[existingIndex] = node
      }
    }
    result.sort(function(left, right) {
      return audioDeviceName(left, "").localeCompare(
        audioDeviceName(right, ""))
    })
    return result
  }

  function audioDeviceName(node, fallback) {
    return node?.nickname || node?.description || node?.name || fallback
  }

  PwObjectTracker {
    objects: root.audioDevices
  }

  Connections {
    target: root.audioSink?.audio ?? null

    function onVolumesChanged() {
      if (root.volume > root.audibleFloor && !root.muted)
        root.lastAudibleVolume = root.volume
      if (root.outputInitialized
          && Date.now() - root.outputMutationTime > 200)
        OsdState.show("volume", root.muted ? 0 : root.volume)
      root.outputInitialized = true
    }

    function onMutedChanged() {
      if (root.outputInitialized
          && Date.now() - root.outputMutationTime > 200)
        OsdState.show("volume", root.muted ? 0 : root.volume)
      root.outputInitialized = true
    }
  }

  Timer {
    id: outputInitializeTimer

    interval: 100
    onTriggered: root.outputInitialized = true
  }

  Connections {
    target: root.audioSource?.audio ?? null

    function onVolumesChanged() {
      if (root.inputVolume > root.audibleFloor && !root.microphoneMuted)
        root.lastAudibleInputVolume = root.inputVolume
    }
  }

  Component.onCompleted: outputInitializeTimer.start()
}
