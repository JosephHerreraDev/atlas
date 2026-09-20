import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import ".."

Item {
  id: root

  property real brightness: 0

  function refresh() {
    if (!brightnessQuery.running)
      brightnessQuery.exec(["brightnessctl", "-m"])
  }

  function setBrightness(value) {
    brightnessSetter.exec([
      "brightnessctl", "set", Math.round(value * 100) + "%"
    ])
  }

  Layout.preferredWidth: 18
  Layout.preferredHeight: 14

  Component.onCompleted: refresh()

  IconImage {
    anchors.fill: parent
    source: {
      if (root.brightness <= 0.33)
        return Qt.resolvedUrl("../assets/brightness-min.svg")
      if (root.brightness <= 0.66)
        return Qt.resolvedUrl("../assets/brightness-med.svg")
      return Qt.resolvedUrl("../assets/brightness-max.svg")
    }

    layer.enabled: true
    layer.effect: MultiEffect {
      brightness: 1
      colorization: 1
      colorizationColor: Theme.foreground
    }
  }

  Process {
    id: brightnessQuery

    stdout: StdioCollector {
      onStreamFinished: {
        const match = text.match(/(\d+)%/)
        if (match)
          root.brightness = Number(match[1]) / 100
      }
    }
  }

  Process {
    id: brightnessSetter

    onExited: root.refresh()
  }
}
