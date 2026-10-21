import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../bar" as Bar
import "../shared/"
import "../widgets" as DesktopWidgets

Scope {
  id: root

  Component.onCompleted: Quickshell.execDetached(["atlas", "settings", "rollback-all"])

  property bool opened: false
  property bool loading: false
  property bool saving: false
  property string currentSection: "system"
  property string operation: ""
  property string pendingJson: ""
  property var previewQueue: []
  property string previewPendingSection: ""
  property string previewPendingJson: ""
  property string previewStdin: ""
  property string previewRunningCommand: ""
  property string previewRunningSection: ""
  property string saveAfterPreview: ""
  property string statusMessage: ""
  property bool statusError: false
  property var sections: ({})
  property var originalSections: ({})
  property var sectionErrors: ({})
  property var dirtySections: ({})
  property var detectedMonitors: []
  property var detectedFonts: []
  property var detectedCursorThemes: []
  property string applicationSearch: ""
  property var applicationPackages: []
  property var selectedApplication: null
  property var installingApplication: null
  property var installedApplications: ({})
  property string applicationActionVerb: ""
  property string applicationPreview: ""
  property bool applicationsLoading: false
  property bool applicationActionRunning: false
  property string applicationsError: ""
  property string fontSearch: ""
  property var keyboardLayouts: []
  property string keyboardCatalogError: ""
  property bool keyboardCatalogLoading: false
  property var timezones: []
  property bool timezonesLoading: false
  property string timezoneError: ""
  property var appearanceWallpapers: []
  property int appearanceWallpaperPage: 1
  readonly property int appearanceWallpaperPageSize: 12
  property bool appearanceWallpapersLoading: false
  property string appearanceWallpaperError: ""
  property var wallhavenWallpapers: []
  property bool wallhavenLoading: false
  property bool wallhavenDownloading: false
  property string wallhavenError: ""
  property string wallhavenQuery: ""
  property int wallhavenPage: 1
  property int wallhavenLastPage: 1
  readonly property int wallhavenPageSize: 12
  property int wallhavenTotal: 0
  property string wallhavenSorting: "toplist"
  property string wallhavenTopRange: "1M"
  property string wallhavenCategories: "111"
  property string wallhavenPurity: "100"
  property string wallhavenMinimumResolution: "1920x1080"
  property int queuedWallhavenPage: -1
  property string pendingWallhavenPath: ""
  property string onlineWallpaperSource: "openverse"
  property string wallpaperSource: "wallhaven"
  property string onlineWallpaperQuery: "nature"
  property var onlineWallpapers: []
  property bool onlineWallpapersLoading: false
  property bool onlineWallpaperDownloading: false
  property string onlineWallpaperError: ""
  property int onlineWallpaperPage: 1
  property int onlineWallpaperPageCount: 1
  property string pendingOnlineWallpaperPath: ""
  property bool wallpaperApplying: false
  property string pendingWallpaperDirectory: ""
  property bool rebuildRequired: false
  property string themeCreationName: "my-theme"
  property bool themeCreating: false
  property string scriptActionLabel: ""
  property string pendingCursorPreviewTheme: ""
  property int pendingCursorPreviewSize: 0
  property string appliedCursorPreviewTheme: ""
  property int appliedCursorPreviewSize: 0
  property string runningCursorPreviewTheme: ""
  property int runningCursorPreviewSize: 0
  property var themeCreationColors: ({
    background: "#282828", surface: "#282828", surface_hover: "#3c3836",
    foreground: "#d4be98", foreground_muted: "#a89984", border: "#3c3836",
    accent: "#7daea3", selection_background: "#d65d0e",
    selection_foreground: "#1a1814", cursor: "#bdae93", error: "#ea6962",
    warning: "#d8a657", success: "#a9b665", info: "#89b482"
  })

  readonly property var pages: [
    { key: "system", label: "System", symbol: "󰒓" },
    { key: "scripts", label: "Atlas", symbol: "󰆍" },
    { key: "applications", label: "Applications", symbol: "󰀻" },
    { key: "displays", label: "Displays", symbol: "󰍹" },
    { key: "audio", label: "Audio", symbol: "󰕾" },
    { key: "input", label: "Input", symbol: "󰌌" },
    { key: "power", label: "Power", symbol: "󰐥" },
    { key: "internet", label: "Internet", symbol: "󰖩" },
    { key: "bluetooth", label: "Bluetooth", symbol: "󰂯" },
    { key: "themes", label: "Themes", symbol: "󰏘" },
    { key: "appearance", label: "Appearance", symbol: "󰛨" },
    { key: "wallpaper", label: "Wallpapers", symbol: "󰸉" },
    { key: "fonts", label: "Fonts", symbol: "󰛖" },
    { key: "cursor", label: "Cursor", symbol: "󰇀" },
    { key: "widgets", label: "Widgets", symbol: "󰄉" }
  ]

  readonly property var navigationItems: [
    { type: "category", label: "System" },
    { type: "page", key: "system", label: "System", symbol: "󰒓" },
    { type: "page", key: "scripts", label: "Atlas", symbol: "󰆍" },
    { type: "page", key: "applications", label: "Applications", symbol: "󰀻" },
    { type: "category", label: "Hardware" },
    { type: "page", key: "displays", label: "Displays", symbol: "󰍹" },
    { type: "page", key: "audio", label: "Audio", symbol: "󰕾" },
    { type: "page", key: "input", label: "Input", symbol: "󰌌" },
    { type: "page", key: "power", label: "Power", symbol: "󰐥" },
    { type: "category", label: "Network" },
    { type: "page", key: "internet", label: "Internet", symbol: "󰖩" },
    { type: "page", key: "bluetooth", label: "Bluetooth", symbol: "󰂯" },
    { type: "category", label: "Appearance" },
    { type: "page", key: "themes", label: "Themes", symbol: "󰏘" },
    { type: "page", key: "appearance", label: "Appearance", symbol: "󰛨" },
    { type: "page", key: "wallpaper", label: "Wallpapers", symbol: "󰸉" },
    { type: "page", key: "fonts", label: "Fonts", symbol: "󰛖" },
    { type: "page", key: "cursor", label: "Cursor", symbol: "󰇀" },
    { type: "category", label: "Widgets" },
    { type: "page", key: "widgets", label: "Widgets", symbol: "󰄉" }
  ]

  function clone(value) {
    return JSON.parse(JSON.stringify(value))
  }

  function open() {
    opened = true
    refresh()
    loadTimezones()
    Qt.callLater(focusCurrentPage)
  }

  function syncSystemView() {
    let section = ""
    if (currentSection === "internet")
      section = Bar.SystemState.internetSection
    else if (currentSection === "bluetooth")
      section = Bar.SystemState.bluetoothSection
    Bar.SystemState.updateView(root, opened && section !== "", section)
  }

  onOpenedChanged: syncSystemView()

  function close() {
    if (originalSections.system !== undefined)
      previewCursor(originalSections.system.cursorTheme, originalSections.system.cursorSize)
    previewTimer.stop()
    previewQueue = [{ command: "rollback-all", section: "", json: "" }]
    saveAfterPreview = ""
    pumpPreviewQueue()
    opened = false
  }

  function toggle() {
    if (opened)
      close()
    else
      open()
  }

  function currentPageIndex() {
    for (let index = 0; index < pages.length; ++index) {
      if (pages[index].key === currentSection)
        return index
    }
    return 0
  }

  function focusCurrentPage() {
    for (let index = 0; index < categoryRepeater.count; ++index) {
      const item = categoryRepeater.itemAt(index)
      if (item && item.pageKey === currentSection) {
        const flickable = categoryScroll
        if (flickable && flickable.contentHeight > flickable.height) {
          const targetY = Math.max(0, Math.min(item.y - Theme.spaceSm,
            flickable.contentHeight - flickable.height))
          flickable.contentY = targetY
        }
        item.pageButtonItem.forceActiveFocus()
        return
      }
    }
  }

  function selectPage(index) {
    const boundedIndex = Math.max(0, Math.min(index, pages.length - 1))
    currentSection = pages[boundedIndex].key
    syncSystemView()
    statusMessage = ""
    Qt.callLater(focusCurrentPage)
    if (currentSection === "appearance" || currentSection === "wallpaper") {
      Qt.callLater(loadAppearanceWallpapers)
      if (wallhavenWallpapers.length === 0)
        Qt.callLater(loadWallhaven)
    }
    if (currentSection === "applications" && applicationPackages.length === 0)
      Qt.callLater(loadApplications)
    if (currentSection === "applications")
      Qt.callLater(loadInstalledApplications)
  }

  function openSection(section) {
    for (let index = 0; index < pages.length; ++index) {
      if (pages[index].key === section) {
        open()
        selectPage(index)
        return
      }
    }
  }

  function selectSection(section) {
    if (section === "layout")
      section = "appearance"
    for (let index = 0; index < pages.length; ++index) {
      if (pages[index].key === section) {
        selectPage(index)
        return
      }
    }
  }

  function cyclePage(offset) {
    const index = (currentPageIndex() + offset + pages.length) % pages.length
    selectPage(index)
  }

  function focusSettingsOption(forward) {
    let item = window.activeFocusItem
    for (let count = 0; item && count < 100; ++count) {
      item = item.nextItemInFocusChain(forward)
      if (!item)
        return
      if (item.categoryNavigationButton === true)
        continue
      item.forceActiveFocus()
      return
    }
  }

  function refresh() {
    if (backend.running)
      return
    loading = true
    statusMessage = ""
    operation = "read"
    backend.exec(["atlas", "settings", "read"])
  }

  function sectionAvailable(section) {
    const source = dataSection(section)
    return sections[source] !== undefined && sectionErrors[source] === undefined
  }

  function dataSection(section) {
    if (section === "fonts" || section === "cursor" || section === "scripts")
      return "system"
    if (section === "layout" || section === "themes")
      return "appearance"
    if (section === "wallpaper")
      return "appearance"
    return section
  }

  function value(section, key, fallback) {
    const source = dataSection(section)
    if (!sectionAvailable(section) || sections[source][key] === undefined)
      return fallback
    return sections[source][key]
  }

  function setValue(section, key, value) {
    const source = dataSection(section)
    if (!sectionAvailable(section))
      return
    const next = clone(sections)
    next[source][key] = value
    sections = next
    const dirty = clone(dirtySections)
    dirty[source] = JSON.stringify(next[source]) !== JSON.stringify(originalSections[source])
    dirtySections = dirty
    if (source === "appearance" || source === "input" || source === "displays") {
      previewPendingSection = source
      previewPendingJson = JSON.stringify(next[source]) + "\n"
      previewTimer.restart()
    }
  }

  function enqueuePreview(section, json) {
    const queue = []
    for (let index = 0; index < previewQueue.length; ++index) {
      const item = previewQueue[index]
      if (!(item.command === "preview" && item.section === section))
        queue.push(item)
    }
    queue.push({ command: "preview", section: section, json: json })
    previewQueue = queue
    pumpPreviewQueue()
  }

  function enqueueRollback(section) {
    previewTimer.stop()
    const queue = []
    for (let index = 0; index < previewQueue.length; ++index) {
      const item = previewQueue[index]
      if (!(item.command === "preview" && item.section === section))
        queue.push(item)
    }
    queue.push({ command: "rollback", section: section, json: "" })
    previewQueue = queue
    pumpPreviewQueue()
  }

  function pumpPreviewQueue() {
    if (previewBackend.running)
      return
    if (previewQueue.length === 0) {
      if (saveAfterPreview !== "") {
        const section = saveAfterPreview
        saveAfterPreview = ""
        performSave(section)
      }
      return
    }
    const queue = previewQueue.slice()
    const item = queue.shift()
    previewQueue = queue
    previewRunningCommand = item.command
    previewRunningSection = item.section
    previewStdin = item.json
    const command = ["atlas", "settings", item.command]
    if (item.section !== "")
      command.push(item.section)
    previewBackend.exec(command)
  }

  function moduleDescription(module) {
    const descriptions = {
      bluetooth: "Bluetooth hardware support and the Blueman device manager.",
      development: "Development tools and languages for coding workflows.",
      media: "Media playback, recording, and related desktop integrations.",
      productivity: "Productivity applications and everyday work tools.",
      laptop: "Laptop power, battery, and hardware-specific behavior.",
      nvidia: "NVIDIA drivers and graphics support for compatible hardware."
    }
    return descriptions[module] || "Optional Atlas system integration."
  }

  function updateMonitor(index, key, value) {
    const monitors = clone(root.value("displays", "monitors", []))
    if (index < 0 || index >= monitors.length)
      return
    monitors[index][key] = value
    setValue("displays", "monitors", monitors)
  }

  function previewCursor(theme, size) {
    pendingCursorPreviewTheme = theme
    pendingCursorPreviewSize = size
    if (!cursorPreviewProcess.running) {
      runningCursorPreviewTheme = theme
      runningCursorPreviewSize = size
      cursorPreviewProcess.exec(["hyprctl", "setcursor", theme, String(size)])
    }
  }

  function runScript(label, command) {
    if (scriptProcess.running)
      return
    scriptActionLabel = label
    statusError = false
    statusMessage = "Running " + label + "…"
    scriptProcess.exec(command)
  }

  function loadApplications() {
    if (applicationCatalogProcess.running)
      return
    applicationsLoading = true
    applicationsError = ""
    applicationCatalogProcess.exec([
      "timeout", "15s", "nix", "eval", "--offline",
      "nixpkgs#legacyPackages.x86_64-linux", "--apply", "builtins.attrNames",
      "--json"
    ])
  }

  function applicationName(entry) {
    return entry && entry.attr ? entry.attr : ""
  }

  function loadInstalledApplications() {
    if (!applicationProfileProcess.running)
      applicationProfileProcess.exec(["atlas", "settings", "applications"])
  }

  function applicationProfileName(entry) {
    if (!entry || !entry.attr)
      return ""
    const installed = installedApplications[entry.attr]
    return installed ? installed.profileName : ""
  }

  function isApplicationInstalled(entry) {
    return applicationProfileName(entry) !== ""
  }

  function installedApplicationEntries() {
    return Object.keys(installedApplications).sort().map(function(attribute) {
      const installed = installedApplications[attribute]
      return {
        attr: attribute,
        profileName: installed.profileName,
        icon: installed.icon || ""
      }
    })
  }

  function filteredApplications() {
    const terms = applicationSearch.trim().toLowerCase().split(/\s+/)
      .filter(function(term) { return term !== "" })
    if (terms.length === 0)
      return []
    return applicationPackages.filter(function(entry) {
      const name = entry.attr.toLowerCase()
      return terms.every(function(term) { return name.indexOf(term) !== -1 })
    }).slice(0, 80)
  }

  function selectApplication(entry) {
    selectedApplication = entry
    applicationPreview = "Loading package details…"
    applicationMetadataProcess.exec([
      "timeout", "10s", "nix", "eval", "--offline", "--json", "--apply",
      "p: let m = p.meta or {}; l = m.license or {}; licenseName = x: if builtins.isString x then x else x.fullName or x.spdxId or x.shortName or \"\"; in { name = p.pname or p.name or \"\"; version = p.version or \"\"; description = m.description or \"\"; homepage = if builtins.isList (m.homepage or \"\") then builtins.concatStringsSep \", \" m.homepage else m.homepage or \"\"; license = if builtins.isList l then builtins.concatStringsSep \", \" (map licenseName l) else licenseName l; mainProgram = m.mainProgram or \"\"; platforms = m.platforms or []; }",
      "nixpkgs#" + entry.attr
    ])
  }

  function useApplication() {
    const name = applicationName(selectedApplication)
    if (name === "") return
    applicationLaunchProcess.exec([
      "kitty", "--detach", "env", "NIXPKGS_ALLOW_UNFREE=1",
      "nix", "shell", "--impure", "nixpkgs#" + name
    ])
  }

  function installApplication() {
    const name = applicationName(selectedApplication)
    if (name === "" || applicationInstallProcess.running) return
    installingApplication = selectedApplication
    applicationActionVerb = "install"
    applicationActionRunning = true
    statusError = false
    statusMessage = "Installing " + name + "…"
    applicationInstallProcess.exec([
      "env", "NIXPKGS_ALLOW_UNFREE=1", "nix", "profile", "add",
      "--impure", "nixpkgs#" + name
    ])
  }

  function removeApplication(entry) {
    const target = entry || selectedApplication
    const profileName = entry && entry.profileName
      ? entry.profileName : applicationProfileName(target)
    if (profileName === "" || applicationInstallProcess.running) return
    installingApplication = target
    applicationActionVerb = "remove"
    applicationActionRunning = true
    statusError = false
    statusMessage = "Removing " + applicationName(target) + "…"
    applicationInstallProcess.exec(["nix", "profile", "remove", profileName])
  }

  function removeMonitor(index) {
    const monitors = clone(value("displays", "monitors", []))
    if (monitors.length <= 1)
      return
    monitors.splice(index, 1)
    setValue("displays", "monitors", monitors)
  }

  function addMonitor() {
    const monitors = clone(value("displays", "monitors", []))
    let output = ""
    for (let i = 0; i < detectedMonitors.length; ++i) {
      const candidate = detectedMonitors[i].name || ""
      if (!monitors.some(function(item) { return item.output === candidate })) {
        output = candidate
        break
      }
    }
    monitors.push({ output: output, mode: "preferred", position: "auto", scale: "1" })
    setValue("displays", "monitors", monitors)
  }

  function detectedMonitor(output) {
    for (let index = 0; index < detectedMonitors.length; ++index) {
      if ((detectedMonitors[index].name || "") === output)
        return detectedMonitors[index]
    }
    return null
  }

  function appendUnique(values, value) {
    if (values.indexOf(value) === -1)
      values.push(value)
  }

  function monitorOutputOptions(current, ruleIndex) {
    const options = [""]
    const rules = value("displays", "monitors", [])
    for (let index = 0; index < detectedMonitors.length; ++index) {
      const output = detectedMonitors[index].name || ""
      const alreadyUsed = rules.some(function(rule, index) {
        return index !== ruleIndex && rule.output === output
      })
      if (!alreadyUsed)
        appendUnique(options, output)
    }
    if (current !== "")
      appendUnique(options, current)
    return options
  }

  function monitorModeOptions(output, current) {
    const options = ["preferred"]
    const monitor = detectedMonitor(output)
    if (monitor && Array.isArray(monitor.modes)) {
      for (let index = 0; index < monitor.modes.length; ++index)
        appendUnique(options, monitor.modes[index])
    }
    if (current !== "")
      appendUnique(options, current)
    return options
  }

  function monitorScaleOptions(current) {
    const options = ["1", "1.25", "1.5", "1.75", "2"]
    if (current !== "")
      appendUnique(options, current)
    return options
  }

  function monitorPreviewGeometry(rule, index) {
    const detected = detectedMonitor(rule.output)
    let width = detected ? Number(detected.width) : 1920
    let height = detected ? Number(detected.height) : 1080
    const modeMatch = String(rule.mode || "").match(/^(\d+)x(\d+)/)
    if (modeMatch) {
      width = Number(modeMatch[1])
      height = Number(modeMatch[2])
    }
    const scale = Math.max(0.25, Number(rule.scale) || (detected ? Number(detected.scale) : 1) || 1)
    width /= scale
    height /= scale
    const positionMatch = String(rule.position || "").match(/^(-?\d+)x(-?\d+)$/)
    return {
      x: positionMatch ? Number(positionMatch[1]) : (detected ? Number(detected.x) : index * width),
      y: positionMatch ? Number(positionMatch[2]) : (detected ? Number(detected.y) : 0),
      width: width,
      height: height
    }
  }

  function monitorArrangementRules() {
    const configured = value("displays", "monitors", [])
    const result = []
    for (let i = 0; i < configured.length; ++i) {
      if (configured[i].output !== "")
        result.push(configured[i])
    }
    for (let i = 0; i < detectedMonitors.length; ++i) {
      const output = detectedMonitors[i].name || ""
      if (output === "" || result.some(function(rule) { return rule.output === output }))
        continue
      result.push({
        output: output,
        mode: "preferred",
        position: Number(detectedMonitors[i].x || 0) + "x" + Number(detectedMonitors[i].y || 0),
        scale: String(detectedMonitors[i].scale || 1)
      })
    }
    return result
  }

  function updateMonitorPosition(output, position) {
    const monitors = clone(value("displays", "monitors", []))
    for (let i = 0; i < monitors.length; ++i) {
      if (monitors[i].output === output) {
        monitors[i].position = position
        setValue("displays", "monitors", monitors)
        return
      }
    }
    const detected = detectedMonitor(output)
    monitors.unshift({
      output: output,
      mode: "preferred",
      position: position,
      scale: String(detected && detected.scale ? detected.scale : 1)
    })
    setValue("displays", "monitors", monitors)
  }

  function snapMonitorPosition(output, x, y) {
    const rules = monitorArrangementRules()
    let movingRule = null
    for (let i = 0; i < rules.length; ++i) {
      if (rules[i].output === output) {
        movingRule = rules[i]
        break
      }
    }
    if (!movingRule)
      return { x: x, y: y }
    const moving = monitorPreviewGeometry(movingRule, 0)
    let bestDistance = Number.MAX_VALUE
    let snappedX = x
    let snappedY = y

    for (let i = 0; i < rules.length; ++i) {
      if (rules[i].output === output)
        continue
      const other = monitorPreviewGeometry(rules[i], i)
      const candidates = [
        { x: other.x + other.width, y: other.y },
        { x: other.x - moving.width, y: other.y },
        { x: other.x, y: other.y + other.height },
        { x: other.x, y: other.y - moving.height }
      ]
      for (let candidateIndex = 0; candidateIndex < candidates.length; ++candidateIndex) {
        const candidate = candidates[candidateIndex]
        const distance = Math.hypot(x - candidate.x, y - candidate.y)
        if (distance < bestDistance) {
          bestDistance = distance
          snappedX = candidate.x
          snappedY = candidate.y
        }
      }
    }
    return { x: Math.round(snappedX), y: Math.round(snappedY) }
  }

  function powerTimeoutLabel(value) {
    const seconds = Number(value)
    if (seconds === 0) return "Never"
    if (seconds < 60) return seconds + " seconds"
    const minutes = seconds / 60
    if (minutes < 60) return minutes + (minutes === 1 ? " minute" : " minutes")
    const hours = minutes / 60
    return hours + (hours === 1 ? " hour" : " hours")
  }

  function wallpaperDirectory() {
    const configured = value("appearance", "wallpaperDirectory", "")
    return configured !== "" ? configured
      : Quickshell.env("HOME") + "/Pictures/wallpapers"
  }

  function wallpaperImageSource(path) {
    return "file://" + path.split("/").map(encodeURIComponent).join("/")
  }

  function loadAppearanceWallpapers() {
    if (!sectionAvailable("appearance") || wallpaperListProcess.running)
      return
    appearanceWallpapersLoading = true
    appearanceWallpaperError = ""
    wallpaperListProcess.exec([
      "find", wallpaperDirectory(), "-type", "f", "(",
      "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o",
      "-iname", "*.png", "-o", "-iname", "*.webp", ")"
    ])
  }

  function appearanceWallpaperPageCount() {
    return Math.max(1, Math.ceil(appearanceWallpapers.length
      / appearanceWallpaperPageSize))
  }

  function appearanceWallpaperPageItems() {
    const pageCount = appearanceWallpaperPageCount()
    const page = Math.max(1, Math.min(appearanceWallpaperPage, pageCount))
    const start = (page - 1) * appearanceWallpaperPageSize
    return appearanceWallpapers.slice(start, start + appearanceWallpaperPageSize)
  }

  function loadWallhaven(page) {
    const requestedPage = Math.max(1, page || 1)
    if (wallhavenProcess.running) {
      queuedWallhavenPage = requestedPage
      wallhavenLoading = true
      return
    }
    wallhavenPage = requestedPage
    wallhavenLoading = true
    wallhavenError = ""
    if (requestedPage === 1) {
      wallhavenWallpapers = []
      wallhavenTotal = 0
    }
    const url = "https://wallhaven.cc/api/v1/search?categories="
      + encodeURIComponent(wallhavenCategories)
      + "&purity=" + encodeURIComponent(wallhavenPurity)
      + "&sorting=" + encodeURIComponent(wallhavenSorting)
      + "&topRange=" + encodeURIComponent(wallhavenTopRange)
      + "&atleast=" + encodeURIComponent(wallhavenMinimumResolution)
      + "&per_page=12&page="
      + wallhavenPage + "&q=" + encodeURIComponent(wallhavenQuery.trim())
    wallhavenProcess.exec(["wget", "-qO-", url])
  }

  function useWallhavenWallpaper(wallpaper) {
    if (wallhavenDownloadProcess.running)
      return
    let extension = wallpaper.file_type === "image/png" ? ".png"
      : (wallpaper.file_type === "image/webp" ? ".webp" : ".jpg")
    pendingWallhavenPath = wallpaperDirectory() + "/wallhaven-"
      + wallpaper.id + extension
    wallhavenDownloading = true
    wallhavenError = ""
    wallhavenDownloadProcess.exec([
      "sh", "-c", "mkdir -p \"$1\" && wget -q -O \"$2\" \"$3\"",
      "wallhaven-download", wallpaperDirectory(), pendingWallhavenPath,
      wallpaper.path
    ])
  }

  function loadOnlineWallpapers(page) {
    if (onlineWallpaperProcess.running)
      return
    onlineWallpaperPage = Math.max(1, page || 1)
    onlineWallpapersLoading = true
    onlineWallpaperError = ""
    let url = ""
    if (onlineWallpaperSource === "openverse") {
      url = "https://api.openverse.org/v1/images/?page_size=12&mature=false"
        + "&license_type=all-cc&page=" + onlineWallpaperPage
        + "&q=" + encodeURIComponent(onlineWallpaperQuery.trim() || "nature")
    } else if (onlineWallpaperSource === "wikimedia") {
      const offset = (onlineWallpaperPage - 1) * 12
      url = "https://commons.wikimedia.org/w/api.php?action=query&format=json"
        + "&formatversion=2&generator=search&gsrnamespace=6&gsrlimit=12"
        + "&gsroffset=" + offset + "&prop=imageinfo"
        + "&iiprop=url%7Csize%7Cmime%7Cextmetadata"
        + "&iiextmetadatafilter=Artist%7CLicenseShortName"
        + "&iiurlwidth=640&origin=*&gsrsearch="
        + encodeURIComponent((onlineWallpaperQuery.trim() || "nature") + " filetype:bitmap")
    } else {
      url = "https://science.nasa.gov/wp-json/wp/v2/apod-basic?per_page=12&page="
        + onlineWallpaperPage
    }
    onlineWallpaperProcess.exec([
      "wget", "-qO-", "--user-agent=Atlas-Wallpapers/1.0", url
    ])
  }

  function useOnlineWallpaper(wallpaper) {
    if (onlineWallpaperDownloadProcess.running)
      return
    const sourceUrl = wallpaper.downloadUrl || wallpaper.previewUrl
    const cleanUrl = sourceUrl.split("?")[0]
    let extension = cleanUrl.substring(cleanUrl.lastIndexOf("."))
    if ([".jpg", ".jpeg", ".png", ".webp"].indexOf(extension.toLowerCase()) === -1)
      extension = ".jpg"
    const safeId = String(wallpaper.id || Date.now()).replace(/[^A-Za-z0-9_-]/g, "-")
    pendingOnlineWallpaperPath = wallpaperDirectory() + "/"
      + onlineWallpaperSource + "-" + safeId + extension
    onlineWallpaperDownloading = true
    onlineWallpaperError = ""
    onlineWallpaperDownloadProcess.exec([
      "wget", "-q", "--user-agent=Atlas-Wallpapers/1.0", "-O",
      pendingOnlineWallpaperPath, sourceUrl
    ])
  }

  function plainMetadata(value) {
    return String(value || "").replace(/<[^>]*>/g, " ")
      .replace(/&amp;/g, "&").replace(/&quot;/g, "\"")
      .replace(/&#39;/g, "'").replace(/\s+/g, " ").trim()
  }

  function applyWallpaper(path) {
    if (wallpaperApplyProcess.running)
      return
    wallpaperApplying = true
    appearanceWallpaperError = ""
    statusError = false
    statusMessage = value("appearance", "wallpaperTheme", false)
      ? "Creating theme from wallpaper…" : "Applying wallpaper…"
    wallpaperApplyProcess.exec([
      "wallpaper-set", "--directory", wallpaperDirectory(), path
    ])
  }

  function setThemeColorValue(key, value) {
    if (!/^#[0-9A-Fa-f]{6}$/.test(value))
      return
    const next = Object.assign({}, themeCreationColors)
    next[key] = value.toLowerCase()
    themeCreationColors = next
  }

  function validThemeName(name) {
    return /^[A-Za-z0-9][A-Za-z0-9_-]{0,31}$/.test(name.trim())
  }

  function applyThemePalette(name) {
    const palettes = {
      graphite: {
        background: "#17191c", surface: "#22252a", surface_hover: "#2d3138",
        foreground: "#e5e7eb", foreground_muted: "#9ca3af", border: "#3f4652",
        accent: "#7aa2f7", selection_background: "#3d59a1", selection_foreground: "#ffffff",
        cursor: "#c0caf5", error: "#f7768e", warning: "#e0af68", success: "#9ece6a", info: "#7dcfff"
      },
      forest: {
        background: "#18201b", surface: "#222c25", surface_hover: "#2e3a31",
        foreground: "#dce7dd", foreground_muted: "#9aad9d", border: "#405044",
        accent: "#8fbf88", selection_background: "#466b4b", selection_foreground: "#f4fff4",
        cursor: "#b8d8b0", error: "#e67e80", warning: "#dbbc7f", success: "#a7c080", info: "#83c092"
      },
      sunset: {
        background: "#21181d", surface: "#302229", surface_hover: "#402f37",
        foreground: "#f5e6df", foreground_muted: "#bda49e", border: "#5a4148",
        accent: "#f08a72", selection_background: "#9b4d54", selection_foreground: "#fff7f2",
        cursor: "#f4b49d", error: "#ed6a75", warning: "#e6b566", success: "#9fbd73", info: "#78b9c4"
      }
    }
    if (palettes[name] !== undefined)
      themeCreationColors = clone(palettes[name])
  }

  function createTheme() {
    if (themeCreating)
      return
    const name = themeCreationName.trim()
    if (!/^[A-Za-z0-9][A-Za-z0-9_-]{0,31}$/.test(name)) {
      statusError = true
      statusMessage = "Use a theme name with letters, numbers, - or _."
      return
    }
    const colors = themeCreationColors
    themeCreating = true
    statusError = false
    statusMessage = "Creating theme…"
    themeCreateProcess.exec([
      "theme-create", name,
      colors.background, colors.surface, colors.surface_hover,
      colors.foreground, colors.foreground_muted, colors.border,
      colors.accent, colors.selection_background,
      colors.selection_foreground, colors.cursor, colors.error,
      colors.warning, colors.success, colors.info
    ])
  }

  function browseWallpaperDirectory() {
    if (wallpaperFolderCreationProcess.running)
      return
    pendingWallpaperDirectory = wallpaperDirectory()
    appearanceWallpaperError = ""
    wallpaperFolderCreationProcess.exec([
      "mkdir", "-p", pendingWallpaperDirectory
    ])
  }

  function loadTimezones() {
    if (timezones.length > 0 || timezonesLoading || timezoneProcess.running)
      return
    timezonesLoading = true
    timezoneError = ""
    timezoneProcess.exec(["find", "-L", "/etc/zoneinfo", "-type", "f"])
  }

  function timezoneRegion(zone) {
    const separator = zone.indexOf("/")
    return separator > 0 ? zone.substring(0, separator) : "Other"
  }

  function timezoneRegions() {
    const regions = []
    for (let index = 0; index < timezones.length; ++index) {
      const region = timezoneRegion(timezones[index])
      if (regions.indexOf(region) === -1)
        regions.push(region)
    }
    return regions.sort(function(left, right) {
      if (left === "Other") return 1
      if (right === "Other") return -1
      return left.localeCompare(right)
    })
  }

  function timezonesForRegion(region) {
    return timezones.filter(function(zone) {
      return timezoneRegion(zone) === region
    })
  }

  function timezoneLabel(zone) {
    const separator = zone.indexOf("/")
    return (separator >= 0 ? zone.substring(separator + 1) : zone)
      .replace(/_/g, " ")
  }

  function resetSection() {
    const source = dataSection(currentSection)
    if (originalSections[source] === undefined)
      return
    const next = clone(sections)
    next[source] = clone(originalSections[source])
    sections = next
    const dirty = clone(dirtySections)
    dirty[source] = false
    dirtySections = dirty
    if (source === "appearance" || source === "input" || source === "displays")
      enqueueRollback(source)
    statusMessage = (source === "appearance" || source === "input" || source === "displays")
      ? "Preview rolled back" : "Changes discarded"
    statusError = false
    if (currentSection === "cursor")
      Qt.callLater(function() {
        root.previewCursor(root.value("cursor", "cursorTheme", "Adwaita"),
          root.value("cursor", "cursorSize", 24))
      })
    if (currentSection === "appearance")
      Qt.callLater(loadAppearanceWallpapers)
  }

  function saveSection() {
    const source = dataSection(currentSection)
    if (!sectionAvailable(currentSection) || !dirtySections[source]
        || backend.running)
      return
    saving = true
    statusMessage = ""
    if (source === "appearance" || source === "input" || source === "displays") {
      previewTimer.stop()
      saveAfterPreview = source
      enqueuePreview(source, JSON.stringify(sections[source]) + "\n")
      return
    }
    performSave(source)
  }

  function performSave(source) {
    operation = "save:" + source
    pendingJson = JSON.stringify(sections[source]) + "\n"
    backend.exec(["atlas", "settings", "save", source])
  }

  function handleResult(raw, exitCode) {
    let result
    try {
      result = JSON.parse(raw)
    } catch (error) {
      loading = false
      saving = false
      statusError = true
      statusMessage = raw.trim() || "Settings backend returned invalid data"
      return
    }
    if (exitCode !== 0 || result.ok !== true) {
      loading = false
      saving = false
      statusError = true
      statusMessage = result.error || "Settings operation failed"
      return
    }
    if (operation === "read") {
      sections = clone(result.sections || {})
      originalSections = clone(result.sections || {})
      sectionErrors = clone(result.errors || {})
      detectedMonitors = clone(result.detectedMonitors || [])
      detectedFonts = clone(result.detectedFonts || [])
      detectedCursorThemes = clone(result.detectedCursorThemes || [])
      rebuildRequired = result.rebuildRequired === true
      dirtySections = ({})
      loading = false
      statusError = false
      statusMessage = ""
      if (currentSection === "appearance") {
        Qt.callLater(loadAppearanceWallpapers)
        if (wallhavenWallpapers.length === 0)
          Qt.callLater(loadWallhaven)
      }
      return
    }
    const section = operation.substring(5)
    const originals = clone(originalSections)
    originals[section] = clone(sections[section])
    originalSections = originals
    const dirty = clone(dirtySections)
    dirty[section] = false
    dirtySections = dirty
    rebuildRequired = rebuildRequired || result.rebuildRequired === true
    saving = false
    statusError = false
    statusMessage = result.changed === false ? "No changes to save" : "Settings saved"
  }

  IpcHandler {
    target: "settings"
    function open(): void { root.open() }
    function openSection(section: string): void { root.openSection(section) }
    function openBluetooth(): void { root.openSection("bluetooth") }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Process {
    id: backend
    stdinEnabled: true

    stdout: StdioCollector {
      id: output
    }

    stderr: StdioCollector {
      id: errorOutput
    }

    onStarted: {
      if (root.pendingJson !== "") {
        write(root.pendingJson)
        root.pendingJson = ""
      }
    }

    onExited: function(exitCode) {
      const raw = output.text.trim() !== "" ? output.text : errorOutput.text
      root.handleResult(raw, exitCode)
    }
  }

  Timer {
    id: previewTimer
    interval: 140
    repeat: false
    onTriggered: root.enqueuePreview(root.previewPendingSection, root.previewPendingJson)
  }

  Process {
    id: previewBackend
    stdinEnabled: true

    stdout: StdioCollector { id: previewOutput }
    stderr: StdioCollector { id: previewErrorOutput }

    onStarted: {
      if (root.previewStdin !== "") {
        write(root.previewStdin)
        root.previewStdin = ""
      }
    }

    onExited: function(exitCode) {
      const raw = previewOutput.text.trim() !== "" ? previewOutput.text : previewErrorOutput.text
      let result = null
      try {
        result = JSON.parse(raw)
      } catch (error) {
      }
      if (exitCode !== 0 || result === null || result.ok !== true) {
        root.statusError = true
        root.statusMessage = result && result.error
          ? result.error : (raw.trim() || "Could not preview Hyprland settings")
        if (root.saveAfterPreview !== "") {
          root.saveAfterPreview = ""
          root.saving = false
        }
      } else if (root.previewRunningCommand === "preview" && root.opened) {
        root.statusError = false
        root.statusMessage = "Previewing changes — Save to keep them"
      }
      root.previewRunningCommand = ""
      root.previewRunningSection = ""
      root.pumpPreviewQueue()
    }
  }

  Process {
    id: scriptProcess
    stdout: StdioCollector { id: scriptOutput }
    stderr: StdioCollector { id: scriptError }
    onExited: function(exitCode) {
      root.statusError = exitCode !== 0
      const message = exitCode === 0 ? scriptOutput.text.trim() : scriptError.text.trim()
      root.statusMessage = message || (exitCode === 0
        ? root.scriptActionLabel + " completed"
        : root.scriptActionLabel + " failed")
    }
  }

  Process {
    id: applicationCatalogProcess
    stdout: StdioCollector { id: applicationCatalogOutput }
    stderr: StdioCollector { id: applicationCatalogError }
    onExited: function(exitCode) {
      root.applicationsLoading = false
      if (exitCode !== 0) {
        root.applicationPackages = []
        root.applicationsError = exitCode === 124
          ? "Loading the local package catalog timed out."
          : (applicationCatalogError.text.trim() || "Could not load the local package catalog")
        return
      }
      try {
        const result = JSON.parse(applicationCatalogOutput.text)
        root.applicationPackages = result.map(function(attribute) {
          return { attr: attribute, name: attribute, version: "", description: "" }
        })
        root.applicationsError = result.length === 0 ? "No packages found" : ""
      } catch (error) {
        root.applicationPackages = []
        root.applicationsError = "Nix returned an invalid package catalog"
      }
    }
  }

  Process {
    id: applicationMetadataProcess
    stdout: StdioCollector { id: applicationMetadataOutput }
    stderr: StdioCollector { id: applicationMetadataError }
    onExited: function(exitCode) {
      if (root.selectedApplication === null)
        return
      if (exitCode !== 0) {
        root.applicationPreview = applicationMetadataError.text.trim()
          || "No package details available."
        return
      }
      try {
        const details = JSON.parse(applicationMetadataOutput.text)
        root.selectedApplication = {
          attr: root.selectedApplication.attr,
          name: details.name || root.selectedApplication.attr,
          version: details.version || "",
          description: details.description || "",
          homepage: details.homepage || "",
          license: details.license || "",
          mainProgram: details.mainProgram || "",
          platforms: details.platforms || []
        }
        root.applicationPreview = root.selectedApplication.description
          || "No package description available."
      } catch (error) {
        root.applicationPreview = "Nix returned invalid package details."
      }
    }
  }

  Process {
    id: applicationLaunchProcess
    stderr: StdioCollector { id: applicationLaunchError }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.statusError = true
        root.statusMessage = applicationLaunchError.text.trim()
          || "Could not open the temporary package shell"
      }
    }
  }

  Process {
    id: applicationProfileProcess
    stdout: StdioCollector { id: applicationProfileOutput }
    stderr: StdioCollector { id: applicationProfileError }
    onExited: function(exitCode) {
      if (exitCode !== 0)
        return
      try {
        const result = JSON.parse(applicationProfileOutput.text)
        const installed = ({})
        const applications = result.applications || []
        applications.forEach(function(application) {
          if (application.attr)
            installed[application.attr] = {
              profileName: application.profileName,
              icon: application.icon || ""
            }
        })
        root.installedApplications = installed
      } catch (error) {
      }
    }
  }

  Process {
    id: applicationInstallProcess
    stdout: StdioCollector { id: applicationInstallOutput }
    stderr: StdioCollector { id: applicationInstallError }
    onExited: function(exitCode) {
      root.applicationActionRunning = false
      root.statusError = exitCode !== 0
      root.statusMessage = exitCode === 0
        ? root.applicationName(root.installingApplication)
          + (root.applicationActionVerb === "remove"
            ? " removed from this user profile" : " installed for this user")
        : (applicationInstallError.text.trim()
          || (root.applicationActionVerb === "remove"
            ? "Package removal failed" : "Package installation failed"))
      if (exitCode === 0)
        Qt.callLater(root.loadInstalledApplications)
    }
  }

  Process {
    id: cursorPreviewProcess
    onExited: {
      root.appliedCursorPreviewTheme = root.runningCursorPreviewTheme
      root.appliedCursorPreviewSize = root.runningCursorPreviewSize
      if (root.appliedCursorPreviewTheme !== root.pendingCursorPreviewTheme
          || root.appliedCursorPreviewSize !== root.pendingCursorPreviewSize)
        root.previewCursor(root.pendingCursorPreviewTheme, root.pendingCursorPreviewSize)
    }
  }

  Process {
    id: statusProcess
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text)
          if (result.ok === true)
            root.rebuildRequired = result.rebuildRequired === true
        } catch (error) {
        }
      }

    }
  }

  Process {
    id: keyboardCatalogProcess
    stdout: StdioCollector { id: keyboardCatalogOutput }
    onExited: function(exitCode) {
      root.keyboardCatalogLoading = false
      try {
        const data = JSON.parse(keyboardCatalogOutput.text)
        if (exitCode !== 0 || !data.ok || !Array.isArray(data.layouts))
          throw new Error(data.error || "Could not load keyboard layouts")
        root.keyboardLayouts = data.layouts
        root.keyboardCatalogError = ""
      } catch (error) {
        root.keyboardCatalogError = String(error.message || error)
      }
    }
  }

  Process {
    id: timezoneProcess
    stdout: StdioCollector {
      id: timezoneOutput
    }
    stderr: StdioCollector {
      id: timezoneErrorOutput
    }
    onExited: function(exitCode) {
      root.timezonesLoading = false
      if (exitCode !== 0) {
        root.timezoneError = timezoneErrorOutput.text.trim()
          || "Could not load available time zones"
        return
      }
      root.timezones = timezoneOutput.text.split("\n").map(function(path) {
        return path.indexOf("/etc/zoneinfo/") === 0
          ? path.substring(14) : ""
      }).filter(function(zone) {
        if (zone === "" || zone.indexOf("posix/") === 0
            || zone.indexOf("right/") === 0)
          return false
        return ["iso3166.tab", "zone.tab", "zone1970.tab", "leapseconds",
          "leap-seconds.list", "localtime", "posixrules", "tzdata.zi"]
          .indexOf(zone) === -1
      }).sort()
    }
  }

  Process {
    id: wallpaperListProcess
    stdout: StdioCollector { id: wallpaperListOutput }
    stderr: StdioCollector { id: wallpaperListError }
    onExited: function(exitCode) {
      root.appearanceWallpapersLoading = false
      if (exitCode !== 0) {
        root.appearanceWallpapers = []
        root.appearanceWallpaperPage = 1
        root.appearanceWallpaperError = wallpaperListError.text.trim()
          || "Could not read the wallpaper directory"
        return
      }
      root.appearanceWallpaperError = ""
      root.appearanceWallpaperPage = 1
      root.appearanceWallpapers = wallpaperListOutput.text.split("\n")
        .filter(function(path) { return path !== "" }).sort()
    }
  }

  Process {
    id: wallhavenProcess
    stdout: StdioCollector { id: wallhavenOutput }
    stderr: StdioCollector { id: wallhavenErrorOutput }
    onExited: function(exitCode) {
      root.wallhavenLoading = false
      if (exitCode !== 0) {
        root.wallhavenWallpapers = []
        root.wallhavenError = wallhavenErrorOutput.text.trim()
          || "Could not load wallpapers from Wallhaven"
      } else {
        try {
          const response = JSON.parse(wallhavenOutput.text)
          root.wallhavenWallpapers = (response.data || []).slice(
            0, root.wallhavenPageSize)
          root.wallhavenLastPage = Math.max(1,
            response.meta && response.meta.last_page ? response.meta.last_page : 1)
          root.wallhavenTotal = response.meta && response.meta.total
            ? response.meta.total : 0
        } catch (error) {
          root.wallhavenWallpapers = []
          root.wallhavenError = "Wallhaven returned an invalid response"
        }
      }
      if (root.queuedWallhavenPage > 0) {
        const nextPage = root.queuedWallhavenPage
        root.queuedWallhavenPage = -1
        Qt.callLater(function() { root.loadWallhaven(nextPage) })
      }
    }
  }

  Timer {
    id: wallhavenSearchTimer
    interval: 500
    repeat: false
    onTriggered: root.loadWallhaven(1)
  }

  Process {
    id: wallhavenDownloadProcess
    stderr: StdioCollector { id: wallhavenDownloadError }
    onExited: function(exitCode) {
      root.wallhavenDownloading = false
      if (exitCode !== 0) {
        root.wallhavenError = wallhavenDownloadError.text.trim()
          || "Could not download this wallpaper"
        return
      }
      root.loadAppearanceWallpapers()
      root.applyWallpaper(root.pendingWallhavenPath)
    }
  }

  Process {
    id: onlineWallpaperProcess
    stdout: StdioCollector { id: onlineWallpaperOutput }
    stderr: StdioCollector { id: onlineWallpaperErrorOutput }
    onExited: function(exitCode) {
      root.onlineWallpapersLoading = false
      if (exitCode !== 0) {
        root.onlineWallpapers = []
        root.onlineWallpaperError = onlineWallpaperErrorOutput.text.trim()
          || "Could not load wallpapers from this source"
        return
      }
      try {
        const response = JSON.parse(onlineWallpaperOutput.text)
        let images = []
        if (root.onlineWallpaperSource === "openverse") {
          images = (response.results || []).filter(function(item) {
            return item.url && item.thumbnail
          }).map(function(item) {
            return {
              id: item.id, title: item.title || "Openverse image",
              previewUrl: item.thumbnail, downloadUrl: item.url,
              detailUrl: item.foreign_landing_url || item.detail_url,
              credit: item.attribution || item.creator || "Openverse",
              resolution: (item.width || "?") + "×" + (item.height || "?")
            }
          })
          root.onlineWallpaperPageCount = Math.max(1, Number(response.page_count || 1))
        } else if (root.onlineWallpaperSource === "wikimedia") {
          images = (((response.query || {}).pages) || []).map(function(page) {
            const info = (page.imageinfo || [])[0] || {}
            const metadata = info.extmetadata || {}
            const artist = root.plainMetadata((metadata.Artist || {}).value)
            const license = root.plainMetadata((metadata.LicenseShortName || {}).value)
            const credit = [artist, license].filter(function(value) {
              return value !== ""
            }).join(" · ")
            return {
              id: page.pageid, title: String(page.title || "").replace(/^File:/, ""),
              previewUrl: info.thumburl || info.url,
              downloadUrl: (info.responsiveUrls || {})["2"] || info.thumburl || info.url,
              detailUrl: info.descriptionurl || "https://commons.wikimedia.org/?curid=" + page.pageid,
              credit: credit || "Wikimedia Commons",
              resolution: (info.width || "?") + "×" + (info.height || "?")
            }
          }).filter(function(item) { return item.downloadUrl })
          root.onlineWallpaperPageCount = response.continue ? root.onlineWallpaperPage + 1
            : root.onlineWallpaperPage
        } else {
          const entries = Array.isArray(response) ? response : [response]
          images = entries.filter(function(item) {
            return item.media_type === "image" && (item.hdurl || item.url)
          }).map(function(item) {
            return {
              id: item.date, title: item.title || "NASA Astronomy Picture of the Day",
              previewUrl: item.hdurl || item.url, downloadUrl: item.hdurl || item.url,
              detailUrl: item.permalink || item.url,
              credit: root.plainMetadata(item.copyright || item.credit || "NASA APOD"),
              resolution: item.date || "NASA APOD"
            }
          })
          root.onlineWallpaperPageCount = root.onlineWallpaperPage + 1
        }
        root.onlineWallpapers = images.slice(0, 12)
        root.onlineWallpaperError = images.length === 0
          ? "No images were returned" : ""
      } catch (error) {
        root.onlineWallpapers = []
        root.onlineWallpaperError = "This source returned an invalid response"
      }
    }
  }

  Process {
    id: onlineWallpaperDownloadProcess
    stderr: StdioCollector { id: onlineWallpaperDownloadError }
    onExited: function(exitCode) {
      root.onlineWallpaperDownloading = false
      if (exitCode !== 0) {
        root.onlineWallpaperError = onlineWallpaperDownloadError.text.trim()
          || "Could not download this wallpaper"
        return
      }
      root.loadAppearanceWallpapers()
      root.applyWallpaper(root.pendingOnlineWallpaperPath)
    }
  }

  Process {
    id: wallpaperApplyProcess
    stdout: StdioCollector { id: wallpaperApplyOutput }
    stderr: StdioCollector { id: wallpaperApplyError }
    onExited: function(exitCode) {
      root.wallpaperApplying = false
      if (exitCode !== 0) {
        root.appearanceWallpaperError = wallpaperApplyError.text.trim()
          || "Could not apply this wallpaper"
        root.statusError = true
        root.statusMessage = root.appearanceWallpaperError
        return
      }
      root.statusError = false
      root.statusMessage = wallpaperApplyOutput.text.trim()
        || "Wallpaper applied"
    }
  }

  Process {
    id: wallpaperFolderCreationProcess
    stderr: StdioCollector { id: wallpaperFolderCreationError }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.appearanceWallpaperError = wallpaperFolderCreationError.text.trim()
          || "Could not create the wallpaper directory"
        return
      }
      wallpaperFolderDialog.currentFolder = root.wallpaperImageSource(
        root.pendingWallpaperDirectory)
      wallpaperFolderDialog.open()
    }
  }

  Process {
    id: themeCreateProcess
    stdout: StdioCollector { id: themeCreateOutput }
    stderr: StdioCollector { id: themeCreateError }
    onExited: function(exitCode) {
      root.themeCreating = false
      root.statusError = exitCode !== 0
      root.statusMessage = exitCode === 0
        ? (themeCreateOutput.text.trim() || "Theme created and applied")
        : (themeCreateError.text.trim() || "Could not create the theme")
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: root.opened && root.rebuildRequired
    onTriggered: if (!statusProcess.running)
      statusProcess.exec(["atlas", "settings", "status"])
  }

  component SectionTitle: ColumnLayout {
    property string title: ""
    property string description: ""
    Layout.fillWidth: true
    spacing: Theme.spaceSm

    Text {
      text: parent.title
      color: Theme.foreground
      font.pixelSize: Theme.fontDisplay
      font.weight: Theme.weightStrong
    }
    Text {
      Layout.fillWidth: true
      text: parent.description
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontBody
      wrapMode: Text.WordWrap
    }
  }

  component LabeledField: ColumnLayout {
    id: fieldRoot
    property string label: ""
    property string fieldText: ""
    property string placeholder: ""
    property string accessibleName: label
    signal committed(string value)
    Layout.fillWidth: true
    spacing: Theme.spaceXs

    Text {
      text: fieldRoot.label
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
      font.weight: Theme.weightMedium
    }
    TextField {
      Layout.fillWidth: true
      Layout.preferredHeight: 34
      text: fieldRoot.fieldText
      placeholderText: fieldRoot.placeholder
      selectByMouse: true
      color: Theme.foreground
      placeholderTextColor: Theme.foregroundMuted
      font.pixelSize: Theme.fontBody
      leftPadding: Theme.spaceSm
      rightPadding: Theme.spaceSm
      Accessible.name: fieldRoot.accessibleName
      background: Rectangle {
        color: Theme.surfaceHover
        radius: Theme.radiusSm
        border.width: Theme.borderWidth
        border.color: parent.activeFocus ? Theme.accent : Theme.border
      }
      onEditingFinished: fieldRoot.committed(text)
    }
  }

  component ToggleRow: Rectangle {
    id: toggleRoot
    property string label: ""
    property string description: ""
    property bool checked: false
    property bool expandable: false
    property bool expanded: false
    signal changed(bool checked)
    signal expansionChanged(bool expanded)
    Layout.fillWidth: true
    implicitHeight: Math.max(34, toggleLayout.implicitHeight)
      + Theme.spaceXl * 2
    color: Theme.surface
    radius: Theme.radiusLg
    border.width: Theme.borderWidth
    border.color: Theme.border

    RowLayout {
      id: toggleLayout
      anchors.fill: parent
      anchors.margins: Theme.spaceXl
      spacing: Theme.spaceLg

      ColumnLayout {
        spacing: 1
        Text {
          text: toggleRoot.label
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightMedium
        }
        Text {
          visible: text !== ""
          text: toggleRoot.description
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
      }

      Item { Layout.fillWidth: true }

      Text {
        text: toggleRoot.checked ? "On" : "Off"
        color: toggleRoot.checked ? Theme.accent : Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        font.weight: Theme.weightMedium
      }

      Toggle {
        checked: toggleRoot.checked
        accessibleName: toggleRoot.label
        onToggled: function(value) { toggleRoot.changed(value) }
      }

      Button {
        visible: toggleRoot.expandable && toggleRoot.checked
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        horizontalPadding: 0
        buttonColor: hovered ? Theme.surfaceHover : "transparent"
        buttonBorderWidth: 0
        accessibleName: toggleRoot.expanded ? "Collapse options" : "Expand options"
        onClicked: toggleRoot.expansionChanged(!toggleRoot.expanded)

        Canvas {
          anchors.centerIn: parent
          width: 16
          height: 16
          rotation: toggleRoot.expanded ? 180 : 0
          onPaint: {
            const context = getContext("2d")
            context.clearRect(0, 0, width, height)
            context.beginPath()
            context.moveTo(3, 6)
            context.lineTo(8, 11)
            context.lineTo(13, 6)
            context.strokeStyle = Theme.foregroundMuted
            context.lineWidth = 2
            context.lineCap = "round"
            context.lineJoin = "round"
            context.stroke()
          }
          Behavior on rotation {
            NumberAnimation { duration: Theme.motionNormal }
          }
        }
      }
    }
  }

  component NumericRow: Rectangle {
    id: numericRoot
    property string label: ""
    property string description: ""
    property int currentValue: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1
    signal changed(int value)
    Layout.fillWidth: true
    implicitHeight: 34 + Theme.spaceXl * 2
    color: Theme.surface
    radius: Theme.radiusLg
    border.width: Theme.borderWidth
    border.color: Theme.border

    RowLayout {
      anchors.fill: parent
      anchors.margins: Theme.spaceXl
      spacing: Theme.spaceLg

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
          text: numericRoot.label
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightMedium
        }
        Text {
          Layout.fillWidth: true
          text: numericRoot.description
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
          elide: Text.ElideRight
        }
      }

      Rectangle {
        Layout.preferredWidth: 106
        Layout.preferredHeight: 34
        color: Theme.surfaceHover
        radius: Theme.radiusMd
        border.width: Theme.borderWidth
        border.color: numericValueField.activeFocus ? Theme.accent : Theme.border
        clip: true

        RowLayout {
          anchors.fill: parent
          spacing: 0

          TextField {
            id: numericValueField
            Layout.preferredWidth: 40
            Layout.fillHeight: true
            text: String(numericRoot.currentValue)
            color: Theme.foreground
            font.pixelSize: Theme.fontBody
            horizontalAlignment: Text.AlignHCenter
            selectByMouse: true
            validator: IntValidator {
              bottom: numericRoot.from
              top: numericRoot.to
            }
            Accessible.name: numericRoot.label
            onEditingFinished: {
              if (acceptableInput) {
                const value = Number(text)
                numericRoot.changed(value)
                text = String(value)
              } else {
                text = String(numericRoot.currentValue)
              }
            }
            background: Rectangle { color: "transparent" }
            Connections {
              target: numericRoot
              function onCurrentValueChanged() {
                if (!numericValueField.activeFocus)
                  numericValueField.text = String(numericRoot.currentValue)
              }
            }
          }

          Rectangle {
            Layout.preferredWidth: Theme.borderWidth
            Layout.fillHeight: true
            color: Theme.border
          }

          Button {
            Layout.preferredWidth: 32
            Layout.fillHeight: true
            horizontalPadding: 0
            radius: 0
            buttonColor: hovered ? Theme.surface : "transparent"
            buttonBorderWidth: 0
            enabled: numericRoot.currentValue > numericRoot.from
            accessibleName: "Decrease " + numericRoot.label
            onClicked: numericRoot.changed(Math.max(numericRoot.from,
              numericRoot.currentValue - numericRoot.stepSize))
            Text { anchors.centerIn: parent; text: "−"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontTitle }
          }

          Rectangle {
            Layout.preferredWidth: Theme.borderWidth
            Layout.fillHeight: true
            color: Theme.border
          }

          Button {
            Layout.preferredWidth: 32
            Layout.fillHeight: true
            horizontalPadding: 0
            radius: 0
            buttonColor: hovered ? Theme.surface : "transparent"
            buttonBorderWidth: 0
            enabled: numericRoot.currentValue < numericRoot.to
            accessibleName: "Increase " + numericRoot.label
            onClicked: numericRoot.changed(Math.min(numericRoot.to,
              numericRoot.currentValue + numericRoot.stepSize))
            Text { anchors.centerIn: parent; text: "+"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontTitle }
          }
        }
      }
    }
  }

  component ChoiceRow: Rectangle {
    id: choiceRoot
    property string label: ""
    property string description: ""
    property var options: []
    property string selectedValue: ""
    property var optionLabel: function(value) { return value }
    signal chosen(string value)
    Layout.fillWidth: true
    implicitHeight: 34 + Theme.spaceXl * 2
    color: Theme.surface
    radius: Theme.radiusLg
    border.width: Theme.borderWidth
    border.color: Theme.border

    RowLayout {
      anchors.fill: parent
      anchors.margins: Theme.spaceXl
      spacing: Theme.spaceLg

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
          text: choiceRoot.label
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightMedium
        }
        Text {
          Layout.fillWidth: true
          text: choiceRoot.description
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
          elide: Text.ElideRight
        }
      }

      TimezoneDropdown {
        Layout.fillWidth: false
        Layout.preferredWidth: 160
        showLabel: false
        label: choiceRoot.label
        options: choiceRoot.options
        selectedValue: choiceRoot.selectedValue
        optionLabel: choiceRoot.optionLabel
        onChosen: function(value) { choiceRoot.chosen(value) }
      }
    }
  }

  component PositionRow: Rectangle {
    id: positionRoot
    property string label: ""
    property string description: ""
    property string selectedValue: "center"
    signal chosen(string value)
    readonly property var gridPositions: [
      "top-left", "top", "top-right",
      "left", "center", "right",
      "bottom-left", "bottom", "bottom-right"
    ]

    Layout.fillWidth: true
    implicitHeight: 112
    color: Theme.surface
    radius: Theme.radiusLg
    border.width: Theme.borderWidth
    border.color: Theme.border

    RowLayout {
      anchors.fill: parent
      anchors.margins: Theme.spaceXl
      spacing: Theme.spaceXl

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
          text: positionRoot.label
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightMedium
        }
        Text {
          Layout.fillWidth: true
          text: positionRoot.description
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
          wrapMode: Text.Wrap
        }
      }

      Grid {
        columns: 3
        spacing: 5

        Repeater {
          model: positionRoot.gridPositions

          Rectangle {
            required property string modelData
            readonly property bool selected: modelData === positionRoot.selectedValue
            width: 24
            height: 24
            radius: Theme.radiusSm
            color: selected ? Theme.accent
              : (positionCellHover.hovered ? Theme.surfaceHover : Theme.background)
            border.width: selected ? 0 : Theme.borderWidth
            border.color: positionCellHover.hovered ? Theme.accent : Theme.border

            Accessible.role: Accessible.Button
            Accessible.name: positionRoot.label + ", " + Placement.label(modelData)
            Accessible.selected: selected
            Accessible.onPressAction: positionRoot.chosen(modelData)

            Rectangle {
              anchors.centerIn: parent
              // Keep an even-sized dot inside the even-sized cell so its
              // center lands on whole pixels instead of a blurry half pixel.
              width: 6
              height: 6
              radius: 3
              color: parent.selected ? Theme.selectionForeground : Theme.foregroundMuted
            }
            HoverHandler { id: positionCellHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: positionRoot.chosen(modelData) }
          }
        }
      }
    }
  }

  component TimezoneDropdown: ColumnLayout {
    id: dropdownRoot
    property string label: ""
    property bool showLabel: true
    property var options: []
    property string selectedValue: ""
    readonly property bool hasSelection:
      options.indexOf(selectedValue) !== -1
    property var optionLabel: function(value) { return value }
    signal chosen(string value)
    Layout.fillWidth: true
    spacing: Theme.spaceXs

    Text {
      visible: dropdownRoot.showLabel
      text: dropdownRoot.label
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
      font.weight: Theme.weightMedium
    }

    Button {
      id: dropdownButton
      Layout.fillWidth: true
      Layout.preferredHeight: 34
      enabled: dropdownRoot.options.length > 0
      horizontalPadding: Theme.spaceSm
      buttonColor: Theme.surfaceHover
      buttonBorderColor: activeFocus ? Theme.accent : Theme.border
      accessibleName: dropdownRoot.label + ", "
        + dropdownRoot.optionLabel(dropdownRoot.selectedValue)
      onClicked: dropdownPopup.open()

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceSm
        anchors.rightMargin: Theme.spaceSm
        Text {
          Layout.fillWidth: true
          text: dropdownRoot.hasSelection
            ? dropdownRoot.optionLabel(dropdownRoot.selectedValue) : "Select"
          color: dropdownRoot.hasSelection
            ? Theme.foreground : Theme.foregroundMuted
          font.pixelSize: Theme.fontBody
          elide: Text.ElideRight
        }
        Canvas {
          id: dropdownChevron
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredWidth: 16
          Layout.preferredHeight: 16
          property color strokeColor: dropdownButton.activeFocus || dropdownPopup.opened
            ? Theme.accent : Theme.foregroundMuted
          rotation: dropdownPopup.opened ? 180 : 0
          opacity: dropdownButton.enabled ? 0.75 : 0.4
          onStrokeColorChanged: requestPaint()
          onPaint: {
            const context = getContext("2d")
            context.clearRect(0, 0, width, height)
            context.beginPath()
            context.moveTo(3, 6)
            context.lineTo(8, 11)
            context.lineTo(13, 6)
            context.strokeStyle = strokeColor
            context.lineWidth = 2
            context.lineCap = "round"
            context.lineJoin = "round"
            context.stroke()
          }
          Behavior on rotation {
            SpringAnimation {
              spring: Theme.motionSpring
              damping: Theme.motionDamping
              epsilon: Theme.motionEpsilon
            }
          }
        }
      }
    }

    Controls.Popup {
      id: dropdownPopup
      y: dropdownButton.y + dropdownButton.height + Theme.spaceXs
      width: dropdownRoot.width
      height: Math.min(320, dropdownRoot.options.length * 32 + Theme.spaceSm * 2)
      padding: Theme.spaceSm
      focus: true
      closePolicy: Controls.Popup.CloseOnEscape
        | Controls.Popup.CloseOnPressOutside
      onOpened: {
        dropdownList.currentIndex = Math.max(0,
          dropdownRoot.options.indexOf(dropdownRoot.selectedValue))
        dropdownList.positionViewAtIndex(dropdownList.currentIndex, ListView.Center)
        dropdownList.forceActiveFocus()
      }
      background: Rectangle {
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusMd
      }
      contentItem: ListView {
        id: dropdownList
        clip: true
        model: dropdownRoot.options
        boundsBehavior: Flickable.StopAtBounds
        Keys.onReturnPressed: chooseCurrent()
        Keys.onEnterPressed: chooseCurrent()
        function chooseCurrent() {
          if (currentIndex >= 0) {
            dropdownRoot.chosen(dropdownRoot.options[currentIndex])
            dropdownPopup.close()
          }
        }
        delegate: Rectangle {
          required property string modelData
          required property int index
          width: dropdownList.width
          height: 32
          radius: Theme.radiusSm
          color: index === dropdownList.currentIndex
            ? Theme.surfaceHover : "transparent"
          Text {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceSm
            anchors.rightMargin: Theme.spaceSm
            verticalAlignment: Text.AlignVCenter
            text: dropdownRoot.optionLabel(modelData)
            color: Theme.foreground
            font.pixelSize: Theme.fontBody
            elide: Text.ElideRight
          }
          HoverHandler {
            onHoveredChanged: if (hovered) dropdownList.currentIndex = index
          }
          TapHandler {
            onTapped: {
              dropdownRoot.chosen(modelData)
              dropdownPopup.close()
            }
          }
        }
        ScrollBar.vertical: ScrollBar {}
      }
    }
  }

  component KeyboardChoice: ColumnLayout {
    id: keyboardChoice
    property string label: ""
    property string selectedCode: ""
    property var options: []
    signal chosen(string code)
    readonly property var selectedOption: options.find(function(option) {
      return option.code === keyboardChoice.selectedCode
    })
    readonly property var matches: {
      const query = keyboardSearch.text.trim().toLowerCase()
      return options.filter(function(option) {
        return !query || (option.label + " " + option.code).toLowerCase().indexOf(query) !== -1
      })
    }
    Layout.fillWidth: true
    spacing: Theme.spaceXs

    Text {
      text: keyboardChoice.label
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
      font.weight: Theme.weightMedium
    }
    Button {
      id: keyboardChoiceButton
      Layout.fillWidth: true
      Layout.preferredHeight: 48
      enabled: keyboardChoice.options.length > 0
      buttonColor: Theme.surfaceHover
      buttonBorderColor: activeFocus || keyboardPopup.opened ? Theme.accent : Theme.border
      accessibleName: keyboardChoice.label + ", " + (keyboardChoice.selectedOption
        ? keyboardChoice.selectedOption.label : keyboardChoice.selectedCode)
      onClicked: keyboardPopup.open()
      RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spaceSm
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1
          Text {
            Layout.fillWidth: true
            text: keyboardChoice.selectedOption ? keyboardChoice.selectedOption.label
              : (keyboardChoice.selectedCode || "Default")
            color: Theme.foreground
            font.pixelSize: Theme.fontBody
            elide: Text.ElideRight
          }
          Text {
            text: keyboardChoice.selectedCode || "Standard variant"
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
          }
        }
        Text { text: keyboardPopup.opened ? "⌃" : "⌄"; color: Theme.foregroundMuted }
      }
    }
    Controls.Popup {
      id: keyboardPopup
      y: keyboardChoiceButton.y + keyboardChoiceButton.height + Theme.spaceXs
      width: keyboardChoice.width
      height: 300
      padding: Theme.spaceSm
      focus: true
      closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
      onOpened: {
        keyboardSearch.text = ""
        keyboardOptions.currentIndex = Math.max(0, keyboardChoice.matches.findIndex(function(option) {
          return option.code === keyboardChoice.selectedCode
        }))
        keyboardOptions.positionViewAtIndex(keyboardOptions.currentIndex, ListView.Center)
        keyboardSearch.forceActiveFocus()
      }
      onClosed: keyboardChoiceButton.forceActiveFocus()
      background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusMd
        border.width: Theme.borderWidth
        border.color: Theme.border
      }
      contentItem: ColumnLayout {
        spacing: Theme.spaceSm
        Controls.TextField {
          id: keyboardSearch
          Layout.fillWidth: true
          placeholderText: "Search name or code…"
          Accessible.name: "Search " + keyboardChoice.label.toLowerCase()
          color: Theme.foreground
          placeholderTextColor: Theme.foregroundMuted
          selectByMouse: true
          background: Rectangle {
            implicitHeight: 34
            color: Theme.surfaceHover
            radius: Theme.radiusSm
            border.width: Theme.borderWidth
            border.color: Theme.accent
          }
          onTextChanged: keyboardOptions.currentIndex = keyboardChoice.matches.length ? 0 : -1
          Keys.onDownPressed: keyboardOptions.currentIndex = Math.min(keyboardChoice.matches.length - 1, keyboardOptions.currentIndex + 1)
          Keys.onUpPressed: keyboardOptions.currentIndex = Math.max(0, keyboardOptions.currentIndex - 1)
          Keys.onReturnPressed: keyboardOptions.chooseCurrent()
          Keys.onEnterPressed: keyboardOptions.chooseCurrent()
        }
        ListView {
          id: keyboardOptions
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          model: keyboardChoice.matches
          boundsBehavior: Flickable.StopAtBounds
          keyNavigationEnabled: true
          highlightMoveDuration: 0
          onCurrentIndexChanged: {
            if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
          }
          function chooseCurrent() {
            if (currentIndex < 0 || currentIndex >= keyboardChoice.matches.length) return
            keyboardChoice.chosen(keyboardChoice.matches[currentIndex].code)
            keyboardPopup.close()
          }
          Keys.onReturnPressed: chooseCurrent()
          Keys.onEnterPressed: chooseCurrent()
          delegate: Rectangle {
            required property var modelData
            required property int index
            width: keyboardOptions.width
            height: 46
            radius: Theme.radiusSm
            color: index === keyboardOptions.currentIndex ? Theme.surfaceHover : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.margins: Theme.spaceSm
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                  Layout.fillWidth: true
                  text: modelData.label
                  color: Theme.foreground
                  font.pixelSize: Theme.fontBody
                  elide: Text.ElideRight
                }
                Text {
                  text: modelData.code || "Standard variant"
                  color: Theme.foregroundMuted
                  font.pixelSize: Theme.fontCaption
                }
              }
              Text {
                text: modelData.code === keyboardChoice.selectedCode ? "✓" : ""
                color: Theme.accent
              }
            }
            HoverHandler { onHoveredChanged: if (hovered) keyboardOptions.currentIndex = index }
            TapHandler {
              onTapped: {
                keyboardChoice.chosen(modelData.code)
                keyboardPopup.close()
              }
            }
          }
          Controls.ScrollBar.vertical: Controls.ScrollBar {}
          Text {
            anchors.centerIn: parent
            visible: keyboardChoice.matches.length === 0
            text: "No matching options"
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontBody
          }
        }
      }
    }
  }

  component ValueSliderRow: Rectangle {
    id: valueSliderRoot
    property string label: ""
    property string description: ""
    property real currentValue: 0
    property real from: 0
    property real to: 1
    property real stepSize: 1
    property var valueLabel: function(value) { return String(value) }
    signal changed(real value)
    Layout.fillWidth: true
    implicitHeight: valueSliderLayout.implicitHeight + Theme.spaceXl * 2
    color: Theme.surface
    border.width: Theme.borderWidth
    border.color: Theme.border
    radius: Theme.radiusLg

    ColumnLayout {
      id: valueSliderLayout
      anchors.fill: parent
      anchors.margins: Theme.spaceXl
      spacing: Theme.spaceSm

      RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceSm

        Text {
          Layout.fillWidth: true
          text: valueSliderRoot.label
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightStrong
          elide: Text.ElideRight
        }

        Rectangle {
          Layout.preferredWidth: Math.max(52,
            currentSliderValue.implicitWidth + Theme.spaceSm * 2)
          Layout.preferredHeight: 24
          color: Qt.rgba(Theme.accent.r, Theme.accent.g,
            Theme.accent.b, 0.14)
          border.width: Theme.borderWidth
          border.color: Qt.rgba(Theme.accent.r, Theme.accent.g,
            Theme.accent.b, 0.45)
          radius: Theme.radiusMd

          Text {
            id: currentSliderValue
            anchors.centerIn: parent
            text: valueSliderRoot.valueLabel(valueSliderRoot.currentValue)
            color: Theme.accent
            font.pixelSize: Theme.fontCaption
            font.weight: Theme.weightStrong
          }
        }
      }

      Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: valueSliderRoot.description
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        elide: Text.ElideRight
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spaceXs
        spacing: Theme.spaceSm

        Text {
          Layout.preferredWidth: 42
          text: valueSliderRoot.valueLabel(valueSliderRoot.from)
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
          horizontalAlignment: Text.AlignLeft
        }

        Slider {
          Layout.fillWidth: true
          Layout.preferredHeight: 24
          from: valueSliderRoot.from
          to: valueSliderRoot.to
          stepSize: valueSliderRoot.stepSize
          value: valueSliderRoot.currentValue
          accessibleName: valueSliderRoot.label
          onMoved: function(value) {
            const steps = Math.round((value - valueSliderRoot.from)
              / valueSliderRoot.stepSize)
            valueSliderRoot.changed(Math.max(valueSliderRoot.from,
              Math.min(valueSliderRoot.to, valueSliderRoot.from
                + steps * valueSliderRoot.stepSize)))
          }
        }

        Text {
          Layout.preferredWidth: 42
          text: valueSliderRoot.valueLabel(valueSliderRoot.to)
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }

  component TimezoneSelector: ColumnLayout {
    id: timezoneRoot
    readonly property string timezone: root.value("system", "timezone", "")
    readonly property string region: root.timezoneRegion(timezone)
    readonly property var regions: root.timezoneRegions()
    readonly property var regionalTimezones: root.timezonesForRegion(region)
    Layout.fillWidth: true
    spacing: Theme.spaceXs

    RowLayout {
      Layout.fillWidth: true
      spacing: Theme.spaceSm
      TimezoneDropdown {
        label: "Timezone region"
        options: timezoneRoot.regions
        selectedValue: timezoneRoot.region
        onChosen: function(value) {
          const choices = root.timezonesForRegion(value)
          if (choices.length > 0)
            root.setValue("system", "timezone", choices[0])
        }
      }
      TimezoneDropdown {
        label: "Timezone"
        options: timezoneRoot.regionalTimezones
        selectedValue: timezoneRoot.timezone
        optionLabel: function(value) { return root.timezoneLabel(value) }
        onChosen: function(value) { root.setValue("system", "timezone", value) }
      }
    }

    Text {
      visible: root.timezonesLoading || root.timezoneError !== ""
      Layout.fillWidth: true
      text: root.timezonesLoading ? "Loading time zones…" : root.timezoneError
      color: root.timezoneError !== "" ? Theme.error : Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
      wrapMode: Text.WordWrap
    }
  }

  component PowerTimeoutRow: Rectangle {
    id: timeoutRoot
    property string symbol: ""
    property string label: ""
    property string description: ""
    property int currentValue: 0
    property var options: []
    signal selected(int value)
    Layout.fillWidth: true
    implicitHeight: Math.max(40, timeoutLayout.implicitHeight) + Theme.spaceXl * 2
    color: Theme.surface
    border.width: Theme.borderWidth
    border.color: Theme.border
    radius: Theme.radiusLg

    RowLayout {
      id: timeoutLayout
      anchors.fill: parent
      anchors.margins: Theme.spaceXl
      spacing: Theme.spaceLg

      Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        Layout.alignment: Qt.AlignVCenter
        color: Theme.surfaceHover
        radius: Theme.radiusMd

        Text {
          anchors.centerIn: parent
          text: timeoutRoot.symbol
          color: Theme.accent
          font.pixelSize: Theme.fontTitle
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
          text: timeoutRoot.label
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightMedium
        }
        Text {
          Layout.fillWidth: true
          text: timeoutRoot.description
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
          wrapMode: Text.WordWrap
        }
      }

      TimezoneDropdown {
        Layout.minimumWidth: 180
        Layout.preferredWidth: 180
        Layout.maximumWidth: 180
        Layout.alignment: Qt.AlignVCenter
        showLabel: false
        label: timeoutRoot.label + " timeout"
        options: timeoutRoot.options
        selectedValue: String(timeoutRoot.currentValue)
        optionLabel: function(value) { return root.powerTimeoutLabel(value) }
        onChosen: function(value) { timeoutRoot.selected(Number(value)) }
      }
    }
  }

  FloatingWindow {
    id: window
    visible: root.opened
    title: "Atlas Settings"
    implicitWidth: 1100
    implicitHeight: 760
    minimumSize: Qt.size(860, 600)
    color: Theme.background
    onClosed: root.opened = false

    FolderDialog {
      id: wallpaperFolderDialog
      title: "Choose wallpaper folder"
      options: FolderDialog.DontUseNativeDialog
      onAccepted: {
        let path = selectedFolder.toString()
        if (path.indexOf("file://") === 0)
          path = decodeURIComponent(path.substring(7))
        root.setValue("appearance", "wallpaperDirectory", path)
        root.loadAppearanceWallpapers()
      }
    }

    Shortcut {
      sequence: "Escape"
      onActivated: root.close()
    }

    Rectangle {
      anchors.fill: parent
      color: Theme.background

      RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
          Layout.fillHeight: true
          Layout.preferredWidth: 220
          color: Theme.surface
          border.width: Theme.borderWidth
          border.color: Theme.border

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceXl
            spacing: Theme.spaceSm

            RowLayout {
              Layout.fillWidth: true
              Layout.bottomMargin: Theme.spaceLg
              spacing: Theme.spaceSm
              IconImage {
                implicitWidth: 22
                implicitHeight: 22
                source: Qt.resolvedUrl("../assets/nix-snowflake.svg")
              }
              Text {
                text: "Atlas Settings"
                color: Theme.foreground
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.weightStrong
              }
            }

            Flickable {
              id: categoryScroll
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              contentWidth: width
              contentHeight: categoryNavigation.implicitHeight
              boundsBehavior: Flickable.StopAtBounds
              flickableDirection: Flickable.VerticalFlick

              Controls.ScrollBar.vertical: Controls.ScrollBar {
                policy: Controls.ScrollBar.AsNeeded
              }

              ColumnLayout {
                id: categoryNavigation
                width: categoryScroll.width
                spacing: Theme.spaceXs

                Repeater {
                  id: categoryRepeater
                  model: root.navigationItems
                  Item {
                id: categoryButton
                required property var modelData
                required property int index
                readonly property bool isPage: modelData.type === "page"
                readonly property string pageKey: isPage ? modelData.key : ""
                property Item pageButtonItem: pageButton
                Layout.fillWidth: true
                implicitHeight: isPage ? 32 : 22

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: Theme.spaceSm
                  anchors.bottom: parent.bottom
                  visible: !categoryButton.isPage
                  text: categoryButton.modelData.label.toUpperCase()
                  color: Theme.foregroundMuted
                  font.pixelSize: Theme.fontCaption
                  font.weight: Theme.weightStrong
                }

                Button {
                  id: pageButton
                  anchors.fill: parent
                  visible: categoryButton.isPage
                  horizontalPadding: Theme.spaceSm
                  buttonColor: root.currentSection === categoryButton.pageKey ? Theme.surfaceHover : Theme.surface
                  buttonBorderColor: root.currentSection === categoryButton.pageKey ? Theme.accent : Theme.surface
                  accessibleName: categoryButton.modelData.label + " settings"
                  onClicked: root.selectSection(categoryButton.pageKey)
                  property bool categoryNavigationButton: true
                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: pageButton.horizontalPadding
                    anchors.rightMargin: pageButton.horizontalPadding
                    spacing: Theme.spaceSm
                    IconImage {
                      visible: categoryButton.pageKey === "widgets"
                      Layout.preferredWidth: 18
                      Layout.preferredHeight: 18
                      source: Qt.resolvedUrl("../assets/widget.svg")
                      layer.enabled: true
                      layer.effect: MultiEffect {
                        brightness: 1
                        colorization: 1
                        colorizationColor: root.currentSection === "widgets"
                          ? Theme.accent : Theme.foregroundMuted
                      }
                    }
                    Text {
                      visible: categoryButton.pageKey !== "widgets"
                      text: categoryButton.modelData.symbol
                      color: root.currentSection === categoryButton.pageKey ? Theme.accent : Theme.foregroundMuted
                      font.pixelSize: Theme.fontTitle
                    }
                    Text {
                      Layout.fillWidth: true
                      text: categoryButton.modelData.label
                      color: Theme.foreground
                      font.pixelSize: Theme.fontBody
                      font.weight: root.currentSection === categoryButton.pageKey ? Theme.weightStrong : Theme.weightRegular
                    }
                  }
                }
                  }
                }
              }
            }

            Text {
              Layout.fillWidth: true
              visible: root.rebuildRequired
              text: "NixOS rebuild required"
              color: Theme.warning
              font.pixelSize: Theme.fontCaption
              wrapMode: Text.WordWrap
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.margins: Theme.spaceXl
          spacing: Theme.spaceLg

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            visible: root.sectionErrors[root.dataSection(root.currentSection)] !== undefined
            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
            border.width: Theme.borderWidth
            border.color: Theme.error
            radius: Theme.radiusMd
            Text {
              anchors.fill: parent
              anchors.margins: Theme.spaceSm
              text: root.sectionErrors[root.dataSection(root.currentSection)]
                ? root.sectionErrors[root.dataSection(root.currentSection)].message + "\n" + root.sectionErrors[root.dataSection(root.currentSection)].path
                : ""
              color: Theme.error
              font.pixelSize: Theme.fontCaption
              wrapMode: Text.WordWrap
            }
          }

          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            Controls.ScrollBar.vertical: Controls.ScrollBar {
              policy: Controls.ScrollBar.AsNeeded
            }

            Loader {
              width: parent.width
              sourceComponent: root.currentSection === "widgets" ? widgetsPage
                : (root.currentSection === "system" ? systemPage
                : (root.currentSection === "scripts" ? scriptsPage
                : (root.currentSection === "applications" ? applicationsPage
                  : (root.currentSection === "layout" ? appearancePage
                  : (root.currentSection === "fonts" ? fontsPage
                  : (root.currentSection === "cursor" ? cursorPage
                    : (root.currentSection === "internet" ? internetPage
                  : (root.currentSection === "audio" ? audioPage
                  : (root.currentSection === "bluetooth" ? bluetoothPage
                      : (root.currentSection === "themes" ? appearancePage
                      : (root.currentSection === "appearance" ? appearancePage
                        : (root.currentSection === "wallpaper" ? appearancePage
                        : (root.currentSection === "input" ? inputPage
                          : (root.currentSection === "power" ? powerPage : displaysPage))))))))))))))
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm
            Text {
              Layout.fillWidth: true
              text: root.loading ? "Loading settings…" : root.statusMessage
              color: root.statusError ? Theme.error : Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
              elide: Text.ElideRight
            }
            Button {
              visible: root.dataSection(root.currentSection) === "system" && root.rebuildRequired
              enabled: !root.saving
              accessibleName: "Rebuild NixOS"
              onClicked: Quickshell.execDetached(["kitty", "--class", "atlas-rebuild", "--hold", "atlas", "rebuild"])
              Text { anchors.centerIn: parent; text: "Rebuild NixOS"; color: Theme.foreground; font.pixelSize: Theme.fontBody }
            }
            Button {
              visible: root.currentSection !== "bluetooth" && root.currentSection !== "internet"
                && root.currentSection !== "audio" && root.currentSection !== "scripts"
                && root.currentSection !== "applications"
              enabled: root.dirtySections[root.dataSection(root.currentSection)] === true && !root.saving
              accessibleName: (root.dataSection(root.currentSection) === "appearance"
                || root.dataSection(root.currentSection) === "input"
                || root.dataSection(root.currentSection) === "displays")
                ? "Roll back preview" : "Discard changes"
              onClicked: root.resetSection()
              Text {
                anchors.centerIn: parent
                text: (root.dataSection(root.currentSection) === "appearance"
                  || root.dataSection(root.currentSection) === "input"
                  || root.dataSection(root.currentSection) === "displays")
                  ? "Roll back" : "Reset"
                color: parent.enabled ? Theme.foreground : Theme.foregroundMuted
                font.pixelSize: Theme.fontBody
              }
            }
            Button {
              visible: root.currentSection !== "bluetooth" && root.currentSection !== "internet"
                && root.currentSection !== "audio" && root.currentSection !== "scripts"
                && root.currentSection !== "applications"
              enabled: root.sectionAvailable(root.currentSection)
                && root.dirtySections[root.dataSection(root.currentSection)] === true && !root.saving
              buttonColor: enabled ? Theme.accent : Theme.surfaceHover
              buttonBorderColor: enabled ? Theme.accent : Theme.border
              accessibleName: "Save current settings page permanently"
              onClicked: root.saveSection()
              Text { anchors.centerIn: parent; text: root.saving ? "Saving…" : "Save permanently"; color: enabled ? Theme.background : Theme.foregroundMuted; font.pixelSize: Theme.fontBody; font.weight: Theme.weightStrong }
            }
          }
        }
      }
    }
  }

  Component {
    id: widgetsPage
    ColumnLayout {
      id: widgetsRoot
      property bool playerExpanded: false
      property bool stickyNotesExpanded: false
      property bool tasksExpanded: false
      property bool focusTimerExpanded: false
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg
      SectionTitle {
        title: "Widgets"
        description: "Small desktop companions that stay available between sessions."
      }
      ToggleRow {
        label: "Sticky Notes"
        description: "Show the movable desktop note"
        checked: DesktopWidgets.WidgetState.stickyNotesVisible
        expandable: true
        expanded: widgetsRoot.stickyNotesExpanded
        onChanged: function(value) {
          DesktopWidgets.WidgetState.stickyNotesVisible = value
          if (!value) widgetsRoot.stickyNotesExpanded = false
        }
        onExpansionChanged: function(expanded) {
          widgetsRoot.stickyNotesExpanded = expanded
        }
      }
      ChoiceRow {
        visible: DesktopWidgets.WidgetState.stickyNotesVisible
          && widgetsRoot.stickyNotesExpanded
        label: "Sticky Notes color"
        description: "Use the current theme or a solid note color"
        options: ["theme", "yellow", "white", "red", "blue", "green", "purple"]
        selectedValue: DesktopWidgets.WidgetState.stickyNotesColor
        optionLabel: function(value) {
          if (value === "theme") return "Current style"
          return value.charAt(0).toUpperCase() + value.substring(1)
        }
        onChosen: function(value) {
          DesktopWidgets.WidgetState.stickyNotesColor = value
        }
      }
      ToggleRow {
        label: "Tasks"
        description: "Checklists, priorities, due dates, and recurring reminders"
        checked: DesktopWidgets.WidgetState.tasksVisible
        expandable: true
        expanded: widgetsRoot.tasksExpanded
        onExpansionChanged: function(value) { widgetsRoot.tasksExpanded = value }
        onChanged: function(value) {
          DesktopWidgets.WidgetState.tasksVisible = value
        }
      }
      ChoiceRow {
        visible: DesktopWidgets.WidgetState.tasksVisible && widgetsRoot.tasksExpanded
        label: "Tasks background"
        description: "Theme transparency or a solid color"
        options: ["theme-transparent", "theme-solid", "yellow", "white", "red", "blue", "green", "purple"]
        selectedValue: DesktopWidgets.WidgetState.tasksColor
        optionLabel: function(value) {
          if (value === "theme-transparent") return "Transparent theme"
          if (value === "theme-solid") return "Solid theme"
          return value.charAt(0).toUpperCase() + value.substring(1)
        }
        onChosen: function(value) { DesktopWidgets.WidgetState.tasksColor = value }
      }
      ToggleRow {
        label: "Focus Timer"
        description: "Pomodoro focus sessions and short or long breaks"
        checked: DesktopWidgets.WidgetState.focusTimerVisible
        expandable: true
        expanded: widgetsRoot.focusTimerExpanded
        onExpansionChanged: function(value) { widgetsRoot.focusTimerExpanded = value }
        onChanged: function(value) { DesktopWidgets.WidgetState.focusTimerVisible = value }
      }
      ChoiceRow {
        visible: DesktopWidgets.WidgetState.focusTimerVisible && widgetsRoot.focusTimerExpanded
        label: "Focus Timer background"
        description: "Theme transparency or a solid color"
        options: ["theme-transparent", "theme-solid", "yellow", "white", "red", "blue", "green", "purple"]
        selectedValue: DesktopWidgets.WidgetState.focusTimerColor
        optionLabel: function(value) {
          if (value === "theme-transparent") return "Transparent theme"
          if (value === "theme-solid") return "Solid theme"
          return value.charAt(0).toUpperCase() + value.substring(1)
        }
        onChosen: function(value) { DesktopWidgets.WidgetState.focusTimerColor = value }
      }
      ToggleRow {
        label: "Music Player"
        description: "Show the desktop now-playing widget"
        checked: DesktopWidgets.WidgetState.playerVisible
        expandable: true
        expanded: widgetsRoot.playerExpanded
        onChanged: function(value) {
          DesktopWidgets.WidgetState.playerVisible = value
          if (!value) widgetsRoot.playerExpanded = false
        }
        onExpansionChanged: function(expanded) {
          widgetsRoot.playerExpanded = expanded
        }
      }
      ChoiceRow {
        visible: DesktopWidgets.WidgetState.playerVisible && widgetsRoot.playerExpanded
        label: "Album artwork"
        description: "Cover, full-background poster, discs, cassette, or no artwork"
        options: ["none", "square", "poster", "cd", "vinyl", "cassette"]
        selectedValue: DesktopWidgets.WidgetState.playerArtworkStyle
        optionLabel: function(value) { return ({none: "No artwork", square: "Square cover", poster: "Poster", cd: "Spinning CD", vinyl: "Spinning vinyl", cassette: "Cassette"})[value] || value }
        onChosen: function(value) { DesktopWidgets.WidgetState.playerArtworkStyle = value }
      }
      ChoiceRow {
        visible: DesktopWidgets.WidgetState.playerVisible
          && widgetsRoot.playerExpanded
        label: "Player colors"
        description: "Choose where the desktop player gets its colors"
        options: ["album", "theme"]
        selectedValue: DesktopWidgets.WidgetState.playerColorSource
        optionLabel: function(value) {
          return value === "album" ? "Album artwork" : "Current style"
        }
        onChosen: function(value) {
          DesktopWidgets.WidgetState.playerColorSource = value
        }
      }
    }
  }

  Component {
    id: scriptsPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg
      SectionTitle {
        title: "Atlas"
        description: "Run Atlas maintenance, appearance, and system tools. Operations that may prompt for input open in a terminal."
      }

      Text { text: "Maintenance"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
      ScriptActionRow {
        label: "Check configuration"
        description: "Validate the current Atlas configuration without changing it"
        actionText: "Check"
        enabled: !scriptProcess.running
        onTriggered: root.runScript("Configuration check", ["atlas", "config", "check"])
      }
      ScriptActionRow {
        label: "Run diagnostics"
        description: "Check Atlas dependencies, paths, and system integration"
        actionText: "Diagnose"
        enabled: !scriptProcess.running
        onTriggered: root.runScript("Atlas diagnostics", ["atlas", "doctor"])
      }

      Text { text: "Appearance"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
      ScriptActionRow {
        label: "Refresh theme"
        description: "Regenerate application colors from the active Atlas theme"
        actionText: "Refresh"
        enabled: !scriptProcess.running
        onTriggered: root.runScript("Theme refresh", ["theme-refresh"])
      }
      Text { text: "System"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
      ScriptActionRow {
        label: "Rebuild NixOS"
        description: "Apply saved Atlas and NixOS configuration changes"
        actionText: "Open terminal"
        onTriggered: Quickshell.execDetached(["kitty", "--class", "atlas-rebuild", "--hold", "atlas", "rebuild"])
      }
      ScriptActionRow {
        label: "Update Atlas"
        description: "Fetch Atlas updates and run the update workflow"
        actionText: "Open terminal"
        onTriggered: Quickshell.execDetached(["kitty", "--class", "atlas-update", "--hold", "atlas", "update"])
      }
    }
  }

  component ScriptActionRow: Rectangle {
    id: scriptActionRoot
    property string label: ""
    property string description: ""
    property string actionText: "Run"
    signal triggered()
    Layout.fillWidth: true
    implicitHeight: 34 + Theme.spaceXl * 2
    color: Theme.surface
    border.width: Theme.borderWidth
    border.color: Theme.border
    radius: Theme.radiusLg

    RowLayout {
      anchors.fill: parent
      anchors.margins: Theme.spaceXl
      spacing: Theme.spaceLg
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text { text: scriptActionRoot.label; color: Theme.foreground; font.pixelSize: Theme.fontBody; font.weight: Theme.weightMedium }
        Text { Layout.fillWidth: true; text: scriptActionRoot.description; color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption; elide: Text.ElideRight }
      }
      Button {
        Layout.preferredHeight: 34
        enabled: scriptActionRoot.enabled
        accessibleName: scriptActionRoot.actionText + " " + scriptActionRoot.label
        onClicked: scriptActionRoot.triggered()
        Text { anchors.centerIn: parent; text: scriptActionRoot.actionText; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontBody }
      }
    }
  }

  Component {
    id: fontsPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg
      SectionTitle { title: "Fonts"; description: "Choose the system font used by applications. Rebuild NixOS after saving to apply it." }
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: fontSearchLayout.implicitHeight + Theme.spaceXl * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        RowLayout {
          id: fontSearchLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceXl
          spacing: Theme.spaceLg
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
              text: "Installed fonts"
              color: Theme.foreground
              font.pixelSize: Theme.fontBody
              font.weight: Theme.weightMedium
            }
            Text {
              text: root.detectedFonts.length + " terminal-compatible font families available"
              color: Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
            }
          }
          TextField {
            Layout.preferredWidth: 220
            Layout.preferredHeight: 34
            text: root.fontSearch
            placeholderText: "Search fonts…"
            color: Theme.foreground
            placeholderTextColor: Theme.foregroundMuted
            selectByMouse: true
            onTextEdited: root.fontSearch = text
            background: Rectangle {
              color: Theme.surfaceHover
              radius: Theme.radiusMd
              border.width: Theme.borderWidth
              border.color: parent.activeFocus ? Theme.accent : Theme.border
            }
          }
        }
      }
      TimezoneDropdown {
        label: "Monospace font"
        options: {
          const current = root.value("fonts", "fontFamily", "FiraCode Nerd Font Mono")
          const query = root.fontSearch.trim().toLowerCase()
          const available = root.detectedFonts.filter(function(font) {
            return query === "" || font.toLowerCase().indexOf(query) !== -1
          })
          if (available.indexOf(current) === -1)
            available.unshift(current)
          return available
        }
        selectedValue: root.value("fonts", "fontFamily", "FiraCode Nerd Font Mono")
        onChosen: function(value) { root.setValue("fonts", "fontFamily", value) }
      }
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: fontPreviewLayout.implicitHeight + Theme.spaceXl * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        ColumnLayout {
          id: fontPreviewLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceXl
          spacing: Theme.spaceSm

          RowLayout {
            Layout.fillWidth: true
            Text {
              Layout.fillWidth: true
              text: "Preview"
              color: Theme.foreground
              font.pixelSize: Theme.fontBody
              font.weight: Theme.weightStrong
            }
            Text {
              text: root.value("fonts", "fontFamily", "FiraCode Nerd Font Mono")
              color: Theme.accent
              font.pixelSize: Theme.fontCaption
            }
          }
          Text {
            Layout.fillWidth: true
            text: "The quick brown fox jumps over the lazy dog."
            color: Theme.foreground
            font.family: root.value("fonts", "fontFamily", "FiraCode Nerd Font Mono")
            font.pixelSize: 20
            wrapMode: Text.WordWrap
          }
          Text {
            Layout.fillWidth: true
            text: "ABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n0123456789  {}[]()  !@#$%^&*"
            color: Theme.foregroundMuted
            font.family: root.value("fonts", "fontFamily", "FiraCode Nerd Font Mono")
            font.pixelSize: 14
            lineHeight: 1.25
          }
        }
      }
      Text {
        Layout.fillWidth: true
        text: "The preview updates immediately. Press Save to apply the font to newly opened terminals, then rebuild NixOS to make it the system-wide default."
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
      }
      Text {
        Layout.fillWidth: true
        visible: root.detectedFonts.length > 0
          && root.detectedFonts.indexOf(root.value("fonts", "fontFamily", "")) === -1
        text: "The selected family is not monospaced, so Kitty may substitute another font. Choose a terminal-compatible family above."
        color: Theme.warning
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
      }
    }
  }

  Component {
    id: cursorPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg
      SectionTitle { title: "Cursor"; description: "Set the pointer theme and size. Press Save to apply it immediately; rebuild NixOS to keep it as the system default." }
      TimezoneDropdown {
        label: "Cursor theme"
        options: {
          const current = root.value("cursor", "cursorTheme", "Adwaita")
          const available = root.detectedCursorThemes.slice()
          if (available.indexOf(current) === -1)
            available.unshift(current)
          return available
        }
        selectedValue: root.value("cursor", "cursorTheme", "Adwaita")
        onChosen: function(value) {
          root.setValue("cursor", "cursorTheme", value)
          root.previewCursor(value, root.value("cursor", "cursorSize", 24))
        }
      }
      NumericRow {
        label: "Cursor size"
        description: "Larger cursors are easier to see on high-resolution displays."
        from: 12
        to: 64
        stepSize: 1
        currentValue: root.value("cursor", "cursorSize", 24)
        onChanged: function(value) {
          root.setValue("cursor", "cursorSize", value)
          root.previewCursor(root.value("cursor", "cursorTheme", "Adwaita"), value)
        }
      }
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: cursorPreviewLayout.implicitHeight + Theme.spaceXl * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        RowLayout {
          id: cursorPreviewLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceXl
          spacing: Theme.spaceLg

          Rectangle {
            Layout.preferredWidth: 112
            Layout.preferredHeight: 88
            color: Theme.surfaceHover
            border.width: Theme.borderWidth
            border.color: cursorPreviewHover.hovered ? Theme.accent : Theme.border
            radius: Theme.radiusMd
            Text {
              anchors.centerIn: parent
              text: "󰇀"
              color: Theme.foreground
              font.pixelSize: Math.max(12, root.value("cursor", "cursorSize", 24))
            }
            HoverHandler {
              id: cursorPreviewHover
              cursorShape: Qt.ArrowCursor
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceXs
            Text {
              text: "Cursor preview"
              color: Theme.foreground
              font.pixelSize: Theme.fontBody
              font.weight: Theme.weightStrong
            }
            Text {
              Layout.fillWidth: true
              text: root.value("cursor", "cursorTheme", "Adwaita") + " · "
                + root.value("cursor", "cursorSize", 24) + " px"
              color: Theme.accent
              font.pixelSize: Theme.fontBody
              elide: Text.ElideRight
            }
            Text {
              Layout.fillWidth: true
              text: "Changes are previewed on the real pointer immediately. Save keeps them; Reset or closing Settings restores the saved cursor."
              color: Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
              wrapMode: Text.WordWrap
            }
          }
        }
      }
    }
  }

  Component {
    id: systemPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg
      SectionTitle { title: "System"; description: "Machine identity and optional Atlas modules. Saving validates the complete NixOS configuration before changing it." }
      LabeledField { label: "Hostname"; fieldText: root.value("system", "hostname", ""); onCommitted: function(value) { root.setValue("system", "hostname", value) } }
      TimezoneSelector {}
      Text { text: "Optional modules"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
      Text {
        Layout.fillWidth: true
        text: "Enable extra Atlas features for this system."
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
      }
      Repeater {
        model: ["bluetooth", "development", "media", "productivity", "laptop", "nvidia"]
        ToggleRow {
          required property string modelData
          label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
          description: root.moduleDescription(modelData)
          checked: root.value("system", "modules", []).indexOf(modelData) !== -1
          onChanged: function(enabled) {
            const modules = root.clone(root.value("system", "modules", []))
            const index = modules.indexOf(modelData)
            if (enabled && index === -1) modules.push(modelData)
            if (!enabled && index !== -1) modules.splice(index, 1)
            root.setValue("system", "modules", modules)
          }
        }
      }
    }
  }

  Component {
    id: internetPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg

      Bar.InternetSection {
        Layout.fillWidth: true
        shown: true
        showBackButton: false
        showSettingsButton: false
      }
    }
  }

  Component {
    id: audioPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg

      SectionTitle {
        title: "Audio"
        description: "Control output and microphone levels, mute state, and the active audio devices. Changes apply immediately."
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: outputAudioLayout.implicitHeight + Theme.spaceXl * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        ColumnLayout {
          id: outputAudioLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceXl
          spacing: Theme.spaceSm

          RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "Output"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
            Text { text: Math.round(Bar.AudioState.volume * 100) + "%"; color: Theme.accent; font.pixelSize: Theme.fontBody; font.weight: Theme.weightStrong }
            Button {
              Layout.preferredHeight: Theme.controlHeight
              enabled: Bar.AudioState.outputAvailable
              accessibleName: Bar.AudioState.muted ? "Unmute output" : "Mute output"
              onClicked: Bar.AudioState.toggleOutputMute()
              Text { anchors.centerIn: parent; text: Bar.AudioState.muted ? "Unmute" : "Mute"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
            }
          }
          Slider {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            enabled: Bar.AudioState.outputAvailable
            from: 0; to: Bar.AudioState.maximumVolume
            value: Bar.AudioState.volume
            accessibleName: "Output volume"
            onMoved: function(value) { Bar.AudioState.setOutputVolume(value) }
          }
        }
      }

      Bar.AudioDeviceSection {
        Layout.fillWidth: true
        shown: true
        title: "Output devices"
        direction: "output"
        devices: Bar.AudioState.audioOutputs
        selectedDevice: Bar.AudioState.audioSink
        showBackButton: false
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: inputAudioLayout.implicitHeight + Theme.spaceXl * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        ColumnLayout {
          id: inputAudioLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceXl
          spacing: Theme.spaceSm

          RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "Microphone"; color: Theme.foreground; font.pixelSize: Theme.fontTitle; font.weight: Theme.weightStrong }
            Text { text: Math.round(Bar.AudioState.inputVolume * 100) + "%"; color: Theme.accent; font.pixelSize: Theme.fontBody; font.weight: Theme.weightStrong }
            Button {
              Layout.preferredHeight: Theme.controlHeight
              enabled: Bar.AudioState.inputAvailable
              accessibleName: Bar.AudioState.microphoneMuted ? "Unmute microphone" : "Mute microphone"
              onClicked: Bar.AudioState.toggleInputMute()
              Text { anchors.centerIn: parent; text: Bar.AudioState.microphoneMuted ? "Unmute" : "Mute"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
            }
          }
          Slider {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            enabled: Bar.AudioState.inputAvailable
            from: 0; to: 1
            value: Bar.AudioState.inputVolume
            accessibleName: "Microphone volume"
            onMoved: function(value) { Bar.AudioState.setInputVolume(value) }
          }
        }
      }

      Bar.AudioDeviceSection {
        Layout.fillWidth: true
        shown: true
        title: "Input devices"
        direction: "input"
        devices: Bar.AudioState.audioInputs
        selectedDevice: Bar.AudioState.audioSource
        showBackButton: false
      }
    }
  }

  Component {
    id: bluetoothPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg

      Bar.BluetoothSection {
        Layout.fillWidth: true
        shown: true
        showBackButton: false
        showSettingsButton: false
        subtitle: "Manage the Bluetooth adapter, saved devices, and nearby devices. Pairing requests and passkeys appear here."
      }
    }
  }

  Component {
    id: themesPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg

      Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: appearancePage
        onLoaded: {
          if (item)
            item.themesOnly = true
        }
      }
    }
  }

  Component {
    id: wallpaperPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg

      Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        sourceComponent: appearancePage
        onLoaded: {
          if (item)
            item.wallpaperOnly = true
        }
      }
    }
  }

  Component {
    id: appearancePage
    ColumnLayout {
      id: appearanceRoot
      property bool rotationExpanded: false
      property bool dimmingExpanded: false
      property bool blurExpanded: false
      property bool shadowsExpanded: false
      readonly property bool wallpaperOnly: root.currentSection === "wallpaper"
      readonly property bool themesOnly: root.currentSection === "themes"
      readonly property bool effectsOnly: !wallpaperOnly && !themesOnly
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg

      SectionTitle {
        visible: appearanceRoot.effectsOnly
        title: "Appearance"
        description: "Tune window decoration and visual effects."
      }

      Text {
        visible: appearanceRoot.effectsOnly
        text: "Layout"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      ChoiceRow {
        visible: appearanceRoot.effectsOnly
        label: "Layout"
        description: "Choose how windows are tiled automatically"
        options: ["dwindle", "master", "scrolling", "monocle"]
        selectedValue: root.value("appearance", "layout", "dwindle")
        optionLabel: function(value) {
          return value.charAt(0).toUpperCase() + value.substring(1)
        }
        onChosen: function(value) { root.setValue("appearance", "layout", value) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Inner gaps"
        description: "Space between tiled windows"
        currentValue: root.value("appearance", "gapsIn", 5)
        from: 0; to: 50
        onChanged: function(value) { root.setValue("appearance", "gapsIn", value) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Outer gaps"
        description: "Space between windows and screen edges"
        currentValue: root.value("appearance", "gapsOut", 10)
        from: 0; to: 100
        onChanged: function(value) { root.setValue("appearance", "gapsOut", value) }
      }

      Text {
        visible: appearanceRoot.effectsOnly
        text: "Overlay positions"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      PositionRow {
        visible: appearanceRoot.effectsOnly
        label: "Start menu"
        description: "Where the Start menu opens"
        selectedValue: Placement.startMenu
        onChosen: function(value) { Placement.startMenu = value }
      }
      PositionRow {
        visible: appearanceRoot.effectsOnly
        label: "Wallpaper selector"
        description: "Where wallpaper choices appear"
        selectedValue: Placement.wallpaperSelector
        onChosen: function(value) { Placement.wallpaperSelector = value }
      }
      PositionRow {
        visible: appearanceRoot.effectsOnly
        label: "Volume and brightness"
        description: "Where volume and brightness indicators appear"
        selectedValue: Placement.osd
        onChosen: function(value) { Placement.osd = value }
      }
      PositionRow {
        visible: appearanceRoot.effectsOnly
        label: "Clipboard"
        description: "Where clipboard history opens"
        selectedValue: Placement.clipboard
        onChosen: function(value) { Placement.clipboard = value }
      }
      PositionRow {
        visible: appearanceRoot.effectsOnly
        label: "Screenshot menu"
        description: "Where screenshot and recording controls open"
        selectedValue: Placement.screenshotMenu
        onChosen: function(value) { Placement.screenshotMenu = value }
      }
      PositionRow {
        visible: appearanceRoot.effectsOnly
        label: "Power menu"
        description: "Where power actions open"
        selectedValue: Placement.powerMenu
        onChosen: function(value) { Placement.powerMenu = value }
      }
      PositionRow {
        visible: appearanceRoot.effectsOnly
        label: "Theme selector"
        description: "Where the theme selector opens"
        selectedValue: Placement.themeSelector
        onChosen: function(value) { Placement.themeSelector = value }
      }

      SectionTitle {
        visible: appearanceRoot.themesOnly
        title: "Themes"
        description: "Create a reusable Atlas color theme or control wallpaper-based theme generation."
      }

      Text {
        visible: appearanceRoot.themesOnly
        text: "Wallpaper automation"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      ToggleRow {
        visible: appearanceRoot.themesOnly
        label: "Create theme from wallpaper"
        description: checked
          ? "Selecting a wallpaper creates and applies a personal Matugen theme"
          : "Wallpapers change independently and keep the current system theme"
        checked: root.value("appearance", "wallpaperTheme", false)
        onChanged: function(enabled) {
          root.setValue("appearance", "wallpaperTheme", enabled)
        }
      }

      Rectangle {
        visible: appearanceRoot.themesOnly
        Layout.fillWidth: true
        implicitHeight: themeEditorLayout.implicitHeight + Theme.spaceLg * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        ColumnLayout {
          id: themeEditorLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceLg
          spacing: Theme.spaceSm

          Text {
            text: "Create a custom theme"
            color: Theme.foreground
            font.pixelSize: Theme.fontBody
            font.weight: Theme.weightStrong
          }

          Text {
            Layout.fillWidth: true
            text: "Choose the colors used by Atlas, terminals, and generated application styles."
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm
            Text {
              Layout.fillWidth: true
              text: "Start with a palette"
              color: Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
            }
            Repeater {
              model: [
                { key: "graphite", label: "Graphite" },
                { key: "forest", label: "Forest" },
                { key: "sunset", label: "Sunset" }
              ]
              Button {
                required property var modelData
                Layout.preferredHeight: 30
                accessibleName: "Use " + modelData.label + " palette"
                onClicked: root.applyThemePalette(modelData.key)
                Text {
                  anchors.centerIn: parent
                  text: modelData.label
                  color: Theme.foreground
                  font.pixelSize: Theme.fontCaption
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 116
            color: root.themeCreationColors.background
            border.width: Theme.borderWidth
            border.color: root.themeCreationColors.accent
            radius: Theme.radiusMd

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Theme.spaceMd
              spacing: Theme.spaceXs

              RowLayout {
                Layout.fillWidth: true
                Text {
                  Layout.fillWidth: true
                  text: root.themeCreationName || "Untitled theme"
                  color: root.themeCreationColors.foreground
                  font.pixelSize: Theme.fontBody
                  font.weight: Theme.weightStrong
                  elide: Text.ElideRight
                }
                Text {
                  text: "LIVE PREVIEW"
                  color: root.themeCreationColors.accent
                  font.pixelSize: Theme.fontCaption
                  font.weight: Theme.weightStrong
                }
              }

              Text {
                Layout.fillWidth: true
                text: "Atlas settings  •  terminal  •  notifications"
                color: root.themeCreationColors.foreground_muted
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideRight
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceSm
                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 22
                  radius: Theme.radiusSm
                  color: root.themeCreationColors.surface
                  border.width: Theme.borderWidth
                  border.color: root.themeCreationColors.border
                  Text {
                    anchors.centerIn: parent
                    text: "Surface"
                    color: root.themeCreationColors.foreground_muted
                    font.pixelSize: Theme.fontCaption
                  }
                }
                Rectangle {
                  Layout.preferredWidth: 72
                  Layout.preferredHeight: 22
                  radius: Theme.radiusSm
                  color: root.themeCreationColors.accent
                  Text {
                    anchors.centerIn: parent
                    text: "Action"
                    color: root.themeCreationColors.selection_foreground
                    font.pixelSize: Theme.fontCaption
                    font.weight: Theme.weightStrong
                  }
                }
              }

              Row {
                spacing: Theme.spaceXs
                Repeater {
                  model: ["accent", "success", "warning", "error", "info"]
                  Rectangle {
                    required property string modelData
                    width: 28
                    height: 6
                    radius: Theme.cornerRadius
                    color: root.themeCreationColors[modelData]
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm
            TextField {
              id: themeNameField
              Layout.fillWidth: true
              Layout.preferredHeight: Theme.controlHeight
              text: root.themeCreationName
              placeholderText: "Theme name"
              color: Theme.foreground
              placeholderTextColor: Theme.foregroundMuted
              onTextEdited: root.themeCreationName = text
              background: Rectangle {
                color: Theme.surfaceHover
                radius: Theme.radiusSm
                border.width: Theme.borderWidth
                border.color: themeNameField.text === "" || root.validThemeName(themeNameField.text)
                  ? (themeNameField.activeFocus ? Theme.accent : Theme.border) : Theme.error
              }
            }
            Button {
              Layout.preferredHeight: Theme.controlHeight
              enabled: !root.themeCreating && root.validThemeName(root.themeCreationName)
              buttonColor: enabled ? Theme.accent : Theme.surfaceHover
              buttonBorderColor: enabled ? Theme.accent : Theme.border
              accessibleName: "Create and apply theme"
              onClicked: root.createTheme()
              Text {
                anchors.centerIn: parent
                text: root.themeCreating ? "Creating…" : "Create & Apply"
                color: parent.enabled ? Theme.background : Theme.foregroundMuted
                font.pixelSize: Theme.fontCaption
                font.weight: Theme.weightStrong
              }
            }
          }

          Text {
            Layout.fillWidth: true
            visible: root.themeCreationName !== "" && !root.validThemeName(root.themeCreationName)
            text: "Use 1–32 letters, numbers, hyphens, or underscores; begin with a letter or number."
            color: Theme.error
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
          }

          GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.spaceSm
            rowSpacing: Theme.spaceSm

            Text {
              Layout.columnSpan: 2
              text: "Palette"
              color: Theme.foreground
              font.pixelSize: Theme.fontCaption
              font.weight: Theme.weightStrong
            }

            Repeater {
              model: [
                { key: "background", label: "Background" },
                { key: "surface", label: "Surface" },
                { key: "surface_hover", label: "Surface hover" },
                { key: "foreground", label: "Foreground" },
                { key: "foreground_muted", label: "Muted text" },
                { key: "border", label: "Border" },
                { key: "accent", label: "Accent" },
                { key: "selection_background", label: "Selection" },
                { key: "selection_foreground", label: "Selected text" },
                { key: "cursor", label: "Cursor" },
                { key: "error", label: "Error" },
                { key: "warning", label: "Warning" },
                { key: "success", label: "Success" },
                { key: "info", label: "Info" }
              ]
              RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: Theme.spaceSm
                Rectangle {
                  Layout.preferredWidth: 18
                  Layout.preferredHeight: 18
                  radius: Theme.radiusSm
                  color: root.themeCreationColors[modelData.key]
                  border.width: Theme.borderWidth
                  border.color: Theme.foregroundMuted
                }
                Text {
                  Layout.fillWidth: true
                  text: modelData.label
                  color: Theme.foreground
                  font.pixelSize: Theme.fontCaption
                  elide: Text.ElideRight
                }
                TextField {
                  id: paletteColorField
                  Layout.preferredWidth: 76
                  Layout.preferredHeight: Theme.controlHeight
                  text: root.themeCreationColors[modelData.key]
                  color: Theme.foreground
                  font.pixelSize: Theme.fontCaption
                  selectByMouse: true
                  horizontalAlignment: Text.AlignHCenter
                  background: Rectangle {
                    color: Theme.surfaceHover
                    radius: Theme.radiusSm
                    border.width: Theme.borderWidth
                    border.color: /^#[0-9A-Fa-f]{6}$/.test(paletteColorField.text)
                      ? (paletteColorField.activeFocus ? Theme.accent : Theme.border) : Theme.error
                  }
                  onTextEdited: {
                    if (/^#[0-9A-Fa-f]{6}$/.test(text))
                      root.setThemeColorValue(modelData.key, text)
                  }
                  onEditingFinished: {
                    if (/^#[0-9A-Fa-f]{6}$/.test(text))
                      root.setThemeColorValue(modelData.key, text)
                    else
                      text = root.themeCreationColors[modelData.key]
                  }
                }
              }
            }
          }
        }
      }

      Text {
        visible: appearanceRoot.wallpaperOnly
        text: "Login screen"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      ToggleRow {
        visible: appearanceRoot.wallpaperOnly
        label: "Use wallpaper on login screen"
        description: checked
          ? "Wallpaper changes are also copied to the SDDM login screen"
          : "Keep the SDDM login screen wallpaper unchanged"
        checked: root.value("appearance", "sddmWallpaper", false)
        onChanged: function(enabled) {
          root.setValue("appearance", "sddmWallpaper", enabled)
        }
      }

      Text {
        visible: appearanceRoot.wallpaperOnly
        text: "Automatic rotation"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      ToggleRow {
        visible: appearanceRoot.wallpaperOnly
        label: "Change wallpaper automatically"
        description: checked
          ? "The wallpaper changes on the selected schedule"
          : "Keep the current wallpaper until you change it"
        checked: root.value("appearance", "wallpaperRotation", false)
        expandable: true
        expanded: appearanceRoot.rotationExpanded
        onChanged: function(enabled) {
          root.setValue("appearance", "wallpaperRotation", enabled)
          if (!enabled)
            appearanceRoot.rotationExpanded = false
        }
        onExpansionChanged: function(expanded) {
          appearanceRoot.rotationExpanded = expanded
        }
      }

      ChoiceRow {
        visible: appearanceRoot.wallpaperOnly
          && root.value("appearance", "wallpaperRotation", false)
          && appearanceRoot.rotationExpanded
        label: "Wallpaper source"
        description: "Rotate through the active theme or your general wallpaper folder"
        options: ["theme", "general"]
        selectedValue: root.value("appearance", "wallpaperRotationSource", "theme")
        optionLabel: function(value) {
          return value === "theme" ? "Current theme" : "General wallpapers"
        }
        onChosen: function(value) {
          root.setValue("appearance", "wallpaperRotationSource", value)
        }
      }

      NumericRow {
        visible: appearanceRoot.wallpaperOnly
          && root.value("appearance", "wallpaperRotation", false)
          && appearanceRoot.rotationExpanded
        label: "Rotation interval"
        description: "Minutes between wallpaper changes"
        currentValue: Math.max(1, Math.round(root.value("appearance",
          "wallpaperRotationInterval", 900) / 60))
        from: 1
        to: 1440
        onChanged: function(value) {
          root.setValue("appearance", "wallpaperRotationInterval", value * 60)
        }
      }

      Text {
        visible: appearanceRoot.wallpaperOnly
        text: "Wallpaper folder"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      Rectangle {
        visible: appearanceRoot.wallpaperOnly
        Layout.fillWidth: true
        implicitHeight: wallpaperFolderLayout.implicitHeight + Theme.spaceLg * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        RowLayout {
          id: wallpaperFolderLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceLg
          spacing: Theme.spaceSm
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text { text: "Image source"; color: Theme.foreground; font.pixelSize: Theme.fontBody; font.weight: Theme.weightMedium }
            Text { Layout.fillWidth: true; text: root.wallpaperDirectory(); color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption; elide: Text.ElideMiddle }
          }
          Button {
            Layout.preferredHeight: 32
            enabled: !wallpaperFolderCreationProcess.running
            accessibleName: "Choose wallpaper folder"
            onClicked: root.browseWallpaperDirectory()
            Text { anchors.centerIn: parent; text: wallpaperFolderCreationProcess.running ? "Creating…" : "Browse…"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontBody }
          }
        }
      }

      Text {
        Layout.fillWidth: true
        visible: appearanceRoot.wallpaperOnly && (root.appearanceWallpapersLoading
          || root.appearanceWallpaperError !== ""
          || root.appearanceWallpapers.length === 0)
        text: root.appearanceWallpapersLoading ? "Loading wallpapers…"
          : (root.appearanceWallpaperError !== "" ? root.appearanceWallpaperError
            : "No JPG, PNG, or WebP images found in this folder")
        color: root.appearanceWallpaperError !== "" ? Theme.error : Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
      }

      Text {
        visible: appearanceRoot.wallpaperOnly && root.appearanceWallpapers.length > 0
        text: "Local wallpapers"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      GridLayout {
        visible: appearanceRoot.wallpaperOnly
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Theme.spaceSm
        rowSpacing: Theme.spaceSm

        Repeater {
          model: root.appearanceWallpaperPageItems()
          Rectangle {
            id: wallpaperTile
            required property string modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 112
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: wallpaperHover.hovered ? Theme.accent : Theme.border
            radius: Theme.radiusLg
            clip: true

            Image {
              anchors.fill: parent
              source: root.wallpaperImageSource(wallpaperTile.modelData)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
            }
            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 25
              color: "#99000000"
              Text {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceSm
                anchors.rightMargin: Theme.spaceSm
                verticalAlignment: Text.AlignVCenter
                text: wallpaperTile.modelData.substring(wallpaperTile.modelData.lastIndexOf("/") + 1)
                color: "#ffffff"
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideMiddle
              }
            }
            HoverHandler { id: wallpaperHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              enabled: !root.wallpaperApplying
              onTapped: root.applyWallpaper(wallpaperTile.modelData)
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        visible: appearanceRoot.wallpaperOnly && root.appearanceWallpapers.length > root.appearanceWallpaperPageSize
        spacing: Theme.spaceSm

        Text {
          Layout.fillWidth: true
          text: "Local folder · " + root.appearanceWallpapers.length + " wallpapers"
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
        Button {
          Layout.preferredHeight: 32
          enabled: root.appearanceWallpaperPage > 1
          accessibleName: "Previous wallpaper page"
          onClicked: root.appearanceWallpaperPage = Math.max(1,
            root.appearanceWallpaperPage - 1)
          Text { anchors.centerIn: parent; text: "‹"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontTitle }
        }
        Text {
          text: root.appearanceWallpaperPage + " / " + root.appearanceWallpaperPageCount()
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
        Button {
          Layout.preferredHeight: 32
          enabled: root.appearanceWallpaperPage < root.appearanceWallpaperPageCount()
          accessibleName: "Next wallpaper page"
          onClicked: root.appearanceWallpaperPage = Math.min(
            root.appearanceWallpaperPageCount(), root.appearanceWallpaperPage + 1)
          Text { anchors.centerIn: parent; text: "›"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontTitle }
        }
      }

      Text {
        visible: appearanceRoot.wallpaperOnly
        text: "Online wallpapers"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      Rectangle {
        visible: appearanceRoot.wallpaperOnly
        Layout.fillWidth: true
        implicitHeight: 42
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        RowLayout {
          anchors.fill: parent
          anchors.margins: 3
          spacing: 2

          Repeater {
            model: [
              { key: "wallhaven", label: "Wallhaven" },
              { key: "openverse", label: "Openverse" },
              { key: "wikimedia", label: "Wikimedia Commons" },
              { key: "nasa", label: "NASA APOD" }
            ]
            Rectangle {
              id: wallpaperTab
              required property var modelData
              readonly property bool selected: root.wallpaperSource === modelData.key
              readonly property bool available: !root.wallhavenLoading
                && !root.onlineWallpapersLoading
              Layout.fillWidth: true
              Layout.fillHeight: true
              color: selected || wallpaperTabHover.hovered
                ? Theme.surfaceHover : "transparent"
              radius: Theme.radiusSm
              opacity: available ? 1 : 0.55
              Accessible.role: Accessible.PageTab
              Accessible.name: modelData.label
              Accessible.selected: selected

              Text {
                anchors.centerIn: parent
                text: wallpaperTab.modelData.label
                color: wallpaperTab.selected ? Theme.accent : Theme.foreground
                font.pixelSize: Theme.fontBody
                font.weight: wallpaperTab.selected
                  ? Theme.weightStrong : Theme.weightMedium
              }

              Rectangle {
                visible: wallpaperTab.selected && !root.wallhavenLoading
                  && !root.onlineWallpapersLoading
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Theme.spaceSm
                anchors.rightMargin: Theme.spaceSm
                height: 2
                color: Theme.accent
                radius: 1
              }

              Rectangle {
                id: tabLoadingLine
                visible: wallpaperTab.selected && (root.wallhavenLoading
                  || root.onlineWallpapersLoading)
                anchors.bottom: parent.bottom
                height: 2
                width: parent.width * 0.3
                color: Theme.accent
                radius: 1

                SequentialAnimation on x {
                  running: tabLoadingLine.visible
                  loops: Animation.Infinite
                  NumberAnimation {
                    from: Theme.spaceSm
                    to: wallpaperTab.width - tabLoadingLine.width - Theme.spaceSm
                    duration: 600
                    easing.type: Easing.InOutQuad
                  }
                  NumberAnimation {
                    from: wallpaperTab.width - tabLoadingLine.width - Theme.spaceSm
                    to: Theme.spaceSm
                    duration: 600
                    easing.type: Easing.InOutQuad
                  }
                }
              }

              HoverHandler {
                id: wallpaperTabHover
                cursorShape: wallpaperTab.available
                  ? Qt.PointingHandCursor : Qt.ArrowCursor
              }
              TapHandler {
                enabled: wallpaperTab.available
                onTapped: {
                  root.wallpaperSource = wallpaperTab.modelData.key
                  if (wallpaperTab.modelData.key === "wallhaven") {
                    if (root.wallhavenWallpapers.length === 0)
                      root.loadWallhaven(1)
                  } else {
                    root.onlineWallpaperSource = wallpaperTab.modelData.key
                    root.loadOnlineWallpapers(1)
                  }
                }
              }
            }
          }
        }

      }

      RowLayout {
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource === "wallhaven"
        Layout.fillWidth: true
        spacing: Theme.spaceSm
        TextField {
          id: wallhavenSearch
          Layout.fillWidth: true
          Layout.preferredHeight: 34
          placeholderText: "Search Wallhaven"
          selectByMouse: true
          color: Theme.foreground
          placeholderTextColor: Theme.foregroundMuted
          font.pixelSize: Theme.fontBody
          leftPadding: Theme.spaceSm
          rightPadding: Theme.spaceSm
          Accessible.name: "Search Wallhaven"
          background: Rectangle {
            color: Theme.surfaceHover
            radius: Theme.radiusSm
            border.width: Theme.borderWidth
            border.color: parent.activeFocus ? Theme.accent : Theme.border
          }
          onTextEdited: {
            root.wallhavenQuery = text
            wallhavenSearchTimer.restart()
          }
          onAccepted: {
            wallhavenSearchTimer.stop()
            root.wallhavenQuery = text
            root.loadWallhaven(1)
          }
        }
        Button {
          Layout.preferredHeight: 34
          enabled: !root.wallhavenLoading
          accessibleName: "Search Wallhaven"
          onClicked: {
            wallhavenSearchTimer.stop()
            root.wallhavenQuery = wallhavenSearch.text
            root.loadWallhaven(1)
          }
          Text { anchors.centerIn: parent; text: "Search"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontBody }
        }
      }

      GridLayout {
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource === "wallhaven"
        Layout.fillWidth: true
        columns: 4
        columnSpacing: Theme.spaceSm
        rowSpacing: Theme.spaceSm

        TimezoneDropdown {
          label: "Sort"
          options: ["toplist", "hot", "date_added", "views", "favorites", "random"]
          selectedValue: root.wallhavenSorting
          optionLabel: function(value) {
            return ({toplist: "Toplist", hot: "Hot", date_added: "Newest",
              views: "Most viewed", favorites: "Favorites", random: "Random"})[value] || value
          }
          onChosen: function(value) { root.wallhavenSorting = value; root.loadWallhaven(1) }
        }
        TimezoneDropdown {
          label: "Time range"
          options: ["1d", "3d", "1w", "1M", "3M", "6M", "1y"]
          selectedValue: root.wallhavenTopRange
          optionLabel: function(value) {
            return ({"1d": "Today", "3d": "3 days", "1w": "This week",
              "1M": "This month", "3M": "3 months", "6M": "6 months",
              "1y": "This year"})[value] || value
          }
          onChosen: function(value) { root.wallhavenTopRange = value; root.loadWallhaven(1) }
        }
        TimezoneDropdown {
          label: "Size"
          options: ["1280x720", "1920x1080", "2560x1440", "3840x2160"]
          selectedValue: root.wallhavenMinimumResolution
          optionLabel: function(value) { return "At least " + value }
          onChosen: function(value) { root.wallhavenMinimumResolution = value; root.loadWallhaven(1) }
        }
        TimezoneDropdown {
          label: "Category"
          options: ["111", "100", "010", "001"]
          selectedValue: root.wallhavenCategories
          optionLabel: function(value) {
            return ({"111": "All", "100": "General", "010": "Anime",
              "001": "People"})[value] || value
          }
          onChosen: function(value) { root.wallhavenCategories = value; root.loadWallhaven(1) }
        }
      }

      Text {
        Layout.fillWidth: true
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource === "wallhaven"
          && (root.wallhavenLoading || root.wallhavenDownloading
          || root.wallhavenError !== ""
          || (!root.wallhavenLoading && root.wallhavenWallpapers.length === 0))
        text: root.wallhavenLoading ? "Loading Wallhaven…"
          : (root.wallhavenDownloading ? "Downloading and applying wallpaper…"
            : (root.wallhavenError !== "" ? root.wallhavenError
              : "Search Wallhaven to browse online wallpapers"))
        color: root.wallhavenError !== "" ? Theme.error : Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
      }

      Text {
        Layout.fillWidth: true
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource === "wallhaven"
          && !root.wallhavenLoading && root.wallhavenError === ""
          && root.wallhavenTotal > 0
        text: root.wallhavenTotal.toLocaleString() + " wallpapers found"
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
      }

      GridLayout {
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource === "wallhaven"
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Theme.spaceSm
        rowSpacing: Theme.spaceSm

        Repeater {
          model: root.wallhavenWallpapers
          Rectangle {
            id: wallhavenTile
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 112
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: wallhavenHover.hovered ? Theme.accent : Theme.border
            radius: Theme.radiusLg
            clip: true
            opacity: root.wallhavenDownloading ? 0.6 : 1

            Image {
              anchors.fill: parent
              source: wallhavenTile.modelData.thumbs
                ? wallhavenTile.modelData.thumbs.large : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
            }
            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 25
              color: "#99000000"
              Text {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceSm
                anchors.rightMargin: Theme.spaceSm
                verticalAlignment: Text.AlignVCenter
                text: "wallhaven-" + wallhavenTile.modelData.id + "  "
                  + wallhavenTile.modelData.resolution
                color: "#ffffff"
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideRight
              }
            }
            HoverHandler { id: wallhavenHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              enabled: !root.wallhavenDownloading
              onTapped: root.useWallhavenWallpaper(wallhavenTile.modelData)
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource === "wallhaven"
          && root.wallhavenWallpapers.length > 0
        spacing: Theme.spaceSm

        Text {
          Layout.fillWidth: true
          text: "Wallhaven · " + root.wallhavenTotal + " wallpapers"
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
        Button {
          Layout.preferredHeight: 32
          enabled: root.wallhavenPage > 1 && !root.wallhavenLoading
          accessibleName: "Previous Wallhaven page"
          onClicked: root.loadWallhaven(root.wallhavenPage - 1)
          Text { anchors.centerIn: parent; text: "‹"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontTitle }
        }

        Text {
          text: "Page " + root.wallhavenPage + " / " + root.wallhavenLastPage
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }

        Button {
          Layout.preferredHeight: 32
          enabled: root.wallhavenPage < root.wallhavenLastPage
            && !root.wallhavenLoading
          visible: root.wallhavenPage < root.wallhavenLastPage
          accessibleName: "Next Wallhaven page"
          onClicked: root.loadWallhaven(root.wallhavenPage + 1)
          Text { anchors.centerIn: parent; text: "›"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontTitle }
        }
      }

      RowLayout {
        visible: appearanceRoot.wallpaperOnly
          && (root.wallpaperSource === "openverse"
            || root.wallpaperSource === "wikimedia")
        Layout.fillWidth: true
        spacing: Theme.spaceSm

        LabeledField {
          Layout.fillWidth: true
          visible: root.wallpaperSource === "openverse"
            || root.wallpaperSource === "wikimedia"
          label: "Search"
          placeholder: "Nature, space, architecture…"
          fieldText: root.onlineWallpaperQuery
          onCommitted: function(value) {
            root.onlineWallpaperQuery = value
            root.loadOnlineWallpapers(1)
          }
        }

        Button {
          Layout.alignment: Qt.AlignBottom
          visible: root.wallpaperSource === "openverse"
            || root.wallpaperSource === "wikimedia"
          Layout.preferredHeight: 34
          enabled: !root.onlineWallpapersLoading
          accessibleName: "Browse selected wallpaper source"
          onClicked: root.loadOnlineWallpapers(1)
          Text {
            anchors.centerIn: parent
            text: root.onlineWallpapersLoading ? "Loading…" : "Browse"
            color: parent.enabled ? Theme.foreground : Theme.foregroundMuted
            font.pixelSize: Theme.fontBody
          }
        }
      }

      Text {
        Layout.fillWidth: true
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource !== "wallhaven"
          && (root.onlineWallpaperDownloading || root.onlineWallpaperError !== "")
        text: root.onlineWallpapersLoading ? "Loading wallpapers…"
          : (root.onlineWallpaperDownloading ? "Downloading and applying wallpaper…"
            : root.onlineWallpaperError)
        color: root.onlineWallpaperError !== "" ? Theme.error : Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
      }

      GridLayout {
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource !== "wallhaven"
          && root.onlineWallpapers.length > 0
        opacity: root.onlineWallpapersLoading ? 0.45 : 1
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Theme.spaceSm
        rowSpacing: Theme.spaceSm

        Repeater {
          model: root.onlineWallpapers
          Rectangle {
            id: onlineWallpaperTile
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 124
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: onlineWallpaperHover.hovered ? Theme.accent : Theme.border
            radius: Theme.radiusLg
            clip: true
            opacity: root.onlineWallpaperDownloading ? 0.6 : 1

            Image {
              anchors.fill: parent
              source: onlineWallpaperTile.modelData.previewUrl
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
            }
            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 38
              color: "#aa000000"
              ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceSm
                anchors.rightMargin: Theme.spaceSm
                spacing: 0
                Text {
                  Layout.fillWidth: true
                  text: onlineWallpaperTile.modelData.title
                  color: "#ffffff"
                  font.pixelSize: Theme.fontCaption
                  elide: Text.ElideRight
                }
                Text {
                  Layout.fillWidth: true
                  text: onlineWallpaperTile.modelData.credit + " · "
                    + onlineWallpaperTile.modelData.resolution
                  color: "#cccccc"
                  font.pixelSize: 9
                  elide: Text.ElideRight
                }
              }
            }
            HoverHandler { id: onlineWallpaperHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              enabled: !root.onlineWallpaperDownloading
              onTapped: root.useOnlineWallpaper(onlineWallpaperTile.modelData)
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        visible: appearanceRoot.wallpaperOnly && root.wallpaperSource !== "wallhaven"
          && root.onlineWallpapers.length > 0
        spacing: Theme.spaceSm
        Text {
          Layout.fillWidth: true
          text: root.onlineWallpaperSource === "openverse"
            ? "Openverse · openly licensed media"
            : (root.onlineWallpaperSource === "wikimedia"
              ? "Wikimedia Commons" : "NASA Astronomy Picture of the Day")
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
        Button {
          Layout.preferredHeight: 32
          enabled: root.onlineWallpaperPage > 1 && !root.onlineWallpapersLoading
          onClicked: root.loadOnlineWallpapers(root.onlineWallpaperPage - 1)
          Text { anchors.centerIn: parent; text: "‹"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontTitle }
        }
        Text {
          text: "Page " + root.onlineWallpaperPage
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
        Button {
          Layout.preferredHeight: 32
          enabled: root.onlineWallpaperPage < root.onlineWallpaperPageCount
            && !root.onlineWallpapersLoading
          onClicked: root.loadOnlineWallpapers(root.onlineWallpaperPage + 1)
          Text { anchors.centerIn: parent; text: "›"; color: parent.enabled ? Theme.foreground : Theme.foregroundMuted; font.pixelSize: Theme.fontTitle }
        }
      }

      Text {
        visible: appearanceRoot.effectsOnly
        text: "Bar"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      ChoiceRow {
        visible: appearanceRoot.effectsOnly
        label: "Bar style"
        description: "Choose the shape of the desktop bar"
        options: ["pills", "bar"]
        selectedValue: Bar.BarStyle.style
        optionLabel: function(value) {
          if (value === "bar") return "Bar"
          return "Pills"
        }
        onChosen: function(value) { Bar.BarStyle.style = value }
      }
      ChoiceRow {
        visible: appearanceRoot.effectsOnly
        label: "Bar position"
        description: "Place the bar along any screen edge"
        options: ["top", "bottom", "left", "right"]
        selectedValue: Bar.BarStyle.position
        optionLabel: function(value) {
          if (value === "bottom") return "Bottom"
          if (value === "left") return "Left"
          if (value === "right") return "Right"
          return "Top"
        }
        onChosen: function(value) { Bar.BarStyle.position = value }
      }
      ScriptActionRow {
        visible: appearanceRoot.effectsOnly
        label: "Edit bar"
        description: "Drag and drop items directly on the bar. Changes are saved automatically."
        actionText: "Edit"
        onTriggered: Bar.BarStyle.editing = true
      }
      Text {
        visible: appearanceRoot.effectsOnly && Bar.BarStyle.editing
        Layout.fillWidth: true
        text: "Drag items directly on the bar. Drop between items to reorder, or into another section to move. Drag available items onto the bar to add them."
        wrapMode: Text.WordWrap
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
      }
      ChoiceRow {
        visible: appearanceRoot.effectsOnly
        label: "Clock format"
        description: "Choose which time and date details appear in the bar"
        options: Bar.BarStyle.timeFormats
        selectedValue: Bar.BarStyle.timeFormat
        optionLabel: function(value) {
          if (value === "time-seconds") return "Time with seconds"
          if (value === "day-time") return "Day and time"
          if (value === "date-time") return "Date and time"
          if (value === "day-date-time") return "Day, date, and time"
          return "Time only"
        }
        onChosen: function(value) { Bar.BarStyle.timeFormat = value }
      }
      ChoiceRow {
        visible: appearanceRoot.effectsOnly
        label: "Workspace indicators"
        description: "Choose how workspaces are represented in the bar"
        options: Bar.WorkspaceDisplay.displayModes
        selectedValue: Bar.WorkspaceDisplay.displayMode
        optionLabel: function(value) {
          if (value === "shapes") return "Shapes"
          if (value === "pacman") return "Pacman"
          return value === "symbols" ? "Symbols" : "Numbers"
        }
        onChosen: function(value) { Bar.WorkspaceDisplay.displayMode = value }
      }
      Text {
        visible: appearanceRoot.effectsOnly
        text: "Window shape"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Quickshell corner rounding"
        description: "Shared corner radius for menus, widgets, and controls"
        currentValue: Theme.cornerRadius
        from: 0; to: 15; stepSize: 1
        onChanged: function(value) { Theme.cornerRadius = value }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Corner rounding"
        description: "Radius of window corners"
        currentValue: root.value("appearance", "rounding", 4)
        from: 0; to: 30; stepSize: 1
        onChanged: function(value) { root.setValue("appearance", "rounding", value) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Rounding power"
        description: "Shape of rounded window corners"
        currentValue: root.value("appearance", "roundingPower", 2)
        from: 1; to: 10; stepSize: 1
        onChanged: function(value) { root.setValue("appearance", "roundingPower", value) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Border size"
        description: "Width of window borders"
        currentValue: root.value("appearance", "borderSize", 1)
        from: 0; to: 10; stepSize: 1
        onChanged: function(value) { root.setValue("appearance", "borderSize", value) }
      }

      Text {
        visible: appearanceRoot.effectsOnly
        text: "Opacity"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Active window opacity"
        description: "Opacity of focused windows in percent"
        currentValue: Math.round(root.value("appearance", "activeOpacity", 1) * 100)
        from: 10; to: 100; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "activeOpacity", value / 100) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Inactive window opacity"
        description: "Opacity of unfocused windows in percent"
        currentValue: Math.round(root.value("appearance", "inactiveOpacity", 1) * 100)
        from: 10; to: 100; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "inactiveOpacity", value / 100) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
        label: "Fullscreen opacity"
        description: "Opacity of fullscreen windows in percent"
        currentValue: Math.round(root.value("appearance", "fullscreenOpacity", 1) * 100)
        from: 10; to: 100; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "fullscreenOpacity", value / 100) }
      }

      Text {
        visible: appearanceRoot.effectsOnly
        text: "Dimming"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      ToggleRow {
        visible: appearanceRoot.effectsOnly
        label: "Dim inactive windows"
        description: "Darken windows that are not focused"
        checked: root.value("appearance", "dimInactive", false)
        expandable: true
        expanded: appearanceRoot.dimmingExpanded
        onChanged: function(value) {
          root.setValue("appearance", "dimInactive", value)
          if (!value) appearanceRoot.dimmingExpanded = false
        }
        onExpansionChanged: function(expanded) {
          appearanceRoot.dimmingExpanded = expanded
        }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "dimInactive", false)
          && appearanceRoot.dimmingExpanded
        label: "Dim around"
        description: "Dimming around modal windows in percent"
        currentValue: Math.round(root.value("appearance", "dimAround", 0.4) * 100)
        from: 0; to: 100; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "dimAround", value / 100) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "dimInactive", false)
          && appearanceRoot.dimmingExpanded
        label: "Dim special"
        description: "Dimming behind special workspaces in percent"
        currentValue: Math.round(root.value("appearance", "dimSpecial", 0.2) * 100)
        from: 0; to: 100; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "dimSpecial", value / 100) }
      }

      Text {
        visible: appearanceRoot.effectsOnly
        text: "Motion"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      ToggleRow {
        visible: appearanceRoot.effectsOnly
        label: "Animations"
        description: "Animate windows, layers, and workspace transitions"
        checked: root.value("appearance", "animations", true)
        onChanged: function(value) { root.setValue("appearance", "animations", value) }
      }

      Text {
        visible: appearanceRoot.effectsOnly
        text: "Blur"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      ToggleRow {
        visible: appearanceRoot.effectsOnly
        label: "Enable blur"
        description: "Blur translucent windows and surfaces"
        checked: root.value("appearance", "blur", true)
        expandable: true
        expanded: appearanceRoot.blurExpanded
        onChanged: function(value) {
          root.setValue("appearance", "blur", value)
          if (!value) appearanceRoot.blurExpanded = false
        }
        onExpansionChanged: function(expanded) {
          appearanceRoot.blurExpanded = expanded
        }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "blur", true)
          && appearanceRoot.blurExpanded
        label: "Blur size"
        description: "Radius of the blur effect"
        currentValue: root.value("appearance", "blurSize", 3)
        from: 1; to: 40; stepSize: 1
        onChanged: function(value) { root.setValue("appearance", "blurSize", value) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "blur", true)
          && appearanceRoot.blurExpanded
        label: "Blur passes"
        description: "Number of blur processing passes"
        currentValue: root.value("appearance", "blurPasses", 1)
        from: 1; to: 10; stepSize: 1
        onChanged: function(value) { root.setValue("appearance", "blurPasses", value) }
      }
      ToggleRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "blur", true)
          && appearanceRoot.blurExpanded
        label: "Ignore opacity"
        description: "Blur transparent surfaces without using their opacity"
        checked: root.value("appearance", "blurIgnoreOpacity", false)
        onChanged: function(value) { root.setValue("appearance", "blurIgnoreOpacity", value) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "blur", true)
          && appearanceRoot.blurExpanded
        label: "Blur noise"
        description: "Noise mixed into the blur in percent"
        currentValue: Math.round(root.value("appearance", "blurNoise", 0.0117) * 100)
        from: 0; to: 100; stepSize: 1
        onChanged: function(value) { root.setValue("appearance", "blurNoise", value / 100) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "blur", true)
          && appearanceRoot.blurExpanded
        label: "Blur contrast"
        description: "Contrast of blurred surfaces in percent"
        currentValue: Math.round(root.value("appearance", "blurContrast", 0.8916) * 100)
        from: 0; to: 200; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "blurContrast", value / 100) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "blur", true)
          && appearanceRoot.blurExpanded
        label: "Blur brightness"
        description: "Brightness of blurred surfaces in percent"
        currentValue: Math.round(root.value("appearance", "blurBrightness", 0.8172) * 100)
        from: 0; to: 200; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "blurBrightness", value / 100) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "blur", true)
          && appearanceRoot.blurExpanded
        label: "Blur vibrancy"
        description: "Color saturation added to blur in percent"
        currentValue: Math.round(root.value("appearance", "blurVibrancy", 0.1696) * 100)
        from: 0; to: 100; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "blurVibrancy", value / 100) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "blur", true)
          && appearanceRoot.blurExpanded
        label: "Blur vibrancy darkness"
        description: "Darkening applied by vibrancy in percent"
        currentValue: Math.round(root.value("appearance", "blurVibrancyDarkness", 0) * 100)
        from: 0; to: 100; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "blurVibrancyDarkness", value / 100) }
      }

      Text {
        visible: appearanceRoot.effectsOnly
        text: "Shadows"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }
      ToggleRow {
        visible: appearanceRoot.effectsOnly
        label: "Enable shadows"
        description: "Draw shadows behind windows"
        checked: root.value("appearance", "shadows", true)
        expandable: true
        expanded: appearanceRoot.shadowsExpanded
        onChanged: function(value) {
          root.setValue("appearance", "shadows", value)
          if (!value) appearanceRoot.shadowsExpanded = false
        }
        onExpansionChanged: function(expanded) {
          appearanceRoot.shadowsExpanded = expanded
        }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "shadows", true)
          && appearanceRoot.shadowsExpanded
        label: "Shadow range"
        description: "Size of the window shadow"
        currentValue: root.value("appearance", "shadowRange", 4)
        from: 0; to: 100; stepSize: 1
        onChanged: function(value) { root.setValue("appearance", "shadowRange", value) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "shadows", true)
          && appearanceRoot.shadowsExpanded
        label: "Shadow render power"
        description: "Falloff curve of the window shadow"
        currentValue: root.value("appearance", "shadowRenderPower", 3)
        from: 1; to: 4; stepSize: 1
        onChanged: function(value) { root.setValue("appearance", "shadowRenderPower", value) }
      }
      NumericRow {
        visible: appearanceRoot.effectsOnly
          && root.value("appearance", "shadows", true)
          && appearanceRoot.shadowsExpanded
        label: "Shadow scale"
        description: "Scale of the window shadow in percent"
        currentValue: Math.round(root.value("appearance", "shadowScale", 1) * 100)
        from: 0; to: 100; stepSize: 5
        onChanged: function(value) { root.setValue("appearance", "shadowScale", value / 100) }
      }
    }
  }

  Component {
    id: applicationsPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg
      Component.onCompleted: {
        if (root.applicationPackages.length === 0)
          root.loadApplications()
        root.loadInstalledApplications()
      }

      SectionTitle {
        title: "Applications"
        description: "Search nixpkgs, try packages in a temporary shell, or install them for your user."
      }

      TextField {
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        text: root.applicationSearch
        placeholderText: "Search nixpkgs packages"
        selectByMouse: true
        color: Theme.foreground
        placeholderTextColor: Theme.foregroundMuted
        font.pixelSize: Theme.fontBody
        leftPadding: Theme.spaceLg
        rightPadding: Theme.spaceLg
        Accessible.name: "Search nixpkgs packages"
        onTextChanged: {
          root.applicationSearch = text
          if (text.trim() === "") {
            root.applicationsError = ""
            root.selectedApplication = null
          }
        }
        background: Rectangle {
          color: Theme.surfaceHover
          radius: Theme.radiusMd
          border.width: Theme.borderWidth
          border.color: parent.activeFocus ? Theme.accent : Theme.border
        }
      }

      Text {
        Layout.fillWidth: true
        visible: root.applicationsLoading || root.applicationsError !== ""
        text: root.applicationsLoading
          ? "Updating the local nixpkgs search index…" : root.applicationsError
        color: root.applicationsError !== "" ? Theme.error : Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
      }

      RowLayout {
        Layout.fillWidth: true
        visible: !root.applicationsLoading && root.applicationsError === ""
        Text {
          Layout.fillWidth: true
          text: root.applicationSearch.trim() === ""
            ? "Type to search " + root.applicationPackages.length + " packages"
            : root.filteredApplications().length + " results shown"
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
        Text {
          text: "Local catalog"
          color: Theme.success
          font.pixelSize: Theme.fontCaption
          font.weight: Theme.weightMedium
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 410
        spacing: Theme.spaceLg

        Rectangle {
          Layout.fillHeight: true
          Layout.preferredWidth: 250
          color: Theme.surface
          border.width: Theme.borderWidth
          border.color: Theme.border
          radius: Theme.radiusLg
          clip: true

          Flickable {
            anchors.fill: parent
            anchors.margins: Theme.spaceSm
            contentWidth: width
            contentHeight: applicationResults.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Controls.ScrollBar.vertical: Controls.ScrollBar {
              policy: Controls.ScrollBar.AsNeeded
            }

            ColumnLayout {
              id: applicationResults
              width: parent.width
              spacing: Theme.spaceXxs

              Repeater {
                model: root.filteredApplications()
                Button {
                  id: applicationResultButton
                  required property var modelData
                  Layout.fillWidth: true
                  Layout.preferredHeight: 32
                  enabled: !applicationMetadataProcess.running
                  horizontalPadding: Theme.spaceSm
                  buttonColor: root.selectedApplication !== null
                    && root.selectedApplication.attr === modelData.attr
                    ? Theme.surfaceHover : "transparent"
                  buttonBorderColor: root.selectedApplication !== null
                    && root.selectedApplication.attr === modelData.attr
                    ? Theme.accent : "transparent"
                  accessibleName: "Select " + root.applicationName(modelData)
                  onClicked: root.selectApplication(modelData)
                  Text {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spaceSm
                    anchors.rightMargin: Theme.spaceSm
                    text: root.applicationName(applicationResultButton.modelData)
                    color: Theme.foreground
                    font.pixelSize: Theme.fontBody
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: Theme.surface
          border.width: Theme.borderWidth
          border.color: Theme.border
          radius: Theme.radiusLg

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceXl
            spacing: Theme.spaceMd

            RowLayout {
              Layout.fillWidth: true
              spacing: Theme.spaceLg

              Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                color: Theme.surfaceHover
                radius: Theme.radiusMd
                Text {
                  anchors.centerIn: parent
                  text: "󰏖"
                  color: Theme.accent
                  font.pixelSize: Theme.fontTitle
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                  Layout.fillWidth: true
                  text: root.selectedApplication === null
                    ? "Select a package" : root.selectedApplication.name
                  color: Theme.foreground
                  font.pixelSize: Theme.fontTitle
                  font.weight: Theme.weightStrong
                  elide: Text.ElideRight
                }
                Text {
                  Layout.fillWidth: true
                  text: root.selectedApplication === null ? ""
                    : root.selectedApplication.attr
                      + (root.selectedApplication.version !== ""
                        ? "  ·  " + root.selectedApplication.version : "")
                  color: Theme.foregroundMuted
                  font.pixelSize: Theme.fontCaption
                  elide: Text.ElideRight
                }
              }

            }

            Text {
              Layout.fillWidth: true
              text: root.selectedApplication === null
                ? "Package details and actions will appear here."
                : root.applicationPreview
              color: root.selectedApplication === null
                ? Theme.foregroundMuted : Theme.foreground
              font.pixelSize: Theme.fontBody
              wrapMode: Text.WordWrap
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: Theme.borderWidth
              color: Theme.border
              visible: root.selectedApplication !== null
            }

            GridLayout {
              Layout.fillWidth: true
              columns: 2
              columnSpacing: Theme.spaceLg
              rowSpacing: Theme.spaceSm
              visible: root.selectedApplication !== null

              Text { text: "License"; color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
              Text {
                Layout.fillWidth: true
                text: root.selectedApplication ? (root.selectedApplication.license || "Not specified") : ""
                color: Theme.foreground
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideRight
              }
              Text { text: "Program"; color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
              Text {
                Layout.fillWidth: true
                text: root.selectedApplication
                  ? (root.selectedApplication.mainProgram || root.selectedApplication.name) : ""
                color: Theme.foreground
                font.pixelSize: Theme.fontCaption
                font.family: "monospace"
                elide: Text.ElideRight
              }
              Text { text: "Platforms"; color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
              Text {
                Layout.fillWidth: true
                text: root.selectedApplication && root.selectedApplication.platforms
                  ? root.selectedApplication.platforms.slice(0, 3).join(", ") : ""
                color: Theme.foreground
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideRight
              }
            }

            Button {
              Layout.preferredHeight: 30
              visible: root.selectedApplication !== null
                && (root.selectedApplication.homepage || "") !== ""
              accessibleName: "Open package homepage"
              onClicked: Quickshell.execDetached([
                "xdg-open", root.selectedApplication.homepage
              ])
              Text {
                anchors.centerIn: parent
                text: "󰖟  Open homepage"
                color: Theme.foreground
                font.pixelSize: Theme.fontCaption
              }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
              Layout.fillWidth: true
              spacing: Theme.spaceSm

              Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                enabled: root.selectedApplication !== null
                  && !root.applicationActionRunning
                accessibleName: "Open temporary shell with selected package"
                onClicked: root.useApplication()
                Text {
                  anchors.centerIn: parent
                  text: "Use temporarily"
                  color: parent.enabled ? Theme.foreground : Theme.foregroundMuted
                  font.pixelSize: Theme.fontBody
                }
              }

              Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                enabled: root.selectedApplication !== null
                  && !root.applicationActionRunning
                  && !root.isApplicationInstalled(root.selectedApplication)
                accessibleName: "Install selected package for this user"
                onClicked: root.installApplication()
                buttonColor: enabled ? Theme.accent : Theme.surfaceHover
                buttonBorderColor: enabled ? Theme.accent : Theme.border
                Text {
                  anchors.centerIn: parent
                  text: root.applicationActionRunning
                    && root.applicationActionVerb === "install" ? "Installing…"
                    : (root.isApplicationInstalled(root.selectedApplication)
                      ? "Installed" : "Install")
                  color: parent.enabled ? Theme.background : Theme.foregroundMuted
                  font.pixelSize: Theme.fontBody
                  font.weight: Theme.weightMedium
                }
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spaceSm
        Text {
          Layout.fillWidth: true
          text: "Installed packages"
          color: Theme.foreground
          font.pixelSize: Theme.fontTitle
          font.weight: Theme.weightStrong
        }
        Text {
          text: root.installedApplicationEntries().length + " installed"
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: installedPackagesLayout.implicitHeight + Theme.spaceSm * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        ColumnLayout {
          id: installedPackagesLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceSm
          spacing: Theme.spaceXxs

          Text {
            Layout.fillWidth: true
            Layout.margins: Theme.spaceSm
            visible: root.installedApplicationEntries().length === 0
            text: "No packages are installed in the user profile."
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
          }

          Repeater {
            model: root.installedApplicationEntries()
            RowLayout {
              id: installedPackageRow
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredHeight: 38
              Layout.leftMargin: Theme.spaceSm
              spacing: Theme.spaceSm

              Item {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28

                IconImage {
                  anchors.fill: parent
                  visible: installedPackageRow.modelData.icon !== ""
                  source: visible
                    ? root.wallpaperImageSource(installedPackageRow.modelData.icon) : ""
                }

                Text {
                  anchors.centerIn: parent
                  visible: installedPackageRow.modelData.icon === ""
                  text: "󰏖"
                  color: Theme.foregroundMuted
                  font.pixelSize: Theme.fontBody
                }
              }

              Text {
                Layout.fillWidth: true
                text: installedPackageRow.modelData.attr
                color: Theme.foreground
                font.pixelSize: Theme.fontBody
                elide: Text.ElideRight
              }

              Button {
                Layout.preferredWidth: 92
                Layout.preferredHeight: 30
                enabled: !root.applicationActionRunning
                accessibleName: "Uninstall " + installedPackageRow.modelData.attr
                onClicked: root.removeApplication(installedPackageRow.modelData)
                buttonBorderColor: enabled ? Theme.error : Theme.border
                Text {
                  anchors.centerIn: parent
                  text: root.applicationActionRunning
                    && root.applicationActionVerb === "remove"
                    && root.applicationName(root.installingApplication)
                      === installedPackageRow.modelData.attr ? "Removing…" : "Uninstall"
                  color: parent.enabled ? Theme.error : Theme.foregroundMuted
                  font.pixelSize: Theme.fontCaption
                  font.weight: Theme.weightMedium
                }
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: inputPage
    ColumnLayout {
      id: inputRoot
      property bool advancedKeyboard: String(root.value("input", "layout", "us")).indexOf(",") !== -1
      readonly property string layoutCode: String(root.value("input", "layout", "us"))
      readonly property string variantCode: String(root.value("input", "variant", ""))
      readonly property var selectedLayout: root.keyboardLayouts.find(function(layout) {
        return layout.code === inputRoot.layoutCode
      })
      Component.onCompleted: {
        if (!root.keyboardLayouts.length && !keyboardCatalogProcess.running) {
          root.keyboardCatalogLoading = true
          keyboardCatalogProcess.exec(["atlas", "settings", "keyboard-catalog"])
        }
      }
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg

      SectionTitle {
        title: "Input"
        description: "Configure the keyboard, pointer focus, and touchpad behavior. Changes apply when this page is saved."
      }

      Text {
        text: "Keyboard"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: keyboardSettings.implicitHeight + Theme.spaceLg * 2
        color: Theme.surface
        radius: Theme.radiusLg
        border.width: Theme.borderWidth
        border.color: Theme.border
        ColumnLayout {
          id: keyboardSettings
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Theme.spaceLg
          spacing: Theme.spaceMd

          Text {
            Layout.fillWidth: true
            text: "Choose a layout, then a compatible variant. Search by language, country, or code."
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
          }
          KeyboardChoice {
            visible: !inputRoot.advancedKeyboard
            label: "Keyboard layout"
            options: root.keyboardLayouts
            selectedCode: inputRoot.layoutCode
            onChosen: function(code) {
              if (code === inputRoot.layoutCode) return
              root.setValue("input", "layout", code)
              root.setValue("input", "variant", "")
            }
          }
          KeyboardChoice {
            visible: !inputRoot.advancedKeyboard
            label: "Layout variant"
            options: inputRoot.selectedLayout ? inputRoot.selectedLayout.variants : []
            selectedCode: inputRoot.variantCode
            onChosen: function(code) { root.setValue("input", "variant", code) }
          }
          Text {
            Layout.fillWidth: true
            visible: !inputRoot.advancedKeyboard && inputRoot.selectedLayout !== undefined
            text: inputRoot.variantCode === "" ? "Default uses the standard keys for this layout."
              : "Variant code: " + inputRoot.variantCode
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
          }
          Text {
            Layout.fillWidth: true
            visible: root.keyboardCatalogLoading || root.keyboardCatalogError !== ""
            text: root.keyboardCatalogLoading ? "Loading keyboard layouts…" : root.keyboardCatalogError
            color: root.keyboardCatalogError ? Theme.error : Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
          }
          Button {
            Layout.fillWidth: true
            accessibleName: inputRoot.advancedKeyboard ? "Use keyboard layout picker" : "Use advanced keyboard codes"
            onClicked: inputRoot.advancedKeyboard = !inputRoot.advancedKeyboard
            Text {
              anchors.centerIn: parent
              text: inputRoot.advancedKeyboard ? "Choose from list" : "Advanced · enter codes"
              color: Theme.accent
              font.pixelSize: Theme.fontCaption
            }
          }
          ColumnLayout {
            Layout.fillWidth: true
            visible: inputRoot.advancedKeyboard
            spacing: Theme.spaceSm
            LabeledField {
              label: "Layout codes"
              placeholder: "us or us,es"
              fieldText: inputRoot.layoutCode
              onCommitted: function(value) { root.setValue("input", "layout", value) }
            }
            LabeledField {
              label: "Variant codes"
              placeholder: "Default: leave empty; e.g. intl"
              fieldText: inputRoot.variantCode
              onCommitted: function(value) { root.setValue("input", "variant", value) }
            }
            Text {
              Layout.fillWidth: true
              text: "For multiple layouts, separate codes with commas. Variants match layouts in the same order; leave a position empty for its default (e.g. intl,)."
              color: Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
              wrapMode: Text.WordWrap
            }
          }
        }
      }

      Text {
        text: "Pointer"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      TimezoneDropdown {
        label: "Focus follows pointer"
        options: ["0", "1", "2", "3"]
        selectedValue: String(root.value("input", "followMouse", 1))
        optionLabel: function(value) {
          if (value === "0") return "Disabled — click to focus"
          if (value === "1") return "Enabled — always follow pointer"
          if (value === "2") return "Detached — keyboard focus is preserved"
          return "Loose — focus follows with exceptions"
        }
        onChosen: function(value) {
          root.setValue("input", "followMouse", Number(value))
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: sensitivityLayout.implicitHeight + Theme.spaceLg * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        ColumnLayout {
          id: sensitivityLayout
          anchors.fill: parent
          anchors.margins: Theme.spaceLg
          spacing: Theme.spaceSm

          RowLayout {
            Layout.fillWidth: true
            Text {
              Layout.fillWidth: true
              text: "Pointer sensitivity"
              color: Theme.foreground
              font.pixelSize: Theme.fontBody
              font.weight: Theme.weightMedium
            }
            Text {
              text: Number(root.value("input", "sensitivity", 0)).toFixed(2)
              color: Theme.accent
              font.pixelSize: Theme.fontCaption
              font.weight: Theme.weightMedium
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm
            Text { text: "Slower"; color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
            Slider {
              Layout.fillWidth: true
              from: -1
              to: 1
              stepSize: 0.05
              value: root.value("input", "sensitivity", 0)
              accessibleName: "Pointer sensitivity"
              onMoved: function(value) {
                root.setValue("input", "sensitivity",
                  Math.round(value * 20) / 20)
              }
            }
            Text { text: "Faster"; color: Theme.foregroundMuted; font.pixelSize: Theme.fontCaption }
          }
        }
      }

      Text {
        text: "Touchpad"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      ToggleRow {
        label: "Natural scrolling"
        description: "Move content in the same direction as your fingers"
        checked: root.value("input", "naturalScroll", false)
        onChanged: function(enabled) {
          root.setValue("input", "naturalScroll", enabled)
        }
      }
    }
  }

  Component {
    id: powerPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceLg

      SectionTitle {
        title: "Power"
        description: "Control automatic locking, display power saving, and suspend behavior while the session is idle."
      }

      PowerTimeoutRow {
        symbol: "󰌾"
        label: "Lock screen"
        description: "Start Hyprlock after the session has been idle"
        currentValue: root.value("power", "lockTimeout", 300)
        options: ["0", "60", "300", "600", "900", "1800"]
        onSelected: function(value) { root.setValue("power", "lockTimeout", value) }
      }

      PowerTimeoutRow {
        symbol: "󰍹"
        label: "Turn displays off"
        description: "Power down connected displays; pointer or keyboard activity wakes them"
        currentValue: root.value("power", "displayTimeout", 600)
        options: ["0", "300", "600", "900", "1800", "3600"]
        onSelected: function(value) { root.setValue("power", "displayTimeout", value) }
      }

      PowerTimeoutRow {
        symbol: "󰒲"
        label: "Automatic suspend"
        description: "Suspend the computer after a longer period without activity"
        currentValue: root.value("power", "suspendTimeout", 1800)
        options: ["0", "900", "1800", "3600", "7200", "14400"]
        onSelected: function(value) { root.setValue("power", "suspendTimeout", value) }
      }

    }
  }

  Component {
    id: displaysPage
    ColumnLayout {
      width: parent ? parent.width : 0
      spacing: Theme.spaceMd
      SectionTitle { title: "Displays"; description: "Choose detected outputs and supported modes, then arrange them with Hyprland positions. A fallback rule applies to every unmatched display." }

      Rectangle {
        id: arrangementCard
        Layout.fillWidth: true
        Layout.preferredHeight: 182
        color: "transparent"
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        property var monitorRules: root.monitorArrangementRules()
        property real minX: {
          let result = 0
          for (let i = 0; i < monitorRules.length; ++i)
            result = Math.min(result, root.monitorPreviewGeometry(monitorRules[i], i).x)
          return result
        }
        property real minY: {
          let result = 0
          for (let i = 0; i < monitorRules.length; ++i)
            result = Math.min(result, root.monitorPreviewGeometry(monitorRules[i], i).y)
          return result
        }
        property real maxX: {
          let result = 1920
          for (let i = 0; i < monitorRules.length; ++i) {
            const geometry = root.monitorPreviewGeometry(monitorRules[i], i)
            result = Math.max(result, geometry.x + geometry.width)
          }
          return result
        }
        property real maxY: {
          let result = 1080
          for (let i = 0; i < monitorRules.length; ++i) {
            const geometry = root.monitorPreviewGeometry(monitorRules[i], i)
            result = Math.max(result, geometry.y + geometry.height)
          }
          return result
        }
        property real previewScale: Math.min((width - Theme.spaceXl * 4) / Math.max(1, maxX - minX),
          (height - 48) / Math.max(1, maxY - minY))

        Item {
          id: arrangementCanvas
          anchors.fill: parent
          anchors.leftMargin: Theme.spaceXl * 2
          anchors.rightMargin: Theme.spaceXl * 2
          anchors.topMargin: Theme.spaceMd
          anchors.bottomMargin: 30

          Repeater {
            model: arrangementCard.monitorRules
            Rectangle {
              id: displayTile
              required property var modelData
              required property int index
              readonly property var geometry: root.monitorPreviewGeometry(modelData, index)
              x: (geometry.x - arrangementCard.minX) * arrangementCard.previewScale
              y: (geometry.y - arrangementCard.minY) * arrangementCard.previewScale
              width: Math.max(80, geometry.width * arrangementCard.previewScale)
              height: Math.max(56, geometry.height * arrangementCard.previewScale)
              color: dragArea.drag.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.surfaceHover
              border.width: 1
              border.color: dragArea.drag.active || (root.detectedMonitor(modelData.output) || {}).focused
                ? Theme.accent : Theme.foregroundMuted

              Text {
                anchors.centerIn: parent
                text: displayTile.index + 1
                color: displayTile.border.color
                font.pixelSize: Math.min(42, displayTile.height * 0.34)
                font.weight: Theme.weightMedium
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                text: modelData.output
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontCaption
              }
              MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: displayTile
                drag.minimumX: 0
                drag.minimumY: 0
                drag.maximumX: arrangementCanvas.width - displayTile.width
                drag.maximumY: arrangementCanvas.height - displayTile.height
                onReleased: {
                  const newX = Math.round(displayTile.x / arrangementCard.previewScale + arrangementCard.minX)
                  const newY = Math.round(displayTile.y / arrangementCard.previewScale + arrangementCard.minY)
                  const snapped = root.snapMonitorPosition(modelData.output, newX, newY)
                  root.updateMonitorPosition(modelData.output, snapped.x + "x" + snapped.y)
                }
              }
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Theme.spaceSm
          text: arrangementCard.monitorRules.length > 1 ? "Drag monitors to reposition" : "Add another display to arrange monitors"
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontBody
        }
      }

      Rectangle {
        Layout.fillWidth: true
        visible: root.detectedMonitors.length === 0
        implicitHeight: noDisplaysText.implicitHeight + Theme.spaceLg * 2
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border
        radius: Theme.radiusLg

        Text {
          id: noDisplaysText
          anchors.fill: parent
          anchors.margins: Theme.spaceLg
          text: "No active displays were detected. Existing rules can still be edited manually."
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
          wrapMode: Text.WordWrap
        }
      }

      Repeater {
        model: root.value("displays", "monitors", [])
        Rectangle {
          id: monitorCard
          required property var modelData
          required property int index
          readonly property var detected: root.detectedMonitor(modelData.output)
          Layout.fillWidth: true
          implicitHeight: monitorLayout.implicitHeight + Theme.spaceLg * 2
          color: Theme.surface
          border.width: Theme.borderWidth
          border.color: Theme.border
          radius: Theme.radiusLg
          ColumnLayout {
            id: monitorLayout
            anchors.fill: parent
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceSm

            RowLayout {
              Layout.fillWidth: true
              spacing: Theme.spaceSm

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                  text: modelData.output || "Fallback display rule"
                  color: Theme.foreground
                  font.pixelSize: Theme.fontTitle
                  font.weight: Theme.weightStrong
                }
                Text {
                  visible: text !== ""
                  text: monitorCard.detected
                    ? monitorCard.detected.description || "Connected display"
                    : (modelData.output === "" ? "Applies when no specific output rule matches" : "Display is not currently connected")
                  color: Theme.foregroundMuted
                  font.pixelSize: Theme.fontCaption
                  elide: Text.ElideRight
                }
              }

              Button {
                Layout.preferredHeight: 30
                enabled: root.value("displays", "monitors", []).length > 1
                accessibleName: "Remove " + (modelData.output || "fallback display rule")
                onClicked: root.removeMonitor(index)
                Text {
                  anchors.centerIn: parent
                  text: "Remove"
                  color: parent.enabled ? Theme.foreground : Theme.foregroundMuted
                  font.pixelSize: Theme.fontCaption
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Theme.spaceSm

              TimezoneDropdown {
                Layout.fillWidth: true
                label: "Output"
                options: root.monitorOutputOptions(modelData.output, index)
                selectedValue: modelData.output
                optionLabel: function(value) {
                  return value === "" ? "All displays (fallback)" : value
                }
                onChosen: function(value) { root.updateMonitor(index, "output", value) }
              }

              TimezoneDropdown {
                Layout.fillWidth: true
                label: "Resolution and refresh rate"
                options: root.monitorModeOptions(modelData.output, modelData.mode)
                selectedValue: modelData.mode
                optionLabel: function(value) {
                  return value === "preferred" ? "Preferred" : value
                }
                onChosen: function(value) { root.updateMonitor(index, "mode", value) }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Theme.spaceSm

              LabeledField {
                Layout.fillWidth: true
                label: "Position"
                placeholder: "auto or 1920x0"
                fieldText: modelData.position
                onCommitted: function(value) { root.updateMonitor(index, "position", value) }
              }

              TimezoneDropdown {
                Layout.fillWidth: true
                label: "Scale"
                options: root.monitorScaleOptions(modelData.scale)
                selectedValue: modelData.scale
                optionLabel: function(value) { return value + "×" }
                onChosen: function(value) { root.updateMonitor(index, "scale", value) }
              }
            }
          }
        }
      }

      Button {
        Layout.preferredHeight: 34
        accessibleName: "Add display rule"
        onClicked: root.addMonitor()
        Text {
          anchors.centerIn: parent
          text: "+  Add display rule"
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
        }
      }
    }
  }

}
