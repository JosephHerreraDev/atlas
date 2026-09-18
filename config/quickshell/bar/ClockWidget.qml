import QtQuick
import "../"
import "../shared/"

Pill {
  Button {
    implicitHeight: 20

    Text {
      id: clockText

      anchors.centerIn: parent
      font.bold: true
      text: Time.time
      color: Theme.foreground
    }
  }
}
