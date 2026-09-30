import Quickshell
import Quickshell.Services.SystemTray as TrayService
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

FocusScope {
  id: root

  property bool revealed: false
  // Many legitimate AppIndicator clients, including Spotify, publish
  // themselves as Passive even though their icon and menu remain useful.
  property bool showPassiveItems: true
  property bool autoCollapseAfterMenu: true
  property bool collapsePending: false
  property int openMenuCount: 0
  property real revealProgress: revealed ? 1 : 0

  readonly property int entrySize: Theme.barControlHeight
  readonly property int toggleWidth: Theme.barControlHeight + Theme.spaceXxs
  readonly property int iconSize: Theme.iconSize
  readonly property int entrySpacing: Theme.spaceXxs
  readonly property int animationDuration: Theme.motionNormal
  readonly property var orderedItems: sortedItems()
  readonly property int totalCount: orderedItems.length

  function itemName(item): string {
    return item.tooltipTitle || item.title || item.id || "Tray item"
  }

  function itemTooltip(item): string {
    const title = itemName(item)
    const description = item.tooltipDescription || ""
    return description && description !== title
      ? title + "\n" + description
      : title
  }

  function sortedItems(): var {
    const result = []
    for (const item of TrayService.SystemTray.items.values) {
      if (showPassiveItems || item.status !== TrayService.Status.Passive)
        result.push(item)
    }

    result.sort(function(left, right) {
      const leftAttention = left.status === TrayService.Status.NeedsAttention
        ? 0 : 1
      const rightAttention = right.status === TrayService.Status.NeedsAttention
        ? 0 : 1
      if (leftAttention !== rightAttention)
        return leftAttention - rightAttention
      if (left.category !== right.category)
        return left.category - right.category
      return root.itemName(left).localeCompare(root.itemName(right))
    })
    return result
  }

  function expand(): void {
    if (totalCount === 0)
      return
    collapsePending = false
    revealed = true
    Qt.callLater(function() { trayToggle.forceActiveFocus() })
  }

  function closeMenus(): void {
    for (let index = 0; index < trayRepeater.count; index++) {
      const entry = trayRepeater.itemAt(index)
      if (entry)
        entry.closeMenu()
    }
  }

  function collapse(): void {
    if (openMenuCount > 0) {
      collapsePending = true
      closeMenus()
      return
    }
    collapsePending = false
    revealed = false
  }

  function toggle(): void {
    if (revealed)
      collapse()
    else
      expand()
  }

  function focusNeighbor(item, direction: int): void {
    const itemCenter = item.mapToItem(trayRow, item.width / 2, 0).x
    let nearest = null
    let nearestDistance = Number.POSITIVE_INFINITY
    const candidates = [trayToggle]
    for (let index = 0; index < trayRepeater.count; index++) {
      const entry = trayRepeater.itemAt(index)
      if (entry && entry.visible)
        candidates.push(entry)
    }

    for (const candidate of candidates) {
      if (candidate === item)
        continue
      const candidateCenter = candidate.mapToItem(
        trayRow, candidate.width / 2, 0).x
      const distance = candidateCenter - itemCenter
      if ((direction < 0 && distance < 0
          || direction > 0 && distance > 0)
          && Math.abs(distance) < nearestDistance) {
        nearest = candidate
        nearestDistance = Math.abs(distance)
      }
    }

    if (nearest)
      nearest.forceActiveFocus()
  }

  implicitWidth: visible ? trayRow.implicitWidth : 0
  implicitHeight: Theme.barControlHeight
  Layout.preferredWidth: visible ? implicitWidth : 0
  visible: totalCount > 0

  onActiveFocusChanged: {
    if (!activeFocus && revealed && openMenuCount === 0)
      focusLossTimer.restart()
  }

  Behavior on revealProgress {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  Timer {
    id: focusLossTimer

    interval: Theme.motionFast
    onTriggered: {
      if (!root.activeFocus && root.openMenuCount === 0)
        root.collapse()
    }
  }

  onTotalCountChanged: {
    if (totalCount === 0) {
      closeMenus()
      revealed = false
    }
  }

  RowLayout {
    id: trayRow

    anchors.fill: parent
    spacing: root.entrySpacing * root.revealProgress
    layoutDirection: Qt.RightToLeft

    Repeater {
      id: trayRepeater

      model: root.orderedItems

      delegate: TrayButton {
        id: trayEntry

        required property int index
        required property var modelData
        readonly property bool menuVisible: trayMenu.visible

        function openMenu(): void {
          if (modelData.hasMenu)
            trayMenu.open()
        }

        function closeMenu(): void {
          if (trayMenu.visible)
            trayMenu.close()
        }

        Layout.preferredWidth: root.entrySize * root.revealProgress
        Layout.preferredHeight: root.entrySize
        visible: root.revealed || root.revealProgress > 0
        enabled: root.revealed
        opacity: root.revealProgress
        buttonSize: root.entrySize
        accessibleName: root.itemName(modelData)
        attention: modelData.status === TrayService.Status.NeedsAttention
        selected: menuVisible

        IconImage {
          id: trayIcon

          anchors.centerIn: parent
          implicitSize: root.iconSize
          source: trayEntry.modelData.icon
          visible: status === Image.Ready
        }

        Text {
          anchors.centerIn: parent
          visible: trayIcon.status !== Image.Ready
          text: root.itemName(trayEntry.modelData).slice(0, 1).toUpperCase()
          color: Theme.foreground
          font.pixelSize: Theme.fontCaption
          font.weight: Theme.weightStrong
        }

        onClicked: function(button) {
          if (button === Qt.MiddleButton) {
            modelData.secondaryActivate()
          } else if (button === Qt.RightButton) {
            openMenu()
          } else if (modelData.onlyMenu && modelData.hasMenu) {
            openMenu()
          } else {
            modelData.activate()
          }
        }

        onWheelMoved: function(delta, horizontal) {
          modelData.scroll(delta, horizontal)
        }

        onNavigate: function(direction) {
          root.focusNeighbor(trayEntry, direction)
        }

        onCancel: root.collapse()

        QsMenuAnchor {
          id: trayMenu

          anchor.item: trayEntry
          anchor.rect.y: trayEntry.height
          menu: trayEntry.modelData.menu

          onOpened: root.openMenuCount++
          onClosed: {
            root.openMenuCount = Math.max(0, root.openMenuCount - 1)
            if (root.openMenuCount === 0
                && (root.collapsePending || root.autoCollapseAfterMenu)) {
              root.collapsePending = false
              root.revealed = false
            }
          }
        }

        Tooltip {
          target: trayEntry
          text: root.itemTooltip(trayEntry.modelData)
          shown: trayEntry.hovered && !trayEntry.menuVisible
        }
      }
    }

    TrayButton {
      id: trayToggle

      Layout.preferredWidth: root.toggleWidth
      Layout.preferredHeight: root.entrySize
      buttonSize: root.entrySize
      accessibleName: root.revealed ? "Collapse system tray" : "Expand system tray"
      selected: root.revealed

      IconImage {
        anchors.centerIn: parent
        implicitSize: root.iconSize - 1
        source: Qt.resolvedUrl("../assets/chevron-left.svg")
        rotation: root.revealed ? 180 : 0

        Behavior on rotation {
          NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: trayToggle.hovered || root.revealed
            ? Theme.accent
            : Theme.foreground
        }
      }

      onClicked: root.toggle()
      onNavigate: function(direction) {
        root.focusNeighbor(trayToggle, direction)
      }
      onCancel: root.collapse()

      Tooltip {
        target: trayToggle
        text: trayToggle.accessibleName
        shown: trayToggle.hovered
      }
    }
  }
}
