import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Popup {
  id: root

  implicitWidth: 320
  padding: Theme.spaceXl

  property int monthOffset: 0
  readonly property date now: clock.date
  readonly property date displayedMonth: new Date(
    now.getFullYear(), now.getMonth() + monthOffset, 1)
  readonly property int firstWeekday: (displayedMonth.getDay() + 6) % 7
  readonly property int daysInMonth: new Date(
    displayedMonth.getFullYear(), displayedMonth.getMonth() + 1, 0).getDate()

  function isToday(day) {
    return day === now.getDate()
      && displayedMonth.getMonth() === now.getMonth()
      && displayedMonth.getFullYear() === now.getFullYear()
  }

  anchor {
    rect.x: root.anchorItem.width / 2
    edges: Edges.Top
    gravity: Edges.Bottom
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Column {
    width: parent.width
    spacing: Theme.spaceLg

    Column {
      width: parent.width
      spacing: Theme.spaceXxs

      Text {
        width: parent.width
        text: Qt.formatDate(root.now, "dddd, MMMM d")
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle + 2
        font.weight: Theme.weightStrong
      }

      Text {
        width: parent.width
        text: Qt.formatDate(root.now, "yyyy")
        color: Theme.color5
        font.pixelSize: Theme.fontBody
      }
    }

    Rectangle {
      width: parent.width
      height: Theme.borderWidth
      color: Theme.border
    }

    RowLayout {
      width: parent.width
      height: 28
      spacing: Theme.spaceSm

      Text {
        Layout.fillWidth: true
        text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      Button {
        Layout.preferredWidth: 28
        Layout.preferredHeight: Theme.controlHeight
        horizontalPadding: 0
        onClicked: root.monthOffset--

        Text {
          anchors.centerIn: parent
          text: "‹"
          color: Theme.foreground
          font.pixelSize: 16
        }
      }

      Button {
        Layout.preferredWidth: 28
        Layout.preferredHeight: Theme.controlHeight
        horizontalPadding: 0
        onClicked: root.monthOffset++

        Text {
          anchors.centerIn: parent
          text: "›"
          color: Theme.foreground
          font.pixelSize: 16
        }
      }
    }

    Row {
      width: parent.width

      Repeater {
        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        Text {
          required property string modelData

          width: parent.width / 7
          height: 20
          text: modelData
          color: Theme.color5
          font.pixelSize: Theme.fontCaption - 1
          font.weight: Theme.weightStrong
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }
    }

    Grid {
      width: parent.width
      columns: 7
      spacing: Theme.spaceXs

      Repeater {
        model: 42

        Rectangle {
          required property int index
          readonly property int day: index - root.firstWeekday + 1
          readonly property bool inMonth: day > 0 && day <= root.daysInMonth

          width: (parent.width - parent.spacing * 6) / 7
          height: 30
          radius: Theme.radiusSm
          color: root.isToday(day) && inMonth ? Theme.color8 : "transparent"
          border.width: root.isToday(day) && inMonth ? 0 : Theme.borderWidth
          border.color: inMonth ? Theme.border : "transparent"

          Text {
            anchors.centerIn: parent
            text: parent.inMonth ? parent.day : ""
            color: root.isToday(parent.day) ? Theme.color0 : Theme.foreground
            font.pixelSize: Theme.fontBody
            font.weight: root.isToday(parent.day)
              ? Theme.weightStrong
              : Theme.weightRegular
          }
        }
      }
    }

    Button {
      width: parent.width
      implicitHeight: Theme.controlHeight
      visible: root.monthOffset !== 0
      onClicked: root.monthOffset = 0

      Text {
        anchors.centerIn: parent
        text: "Today"
        color: Theme.color8
        font.pixelSize: Theme.fontCaption
      }
    }
  }
}
