import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../" as Global
import "../widgets" as DesktopWidgets

Scope {
  id: root

  property QtObject systemState
  required property var notifications
  signal systemTrayToggleRequested()
  signal screenshotMenuToggleRequested()

  IpcHandler {
    target: "system-tray"

    function toggle(): void {
      root.systemTrayToggleRequested()
    }
  }

  IpcHandler {
    target: "screenshot-menu"

    function toggle(): void {
      root.screenshotMenuToggleRequested()
    }
  }

  Variants {
    // Create layer-shell windows only after the persisted style has loaded.
    // Otherwise a solid bar is initially configured with pill margins, which
    // some compositors retain after the style binding updates.
    model: BarStyle.initialized ? Quickshell.screens : []

    PanelWindow {
      id: window

      readonly property int screenGap: 2
      readonly property int barHeight: 30
      readonly property bool pillMode: BarStyle.pillMode
      readonly property bool vertical: BarStyle.position === "left"
        || BarStyle.position === "right"
      readonly property bool atBottom: BarStyle.position === "bottom"
      readonly property bool atRight: BarStyle.position === "right"
      readonly property real layoutLength: vertical ? window.height : window.width
      // Pills are compact controls; keep the layer the same size at either
      // edge so moving the bar does not change its vertical geometry.
      readonly property int surfaceHeight: BarStyle.editing
        ? 44 + Math.max(28, Math.ceil(BarStyle.itemIds.filter(function(id) {
            return BarStyle.zoneFor(id) === ""
          }).length / Math.max(1, Math.floor((layoutLength - 210 + 6) / 156))) * 34 - 6)
        : barHeight

      function itemFor(id) {
        const fixed = ({workspaces: workspaces, clock: clock,
          nowPlaying: nowPlaying, focusTimer: focusTimer, system: system})[id]
        if (fixed) return fixed
        const index = BarStyle.buttonIds.indexOf(id)
        return index >= 0 && index < systemButtons.count ? systemButtons.itemAt(index) : null
      }

      function itemPadding(id, left): real {
        if (!window.pillMode) return 0
        if (BarStyle.editing) return Global.Theme.spaceXxs
        if (left && BarStyle.isJoined(id)) return 0
        if (!left) {
          const group = BarStyle.items.filter(function(entry) { return entry.zone === BarStyle.zoneFor(id) })
          const index = group.findIndex(function(entry) { return entry.id === id })
          for (let i = index + 1; i < group.length; ++i) {
            const next = itemFor(group[i].id)
            if (next && next.visible)
              return BarStyle.isJoined(group[i].id) ? 0 : Global.Theme.spaceXxs
          }
        }
        return Global.Theme.spaceXxs
      }

      function editWidth(id): real {
        if (id === "system" || BarStyle.buttonIds.indexOf(id) !== -1) return 52
        const item = itemFor(id)
        return Math.min(160, Math.max(100, item ? item.width : 0))
      }

      function itemX(id): real {
        const zone = BarStyle.zoneFor(id)
        const entries = BarStyle.items.filter(function(entry) {
          return entry.zone === zone
        })
        let total = 0
        let before = 0
        let count = 0
        for (const entry of entries) {
          const item = itemFor(entry.id)
          if (!item || !item.visible) continue
          const gap = count === 0 ? 0 : BarStyle.editing ? 22
            : BarStyle.isJoined(entry.id) ? 0 : 6
          total += gap
          if (entry.id === id) before = total
          total += BarStyle.editing ? editWidth(entry.id) : item.width
          count++
        }
        const edge = pillMode ? 0 : 10
        const origin = zone === "center" ? (window.layoutLength - total) / 2
          : zone === "right" ? window.layoutLength - edge - total : edge
        return origin + before
      }

      readonly property var pillGroups: {
        const groups = []
        for (const zone of ["left", "center", "right"]) {
          let group = null
          for (const entry of BarStyle.items) {
            if (entry.zone !== zone) continue
            const item = itemFor(entry.id)
            if (!item || !item.visible) continue
            if (!group || !BarStyle.isJoined(entry.id)) {
              group = {x: item.x, y: item.y, width: item.width, height: item.height}
              groups.push(group)
            } else {
              const right = Math.max(group.x + group.width, item.x + item.width)
              group.x = Math.min(group.x, item.x)
              group.width = right - group.x
              group.y = Math.min(group.y, item.y)
              group.height = Math.max(group.height, item.height)
            }
          }
        }
        return groups
      }

      readonly property var buttonBounds: {
        let left = window.width
        let right = 0
        for (let i = 0; i < systemButtons.count; ++i) {
          const item = systemButtons.itemAt(i)
          if (item && item.visible) {
            left = Math.min(left, item.x)
            right = Math.max(right, item.x + item.width)
          }
        }
        return {x: Math.min(left, right), width: Math.max(0, right - left)}
      }

      color: "#00000000"

      required property var modelData
      screen: modelData
      focusable: system.trayRevealed
      WlrLayershell.keyboardFocus: system.trayRevealed
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

      anchors {
        // Side rails span between both vertical anchors so their top/bottom
        // pill margins are honored, matching the end margins of horizontal bars.
        top: window.vertical || !window.atBottom
        bottom: window.vertical || window.atBottom
        left: !window.vertical || !window.atRight
        right: !window.vertical || window.atRight
      }

      margins {
        top: window.pillMode ? (window.vertical ? 10
          : (!window.atBottom ? screenGap : 0)) : 0
        bottom: window.pillMode ? (window.vertical ? 10
          : (window.atBottom ? screenGap : 0)) : 0
        left: window.pillMode ? (window.vertical
          ? (!window.atRight ? screenGap : 0) : 10) : 0
        right: window.pillMode ? (window.vertical
          ? (window.atRight ? screenGap : 0) : 10) : 0
      }

      implicitWidth: vertical ? surfaceHeight : (screen ? screen.width : 1920)
      implicitHeight: vertical ? (screen ? screen.height : 1080) : surfaceHeight
      exclusiveZone: window.pillMode
        ? screenGap + barHeight - 10
        : barHeight

      mask: Region {
        Region {
          intersection: Intersection.Combine
          width: window.vertical ? window.width : 0
          height: window.vertical ? window.height : 0
        }
        Region {
          intersection: Intersection.Combine
          x: buttonBounds.x
          y: window.atBottom ? window.height - window.barHeight : 0
          width: buttonBounds.width
          height: window.barHeight
        }
        Region {
          intersection: Intersection.Combine
          width: BarStyle.editing ? window.width : 0
          height: BarStyle.editing ? window.height : 0
        }
        Region {
          intersection: Intersection.Combine
          x: Math.floor(workspaces.x)
          y: Math.floor(workspaces.y)
          width: workspaces.visible ? Math.ceil(workspaces.width) : 0
          height: workspaces.visible ? Math.ceil(workspaces.height) : 0
        }

        Region {
          intersection: Intersection.Combine
          x: Math.floor(clock.x)
          y: Math.floor(clock.y)
          width: clock.visible ? Math.ceil(clock.width) : 0
          height: clock.visible ? Math.ceil(clock.height) : 0
        }

        Region {
          intersection: Intersection.Combine
          x: Math.floor(nowPlaying.x)
          y: Math.floor(nowPlaying.y)
          width: nowPlaying.visible ? Math.ceil(nowPlaying.width) : 0
          height: nowPlaying.visible ? Math.ceil(nowPlaying.height) : 0
        }

        Region {
          intersection: Intersection.Combine
          x: Math.floor(focusTimer.x)
          y: Math.floor(focusTimer.y)
          width: focusTimer.visible ? Math.ceil(focusTimer.width) : 0
          height: focusTimer.visible ? Math.ceil(focusTimer.height) : 0
        }

        Region {
          intersection: Intersection.Combine
          x: Math.floor(system.x)
          y: Math.floor(system.y)
          width: system.visible ? Math.ceil(system.width) : 0
          height: system.visible ? Math.ceil(system.height) : 0
        }
      }

      Item {
        id: barContent
        width: window.vertical ? window.height : window.width
        height: window.vertical ? window.width : window.height
        anchors.centerIn: parent
        // Keep the logical left zone at the physical top on both side rails.
        rotation: window.vertical ? 90 : 0

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: window.atBottom ? undefined : parent.top
          anchors.bottom: window.atBottom ? parent.bottom : undefined
          height: window.barHeight
          visible: BarStyle.style === "bar"
          color: Global.Theme.surface
        }

        Repeater {
          model: window.pillMode && !BarStyle.editing ? window.pillGroups : []
          Rectangle {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: modelData.width
            height: modelData.height
            color: Global.Theme.surface
            radius: Global.Theme.radiusSm
            border.width: Global.Theme.borderWidth
            border.color: Global.Theme.borderStrong
          }
        }

        Workspaces {
          id: workspaces
          vertical: window.vertical
          leftPadding: window.itemPadding("workspaces", true)
          rightPadding: window.itemPadding("workspaces", false)
          backgroundEnabled: false
          shellScreen: modelData
          visible: BarStyle.zoneFor("workspaces") !== ""
          width: implicitWidth
          height: implicitHeight
          x: window.itemX("workspaces")
          y: (window.atBottom ? window.height - window.barHeight : 0)
            + Math.max(0, (window.barHeight - height) / 2)
        }

        ClockWidget {
          id: clock
          leftPadding: window.itemPadding("clock", true)
          rightPadding: window.itemPadding("clock", false)
          backgroundEnabled: false
          shellScreen: modelData
          barHorizontalInset: window.pillMode ? 10 : 0
          visible: BarStyle.zoneFor("clock") !== ""
          width: implicitWidth
          height: implicitHeight
          x: window.itemX("clock")
          y: (window.atBottom ? window.height - window.barHeight : 0)
            + Math.max(0, (window.barHeight - height) / 2)
        }

        System {
          id: system
          leftPadding: window.itemPadding("system", true)
          rightPadding: window.itemPadding("system", false)
          backgroundEnabled: false
          controller: systemController
          notifications: root.notifications
          visible: BarStyle.zoneFor("system") !== ""
          width: implicitWidth
          height: implicitHeight
          x: window.itemX("system")
          y: (window.atBottom ? window.height - window.barHeight : 0)
            + Math.max(0, (window.barHeight - height) / 2)
        }

        NowPlaying {
          id: nowPlaying
          leftPadding: window.itemPadding("nowPlaying", true)
          rightPadding: window.itemPadding("nowPlaying", false)
          backgroundEnabled: false
          visible: BarStyle.zoneFor("nowPlaying") !== "" && (BarStyle.editing || (DesktopWidgets.WidgetState.nowPlayingVisible && present))
          width: implicitWidth
          height: implicitHeight
          x: window.itemX("nowPlaying")
          y: (window.atBottom ? window.height - window.barHeight : 0)
            + Math.max(0, (window.barHeight - height) / 2)
        }

        FocusTimer {
          id: focusTimer
          leftPadding: window.itemPadding("focusTimer", true)
          rightPadding: window.itemPadding("focusTimer", false)
          backgroundEnabled: false
          visible: BarStyle.zoneFor("focusTimer") !== ""
            && (BarStyle.editing || DesktopWidgets.WidgetState.focusTimerBarVisible)
          width: implicitWidth
          height: implicitHeight
          x: window.itemX("focusTimer")
          y: (window.atBottom ? window.height - window.barHeight : 0)
            + Math.max(0, (window.barHeight - height) / 2)
        }

        Repeater {
          id: systemButtons
          model: BarStyle.buttonIds
          Pill {
            id: buttonPill
            leftPadding: window.itemPadding(modelData, true)
            rightPadding: window.itemPadding(modelData, false)
            backgroundEnabled: false
            required property string modelData
            visible: BarStyle.zoneFor(modelData) !== ""
            width: implicitWidth
            height: implicitHeight
            x: window.itemX(modelData)
            y: (window.atBottom ? window.height - window.barHeight : 0)
              + Math.max(0, (window.barHeight - height) / 2)
            // The side rail rotates the horizontal layout as a whole. Undo
            // that rotation for compact controls so their glyphs stay upright.
            rotation: window.vertical ? -90 : 0
            borderEnabled: BarStyle.pillMode
            Item {
              id: buttonHost
              implicitWidth: 22
              implicitHeight: Global.Theme.barControlHeight
              width: implicitWidth
              height: implicitHeight
            }
            property alias controlHost: buttonHost
          }
        }

        SystemButton {
          id: systemController
          notifications: root.notifications
          buttonHosts: {
            const hosts = {}
            for (let i = 0; i < systemButtons.count; ++i) {
              const item = systemButtons.itemAt(i)
              if (item) hosts[item.modelData] = item.controlHost
            }
            return hosts
          }
          popupAnchor: {
            const id = activePanel.indexOf("volume") === 0 ? "volume" : activePanel
            return window.itemFor(id) || system
          }
        }

        BarEditor {
          anchors.fill: parent
          visible: BarStyle.editing
          atBottom: window.atBottom
          itemGeometry: function(id) {
            const item = window.itemFor(id)
            return {x: item ? item.x : 0, width: window.editWidth(id)}
          }
        }

        Connections {
          target: root

          function onSystemTrayToggleRequested(): void {
            if (Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)
              system.toggleTray()
          }

          function onScreenshotMenuToggleRequested(): void {
            const monitor = Hyprland.monitorFor(modelData)
            if (monitor !== null && Hyprland.focusedMonitor !== null
                && monitor.name === Hyprland.focusedMonitor.name)
              clock.toggleScreenshotMenu()
          }

        }
      }
    }
  }
}
