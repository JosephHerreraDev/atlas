import Quickshell
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../"
import "../shared/"

FocusScope {
  id: root

  implicitWidth: 356
  implicitHeight: calendar.implicitHeight + padding * 2

  readonly property int padding: Theme.spaceSm
  readonly property real contentWidth: width - padding * 2
  readonly property real backgroundOpacity: 1
  required property bool calendarVisible

  property bool datePicker: false
  signal datePicked(date day)
  signal closeRequested()

  property date selectedDate: new Date()
  property int monthOffset: 0
  property string viewMode: "days"
  property int yearPageStart: 0
  readonly property date now: clock.date
  readonly property date displayedMonth: new Date(
    now.getFullYear(), now.getMonth() + monthOffset, 1)
  readonly property int firstWeekday: (displayedMonth.getDay() + 6) % 7

  function dateForCell(index) {
    return new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(),
      index - firstWeekday + 1)
  }

  function sameDate(left, right) {
    return left.getDate() === right.getDate()
      && left.getMonth() === right.getMonth()
      && left.getFullYear() === right.getFullYear()
  }

  readonly property var dayTasks: datePicker ? [] : ReminderState.reminders.filter(function(task) {
    return task.due !== null && root.sameDate(new Date(task.due), root.selectedDate)
  })

  function hasDateReminder(selectedDate) {
    return ReminderState.reminders.some(function(reminder) {
      return !reminder.completed && reminder.due !== null
        && root.sameDate(new Date(reminder.due), selectedDate)
    })
  }

  function showNextLevel() {
    if (viewMode === "days") {
      viewMode = "months"
    } else if (viewMode === "months") {
      yearPageStart = Math.floor(displayedMonth.getFullYear() / 12) * 12
      viewMode = "years"
    }
  }

  function navigate(amount) {
    if (viewMode === "days") monthOffset += amount
    else if (viewMode === "months") monthOffset += amount * 12
    else yearPageStart += amount * 12
  }

  function chooseYear(year) {
    monthOffset += (year - displayedMonth.getFullYear()) * 12
    viewMode = "months"
  }

  function chooseMonth(month) {
    monthOffset += month - displayedMonth.getMonth()
    viewMode = "days"
  }

  focus: calendarVisible

  onCalendarVisibleChanged: {
    if (calendarVisible && !datePicker) {
      // Reopen on the current month so the widget never starts in a stale view.
      selectedDate = new Date()
      monthOffset = 0
      viewMode = "days"
      yearPageStart = Math.floor(now.getFullYear() / 12) * 12
      Qt.callLater(function() { root.forceActiveFocus() })
    }
  }

  Keys.onEscapePressed: function(event) {
    root.closeRequested()
    event.accepted = true
  }

  Shortcut {
    sequence: "Escape"
    context: Qt.WindowShortcut
    enabled: root.calendarVisible
    onActivated: root.closeRequested()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Column {
    id: calendar

    anchors.centerIn: parent
    width: root.contentWidth
    spacing: Theme.spaceMd

    Rectangle {
      width: parent.width
      height: 78
      visible: !root.datePicker
      radius: Theme.radiusLg
      color: Theme.surfaceHover
      border.width: Theme.borderWidth
      border.color: Theme.accent

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceSm
        anchors.rightMargin: Theme.spaceSm
        anchors.topMargin: Theme.spaceSm
        anchors.bottomMargin: Theme.spaceSm
        spacing: Theme.spaceLg

        Column {
          Layout.fillWidth: true
          spacing: Theme.spaceXxs

          Text {
            text: Qt.formatDate(root.now, "dddd").toUpperCase()
            color: Theme.accent
            font.pixelSize: Theme.fontBody
            font.weight: Theme.weightStrong
          }

          Text {
            text: Qt.formatDate(root.now, "MMMM d, yyyy")
            color: Theme.foreground
            font.pixelSize: Theme.fontTitle + 1
            font.weight: Theme.weightStrong
          }
        }

        Item {
          Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
          implicitWidth: timeText.implicitWidth
          implicitHeight: timeText.implicitHeight

          Text {
            id: timeText
            anchors.centerIn: parent
            text: Qt.formatDateTime(root.now, "HH:mm:ss")
            color: Theme.foreground
            font.pixelSize: Theme.fontDisplay
            font.weight: Theme.weightStrong
          }
        }
      }
    }

    Rectangle {
      width: parent.width
      height: monthContent.implicitHeight + Theme.spaceSm * 2
      radius: Theme.radiusLg
      color: Theme.surface
      border.width: Theme.borderWidth
      border.color: Theme.border

      Column {
        id: monthContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spaceSm
        anchors.rightMargin: Theme.spaceSm
        spacing: Theme.spaceSm

        RowLayout {
          width: parent.width
          height: Theme.controlHeight
          spacing: Theme.spaceXs

          Button {

            consumeWheel: false
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            horizontalPadding: Theme.spaceXs
            buttonColor: hovered ? Theme.surfaceHover : "transparent"
            buttonBorderWidth: 0
            accessibleName: root.viewMode === "days"
              ? "Choose month" : "Choose year"
            onClicked: root.showNextLevel()

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: root.viewMode === "days"
                ? Qt.formatDate(root.displayedMonth, "MMMM yyyy")
                : (root.viewMode === "months"
                  ? String(root.displayedMonth.getFullYear())
                  : String(root.yearPageStart) + "–"
                    + String(root.yearPageStart + 11))
              color: Theme.foreground
              font.pixelSize: Theme.fontTitle
              font.weight: Theme.weightStrong
            }
          }

          Button {

            consumeWheel: false
            Layout.preferredHeight: 24
            horizontalPadding: Theme.spaceSm
            enabled: root.monthOffset !== 0 || root.viewMode !== "days"
            opacity: enabled ? 1 : 0
            buttonColor: hovered ? Theme.surfaceHover : "transparent"
            buttonBorderWidth: 0
            accessibleName: "Return to current month"
            onClicked: {
              root.monthOffset = 0
              root.viewMode = "days"
            }

            Text {
              anchors.centerIn: parent
              text: "Today"
              color: Theme.accent
              font.pixelSize: Theme.fontCaption
              font.weight: Theme.weightStrong
            }
          }

          Button {

            consumeWheel: false
            Layout.preferredWidth: 26
            Layout.preferredHeight: 24
            horizontalPadding: 0
            buttonColor: hovered ? Theme.surfaceHover : "transparent"
            buttonBorderWidth: 0
            accessibleName: "Previous calendar page"
            onClicked: root.navigate(-1)

            Text {
              anchors.centerIn: parent
              text: "‹"
              color: Theme.foreground
              font.pixelSize: 18
            }
          }

          Button {

            consumeWheel: false
            Layout.preferredWidth: 26
            Layout.preferredHeight: 24
            horizontalPadding: 0
            buttonColor: hovered ? Theme.surfaceHover : "transparent"
            buttonBorderWidth: 0
            accessibleName: "Next calendar page"
            onClicked: root.navigate(1)

            Text {
              anchors.centerIn: parent
              text: "›"
              color: Theme.foreground
              font.pixelSize: 18
            }
          }
        }

        Grid {
          id: calendarGrid
          visible: root.viewMode === "days"
          width: parent.width
          columns: 7
          spacing: Theme.spaceXxs

          Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]

            Text {
              required property string modelData

              width: (calendarGrid.width - calendarGrid.spacing * 6) / 7
              height: 20
              text: modelData
              color: Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
              font.weight: Theme.weightStrong
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }

          Repeater {
            model: 42

            Rectangle {
              id: dayCell

              required property int index
              readonly property date cellDate: root.dateForCell(index)
              readonly property bool inMonth:
                cellDate.getMonth() === root.displayedMonth.getMonth()
                && cellDate.getFullYear() === root.displayedMonth.getFullYear()
              readonly property bool today: root.sameDate(cellDate, root.now)
              readonly property bool hasEntry: root.hasDateReminder(cellDate)
              readonly property bool selected: root.sameDate(cellDate, root.selectedDate)
              width: (calendarGrid.width - calendarGrid.spacing * 6) / 7
              height: 32
              radius: height / 2
              color: today ? Theme.accent
                : (dayHover.hovered && inMonth
                  ? Theme.selectionBackground
                  : "transparent")
              border.width: today || selected ? Theme.borderWidth : 0
              border.color: today || selected ? Theme.accent : "transparent"

              Text {
                anchors.centerIn: parent
                text: dayCell.cellDate.getDate()
                color: dayCell.today ? Theme.background
                  : (dayHover.hovered && dayCell.inMonth ? Theme.selectionForeground
                    : dayCell.inMonth ? Theme.foreground : Theme.foregroundMuted)
                opacity: dayCell.inMonth ? 1 : 0.55
                font.pixelSize: Theme.fontBody
                font.weight: dayCell.today
                  ? Theme.weightStrong : Theme.weightRegular
              }

              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                width: 4
                height: 4
                radius: 2
                visible: dayCell.inMonth && dayCell.hasEntry
                color: dayCell.today ? Theme.background
                  : dayHover.hovered ? Theme.selectionForeground : Theme.accent
              }

              HoverHandler {
                id: dayHover
                cursorShape: dayCell.inMonth
                  ? Qt.PointingHandCursor : Qt.ArrowCursor
              }

              TapHandler {
                enabled: dayCell.inMonth
                onTapped: {
                  root.selectedDate = dayCell.cellDate
                  if (root.datePicker) root.datePicked(dayCell.cellDate)
                }
              }

              Behavior on color {
                ColorAnimation { duration: Theme.motionQuick }
              }
            }
          }
        }

        Grid {
          id: pickerGrid
          visible: root.viewMode !== "days"
          width: parent.width
          columns: 3
          spacing: Theme.spaceXs

          Repeater {
            model: root.viewMode === "months"
              ? ["January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"]
              : 12

            Rectangle {
              id: pickerCell
              required property int index
              required property var modelData
              readonly property int value: root.viewMode === "months"
                ? index : root.yearPageStart + index
              readonly property bool selected: root.viewMode === "months"
                ? index === root.displayedMonth.getMonth()
                : value === root.displayedMonth.getFullYear()
              width: (pickerGrid.width - pickerGrid.spacing * 2) / 3
              height: 42
              radius: Theme.cornerRadius
              color: selected ? Theme.accent
                : (pickerHover.hovered ? Theme.selectionBackground : "transparent")

              Text {
                anchors.centerIn: parent
                text: root.viewMode === "months"
                  ? pickerCell.modelData : String(pickerCell.value)
                color: pickerCell.selected ? Theme.background
                  : pickerHover.hovered ? Theme.selectionForeground : Theme.foreground
                font.pixelSize: Theme.fontBody
                font.weight: pickerCell.selected
                  ? Theme.weightStrong : Theme.weightRegular
              }

              HoverHandler {
                id: pickerHover
                cursorShape: Qt.PointingHandCursor
              }

              TapHandler {
                onTapped: {
                  if (root.viewMode === "months")
                    root.chooseMonth(pickerCell.value)
                  else
                    root.chooseYear(pickerCell.value)
                }
              }

              Behavior on color {
                ColorAnimation { duration: Theme.motionQuick }
              }
            }
          }
        }
      }
    }

    Column {
      visible: !root.datePicker
      width: parent.width
      spacing: Theme.spaceSm
      Rectangle {
        width: parent.width
        height: 1
        color: Theme.border
      }
      RowLayout {
        width: parent.width
        Text {
          Layout.fillWidth: true
          text: Qt.formatDate(root.selectedDate, "ddd, MMM d")
          color: Theme.foreground
          font.pixelSize: Theme.fontTitle
          font.weight: Theme.weightStrong
        }
        Text {
          text: root.dayTasks.length + (root.dayTasks.length === 1 ? " task" : " tasks")
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
      }
      Text {
        visible: root.dayTasks.length === 0
        width: parent.width
        text: "No tasks scheduled for this day."
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontBody
        wrapMode: Text.WordWrap
      }
      Flickable {
        width: parent.width
        height: Math.min(200, dayTaskList.implicitHeight)
        contentHeight: dayTaskList.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }
        Column {
          id: dayTaskList
          width: parent.width
          spacing: 6
          Repeater {
            model: root.dayTasks
            Rectangle {
              id: calendarTask
              required property var modelData
              width: dayTaskList.width
              height: taskInfo.implicitHeight + 20
              color: Theme.surfaceHover
              radius: Theme.radiusMd
              RowLayout {
                id: taskInfo
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10
                Button {
                  consumeWheel: false
                  Layout.preferredWidth: 36
                  Layout.preferredHeight: 36
                  Layout.alignment: Qt.AlignTop
                  enabled: ReminderState.loaded
                  buttonColor: hovered ? Theme.surface : "transparent"
                  buttonBorderColor: activeFocus ? Theme.accent : "transparent"
                  accessibleName: (calendarTask.modelData.completed ? "Reopen " : "Complete ")
                    + calendarTask.modelData.title
                  onClicked: ReminderState.toggleComplete(calendarTask.modelData.id)
                  Rectangle {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.accent
                    Text {
                      anchors.centerIn: parent
                      text: "✓"
                      visible: calendarTask.modelData.completed
                      color: Theme.accent
                      font.pixelSize: 16
                    }
                  }
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 4
                  Text {
                    Layout.fillWidth: true
                    text: calendarTask.modelData.title
                    color: calendarTask.modelData.completed ? Theme.foregroundMuted : Theme.foreground
                    font.pixelSize: Theme.fontBody + 1
                    font.strikeout: calendarTask.modelData.completed
                    wrapMode: Text.WordWrap
                  }
                  Text {
                    text: calendarTask.modelData.completed ? "Completed"
                      : calendarTask.modelData.hasTime === false ? "Any time"
                      : Qt.formatTime(new Date(calendarTask.modelData.due), "HH:mm")
                    color: Theme.foregroundMuted
                    font.pixelSize: Theme.fontCaption
                  }
                }
              }
            }
          }
        }
      }
      Button {
        consumeWheel: false
        visible: !root.datePicker
        width: parent.width
        height: 40
        radius: Theme.radiusMd
        accessibleName: "Add task due " + Qt.formatDate(root.selectedDate, "MMMM d, yyyy")
        onClicked: {
          ReminderState.toggleForDate(root.selectedDate)
          root.closeRequested()
        }

        Text {
          anchors.centerIn: parent
          text: "+ Add task"
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightStrong
        }
      }

    }

  }
}
