pragma Singleton

import QtQuick
import QtCore
import Quickshell

Singleton {
  id: root

  readonly property int edgeMargin: 8

  readonly property var positions: [
    "top-right", "top", "top-left", "left", "center", "right",
    "bottom-left", "bottom", "bottom-right"
  ]

  property string startMenu: "left"
  property string wallpaperSelector: "bottom"
  property string osd: "bottom"
  property string clipboard: "bottom"
  property string screenshotMenu: "bottom"
  property string powerMenu: "center"
  property string themeSelector: "center"

  function valid(position, fallback): string {
    return positions.indexOf(position) === -1 ? fallback : position
  }

  function horizontal(position): string {
    if (position.indexOf("left") !== -1 || position === "left") return "left"
    if (position.indexOf("right") !== -1 || position === "right") return "right"
    return "center"
  }

  function vertical(position): string {
    if (position.indexOf("top") === 0) return "top"
    if (position.indexOf("bottom") === 0) return "bottom"
    return "center"
  }

  function label(position): string {
    return position.split("-").map(function(part) {
      return part.charAt(0).toUpperCase() + part.substring(1)
    }).join(" ")
  }

  function itemX(position, containerWidth, itemWidth, margin): real {
    const alignment = horizontal(position)
    if (alignment === "left") return margin
    if (alignment === "right") return containerWidth - itemWidth - margin
    return (containerWidth - itemWidth) / 2
  }

  function itemY(position, containerHeight, itemHeight, topMargin, bottomMargin): real {
    const alignment = vertical(position)
    if (alignment === "top") return topMargin
    if (alignment === "bottom") return containerHeight - itemHeight - bottomMargin
    return (containerHeight - itemHeight) / 2
  }

  onStartMenuChanged: startMenu = valid(startMenu, "left")
  onWallpaperSelectorChanged: wallpaperSelector = valid(wallpaperSelector, "bottom")
  onOsdChanged: osd = valid(osd, "bottom")
  onClipboardChanged: clipboard = valid(clipboard, "bottom")
  onScreenshotMenuChanged: screenshotMenu = valid(screenshotMenu, "bottom")
  onPowerMenuChanged: powerMenu = valid(powerMenu, "center")
  onThemeSelectorChanged: themeSelector = valid(themeSelector, "center")

  Settings {
    category: "overlayPositions"
    // Keep the old persistence key so existing launcher placement carries over.
    property alias launcher: root.startMenu
    property alias wallpaperSelector: root.wallpaperSelector
    property alias osd: root.osd
    property alias clipboard: root.clipboard
    property alias screenshotMenu: root.screenshotMenu
    property alias powerMenu: root.powerMenu
    property alias themeSelector: root.themeSelector
  }
}
