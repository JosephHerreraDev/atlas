import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  id: root

  property bool calendarVisible: false
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

  Item {
    implicitWidth: clockButton.implicitWidth
    implicitHeight: clockButton.implicitHeight

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

    Button {
      id: clockButton

      implicitHeight: 20
      onClicked: root.calendarVisible = !root.calendarVisible

      Text {
        anchors.centerIn: parent
        font.weight: Font.DemiBold
        text: Time.time
        color: Theme.foreground
      }
    }

    Popup {
      id: calendarPopup

    anchorItem: clockButton
    implicitWidth: 320
    padding: 16
    shown: root.calendarVisible

    anchor {
      rect.x: clockButton.width / 2
      edges: Edges.Top
      gravity: Edges.Bottom
    }

    onVisibleChanged: {
      if (!visible && root.calendarVisible)
        root.calendarVisible = false
    }

    Column {
      width: parent.width
      spacing: 12

      Column {
        width: parent.width
        spacing: 2

        Text {
          width: parent.width
          text: Qt.formatDate(root.now, "dddd, MMMM d")
          color: Theme.foreground
          font.pixelSize: 16
          font.weight: Font.DemiBold
        }

        Text {
          width: parent.width
          text: Qt.formatDate(root.now, "yyyy")
          color: Theme.color5
          font.pixelSize: 12
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Theme.color2
      }

      RowLayout {
        width: parent.width
        height: 28
        spacing: 8

        Text {
          Layout.fillWidth: true
          text: Qt.formatDate(root.displayedMonth, "MMMM yyyy")
          color: Theme.foreground
          font.pixelSize: 14
          font.weight: Font.DemiBold
        }

        Button {
          Layout.preferredWidth: 28
          Layout.preferredHeight: 28
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
          Layout.preferredHeight: 28
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
            font.pixelSize: 10
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }
      }

      Grid {
        width: parent.width
        columns: 7
        spacing: 4

        Repeater {
          model: 42

          Rectangle {
            required property int index
            readonly property int day: index - root.firstWeekday + 1
            readonly property bool inMonth: day > 0 && day <= root.daysInMonth

            width: (parent.width - parent.spacing * 6) / 7
            height: 30
            radius: 4
            color: root.isToday(day) && inMonth ? Theme.color8 : "transparent"
            border.width: root.isToday(day) && inMonth ? 0 : 1
            border.color: inMonth ? Theme.color2 : "transparent"

            Text {
              anchors.centerIn: parent
              text: parent.inMonth ? parent.day : ""
              color: root.isToday(parent.day)
                ? Theme.color0
                : Theme.foreground
              font.pixelSize: 12
              font.weight: root.isToday(parent.day)
                ? Font.DemiBold
                : Font.Normal
            }
          }
        }
      }

      Button {
        width: parent.width
        implicitHeight: 28
        visible: root.monthOffset !== 0
        onClicked: root.monthOffset = 0

        Text {
          anchors.centerIn: parent
          text: "Today"
          color: Theme.color8
          font.pixelSize: 11
        }
      }
    }
  }
  }
}
