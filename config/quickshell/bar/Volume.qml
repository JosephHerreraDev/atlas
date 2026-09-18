import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

Item {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property real volume: sink?.audio.volume ?? 0
  readonly property bool muted: sink?.audio.muted ?? true

  Layout.preferredWidth: 18
  Layout.preferredHeight: 14

  IconImage {
    anchors.fill: parent
    source: {
      if (root.muted || root.volume <= 0)
        return Qt.resolvedUrl("../assets/volume-mute.svg")
      if (root.volume <= 0.33)
        return Qt.resolvedUrl("../assets/volume-min.svg")
      if (root.volume <= 0.66)
        return Qt.resolvedUrl("../assets/volume-med.svg")
      return Qt.resolvedUrl("../assets/volume-max.svg")
    }

    layer.enabled: true
    layer.effect: MultiEffect {
      brightness: 1
      colorization: 1
      colorizationColor: Theme.foreground
    }
  }

  PwObjectTracker {
    objects: [root.sink]
  }
}
