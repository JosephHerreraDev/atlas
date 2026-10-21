import QtQuick
import "../"

QtObject {
  property string choice: "theme-transparent"
  readonly property bool themed: choice === "theme-transparent" || choice === "theme-solid"
  readonly property bool transparentTheme: choice === "theme-transparent"
  readonly property bool darkInk: ["yellow", "white", "green"].indexOf(choice) !== -1
  readonly property color solidColor: ({yellow: "#f6d365", white: "#f4f4f2", red: "#d95c5c",
    blue: "#5b8def", green: "#66b982", purple: "#9b72cf"})[choice] || Theme.surface
  readonly property color surfaceColor: themed ? Theme.surface : solidColor
  readonly property color backgroundColor: transparentTheme
    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.88) : surfaceColor
  readonly property color textColor: themed ? Theme.foreground : darkInk ? "#202124" : "#ffffff"
  readonly property color mutedColor: themed ? Theme.foregroundMuted : Qt.rgba(textColor.r, textColor.g, textColor.b, 0.75)
  readonly property color accentColor: themed ? Theme.accent : textColor
  readonly property color hoverColor: themed ? Theme.surfaceHover : Qt.tint(surfaceColor, Qt.rgba(textColor.r, textColor.g, textColor.b, 0.10))
  readonly property color selectionTextColor: themed ? Theme.selectionForeground : textColor
  readonly property color selectionColor: themed ? Theme.selectionBackground : Qt.tint(surfaceColor, Qt.rgba(textColor.r, textColor.g, textColor.b, 0.20))
  readonly property color borderColor: themed ? Theme.border : Qt.rgba(textColor.r, textColor.g, textColor.b, 0.28)
  readonly property color panelColor: transparentTheme ? "transparent" : surfaceColor
}
