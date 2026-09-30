pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  FileView {
    path: Qt.resolvedUrl("ThemeColors.json")
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
      id: palette

      property string background: "#2e3440"
      property string surface: "#2e3440"
      property string surfaceHover: "#3b4252"
      property string foreground: "#d8dee9"
      property string foregroundMuted: "#aeb4bf"
      property string border: "#4c566a"
      property string accent: "#81a1c1"
      property string selectionForeground: "#d8dee9"
      property string selectionBackground: "#4c566a"
      property string cursor: "#d8dee9"
      property string error: "#cf898f"
      property string warning: "#ebcb8b"
      property string success: "#a3be8c"
      property string info: "#88c0d0"
      property string ansiBlack: "#3b4252"
      property string ansiRed: "#bf616a"
      property string ansiGreen: "#a3be8c"
      property string ansiYellow: "#ebcb8b"
      property string ansiBlue: "#81a1c1"
      property string ansiMagenta: "#b48ead"
      property string ansiCyan: "#88c0d0"
      property string ansiWhite: "#e5e9f0"
      property string ansiBrightBlack: "#4c566a"
      property string ansiBrightRed: "#bf616a"
      property string ansiBrightGreen: "#a3be8c"
      property string ansiBrightYellow: "#ebcb8b"
      property string ansiBrightBlue: "#81a1c1"
      property string ansiBrightMagenta: "#b48ead"
      property string ansiBrightCyan: "#8fbcbb"
      property string ansiBrightWhite: "#eceff4"
    }
  }

  readonly property color background: palette.background
  readonly property color surface: palette.surface
  readonly property color surfaceHover: palette.surfaceHover
  readonly property color foreground: palette.foreground
  readonly property color foregroundMuted: palette.foregroundMuted
  readonly property color border: palette.border
  readonly property color accent: palette.accent
  readonly property color selectionForeground: palette.selectionForeground
  readonly property color selectionBackground: palette.selectionBackground
  readonly property color cursor: palette.cursor
  readonly property color error: palette.error
  readonly property color warning: palette.warning
  readonly property color success: palette.success
  readonly property color info: palette.info
  readonly property color ansiBlack: palette.ansiBlack
  readonly property color ansiRed: palette.ansiRed
  readonly property color ansiGreen: palette.ansiGreen
  readonly property color ansiYellow: palette.ansiYellow
  readonly property color ansiBlue: palette.ansiBlue
  readonly property color ansiMagenta: palette.ansiMagenta
  readonly property color ansiCyan: palette.ansiCyan
  readonly property color ansiWhite: palette.ansiWhite
  readonly property color ansiBrightBlack: palette.ansiBrightBlack
  readonly property color ansiBrightRed: palette.ansiBrightRed
  readonly property color ansiBrightGreen: palette.ansiBrightGreen
  readonly property color ansiBrightYellow: palette.ansiBrightYellow
  readonly property color ansiBrightBlue: palette.ansiBrightBlue
  readonly property color ansiBrightMagenta: palette.ansiBrightMagenta
  readonly property color ansiBrightCyan: palette.ansiBrightCyan
  readonly property color ansiBrightWhite: palette.ansiBrightWhite

  readonly property int spaceXxs: 2
  readonly property int spaceXs: 4
  readonly property int spaceSm: 8
  readonly property int spaceMd: 8
  readonly property int spaceLg: 12
  readonly property int spaceXl: 16
  readonly property int fontCaption: 11
  readonly property int fontBody: 12
  readonly property int fontTitle: 14
  readonly property int fontDisplay: 18
  readonly property int weightRegular: Font.Normal
  readonly property int weightMedium: Font.Medium
  readonly property int weightStrong: Font.DemiBold
  readonly property int barControlHeight: 20
  readonly property int controlHeight: 28
  readonly property int listRowHeight: 32
  readonly property int iconSize: 14
  readonly property int radiusSm: 4
  readonly property int radiusMd: 6
  readonly property int radiusLg: 8
  readonly property int borderWidth: 1
  readonly property int motionQuick: 90
  readonly property int motionFast: 100
  readonly property int motionNormal: 160
  readonly property int motionSlow: 240
  readonly property real popupOpacity: 0.9
  readonly property color borderStrong: accent
  readonly property color borderFocus: accent
  readonly property color text: foreground
  readonly property color textMuted: foregroundMuted
}
