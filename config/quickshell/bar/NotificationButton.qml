import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

Button {
  id: notificationButton

  Layout.preferredWidth: 24
  Layout.preferredHeight: 20

  IconImage {
    anchors.centerIn: parent

    implicitWidth: 14
    implicitHeight: 14
    source: Qt.resolvedUrl("../assets/bell.svg")

    layer.enabled: true
    layer.effect: MultiEffect {
      brightness: 1
      colorizationColor: Theme.foreground
    }
  }
}
