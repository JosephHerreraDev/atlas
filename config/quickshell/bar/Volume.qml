import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Item {
  id: root

  readonly property var sink: AudioState.audioSink
  readonly property real volume: AudioState.volume
  readonly property bool muted: AudioState.muted
  readonly property bool available: AudioState.outputAvailable
  readonly property string accessibleDescription:
    AudioState.outputDescription

  implicitWidth: 18
  implicitHeight: 14
  Layout.preferredWidth: implicitWidth
  Layout.preferredHeight: implicitHeight

  function setVolume(value) {
    AudioState.setOutputVolume(value)
  }

  function adjustVolume(delta) {
    AudioState.adjustOutputVolume(delta)
  }

  function toggleMute() {
    AudioState.toggleOutputMute()
  }

  LevelIcon {
    anchors.fill: parent
    value: root.volume
    available: root.available
    zeroState: root.muted
    zeroSource: Qt.resolvedUrl("../assets/volume-mute.svg")
    lowSource: Qt.resolvedUrl("../assets/volume-min.svg")
    mediumSource: Qt.resolvedUrl("../assets/volume-med.svg")
    highSource: Qt.resolvedUrl("../assets/volume-max.svg")
    iconColor: !root.available
      ? Theme.color2
      : (root.muted ? Theme.color11 : Theme.foreground)
    accessibleName: root.accessibleDescription
  }
}
