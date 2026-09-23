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
      property string foreground: "#d8dee9"
      property string accent: "#81a1c1"
      property string selectionForeground: "#d8dee9"
      property string selectionBackground: "#4c566a"
      property string cursor: "#d8dee9"
      property string color0: "#3b4252"
      property string color1: "#bf616a"
      property string color2: "#a3be8c"
      property string color3: "#ebcb8b"
      property string color4: "#81a1c1"
      property string color5: "#b48ead"
      property string color6: "#88c0d0"
      property string color7: "#e5e9f0"
      property string color8: "#4c566a"
      property string color9: "#bf616a"
      property string color10: "#a3be8c"
      property string color11: "#ebcb8b"
      property string color12: "#81a1c1"
      property string color13: "#b48ead"
      property string color14: "#8fbcbb"
      property string color15: "#eceff4"
    }
  }

  readonly property color background: palette.background
  readonly property color foreground: palette.foreground
  readonly property color accent: palette.accent
  readonly property color selectionForeground: palette.selectionForeground
  readonly property color selectionBackground: palette.selectionBackground
  readonly property color cursor: palette.cursor

  readonly property color color0: background
  readonly property color color1: palette.color0
  readonly property color color2: palette.color8
  readonly property color color3: selectionBackground
  readonly property color color4: foreground
  readonly property color color5: palette.color7
  readonly property color color6: palette.color15
  readonly property color color7: palette.color14
  readonly property color color8: palette.color6
  readonly property color color9: accent
  readonly property color color10: palette.color12
  readonly property color color11: palette.color1
  readonly property color color12: palette.color9
  readonly property color color13: palette.color3
  readonly property color color14: palette.color2
  readonly property color color15: palette.color5

  readonly property color terminalColor0: palette.color0
  readonly property color terminalColor1: palette.color1
  readonly property color terminalColor2: palette.color2
  readonly property color terminalColor3: palette.color3
  readonly property color terminalColor4: palette.color4
  readonly property color terminalColor5: palette.color5
  readonly property color terminalColor6: palette.color6
  readonly property color terminalColor7: palette.color7
  readonly property color terminalColor8: palette.color8
  readonly property color terminalColor9: palette.color9
  readonly property color terminalColor10: palette.color10
  readonly property color terminalColor11: palette.color11
  readonly property color terminalColor12: palette.color12
  readonly property color terminalColor13: palette.color13
  readonly property color terminalColor14: palette.color14
  readonly property color terminalColor15: palette.color15

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
  readonly property color surface: color0
  readonly property color surfaceHover: color1
  readonly property color border: color2
  readonly property color borderStrong: color9
  readonly property color borderFocus: color8
  readonly property color text: foreground
  readonly property color textMuted: color5
}
