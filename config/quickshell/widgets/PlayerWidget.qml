// SPDX-License-Identifier: GPL-3.0-only
// Adapted from Ryoku MusicWidget.qml and WidgetSlot.qml:
// https://github.com/ryoku-dev/ryoku
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Controls as Controls
import "../"

Scope {
  id: root

  readonly property bool opened: WidgetState.playerVisible
  readonly property bool posterArtwork: WidgetState.playerArtworkStyle === "poster"
  readonly property bool artworkVisible: WidgetState.playerArtworkStyle !== "none" && !posterArtwork
  property bool loaded: false
  property int widgetX: 340
  property int widgetY: 420
  property string playerLayout: "horizontal"
  readonly property int horizontalBaseHeight: 200 + (lyrics !== "" ? 52 : 0)
  readonly property int widgetWidth: playerLayout === "vertical" ? 280
    : visualizerStyle === "Off" && lyrics === "" ? 460 : 680
  readonly property int widgetHeight: playerLayout === "vertical"
    ? (artworkVisible || posterArtwork ? 466 : 214) + (visualizerStyle !== "Off" ? 54 : 0) + (lyrics !== "" ? 52 : 0)
    : horizontalBaseHeight + (visualizerStyle !== "Off" ? 48 : 0)
  property bool locked: false
  property bool alwaysOnTop: false
  property var spectrum: Array(32).fill(0)
  readonly property var visualizerStyles: ["Rounded", "Squared", "Mirror", "Dots", "Outline", "Off"]
  property string visualizerStyle: "Rounded"

  function cycleVisualizer(): void {
    visualizerStyle = visualizerStyles[(visualizerStyles.indexOf(visualizerStyle)
      + 1) % visualizerStyles.length]
    styleNotice.restart()
  }

  Timer { id: styleNotice; interval: 1400 }

  readonly property var player: {
    const players = Mpris.players.values
    return players.find(function(candidate) { return candidate.isPlaying })
      || players[0] || null
  }
  readonly property bool present: player !== null
  readonly property bool playing: present && player.isPlaying
  readonly property string artworkUrl: present && player.trackArtUrl
    ? String(player.trackArtUrl) : ""
  readonly property string artworkCachePath: Quickshell.cachePath("atlas-player-art")
  property string paletteSource: ""
  readonly property bool seekable: present && player.lengthSupported
    && player.length > 0
  readonly property real progress: seekable
    ? Math.max(0, Math.min(1, player.position / player.length)) : 0
  readonly property string metadataLyrics: lyricsFromMetadata()
  property bool lyricsEnabled: true
  readonly property string timedLyricsSource: parseTimedLyrics(fetchedLyrics).length > 0
    ? fetchedLyrics : metadataLyrics
  readonly property string lyrics: lyricsEnabled && timedLyrics.length > 0
    ? timedLyricsSource : ""
  onLyricsEnabledChanged: {
    if (lyricsEnabled && !fetchedLyrics) lyricsLookupTimer.restart()
  }
  property string fetchedLyrics: ""
  readonly property var timedLyrics: parseTimedLyrics(timedLyricsSource)
  readonly property string currentLyricLine: lyrics !== ""
    ? lyricAt(timedLyrics, player ? player.position : 0) : ""

  function parseTimedLyrics(source) {
    const entries = []
    const offsetMatch = source.match(/\[offset:([+-]?\d+)\]/i)
    const offset = offsetMatch ? Number(offsetMatch[1]) / 1000 : 0
    for (const line of source.split(/\r?\n/)) {
      const pattern = /\[(\d+):(\d+(?:\.\d+)?)\]/g
      const text = line.replace(pattern, "").trim()
      let match
      while ((match = pattern.exec(line)) !== null)
        entries.push({ time: Number(match[1]) * 60 + Number(match[2]) - offset,
          text: text })
    }
    return entries.sort(function(a, b) { return a.time - b.time })
  }

  function lyricAt(entries, position) {
    let current = "♪"
    for (const entry of entries) {
      if (entry.time > position) break
      current = entry.text || "♪"
    }
    return current
  }
  readonly property string lyricsTrackKey: JSON.stringify([
    present ? player.trackTitle : "",
    present ? player.trackArtist : "",
    present ? player.trackAlbum : ""
  ])
  onLyricsTrackKeyChanged: {
    fetchedLyrics = ""
    lyricsLookupTimer.restart()
  }
  onOpenedChanged: if (opened && !lyrics) lyricsLookupTimer.restart()

  Timer {
    id: lyricsLookupTimer
    interval: 350
    onTriggered: root.fetchLyrics()
  }

  function fetchLyrics(): void {
    if (!lyricsEnabled || !opened || !present || parseTimedLyrics(metadataLyrics).length > 0 || lyricsFetch.running
        || !player.trackTitle || !player.trackArtist)
      return
    lyricsFetch.requestKey = lyricsTrackKey
    lyricsFetch.command = ["curl", "-fsSL", "--connect-timeout", "5",
      "--max-time", "15", "--max-filesize", "1048576",
      "--user-agent", "AtlasPlayer/1.0", "--get",
      "--data-urlencode", "track_name=" + player.trackTitle,
      "--data-urlencode", "artist_name=" + player.trackArtist,
      "--data-urlencode", "album_name=" + (player.trackAlbum || ""),
      "https://lrclib.net/api/get"]
    lyricsFetch.running = true
  }

  function parseLyricsResponse(response) {
    try {
      const data = JSON.parse(response)
      if (typeof data.syncedLyrics === "string" && data.syncedLyrics.trim())
        return data.syncedLyrics.trim()
      if (typeof data.plainLyrics === "string")
        return data.plainLyrics.trim()
    } catch (error) {}
    return ""
  }

  Process {
    id: lyricsFetch
    property string requestKey: ""
    stdout: StdioCollector { id: lyricsResponse }
    stderr: StdioCollector {}
    onExited: function(exitCode) {
      if (requestKey !== root.lyricsTrackKey) {
        lyricsLookupTimer.restart()
        return
      }
      if (exitCode === 0)
        root.fetchedLyrics = root.parseLyricsResponse(lyricsResponse.text)
    }
  }

  function lyricsFromMetadata() {
    if (!player || !player.metadata)
      return ""
    const keys = ["xesam:asText", "xesam:lyrics", "mpris:lyrics"]
    for (let index = 0; index < keys.length; ++index) {
      const value = player.metadata[keys[index]]
      if (typeof value === "string" && value.trim() !== "")
        return value.trim()
    }
    return ""
  }
  function acceptSpectrum(line) {
    const values = String(line).trim().split(";")
      .map(function(value) { return Math.max(0, Math.min(100, Number(value) || 0)) })
    if (values.length >= 8)
      spectrum = values
  }

  function refreshArtworkPalette(): void {
    paletteSource = ""
    artworkFetch.running = false
    if (artworkUrl === "")
      return
    Qt.callLater(function() { artworkFetch.running = true })
  }

  function colorLuma(color) {
    if (color === undefined || color === null)
      return 0
    return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
  }

  function mixColor(first, second, amount) {
    const mix = Math.max(0, Math.min(1, amount))
    return Qt.rgba(first.r + (second.r - first.r) * mix,
      first.g + (second.g - first.g) * mix,
      first.b + (second.b - first.b) * mix, 1)
  }

  function colorContrast(first, second) {
    const bright = Math.max(colorLuma(first), colorLuma(second))
    const dark = Math.min(colorLuma(first), colorLuma(second))
    return (bright + 0.05) / (dark + 0.05)
  }

  function paletteSurface(colors) {
    if (!colors || colors.length === 0)
      return Theme.surface
    let best = colors[0]
    let bestScore = -100
    for (let index = 0; index < colors.length; ++index) {
      const color = colors[index]
      if (color === undefined || color === null)
        continue
      const maximum = Math.max(color.r, color.g, color.b)
      const minimum = Math.min(color.r, color.g, color.b)
      const saturation = maximum <= 0 ? 0 : (maximum - minimum) / maximum
      const luma = colorLuma(color)
      // Prefer a dark chromatic color over either flat black or a bright swatch.
      const score = saturation * 1.4 - Math.abs(luma - 0.16) * 3
        - (maximum < 0.07 ? 1.5 : 0)
      if (score > bestScore) {
        best = color
        bestScore = score
      }
    }
    if (bestScore === -100)
      return Theme.surface
    const luma = colorLuma(best)
    if (luma > 0.18)
      return mixColor(best, Qt.rgba(0, 0, 0, 1), 1 - 0.16 / luma)
    if (luma < 0.09)
      return mixColor(best, Qt.rgba(1, 1, 1, 1), Math.min(0.12, 0.09 - luma))
    return best
  }

  function paletteAccent(colors, surface) {
    if (!colors || colors.length === 0)
      return Theme.accent
    let best = colors[0]
    let bestScore = -1
    for (let index = 0; index < colors.length; ++index) {
      const color = colors[index]
      if (color === undefined || color === null)
        continue
      const maximum = Math.max(color.r, color.g, color.b)
      const minimum = Math.min(color.r, color.g, color.b)
      const saturation = maximum <= 0 ? 0 : (maximum - minimum) / maximum
      const luma = colorLuma(color)
      const usableBrightness = 1 - Math.abs(luma - 0.58)
      const darknessPenalty = luma < 0.12 ? 4 : (luma < 0.2 ? 1.2 : 0)
      const score = saturation * 1.8 + usableBrightness
        + Math.min(2, colorContrast(color, surface)) * 0.35 - darknessPenalty
      if (score > bestScore) {
        best = color
        bestScore = score
      }
    }
    if (bestScore === -1)
      return Theme.accent
    const maximum = Math.max(best.r, best.g, best.b)
    const minimum = Math.min(best.r, best.g, best.b)
    if (maximum < 0.16 && maximum - minimum < 0.035)
      return Theme.accent
    let adjusted = best
    let attempts = 0
    while (colorContrast(adjusted, surface) < 3.5 && attempts < 8) {
      adjusted = mixColor(adjusted, Qt.rgba(1, 1, 1, 1), 0.12)
      attempts++
    }
    return adjusted
  }

  onArtworkUrlChanged: refreshArtworkPalette()
  Component.onCompleted: {
    refreshArtworkPalette()
    lyricsLookupTimer.restart()
  }

  function open(): void { WidgetState.playerVisible = true }
  function close(): void { WidgetState.playerVisible = false; save() }
  function toggle(): void {
    WidgetState.playerVisible = !WidgetState.playerVisible
  }
  function save(): void {
    if (!loaded)
      return
    stateFile.setText(JSON.stringify({
      x: widgetX, y: widgetY, layout: playerLayout,
      locked: locked, alwaysOnTop: alwaysOnTop,
      visualizerStyle: visualizerStyle, lyricsEnabled: lyricsEnabled
    }, null, 2) + "\n")
  }
  function stamp(seconds) {
    const value = Math.max(0, Math.floor(Number(seconds) || 0))
    const minutes = Math.floor(value / 60)
    const remainder = value % 60
    return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
  }

  component TransportIcon: Item {
    id: transportIcon
    property url source
    property color iconColor: "white"

    IconImage {
      anchors.centerIn: parent
      width: 24
      height: 24
      source: transportIcon.source
      layer.enabled: true
      layer.effect: MultiEffect {
        brightness: 1
        colorization: 1
        colorizationColor: transportIcon.iconColor
      }
    }
  }

  IpcHandler {
    target: "player-widget"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  FileView {
    id: stateFile
    path: (Quickshell.env("XDG_CONFIG_HOME")
      || Quickshell.env("HOME") + "/.config")
      + "/atlas/player-widget.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (Number.isFinite(Number(data.x))) root.widgetX = Math.max(0, Number(data.x))
        if (Number.isFinite(Number(data.y))) root.widgetY = Math.max(0, Number(data.y))
        if (data.layout === "vertical" || data.layout === "horizontal") {
          root.playerLayout = data.layout
        } else if (Number(data.height) > Number(data.width) * 1.05) {
          // Preserve the orientation from older resizable widget settings.
          root.playerLayout = "vertical"
        }
        if (typeof data.lyricsEnabled === "boolean")
          root.lyricsEnabled = data.lyricsEnabled
        if (root.visualizerStyles.indexOf(data.visualizerStyle) >= 0)
          root.visualizerStyle = data.visualizerStyle
        if (typeof data.locked === "boolean") root.locked = data.locked
        if (typeof data.alwaysOnTop === "boolean")
          root.alwaysOnTop = data.alwaysOnTop
      } catch (error) {}
      root.loaded = true
    }
    onLoadFailed: { root.loaded = true; root.save() }
  }

  Timer { id: saveTimer; interval: 350; onTriggered: root.save() }
  Connections {
    target: root
    function onWidgetXChanged(): void { if (root.loaded) saveTimer.restart() }
    function onWidgetYChanged(): void { if (root.loaded) saveTimer.restart() }
    function onPlayerLayoutChanged(): void { if (root.loaded) saveTimer.restart() }
    function onLyricsEnabledChanged(): void { if (root.loaded) saveTimer.restart() }
    function onVisualizerStyleChanged(): void { if (root.loaded) saveTimer.restart() }
    function onLockedChanged(): void { if (root.loaded) saveTimer.restart() }
    function onAlwaysOnTopChanged(): void {
      if (root.loaded) saveTimer.restart()
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.opened && root.playing && root.player !== null
    onTriggered: root.player.positionChanged()
  }

  Process {
    id: artworkFetch
    command: ["curl", "-fsSL", "--output", root.artworkCachePath,
      "--", root.artworkUrl]
    running: false
    onExited: function(exitCode) {
      if (exitCode === 0 && root.artworkUrl !== "")
        root.paletteSource = Qt.resolvedUrl(root.artworkCachePath)
    }
  }

  Process {
    id: cavaProcess
    command: ["cava", "-p", (Quickshell.env("HOME") || "")
      + "/.config/quickshell/widgets/cava.conf"]
    running: root.opened && root.visualizerStyle !== "Off"
    stdout: SplitParser {
      onRead: function(line) { root.acceptSpectrum(line) }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData
      readonly property bool focusedScreen: Hyprland.focusedMonitor !== null
        && Hyprland.monitorFor(modelData) !== null
        && Hyprland.monitorFor(modelData).name === Hyprland.focusedMonitor.name

      screen: modelData
      visible: root.opened && focusedScreen
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: root.alwaysOnTop || WidgetState.playerRaised
        ? WlrLayer.Overlay : WlrLayer.Bottom
      // Release keyboard focus as soon as the pointer leaves the widget.
      WlrLayershell.keyboardFocus: playerHover.hovered || playerMenu.visible
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
      WlrLayershell.namespace: "atlas-player-widget"
      anchors { top: true; bottom: true; left: true; right: true }

      // Popup menus live in Qt's window overlay, outside the widget region.
      // Accept input across the window while a menu is open, including outside
      // clicks that dismiss it; restore click-through immediately on close.
      mask: (playerMenu.visible) ? null : widgetInputRegion
      property Region widgetInputRegion: Region {
        Region {
          intersection: Intersection.Combine
          x: Math.floor(playerSlot.x)
          y: Math.floor(playerSlot.y)
          width: Math.ceil(playerSlot.width)
          height: Math.ceil(playerSlot.height)
        }
      }

      Item {
        id: playerSlot
        focus: true
        Shortcut {
          sequence: "V"
          context: Qt.WindowShortcut
          enabled: window.visible && playerHover.hovered
          autoRepeat: false
          onActivated: root.cycleVisualizer()
        }
        Shortcut {
          sequence: "L"
          context: Qt.WindowShortcut
          enabled: window.visible && playerHover.hovered
          autoRepeat: false
          onActivated: root.lyricsEnabled = !root.lyricsEnabled
        }
        readonly property bool portrait: root.playerLayout === "vertical"
        property bool dragging: false
        property real dragX: root.widgetX
        property real dragY: root.widgetY

        function clampX(value) {
          if (window.width <= 0) return value
          return Math.max(0, Math.min(value, window.width - width))
        }
        function clampY(value) {
          if (window.height <= 0) return value
          return Math.max(0, Math.min(value, window.height - height))
        }
        function snap(value) { return Math.round(value / 16) * 16 }
        x: dragging ? dragX : clampX(root.widgetX)
        y: dragging ? dragY : clampY(root.widgetY)
        width: root.widgetWidth
        height: root.widgetHeight
        scale: dragging ? 1.025 : 1
        transformOrigin: Item.Center
        Behavior on scale {
          NumberAnimation { duration: 140; easing.type: Easing.OutExpo }
        }

        MouseArea {
          id: moveGrip
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          hoverEnabled: true
          cursorShape: root.locked ? Qt.ArrowCursor
            : (playerSlot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
          property bool leftDown: false
          property real grabOffsetX: 0
          property real grabOffsetY: 0
          onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
              playerMenu.popup(mouse.x, mouse.y)
              return
            }
            if (root.locked) return
            leftDown = true
            const point = playerSlot.mapToItem(window.contentItem, mouse.x, mouse.y)
            grabOffsetX = point.x - playerSlot.x
            grabOffsetY = point.y - playerSlot.y
          }
          onPositionChanged: function(mouse) {
            if (!leftDown || root.locked) return
            const point = playerSlot.mapToItem(window.contentItem, mouse.x, mouse.y)
            const nextX = point.x - grabOffsetX
            const nextY = point.y - grabOffsetY
            if (!playerSlot.dragging && Math.abs(nextX - playerSlot.x) < 6
                && Math.abs(nextY - playerSlot.y) < 6) return
            playerSlot.dragging = true
            playerSlot.dragX = playerSlot.clampX(playerSlot.snap(nextX))
            playerSlot.dragY = playerSlot.clampY(playerSlot.snap(nextY))
          }
          onReleased: {
            if (playerSlot.dragging) {
              root.widgetX = Math.round(playerSlot.dragX)
              root.widgetY = Math.round(playerSlot.dragY)
              playerSlot.dragging = false
            }
            leftDown = false
          }
        }

        ColorQuantizer {
          id: quantizer
          source: root.paletteSource
          depth: 3
          rescaleSize: 48
        }
        readonly property bool useAlbumColors:
          WidgetState.playerColorSource === "album"
        readonly property color albumSurface: root.posterArtwork ? "#17191c" : useAlbumColors
          ? root.paletteSurface(quantizer.colors) : Theme.surface
        readonly property color albumAccent: useAlbumColors
          ? root.paletteAccent(quantizer.colors, albumSurface) : Theme.accent
        readonly property color rawAlbumSecondary: quantizer.colors.length > 1
          ? quantizer.colors[1] : albumAccent
        readonly property real secondaryLuma: rawAlbumSecondary.r * 0.2126
          + rawAlbumSecondary.g * 0.7152 + rawAlbumSecondary.b * 0.0722
        readonly property color albumSecondary: !useAlbumColors
          ? Theme.surfaceHover : (secondaryLuma < 0.14
            ? albumAccent : rawAlbumSecondary)
        readonly property color albumSurfaceRaised: root.posterArtwork ? "#303238" : useAlbumColors
          && quantizer.colors.length > 0
          ? root.mixColor(albumSurface, albumAccent, 0.13) : Theme.surfaceHover
        readonly property color albumInk: root.posterArtwork || useAlbumColors
          ? "#f7f8fa" : Theme.foreground
        readonly property color albumAccentInk: !useAlbumColors
          ? Theme.background
          : (root.colorContrast(albumAccent, Qt.rgba(0.063, 0.071, 0.078, 1))
            >= root.colorContrast(albumAccent, Qt.rgba(0.969, 0.973, 0.98, 1))
            ? "#101214" : "#f7f8fa")
        readonly property color albumInkMuted: root.posterArtwork || useAlbumColors
          ? Qt.rgba(albumInk.r, albumInk.g, albumInk.b, 0.74)
          : Theme.foregroundMuted
        readonly property color albumBorder: root.posterArtwork || useAlbumColors
          ? Qt.rgba(albumInk.r, albumInk.g, albumInk.b, 0.14)
          : Theme.border

        Rectangle {
          anchors.fill: parent
          radius: root.posterArtwork ? Theme.radiusLg : Theme.cornerRadius
          color: playerSlot.albumSurface
          gradient: Gradient {
            orientation: playerSlot.portrait ? Gradient.Vertical : Gradient.Horizontal
            GradientStop {
              position: 0
              color: root.mixColor(playerSlot.albumSurface,
                playerSlot.albumAccent, 0.20)
            }
            GradientStop {
              position: 0.55
              color: playerSlot.albumSurface
            }
            GradientStop {
              position: 1
              color: Qt.darker(playerSlot.albumSurface, 1.18)
            }
          }
          border.width: Theme.borderWidth
          border.color: playerHover.hovered
            ? playerSlot.albumAccent : playerSlot.albumBorder
          Behavior on border.color { ColorAnimation { duration: Theme.motionQuick } }
        }
        Rectangle {
          id: posterMask
          width: playerSlot.width
          height: playerSlot.height
          radius: Theme.radiusLg
          color: "white"
          visible: false
          antialiasing: true
          layer.enabled: true
        }
        Rectangle {
          id: posterBackground
          anchors.fill: parent
          visible: root.posterArtwork
          radius: Theme.radiusLg
          color: playerSlot.albumSurface
          layer.enabled: root.posterArtwork
          layer.smooth: true
          layer.effect: MultiEffect { maskEnabled: true; maskSource: posterMask }
          Image {
            id: posterImage
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: playerSlot.portrait ? parent.width : Math.min(parent.width * 0.6, parent.height * 1.25)
            source: root.artworkUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true
          }
          Rectangle {
            id: posterShade
            anchors.fill: parent
            readonly property real fadeEnd: posterImage.width / width
            gradient: Gradient {
              orientation: playerSlot.portrait ? Gradient.Vertical : Gradient.Horizontal
              GradientStop { position: 0; color: "#18000000" }
              GradientStop { position: playerSlot.portrait ? 0.4 : posterShade.fadeEnd * 0.35; color: "#18000000" }
              GradientStop { position: playerSlot.portrait ? 0.65 : posterShade.fadeEnd; color: playerSlot.portrait ? "#99000000" : playerSlot.albumSurface }
              GradientStop { position: 1; color: playerSlot.portrait ? "#ef000000" : playerSlot.albumSurface }
            }
          }
          Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: Theme.borderWidth
            border.color: playerSlot.albumBorder
            radius: Theme.radiusLg
          }
        }
        HoverHandler { id: playerHover }

        Rectangle {
          z: 10
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.topMargin: 8
          width: styleLabel.implicitWidth + 20
          height: 28
          radius: Theme.cornerRadius
          color: playerSlot.albumSurfaceRaised
          border.width: 1
          border.color: playerSlot.albumBorder
          visible: styleNotice.running
          Text {
            id: styleLabel
            anchors.centerIn: parent
            text: "Visualizer · " + root.visualizerStyle + "  [V]"
            font.pixelSize: 11
            color: playerSlot.albumInk
          }
        }

        Item {
          id: playerBody
          anchors.fill: parent
          anchors.margins: 20
          visible: !playerSlot.portrait

          Item {
            anchors.fill: parent

            AlbumArtwork {
              id: cover
              visible: root.artworkVisible
              x: 0
              y: root.visualizerStyle === "Off" && root.lyrics === ""
                ? 0 : (parent.height - 60 - height) / 2
              width: root.visualizerStyle === "Off" && root.lyrics === ""
                ? parent.height
                : Math.min(parent.height - 60, root.horizontalBaseHeight - 40)
              height: width
              source: root.artworkUrl
              style: WidgetState.playerArtworkStyle
              playing: root.playing
              surfaceColor: playerSlot.albumSurfaceRaised
              accentColor: playerSlot.albumAccent
            }

            Item {
              id: playbackField
              x: root.posterArtwork ? Math.min(parent.width * 0.38, parent.height * 0.95)
                : root.artworkVisible ? cover.x + cover.width + 22 : 0
              y: trackInfo.y + trackInfo.height + 8
              width: parent.width - x
              height: Math.max(0, bottomControls.y - y - 8)
              visible: width > 100
              PlayerVisualizer {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: root.lyrics !== "" ? horizontalLyrics.bottom : parent.top
                anchors.topMargin: root.lyrics !== "" && root.visualizerStyle !== "Off" ? 8 : 0
                anchors.bottom: parent.bottom
                spectrum: root.present ? root.spectrum : []
                style: root.visualizerStyle
                accent: playerSlot.albumAccent
              }
              Flickable {
                id: horizontalLyrics
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 40
                clip: true
                contentHeight: lyricText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                visible: root.lyrics !== ""
                Connections {
                  target: root
                  function onCurrentLyricLineChanged(): void { horizontalLyrics.contentY = 0 }
                }
                Text {
                  id: lyricText
                  width: parent.width
                  text: root.currentLyricLine
                  textFormat: Text.PlainText
                  horizontalAlignment: Text.AlignLeft
                  color: playerSlot.albumInk
                  opacity: 0.9
                  wrapMode: Text.WordWrap
                  lineHeight: 1.2
                  font.pixelSize: 12
                  font.weight: Font.Medium
                  font.family: "sans-serif"
                }
              }
            }

            Item {
              id: trackInfo
              x: playbackField.x
              y: 0
              width: playbackField.width
              height: 56

              Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 3
                ScrollingText {
                  width: parent.width
                  text: root.player ? (root.player.trackTitle || "Unknown title") : "Nothing playing"
                  color: playerSlot.albumInk
                  font.family: "sans-serif"
                  font.pixelSize: 22
                  font.weight: Font.DemiBold
                  scrollingEnabled: root.opened
                }
                ScrollingText {
                  width: parent.width
                  text: root.player
                    ? (root.player.trackArtist || "Unknown artist")
                      + (root.player.trackAlbum ? " · " + root.player.trackAlbum : "")
                    : "Start some music to see it here"
                  color: playerSlot.albumInkMuted
                  font.family: "sans-serif"
                  font.pixelSize: 12
                  scrollingEnabled: root.opened
                }
              }
            }

            Item {
              id: bottomControls
              x: playbackField.x
              y: !root.artworkVisible ? parent.height - height
                : root.visualizerStyle === "Off" && root.lyrics === ""
                  ? trackInfo.y + trackInfo.height + 12 : parent.height - height
              width: playbackField.width
              height: root.artworkVisible ? 32 : 96

              Text {
                anchors.left: parent.left
                anchors.top: parent.top
                visible: root.seekable
                text: root.stamp(root.player ? root.player.position : 0)
                color: playerSlot.albumInkMuted
                font.family: "sans-serif"
                font.pixelSize: 9
              }
              Text {
                anchors.right: parent.right
                anchors.top: parent.top
                visible: root.seekable
                text: root.stamp(root.player ? root.player.length : 0)
                color: playerSlot.albumInkMuted
                font.family: "sans-serif"
                font.pixelSize: 9
              }

              Item {
                id: seekRail
                anchors.left: parent.left
                anchors.right: transport.left
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                height: 18
                visible: false

                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  height: 2
                  radius: 1
                  color: playerSlot.albumBorder
                }
                Item {
                  width: parent.width * root.progress
                  height: parent.height
                  clip: true
                  Canvas {
                    id: progressWave
                    width: seekRail.width + 16
                    height: seekRail.height
                    property real phase: 0
                    x: phase
                    onPaint: {
                      const context = getContext("2d")
                      context.reset()
                      context.strokeStyle = playerSlot.albumAccent
                      context.lineWidth = 2.2
                      context.lineCap = "round"
                      context.beginPath()
                      for (let point = 0; point <= width; point += 2) {
                        const waveY = height / 2 + 3 * Math.sin(point * 0.42)
                        if (point === 0) context.moveTo(point, waveY)
                        else context.lineTo(point, waveY)
                      }
                      context.stroke()
                    }
                    Component.onCompleted: requestPaint()
                    Connections {
                      target: playerSlot
                      function onAlbumAccentChanged(): void { progressWave.requestPaint() }
                    }
                    NumberAnimation on phase {
                      running: root.playing
                      loops: Animation.Infinite
                      from: -15
                      to: 0
                      duration: 1100
                    }
                  }
                }
                Rectangle {
                  x: Math.max(0, Math.min(parent.width - width,
                    parent.width * root.progress - width / 2))
                  anchors.verticalCenter: parent.verticalCenter
                  width: 3
                  height: 12
                  radius: 2
                  color: playerSlot.albumAccent
                }
                MouseArea {
                  anchors.fill: parent
                  anchors.topMargin: -7
                  anchors.bottomMargin: -7
                  enabled: root.player && root.player.canSeek
                  cursorShape: Qt.PointingHandCursor
                  function seekAt(pointX) {
                    root.player.position = Math.max(0,
                      Math.min(1, pointX / width)) * root.player.length
                  }
                  onPressed: function(mouse) { seekAt(mouse.x) }
                  onPositionChanged: function(mouse) { if (pressed) seekAt(mouse.x) }
                }
              }

              Row {
                id: kewSpectrum
                visible: false
                anchors.left: parent.left
                anchors.right: transport.left
                anchors.rightMargin: 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                height: 42
                spacing: 4
                Repeater {
                  model: 24
                  Rectangle {
                    required property int index
                    width: Math.max(2, (kewSpectrum.width - 92) / 24)
                    height: Math.max(2, kewSpectrum.height
                      * (root.spectrum[Math.floor(index
                        * root.spectrum.length / 24)] || 0) / 100)
                    anchors.bottom: parent.bottom
                    color: Qt.tint(playerSlot.albumAccent,
                      Qt.rgba(index / 30, index / 45, index / 24, 0.24))
                    Behavior on height {
                      NumberAnimation { duration: 65; easing.type: Easing.OutCubic }
                    }
                  }
                }
              }

              Item {
                id: timeline
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 14
                height: 16

                Rectangle {
                  id: timelineTrack
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  height: 4
                  radius: 2
                  color: playerSlot.albumBorder
                  Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: parent.radius
                    color: playerSlot.albumAccent
                  }
                }
                Rectangle {
                  x: Math.max(0, Math.min(parent.width - width,
                    timelineTrack.width * root.progress - width / 2))
                  anchors.verticalCenter: parent.verticalCenter
                  width: timelineMouse.pressed || timelineMouse.containsMouse ? 11 : 8
                  height: width
                  radius: width / 2
                  color: playerSlot.albumInk
                  border.width: 2
                  border.color: playerSlot.albumAccent
                  Behavior on width { NumberAnimation { duration: 90 } }
                }
                MouseArea {
                  id: timelineMouse
                  anchors.fill: parent
                  enabled: root.player && root.player.canSeek
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  function seekAt(pointerX) {
                    root.player.position = Math.max(0,
                      Math.min(1, pointerX / width)) * root.player.length
                  }
                  onPressed: function(mouse) { seekAt(mouse.x) }
                  onPositionChanged: function(mouse) {
                    if (pressed) seekAt(mouse.x)
                  }
                }
              }

              Item {
                id: transport
                parent: cover.parent
                width: 148
                height: 48
                x: !root.artworkVisible || (root.visualizerStyle === "Off" && root.lyrics === "")
                  ? bottomControls.x + (bottomControls.width - width) / 2
                  : cover.x + (cover.width - width) / 2
                anchors.bottom: parent.bottom

                Controls.Button {
                  x: 0
                  anchors.verticalCenter: parent.verticalCenter
                  width: 40; height: 40
                  enabled: root.player && root.player.canGoPrevious
                  onClicked: root.player.previous()
                  Accessible.name: "Previous track"
                  Controls.ToolTip.visible: hovered
                  Controls.ToolTip.delay: 650
                  Controls.ToolTip.text: Accessible.name
                  opacity: enabled ? 1 : 0.35
                  scale: down ? 0.9 : 1
                  Behavior on scale { NumberAnimation { duration: 90 } }
                  background: Rectangle {
                    radius: Theme.cornerRadius
                    color: parent.hovered
                      ? Qt.rgba(playerSlot.albumInk.r, playerSlot.albumInk.g,
                        playerSlot.albumInk.b, 0.10) : "transparent"
                  }
                  contentItem: TransportIcon {
                    source: Qt.resolvedUrl("../assets/previous.svg")
                    iconColor: parent.enabled
                      ? playerSlot.albumInk : playerSlot.albumInkMuted
                  }
                }
                Controls.Button {
                  x: 50
                  anchors.verticalCenter: parent.verticalCenter
                  width: 48; height: 48
                  enabled: root.player && root.player.canTogglePlaying
                  onClicked: root.player.togglePlaying()
                  Accessible.name: "Play or pause"
                  Controls.ToolTip.visible: hovered
                  Controls.ToolTip.delay: 650
                  Controls.ToolTip.text: Accessible.name
                  opacity: enabled ? 1 : 0.35
                  scale: down ? 0.9 : 1
                  Behavior on scale { NumberAnimation { duration: 90 } }
                  background: Rectangle {
                    radius: Theme.cornerRadius
                    color: parent.down ? Qt.darker(playerSlot.albumAccent, 1.12)
                      : parent.hovered ? Qt.lighter(playerSlot.albumAccent, 1.10)
                      : playerSlot.albumAccent
                    Behavior on color { ColorAnimation { duration: 120 } }
                  }
                  contentItem: TransportIcon {
                    source: Qt.resolvedUrl(root.playing
                      ? "../assets/pause.svg" : "../assets/play.svg")
                    iconColor: playerSlot.albumAccentInk
                  }
                }
                Controls.Button {
                  x: 108
                  anchors.verticalCenter: parent.verticalCenter
                  width: 40; height: 40
                  enabled: root.player && root.player.canGoNext
                  onClicked: root.player.next()
                  Accessible.name: "Next track"
                  Controls.ToolTip.visible: hovered
                  Controls.ToolTip.delay: 650
                  Controls.ToolTip.text: Accessible.name
                  opacity: enabled ? 1 : 0.35
                  scale: down ? 0.9 : 1
                  Behavior on scale { NumberAnimation { duration: 90 } }
                  background: Rectangle {
                    radius: Theme.cornerRadius
                    color: parent.hovered
                      ? Qt.rgba(playerSlot.albumInk.r, playerSlot.albumInk.g,
                        playerSlot.albumInk.b, 0.10) : "transparent"
                  }
                  contentItem: TransportIcon {
                    source: Qt.resolvedUrl("../assets/next.svg")
                    iconColor: parent.enabled
                      ? playerSlot.albumInk : playerSlot.albumInkMuted
                  }
                }
              }
            }
          }
        }

        Item {
          id: portraitBody
          anchors.fill: parent
          anchors.margins: 20
          visible: playerSlot.portrait

          AlbumArtwork {
            id: portraitArt
            visible: root.artworkVisible
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: root.artworkVisible ? width : 0
            source: root.artworkUrl
            style: WidgetState.playerArtworkStyle
            playing: root.playing
            surfaceColor: playerSlot.albumSurfaceRaised
            accentColor: playerSlot.albumAccent
          }

          Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: root.posterArtwork ? undefined : portraitArt.bottom
            anchors.bottom: root.posterArtwork ? portraitLyricsScroll.top : undefined
            anchors.bottomMargin: root.posterArtwork ? 12 : 0
            anchors.topMargin: root.artworkVisible ? 12 : 0
            spacing: 3
            ScrollingText {
              width: parent.width
              text: root.player ? (root.player.trackTitle || "Unknown title") : "Nothing playing"
              color: playerSlot.albumInk
              font.family: "sans-serif"
              font.pixelSize: 22
              font.weight: Font.DemiBold
              scrollingEnabled: root.opened
            }
            ScrollingText {
              width: parent.width
              text: root.player
                ? (root.player.trackArtist || "Unknown artist")
                  + (root.player.trackAlbum ? " · " + root.player.trackAlbum : "")
                : "Start some music to see it here"
              color: playerSlot.albumInkMuted
              font.family: "sans-serif"
              font.pixelSize: 12
              scrollingEnabled: root.opened
            }
          }

          Flickable {
            id: portraitLyricsScroll
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: portraitFooterSpectrum.top
            anchors.bottomMargin: root.lyrics !== "" ? 12 : 0
            height: root.lyrics !== "" ? 40 : 0
            visible: root.lyrics !== ""
            clip: true
            contentWidth: width
            contentHeight: portraitLyrics.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            Controls.ScrollBar.vertical: Controls.ScrollBar {
              policy: Controls.ScrollBar.AsNeeded
            }
            Connections {
              target: root
              function onCurrentLyricLineChanged(): void { portraitLyricsScroll.contentY = 0 }
            }
            Text {
              id: portraitLyrics
              width: Math.max(0, portraitLyricsScroll.width - 12)
              text: root.currentLyricLine
              textFormat: Text.PlainText
              color: playerSlot.albumInk
              wrapMode: Text.WordWrap
              horizontalAlignment: Text.AlignLeft
              lineHeight: 1.3
              font.family: "sans-serif"
              font.pixelSize: 12
              font.weight: Font.Medium
            }
          }

          PlayerVisualizer {
            id: portraitFooterSpectrum
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: portraitTimestamps.top
            anchors.bottomMargin: root.visualizerStyle !== "Off" ? 6 : 0
            height: root.visualizerStyle !== "Off" ? 48 : 0
            spectrum: root.present ? root.spectrum : []
            style: root.visualizerStyle
            accent: playerSlot.albumAccent
          }

          Item {
            id: portraitTimestamps
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: portraitTimeline.top
            anchors.bottomMargin: 2
            height: root.seekable ? 12 : 0
            visible: root.seekable

            Text {
              anchors.left: parent.left
              anchors.top: parent.top
              text: root.stamp(root.player ? root.player.position : 0)
              color: playerSlot.albumInkMuted
              font.family: "sans-serif"
              font.pixelSize: 9
            }
            Text {
              anchors.right: parent.right
              anchors.top: parent.top
              text: root.stamp(root.player ? root.player.length : 0)
              color: playerSlot.albumInkMuted
              font.family: "sans-serif"
              font.pixelSize: 9
            }
          }

          Item {
            id: portraitTimeline
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: portraitTransport.top
            anchors.bottomMargin: 10
            height: 18
            Rectangle {
              id: portraitTimelineTrack
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              height: 4
              radius: 2
              color: playerSlot.albumBorder
              Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: parent.radius
                color: playerSlot.albumAccent
              }
            }
            Rectangle {
              x: Math.max(0, Math.min(parent.width - width,
                portraitTimelineTrack.width * root.progress - width / 2))
              anchors.verticalCenter: parent.verticalCenter
              width: portraitTimelineMouse.pressed
                || portraitTimelineMouse.containsMouse ? 11 : 8
              height: width
              radius: width / 2
              color: playerSlot.albumInk
              border.width: 2
              border.color: playerSlot.albumAccent
              Behavior on width { NumberAnimation { duration: 90 } }
            }
            MouseArea {
              id: portraitTimelineMouse
              anchors.fill: parent
              enabled: root.player && root.player.canSeek
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              function seekAt(pointerX) {
                root.player.position = Math.max(0,
                  Math.min(1, pointerX / width)) * root.player.length
              }
              onPressed: function(mouse) { seekAt(mouse.x) }
              onPositionChanged: function(mouse) {
                if (pressed) seekAt(mouse.x)
              }
            }
          }

          Row {
            id: portraitTransport
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 12
            Controls.Button {
              anchors.verticalCenter: parent.verticalCenter
              width: 40; height: 40
              enabled: root.player && root.player.canGoPrevious
              onClicked: root.player.previous()
              Accessible.name: "Previous track"
              Controls.ToolTip.visible: hovered
              Controls.ToolTip.delay: 650
              Controls.ToolTip.text: Accessible.name
              opacity: enabled ? 1 : 0.35
              scale: down ? 0.9 : 1
              Behavior on scale { NumberAnimation { duration: 90 } }
              background: Rectangle { radius: Theme.cornerRadius; color: parent.hovered ? Qt.rgba(playerSlot.albumInk.r, playerSlot.albumInk.g, playerSlot.albumInk.b, 0.10) : "transparent" }
              contentItem: TransportIcon { source: Qt.resolvedUrl("../assets/previous.svg"); iconColor: parent.enabled ? playerSlot.albumInk : playerSlot.albumInkMuted }
            }
            Controls.Button {
              anchors.verticalCenter: parent.verticalCenter
              width: 48; height: 48
              enabled: root.player && root.player.canTogglePlaying
              onClicked: root.player.togglePlaying()
              Accessible.name: "Play or pause"
              Controls.ToolTip.visible: hovered
              Controls.ToolTip.delay: 650
              Controls.ToolTip.text: Accessible.name
              opacity: enabled ? 1 : 0.35
              scale: down ? 0.9 : 1
              Behavior on scale { NumberAnimation { duration: 90 } }
              background: Rectangle { radius: Theme.cornerRadius; color: parent.down ? Qt.darker(playerSlot.albumAccent, 1.12) : parent.hovered ? Qt.lighter(playerSlot.albumAccent, 1.10) : playerSlot.albumAccent; Behavior on color { ColorAnimation { duration: 120 } } }
              contentItem: TransportIcon { source: Qt.resolvedUrl(root.playing ? "../assets/pause.svg" : "../assets/play.svg"); iconColor: playerSlot.albumAccentInk }
            }
            Controls.Button {
              anchors.verticalCenter: parent.verticalCenter
              width: 40; height: 40
              enabled: root.player && root.player.canGoNext
              onClicked: root.player.next()
              Accessible.name: "Next track"
              Controls.ToolTip.visible: hovered
              Controls.ToolTip.delay: 650
              Controls.ToolTip.text: Accessible.name
              opacity: enabled ? 1 : 0.35
              scale: down ? 0.9 : 1
              Behavior on scale { NumberAnimation { duration: 90 } }
              background: Rectangle { radius: Theme.cornerRadius; color: parent.hovered ? Qt.rgba(playerSlot.albumInk.r, playerSlot.albumInk.g, playerSlot.albumInk.b, 0.10) : "transparent" }
              contentItem: TransportIcon { source: Qt.resolvedUrl("../assets/next.svg"); iconColor: parent.enabled ? playerSlot.albumInk : playerSlot.albumInkMuted }
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          z: 20
          acceptedButtons: Qt.RightButton
          onPressed: function(mouse) {
            const point = mapToItem(playerSlot, mouse.x, mouse.y)
            playerMenu.popup(point.x, point.y)
            mouse.accepted = true
          }
        }

        WidgetMenu {
          id: playerMenu
          surfaceColor: playerSlot.albumSurface
          hoverColor: playerSlot.albumSurfaceRaised
          textColor: playerSlot.albumInk
          mutedTextColor: playerSlot.albumInkMuted
          accentColor: playerSlot.albumAccent
          borderColor: playerSlot.albumBorder
          separatorColor: playerSlot.albumBorder
          WidgetMenuItem {
            menuColors: playerMenu
            text: root.playing ? "Pause playback" : "Play"
            enabled: root.present && root.player.canTogglePlaying
            onTriggered: root.player.togglePlaying()
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Previous track"
            enabled: root.present && root.player.canGoPrevious
            onTriggered: root.player.previous()
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Next track"
            enabled: root.present && root.player.canGoNext
            onTriggered: root.player.next()
          }
          WidgetMenuSeparator { menuColors: playerMenu }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Lock position and size"
            checkable: true
            checked: root.locked
            onTriggered: root.locked = checked
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Keep above windows"
            checkable: true
            checked: root.alwaysOnTop
            onTriggered: root.alwaysOnTop = checked
          }
          WidgetMenuSeparator { menuColors: playerMenu }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Horizontal layout"
            checkable: true
            checked: root.playerLayout === "horizontal"
            onTriggered: root.playerLayout = "horizontal"
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Vertical layout"
            checkable: true
            checked: root.playerLayout === "vertical"
            onTriggered: root.playerLayout = "vertical"
          }
          WidgetMenuSeparator { menuColors: playerMenu }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "No artwork"
            checkable: true
            checked: WidgetState.playerArtworkStyle === "none"
            onTriggered: WidgetState.playerArtworkStyle = "none"
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Square album artwork"
            checkable: true
            checked: WidgetState.playerArtworkStyle === "square"
            onTriggered: WidgetState.playerArtworkStyle = "square"
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Poster artwork"
            checkable: true
            checked: WidgetState.playerArtworkStyle === "poster"
            onTriggered: WidgetState.playerArtworkStyle = "poster"
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Spinning CD artwork"
            checkable: true
            checked: WidgetState.playerArtworkStyle === "cd"
            onTriggered: WidgetState.playerArtworkStyle = "cd"
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Spinning vinyl artwork"
            checkable: true
            checked: WidgetState.playerArtworkStyle === "vinyl"
            onTriggered: WidgetState.playerArtworkStyle = "vinyl"
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Cassette artwork"
            checkable: true
            checked: WidgetState.playerArtworkStyle === "cassette"
            onTriggered: WidgetState.playerArtworkStyle = "cassette"
          }
          WidgetMenuSeparator { menuColors: playerMenu }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Visualizer: " + root.visualizerStyle
            hint: "V"
            onTriggered: root.cycleVisualizer()
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Show lyrics"
            hint: "L"
            checkable: true
            checked: root.lyricsEnabled
            onTriggered: root.lyricsEnabled = checked
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Visualizer off"
            checkable: true
            checked: root.visualizerStyle === "Off"
            onTriggered: root.visualizerStyle = checked ? "Off" : "Rounded"
          }
          WidgetMenuItem {
            menuColors: playerMenu
            text: "Reset position"
            enabled: !root.locked
            onTriggered: { root.widgetX = 52; root.widgetY = 52 }
          }
          WidgetMenuSeparator { menuColors: playerMenu }
          WidgetMenuItem {
            menuColors: playerMenu; text: "Hide widget"; onTriggered: root.close() }
        }
      }
    }
  }
}
