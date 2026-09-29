import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

Item {
  id: root

  required property real value
  required property url lowSource
  required property url mediumSource
  required property url highSource
  property url zeroSource: lowSource
  property bool available: true
  property bool zeroState: false
  property real lowThreshold: 0.33
  property real highThreshold: 0.66
  property color iconColor: "white"
  property string accessibleName: ""

  readonly property url iconSource: {
    if (!available || zeroState || value <= 0)
      return zeroSource
    if (value <= lowThreshold)
      return lowSource
    if (value <= highThreshold)
      return mediumSource
    return highSource
  }

  implicitWidth: 18
  implicitHeight: 14

  Accessible.role: Accessible.StaticText
  Accessible.name: accessibleName
  Accessible.ignored: accessibleName === ""

  IconImage {
    anchors.fill: parent
    source: root.iconSource

    layer.enabled: true
    layer.effect: MultiEffect {
      brightness: 1
      colorization: 1
      colorizationColor: root.iconColor
    }
  }
}
