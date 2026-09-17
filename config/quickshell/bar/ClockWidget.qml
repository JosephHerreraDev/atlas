import QtQuick
import "../"

Pill {
  implicitWidth: clockText.implicitWidth + 16
  implicitHeight: clockText.implicitHeight + 8

  Text {
    id: clockText
    anchors.centerIn: parent

    text: Time.time
    color: Theme.foreground
  }
}
