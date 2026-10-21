import QtQuick
import QtQuick.Effects
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../"
import "../shared/"
import "../bar/"
import "../bar/ReminderSchedule.js" as Schedule

Rectangle {
  id: root

  WidgetPalette { id: colors; choice: WidgetState.tasksColor }
  component ColorButton: Button {
    consumeWheel: false
    Layout.minimumHeight: 36
    Layout.minimumWidth: 36
    horizontalPadding: 10
    verticalPadding: 8
    buttonColor: hovered ? colors.hoverColor : colors.surfaceColor
    buttonBorderColor: colors.borderColor
  }

  component TaskNumberInput: Controls.SpinBox {
    wheelEnabled: false
    id: numberControl
    Layout.minimumHeight: 40
    implicitHeight: 40
    editable: true
    font.pixelSize: Theme.fontBody + 1
    leftPadding: 32
    rightPadding: 32
    background: Rectangle {
      radius: Theme.radiusSm
      color: colors.surfaceColor
      border.width: 1
      border.color: numberControl.activeFocus ? colors.accentColor : colors.borderColor
    }
    contentItem: TextInput {
      text: numberControl.textFromValue(numberControl.value, numberControl.locale)
      color: colors.textColor
      font: numberControl.font
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      selectByMouse: true
      validator: numberControl.validator
      inputMethodHints: Qt.ImhDigitsOnly
      onEditingFinished: {
        const value = numberControl.valueFromText(text, numberControl.locale)
        if (Number.isFinite(value)) numberControl.value = Math.max(numberControl.from, Math.min(numberControl.to, value))
        text = Qt.binding(function() { return numberControl.textFromValue(numberControl.value, numberControl.locale) })
      }
      Keys.onUpPressed: numberControl.increase()
      Keys.onDownPressed: numberControl.decrease()
    }
    down.indicator: Rectangle {
      width: 30
      height: numberControl.height
      radius: Theme.radiusSm
      color: numberControl.down.pressed || numberControl.down.hovered ? colors.hoverColor : "transparent"
      Text { anchors.centerIn: parent; text: "−"; color: numberControl.down.enabled ? colors.accentColor : colors.mutedColor; font.pixelSize: 20 }
    }
    up.indicator: Rectangle {
      x: numberControl.width - width
      width: 30
      height: numberControl.height
      radius: Theme.radiusSm
      color: numberControl.up.pressed || numberControl.up.hovered ? colors.hoverColor : "transparent"
      Text { anchors.centerIn: parent; text: "+"; color: numberControl.up.enabled ? colors.accentColor : colors.mutedColor; font.pixelSize: 20 }
    }
  }

  component TaskCheckBox: Controls.CheckBox {
    id: check
    Layout.minimumHeight: 40
    Layout.minimumWidth: 40
    implicitHeight: 40
    spacing: 10
    padding: 8
    hoverEnabled: true
    font.pixelSize: Theme.fontBody + 1
    opacity: enabled ? 1 : 0.45
    indicator: Rectangle {
      x: check.leftPadding
      y: (check.height - height) / 2
      width: 20
      height: 20
      radius: 4
      color: check.checked
        ? Qt.tint(colors.surfaceColor, Qt.rgba(colors.accentColor.r, colors.accentColor.g, colors.accentColor.b, 0.12))
        : check.hovered ? colors.hoverColor : "transparent"
      border.width: check.activeFocus ? 2 : 1
      border.color: colors.accentColor
      scale: check.down ? 0.92 : 1
      Behavior on color { ColorAnimation { duration: 120 } }
      Behavior on scale { NumberAnimation { duration: 100 } }
      Image {
        anchors.centerIn: parent
        width: 16
        height: 16
        source: "../assets/check.svg"
        visible: check.checked
        layer.enabled: true
        layer.effect: MultiEffect { brightness: 1; colorization: 1; colorizationColor: colors.accentColor }
      }
    }
    contentItem: Text {
      text: check.text
      font: check.font
      color: colors.textColor
      leftPadding: check.text ? check.indicator.width + check.spacing : 0
      verticalAlignment: Text.AlignVCenter
      wrapMode: Text.WordWrap
    }
    background: Rectangle {
      radius: Theme.radiusSm
      color: "transparent"
      border.width: check.activeFocus ? 1 : 0
      border.color: colors.accentColor
    }
  }

  ListModel { id: draftSubtasks }
  function subtaskValues() {
    const result = []
    for (let i = 0; i < draftSubtasks.count; i++) {
      const item = draftSubtasks.get(i)
      result.push({ title: item.title, completed: item.completed })
    }
    return result
  }

  property date selectedDate: new Date()
  property string message: ""
  property string editingId: ""
  property bool editorOpen: false
  property string repeatPreset: "daily"

  function startNew(withDueDate): void {
    resetTime()
    dueEnabled.checked = withDueDate === true
    editorOpen = true
    titleInput.forceActiveFocus()
  }
  readonly property var repeatUnits: ["hour", "day", "week", "month", "year"]
  property double now: Date.now()
  Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }

  function matchesView(task, filter): bool {
    if (filter === "open") return !task.completed
    if (filter === "done") return task.completed
    return true
  }

  readonly property var selectedTasks: {
    const query = searchInput.text.trim().toLowerCase()
    const currentTime = root.now
    return ReminderState.reminders.filter(function(task) {
      return root.matchesView(task, ReminderState.taskFilter)
        && (!query || task.title.toLowerCase().indexOf(query) !== -1)
    }).sort(function(a, b) {
      if (a.completed !== b.completed) return a.completed ? 1 : -1
      const aLate = !a.completed && a.due !== null && a.due < currentTime
      const bLate = !b.completed && b.due !== null && b.due < currentTime
      if (aLate !== bLate) return aLate ? -1 : 1
      return (a.due === null ? Infinity : a.due) - (b.due === null ? Infinity : b.due)
    })
  }

  implicitHeight: form.implicitHeight + Theme.spaceSm * 2
  radius: Theme.radiusLg
  color: colors.panelColor
  border.width: colors.borderColorWidth
  border.color: colors.borderColor

  function resetTime(): void {
    const next = new Date(Date.now() + 5 * 60000)
    editingId = ""
    dateInput.expanded = false
    endDate.expanded = false
    draftSubtasks.clear()
    titleInput.text = ""
    dateInput.text = Qt.formatDate(selectedDate, "yyyy-MM-dd")
    timeSelector.hour = next.getHours()
    timeSelector.minute = next.getMinutes()
    dueEnabled.checked = false
    timeEnabled.checked = false
    notifyEnabled.checked = true
    repeatEnabled.checked = false
    repeatPreset = "daily"
    repeatEvery.value = 1
    repeatUnit.currentIndex = 1
    endMode.currentIndex = 0
    endDate.text = Qt.formatDate(selectedDate, "yyyy-MM-dd")
    occurrenceCount.value = 10
    message = ""
  }

  function editTask(reminder): void {
    editorOpen = true
    editingId = reminder.id
    draftSubtasks.clear()
    ;(reminder.subtasks || []).forEach(function(item) {
      draftSubtasks.append({ title: item.title, completed: item.completed })
    })
    titleInput.text = reminder.title
    dueEnabled.checked = reminder.due !== null
    timeEnabled.checked = reminder.due !== null && reminder.hasTime !== false
    notifyEnabled.checked = reminder.notify
    const due = new Date(reminder.due === null ? selectedDate : reminder.due)
    dateInput.text = Qt.formatDate(due, "yyyy-MM-dd")
    timeSelector.hour = due.getHours()
    timeSelector.minute = due.getMinutes()
    const repeat = Schedule.normalizeRepeat(reminder.repeat)
    repeatEnabled.checked = repeat !== null
    repeatEvery.value = repeat ? repeat.every : 1
    repeatUnit.currentIndex = repeat ? repeatUnits.indexOf(repeat.unit) : 1
    repeatPreset = repeat && repeat.every === 1
      ? ({day: "daily", week: "weekly", month: "monthly", year: "yearly"})[repeat.unit] || "custom"
      : repeat ? "custom" : "daily"
    endMode.currentIndex = repeat && repeat.count ? 2
      : repeat && repeat.until !== undefined ? 1 : 0
    endDate.text = Qt.formatDate(repeat && repeat.until !== undefined
      ? new Date(repeat.until) : due, "yyyy-MM-dd")
    occurrenceCount.value = repeat && repeat.count ? repeat.count : 10
    message = ""
    titleInput.forceActiveFocus()
  }

  function saveTask(): void {
    const parts = dateInput.text.match(/^(\d{4})-(\d{2})-(\d{2})$/)
    if (dueEnabled.checked && !parts) {
      message = "Enter a date as YYYY-MM-DD."
      return
    }
    const due = dueEnabled.checked ? new Date(Number(parts[1]), Number(parts[2]) - 1,
      Number(parts[3]), timeEnabled.checked ? timeSelector.hour : 23,
      timeEnabled.checked ? timeSelector.minute : 59, timeEnabled.checked ? 0 : 59,
      timeEnabled.checked ? 0 : 999) : null
    if (due && (due.getFullYear() !== Number(parts[1]) || due.getMonth() !== Number(parts[2]) - 1
        || due.getDate() !== Number(parts[3]))) {
      message = "Choose a valid date."
      return
    }
    const repeat = dueEnabled.checked && repeatEnabled.checked
      ? { every: repeatEvery.value, unit: repeatUnits[repeatUnit.currentIndex] } : null
    if (repeat && repeat.unit === "hour" && !timeEnabled.checked) {
      message = "Enable a due time to repeat hourly."
      return
    }
    if (repeat && endMode.currentIndex === 1) {
      const end = Schedule.parseDate(endDate.text)
      if (!end) {
        message = "Enter a valid end date as YYYY-MM-DD."
        return
      }
      end.setHours(23, 59, 59, 999)
      if (end.getTime() < due.getTime()) {
        message = "End date must be on or after the reminder date."
        return
      }
      repeat.until = end.getTime()
    }
    if (repeat && endMode.currentIndex === 2) repeat.count = occurrenceCount.value
    const editing = editingId !== ""
    const saved = editing
      ? ReminderState.update(editingId, titleInput.text, due ? due.getTime() : null, repeat, notifyEnabled.checked, root.subtaskValues(), dueEnabled.checked && timeEnabled.checked)
      : ReminderState.add(titleInput.text, due ? due.getTime() : null, repeat, notifyEnabled.checked, root.subtaskValues(), dueEnabled.checked && timeEnabled.checked)
    if (!saved) {
      message = "Enter a task and ensure the repeat limit includes this occurrence."
      return
    }
    if (due) ReminderState.selectedDate = due
    else ReminderState.taskFilter = "open"
    searchInput.text = ""
    resetTime()
    editorOpen = false
    message = editing ? "Task updated" : "Task saved"
  }

  Component.onCompleted: resetTime()
  onSelectedDateChanged: { resetTime(); editorOpen = false }

  Connections {
    target: ReminderState
    function onRemindersChanged(): void {
      if (root.editingId && !ReminderState.reminders.some(function(reminder) {
        return reminder.id === root.editingId
      })) root.resetTime()
    }
  }

  ColumnLayout {
    id: form
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      margins: Theme.spaceSm
    }
    spacing: Theme.spaceSm

    RowLayout {
      Layout.fillWidth: true
      visible: !root.editorOpen
      spacing: Theme.spaceXs
      Repeater {
        model: ["open", "done", "all"]
        ColorButton {
          required property string modelData
          Layout.fillWidth: true
          buttonColor: ReminderState.taskFilter === modelData ? colors.selectionColor : colors.hoverColor
          accessibleName: "Show " + modelData + " tasks"
          onClicked: ReminderState.taskFilter = modelData
          Text {
            anchors.centerIn: parent
            text: (modelData.charAt(0).toUpperCase() + modelData.slice(1))
              + " " + ReminderState.reminders.filter(function(task) { return root.matchesView(task, modelData) }).length
            color: ReminderState.taskFilter === modelData ? colors.selectionTextColor : colors.textColor
            font.pixelSize: Theme.fontBody + 1
          }
        }
      }
    }

    Controls.TextField {
        font.pixelSize: Theme.fontBody + 1
        Layout.minimumHeight: 36
      id: searchInput
      Layout.fillWidth: true
      visible: !root.editorOpen
      placeholderText: "Search tasks…"
      Accessible.name: "Search tasks by title"
      color: colors.textColor
      placeholderTextColor: colors.mutedColor
      selectByMouse: true
      leftPadding: 12
      rightPadding: 12
      background: Rectangle {
        implicitHeight: 40
        radius: Theme.radiusSm
        color: colors.hoverColor
        border.width: colors.borderColorWidth
        border.color: searchInput.activeFocus ? colors.accentColor : colors.borderColor
      }
      Keys.onEscapePressed: text = ""
    }

    ColumnLayout {
      Layout.fillWidth: true
      visible: root.editorOpen
      spacing: Theme.spaceSm
      Controls.TextField {
        font.pixelSize: Theme.fontBody + 1
        Layout.minimumHeight: 36
        id: titleInput
        Layout.fillWidth: true
        placeholderText: "What needs to be done?"
        Accessible.name: "Task title"
        color: colors.textColor
        placeholderTextColor: colors.mutedColor
        selectByMouse: true
        background: Rectangle {
          implicitHeight: 40
          color: colors.hoverColor
          radius: Theme.radiusSm
          border.width: colors.borderColorWidth
          border.color: titleInput.activeFocus ? colors.accentColor : colors.borderColor
        }
        onAccepted: root.saveTask()
      }

      Text {
        text: "Subtasks"
        color: colors.mutedColor
        font.pixelSize: Theme.fontBody + 1
      }
      Repeater {
        model: draftSubtasks
        RowLayout {
          required property int index
          required property string title
          required property bool completed
          Layout.fillWidth: true
          TaskCheckBox {
            checked: parent.completed
            Accessible.name: "Complete subtask " + parent.title
            onClicked: draftSubtasks.setProperty(parent.index, "completed", checked)
          }
          Controls.TextField {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 40
            text: parent.title
            placeholderText: "What is the next step?"
            Accessible.name: "Subtask title"
            color: colors.textColor
            placeholderTextColor: colors.mutedColor
            font.pixelSize: Theme.fontBody + 1
            selectByMouse: true
            onTextEdited: draftSubtasks.setProperty(parent.index, "title", text)
            background: Rectangle {
              radius: Theme.radiusSm
              color: colors.hoverColor
              border.width: 1
              border.color: parent.activeFocus ? colors.accentColor : colors.borderColor
            }
          }
          ColorButton {
            accessibleName: "Remove subtask " + parent.title
            onClicked: draftSubtasks.remove(parent.index)
            Text { anchors.centerIn: parent; text: "×"; color: colors.mutedColor; font.pixelSize: Theme.fontTitle }
          }
        }
      }
      ColorButton {
        Layout.fillWidth: true
        accessibleName: "Add subtask"
        onClicked: draftSubtasks.append({ title: "", completed: false })
        Text { anchors.centerIn: parent; text: "+ Add subtask"; color: colors.accentColor; font.pixelSize: Theme.fontBody + 1 }
      }

      TaskCheckBox {
        id: dueEnabled
        text: "Due date"

      }

      TaskDateSelector {
        id: dateInput
        visible: dueEnabled.checked
        Layout.fillWidth: true
      }

      TaskCheckBox {
        id: timeEnabled
        visible: dueEnabled.checked
        text: "Due time"
      }

      ReminderTimeSelector {
        id: timeSelector
        wheelEnabled: false
        visible: dueEnabled.checked && timeEnabled.checked
        Layout.fillWidth: true
      }

      TaskCheckBox {
        id: notifyEnabled
        visible: dueEnabled.checked
        text: timeEnabled.checked ? "Notify me at the due time" : "Notify me at 9:00 AM"
        checked: true

      }

      TaskCheckBox {
        id: repeatEnabled
        visible: dueEnabled.checked
        text: "Repeat task"

      }

      Rectangle {
        Layout.fillWidth: true
        visible: dueEnabled.checked && repeatEnabled.checked
        implicitHeight: repeatOptions.implicitHeight + 24
        radius: Theme.radiusMd
        color: colors.hoverColor
        border.width: colors.borderColorWidth
        border.color: colors.borderColor
        ColumnLayout {
          id: repeatOptions
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 12
          spacing: 10
          Text {
            text: "Frequency"
            color: colors.textColor
            font.pixelSize: Theme.fontBody + 1
            font.weight: Theme.weightStrong
          }
          GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 6
            columnSpacing: 6
            Repeater {
              model: ["daily", "weekly", "monthly", "yearly", "custom"]
              ColorButton {
                required property string modelData
                Layout.fillWidth: true
                buttonColor: root.repeatPreset === modelData ? colors.selectionColor : colors.surfaceColor
                accessibleName: "Repeat " + modelData
                onClicked: {
                  root.repeatPreset = modelData
                  if (modelData !== "custom") {
                    repeatEvery.value = 1
                    repeatUnit.currentIndex = ({daily: 1, weekly: 2, monthly: 3, yearly: 4})[modelData]
                  }
                }
                Text {
                  anchors.centerIn: parent
                  text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                  color: root.repeatPreset === modelData ? colors.selectionTextColor : colors.textColor
                  font.pixelSize: Theme.fontBody
                }
              }
            }
          }
      RowLayout {
        Layout.fillWidth: true
        visible: root.repeatPreset === "custom"
        Text {
          text: "Every"
          color: colors.textColor
          font.pixelSize: Theme.fontBody
        }
        TaskNumberInput {
        font.pixelSize: Theme.fontBody + 1
        Layout.minimumHeight: 36
          id: repeatEvery
          Layout.fillWidth: true
          from: 1
          to: 999
          value: 1
          editable: true
          Accessible.name: "Repeat interval"
        }
        Controls.ComboBox {
          wheelEnabled: false
        font.pixelSize: Theme.fontBody + 1
        Layout.minimumHeight: 36
          id: repeatUnit
          Layout.fillWidth: true
          model: repeatEvery.value === 1 ? ["hour", "day", "week", "month", "year"] : ["hours", "days", "weeks", "months", "years"]
          currentIndex: 1
          Accessible.name: "Repeat unit"
          leftPadding: 12
          rightPadding: 28
          Layout.preferredHeight: 40
          background: Rectangle {
            radius: Theme.radiusSm
            color: repeatUnit.hovered ? colors.hoverColor : colors.surfaceColor
            border.width: 1
            border.color: repeatUnit.activeFocus ? colors.accentColor : colors.borderColor
          }
          contentItem: Text {
            text: repeatUnit.displayText
            color: colors.textColor
            font: repeatUnit.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
          indicator: Text {
            x: repeatUnit.width - width - 10
            y: (repeatUnit.height - height) / 2
            text: "⌄"
            color: colors.mutedColor
            font.pixelSize: 18
          }
          popup: Controls.Popup {
            y: repeatUnit.height + 4
            width: repeatUnit.width
            padding: 4
            implicitHeight: unitList.contentHeight + 8
            background: Rectangle {
              color: colors.surfaceColor
              radius: Theme.radiusSm
              border.width: 1
              border.color: colors.borderColor
            }
            contentItem: ListView {
              id: unitList
              implicitHeight: contentHeight
              clip: true
              model: repeatUnit.popup.visible ? repeatUnit.delegateModel : null
              currentIndex: repeatUnit.highlightedIndex
            }
          }
          delegate: Controls.ItemDelegate {
            id: unitOption
            required property int index
            required property string modelData
            width: repeatUnit.width - 8
            height: 36
            highlighted: repeatUnit.highlightedIndex === index
            background: Rectangle {
              radius: Theme.radiusSm
              color: unitOption.highlighted ? colors.selectionColor : "transparent"
            }
            contentItem: Text {
              text: unitOption.modelData
              color: unitOption.highlighted ? colors.selectionTextColor : colors.textColor
              font.pixelSize: Theme.fontBody + 1
              verticalAlignment: Text.AlignVCenter
            }
          }
        }
      }

          Text {
            Layout.fillWidth: true
            visible: root.repeatPreset === "custom" && repeatUnit.currentIndex === 0 && !timeEnabled.checked
            text: "Enable Due time to repeat hourly."
            color: Theme.warning
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
          }
          Text {
            text: "Ends"
            color: colors.textColor
            font.pixelSize: Theme.fontBody + 1
            font.weight: Theme.weightStrong
          }
          ColumnLayout {
            id: endMode
            property int currentIndex: 0
            Layout.fillWidth: true
            spacing: 2
            Repeater {
              model: ["Never", "On a date", "After a set number"]
              ColorButton {
                required property int index
                required property string modelData
                Layout.fillWidth: true
                buttonColor: endMode.currentIndex === index ? colors.selectionColor : "transparent"
                buttonBorderColor: "transparent"
                accessibleName: "Repeat ends " + modelData
                onClicked: endMode.currentIndex = index
                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  text: (endMode.currentIndex === index ? "●  " : "○  ") + modelData
                  color: endMode.currentIndex === index ? colors.selectionTextColor : colors.textColor
                  font.pixelSize: Theme.fontBody + 1
                }
              }
            }
          }
          TaskDateSelector {
            id: endDate
            Layout.fillWidth: true
            visible: endMode.currentIndex === 1
          }
          RowLayout {
            Layout.fillWidth: true
            visible: endMode.currentIndex === 2
            TaskNumberInput {
              id: occurrenceCount
              Layout.fillWidth: true
              Layout.minimumHeight: 40
              font.pixelSize: Theme.fontBody + 1
              from: 1
              to: 9999
              value: 10
              editable: true
              Accessible.name: "Total task occurrences, including the first"
            }
            Text { text: "times"; color: colors.textColor; font.pixelSize: Theme.fontBody + 1 }
          }
          Text {
            Layout.fillWidth: true
            text: Schedule.repeatLabel({every: repeatEvery.value, unit: root.repeatUnits[repeatUnit.currentIndex]}).replace(" · no end", endMode.currentIndex === 0 ? " · no end" : "")
              + (endMode.currentIndex === 1 ? "\nEnds " + Qt.formatDate(endDate.dateValue, "MMM d, yyyy")
                : endMode.currentIndex === 2 ? "\n" + occurrenceCount.value + " occurrences, including the first" : "")
            color: colors.accentColor
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
          }
          Text {
            Layout.fillWidth: true
            text: "Completing this task schedules the next occurrence."
            color: colors.mutedColor
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
          }
        }
      }

      ColorButton {
        Layout.fillWidth: true
        id: saveTaskButton
        Layout.preferredHeight: 40
        radius: Theme.radiusMd
        enabled: ReminderState.loaded && titleInput.text.trim().length > 0
        opacity: enabled ? 1 : 0.45
        buttonColor: pressed ? Qt.darker(colors.accentColor, 1.12)
          : hovered ? Qt.lighter(colors.accentColor, 1.08) : colors.accentColor
        buttonBorderWidth: activeFocus ? 2 : 0
        buttonBorderColor: colors.textColor
        accessibleName: "Save task"
        onClicked: root.saveTask()
        Text {
          anchors.centerIn: parent
          text: root.editingId ? "Save changes" : "Add task"
          color: colors.surfaceColor
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightStrong
        }
      }

      ColorButton {
        Layout.fillWidth: true
        accessibleName: "Cancel editing task"
        onClicked: { root.resetTime(); root.editorOpen = false }
        Text {
          anchors.centerIn: parent
          text: "Cancel"
          color: colors.textColor
          font.pixelSize: Theme.fontBody
        }
      }

    }

    Text {
      Layout.fillWidth: true
      visible: root.message.length > 0
      text: root.message
      color: colors.accentColor
      font.pixelSize: Theme.fontBody + 1
      wrapMode: Text.WordWrap
    }

    Text {
      visible: !root.editorOpen && root.selectedTasks.length > 0
      text: "Tasks · " + root.selectedTasks.length
      color: colors.mutedColor
      font.pixelSize: Theme.fontBody + 1
      font.weight: Theme.weightStrong
    }

    Text {
      Layout.fillWidth: true
      visible: !root.editorOpen && root.selectedTasks.length === 0
      text: searchInput.text.trim() ? "No matching tasks. Try another search."
        : ReminderState.taskFilter === "done" ? "Completed tasks will appear here."
        : "All clear. Use + New to add your next task."
      wrapMode: Text.WordWrap
      Layout.topMargin: Theme.spaceSm
      Layout.bottomMargin: Theme.spaceSm
      color: colors.mutedColor
      font.pixelSize: Theme.fontBody + 1
    }

    ColumnLayout {
      Layout.fillWidth: true
      visible: !root.editorOpen
      spacing: 6
      Repeater {
        model: root.selectedTasks
        Rectangle {
          id: taskCard
          required property var modelData
          readonly property var subtasks: modelData.subtasks || []
          readonly property int doneCount: subtasks.filter(function(item) { return item.completed }).length
          readonly property bool overdue: !modelData.completed && modelData.due !== null && modelData.due < root.now
          Layout.fillWidth: true
          implicitHeight: taskBody.implicitHeight + 24
          radius: Theme.radiusMd
          color: colors.surfaceColor
          border.width: colors.borderColorWidth
          border.color: overdue ? Theme.warning : colors.borderColor

          ColumnLayout {
            id: taskBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10
          RowLayout {
            id: taskRow
            Layout.fillWidth: true
            spacing: 6
            TaskCheckBox {
              Layout.alignment: Qt.AlignTop
              Layout.preferredWidth: 36
              padding: 6
              checked: taskCard.modelData.completed
              Accessible.name: (checked ? "Reopen " : "Complete ") + taskCard.modelData.title
              onClicked: ReminderState.toggleComplete(taskCard.modelData.id)
            }
            ColumnLayout {
              Layout.fillWidth: true
              Layout.minimumWidth: 0
              spacing: 4
              Text {
                Layout.fillWidth: true
                text: taskCard.modelData.title
                color: taskCard.modelData.completed ? colors.mutedColor : colors.textColor
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.weightStrong
                font.strikeout: taskCard.modelData.completed
                wrapMode: Text.Wrap
              }
              Text {
                Layout.fillWidth: true
                visible: taskCard.modelData.due !== null
                text: (taskCard.overdue ? "Overdue · " : "")
                  + (taskCard.modelData.due === null ? "No due date"
                    : Qt.formatDateTime(new Date(taskCard.modelData.due), taskCard.modelData.hasTime === false ? "MMM d" : "MMM d · HH:mm"))
                color: taskCard.overdue ? Theme.warning : colors.mutedColor
                font.pixelSize: Theme.fontBody + 1
                wrapMode: Text.WordWrap
              }
              Text {
                Layout.fillWidth: true
                visible: !!taskCard.modelData.repeat
                text: taskCard.modelData.repeat ? Schedule.repeatLabel(taskCard.modelData.repeat) : ""
                color: colors.mutedColor
                font.pixelSize: Theme.fontBody + 1
                wrapMode: Text.WordWrap
              }
            }
            ColorButton {
              Layout.alignment: Qt.AlignTop
              buttonColor: hovered ? colors.hoverColor : "transparent"
              buttonBorderColor: "transparent"
              accessibleName: "Edit task " + taskCard.modelData.title
              onClicked: root.editTask(taskCard.modelData)
              Text { anchors.centerIn: parent; text: "Edit"; color: colors.accentColor; font.pixelSize: Theme.fontBody + 1 }
            }
            ColorButton {
              Layout.alignment: Qt.AlignTop
              buttonColor: hovered ? colors.hoverColor : "transparent"
              buttonBorderColor: "transparent"
              accessibleName: "Delete task " + taskCard.modelData.title
              onClicked: ReminderState.remove(taskCard.modelData.id)
              Text { anchors.centerIn: parent; text: "×"; color: colors.mutedColor; font.pixelSize: Theme.fontTitle }
            }
          }
            Rectangle {
              Layout.fillWidth: true
              visible: taskCard.subtasks.length > 0
              implicitHeight: subtaskBody.implicitHeight + 16
              radius: Theme.radiusSm
              color: colors.hoverColor
              ColumnLayout {
                id: subtaskBody
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 2
                RowLayout {
                  Layout.fillWidth: true
                  Layout.leftMargin: 6
                  Layout.rightMargin: 6
                  Text {
                    text: "Subtasks"
                    color: colors.mutedColor
                    font.pixelSize: Theme.fontCaption
                    font.weight: Theme.weightStrong
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: taskCard.doneCount + " / " + taskCard.subtasks.length
                    color: taskCard.doneCount === taskCard.subtasks.length ? colors.accentColor : colors.mutedColor
                    font.pixelSize: Theme.fontCaption
                  }
                }
                Rectangle {
                  Layout.fillWidth: true
                  Layout.leftMargin: 6
                  Layout.rightMargin: 6
                  Layout.topMargin: 4
                  Layout.bottomMargin: 4
                  height: 3
                  radius: 1.5
                  color: colors.borderColor
                  Rectangle {
                    width: parent.width * (taskCard.subtasks.length ? taskCard.doneCount / taskCard.subtasks.length : 0)
                    height: parent.height
                    radius: parent.radius
                    color: colors.accentColor
                    Behavior on width { NumberAnimation { duration: 160 } }
                  }
                }
                Repeater {
                  model: taskCard.subtasks
                  TaskCheckBox {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    enabled: !taskCard.modelData.completed
                    text: modelData.title
                    checked: modelData.completed
                    font.strikeout: modelData.completed
                    contentItem: Text {
                      text: parent.text
                      font: parent.font
                      color: parent.checked ? colors.mutedColor : colors.textColor
                      leftPadding: parent.indicator.width + parent.spacing
                      verticalAlignment: Text.AlignVCenter
                      wrapMode: Text.WordWrap
                    }
                    Accessible.name: (checked ? "Reopen subtask " : "Complete subtask ") + modelData.title
                    onClicked: ReminderState.toggleSubtask(taskCard.modelData.id, index)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
