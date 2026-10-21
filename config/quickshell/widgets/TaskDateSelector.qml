import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"
import "../bar/" as Bar
import "../bar/ReminderSchedule.js" as Schedule

ColumnLayout {
  id: root
  property string text: ""
  property bool expanded: false
  readonly property var dateValue: Schedule.parseDate(text) || new Date()
  WidgetPalette { id: colors; choice: WidgetState.tasksColor }
  spacing: Theme.spaceSm
  onVisibleChanged: { if (!visible) expanded = false }

  Button {
    consumeWheel: false
    Layout.fillWidth: true
    Layout.preferredHeight: 40
    buttonColor: hovered ? colors.hoverColor : colors.surfaceColor
    buttonBorderColor: activeFocus || root.expanded ? colors.accentColor : colors.borderColor
    accessibleName: "Choose date, " + Qt.formatDate(root.dateValue, "MMMM d, yyyy")
    onClicked: {
      if (!root.expanded) {
        picker.selectedDate = root.dateValue
        picker.monthOffset = (root.dateValue.getFullYear() - picker.now.getFullYear()) * 12
          + root.dateValue.getMonth() - picker.now.getMonth()
        picker.viewMode = "days"
      }
      root.expanded = !root.expanded
    }
    Text {
      anchors.centerIn: parent
      text: Qt.formatDate(root.dateValue, "ddd, MMM d, yyyy") + (root.expanded ? "  ▴" : "  ▾")
      color: colors.textColor
      font.pixelSize: Theme.fontBody + 1
    }
  }
  Bar.CalendarMenu {
    id: picker
    Layout.fillWidth: true
    visible: root.expanded
    calendarVisible: root.expanded
    datePicker: true
    onDatePicked: function(day) {
      root.text = Qt.formatDate(day, "yyyy-MM-dd")
      root.expanded = false
    }
    onCloseRequested: root.expanded = false
  }
}
