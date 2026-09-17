import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell.Widgets
import QtQuick.Effects
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import "../"
import "../shared/"

Pill {
  RowLayout {
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
  }
}
