import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Item {
  id: root

  readonly property real brightness: BrightnessState.brightness >= 0
    ? BrightnessState.brightness
    : 0
  readonly property bool available: BrightnessState.available
  readonly property bool loading: BrightnessState.loading
  readonly property string accessibleDescription: loading
    ? "Loading display brightness"
    : (!available
      ? BrightnessState.errorMessage
      : "Brightness " + Math.round(brightness * 100) + "%")

  implicitWidth: 18
  implicitHeight: 14
  Layout.preferredWidth: implicitWidth
  Layout.preferredHeight: implicitHeight

  function refresh() {
    BrightnessState.refresh()
  }

  function setBrightness(value) {
    BrightnessState.setBrightness(value)
  }

  function adjustBrightness(delta) {
    BrightnessState.adjustBrightness(delta)
  }

  LevelIcon {
    anchors.fill: parent
    value: root.brightness
    available: root.available
    zeroState: root.loading
    zeroSource: Qt.resolvedUrl("../assets/brightness-min.svg")
    lowSource: Qt.resolvedUrl("../assets/brightness-min.svg")
    mediumSource: Qt.resolvedUrl("../assets/brightness-med.svg")
    highSource: Qt.resolvedUrl("../assets/brightness-max.svg")
    iconColor: root.available ? Theme.foreground : Theme.border
    accessibleName: root.accessibleDescription
  }
}
