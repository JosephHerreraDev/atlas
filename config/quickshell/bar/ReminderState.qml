pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "ReminderSchedule.js" as Schedule
import "../widgets/" as DesktopWidgets

Singleton {
  id: root

  property var reminders: []
  property bool loaded: false
  property date selectedDate: new Date()
  property string taskFilter: "open"
  signal dayOpened()

  function toggleForDate(day: date): void {
    if (DesktopWidgets.WidgetState.tasksVisible && DesktopWidgets.WidgetState.tasksRaised)
      DesktopWidgets.WidgetState.tasksVisible = false
    else
      openForDate(day)
  }

  function openForDate(day: date): void {
    taskFilter = "open"
    selectedDate = day
    DesktopWidgets.WidgetState.showWidget("tasks")
    dayOpened()
  }

  function save(): void {
    if (loaded)
      stateFile.setText(JSON.stringify({ reminders: reminders }, null, 2) + "\n")
  }

  function sortTasks(items) {
    return items.sort(function(a, b) {
      if (a.completed !== b.completed) return a.completed ? 1 : -1
      return (a.due === null ? Infinity : a.due) - (b.due === null ? Infinity : b.due)
    })
  }

  function normalizeSubtasks(items) {
    return (Array.isArray(items) ? items : []).filter(function(item) {
      return item && typeof item.title === "string" && item.title.trim().length > 0
    }).map(function(item) { return { title: item.title.trim(), completed: item.completed === true } })
  }

  function toggleSubtask(id: string, index: int): void {
    if (!loaded) return
    reminders = reminders.map(function(task) {
      if (task.id !== id || task.completed || !task.subtasks || !task.subtasks[index]) return task
      return Object.assign({}, task, { subtasks: task.subtasks.map(function(item, i) {
        return i === index ? Object.assign({}, item, { completed: !item.completed }) : item
      }) })
    })
    save()
  }

  function add(title: string, due: var, repeat: var, notify: bool, subtasks: var, hasTime: bool): bool {
    title = title.trim()
    if (!loaded || !title || (due !== null && !Number.isFinite(due))
        || (repeat && (due === null || !Schedule.validLimits(repeat, due, due)))) return false
    reminders = sortTasks(reminders.concat([{ id: Date.now().toString() + "-"
      + Math.random().toString(36).slice(2), title: title, due: due,
      repeat: Schedule.normalizeRepeat(repeat), repeatAnchor: due,
      subtasks: normalizeSubtasks(subtasks), hasTime: hasTime && due !== null,
      notify: notify && due !== null,
      notified: false, completed: false }]))
    save()
    return true
  }

  function update(id: string, title: string, due: var, repeat: var, notify: bool, subtasks: var, hasTime: bool): bool {
    title = title.trim()
    const original = reminders.find(function(task) { return task.id === id })
    if (!loaded || !title || !original || (due !== null && !Number.isFinite(due))) return false
    const normalized = Schedule.normalizeRepeat(repeat)
    const previous = Schedule.normalizeRepeat(original.repeat)
    const sameSchedule = original.due === due && normalized && previous
      && normalized.every === previous.every && normalized.unit === previous.unit
    const anchor = sameSchedule && Number.isFinite(original.repeatAnchor) ? original.repeatAnchor : due
    if (repeat && (due === null || !Schedule.validLimits(repeat, due, anchor))) return false
    reminders = sortTasks(reminders.map(function(task) {
      return task.id !== id ? task : Object.assign({}, task, {
        title: title, due: due, repeat: normalized, repeatAnchor: anchor,
        subtasks: normalizeSubtasks(subtasks), hasTime: hasTime && due !== null,
      notify: notify && due !== null,
        notified: original.due === due && original.notify === notify && original.hasTime === hasTime ? original.notified : false
      })
    }))
    save()
    return true
  }

  function toggleComplete(id: string): void {
    if (!loaded) return
    const task = reminders.find(function(item) { return item.id === id })
    if (!task) return
    let nextItems = reminders.slice()
    const index = nextItems.findIndex(function(item) { return item.id === id })
    const nextDue = !task.completed && task.repeat ? Schedule.nextDue(task, Math.max(Date.now(), task.due)) : null
    if (nextDue !== null) {
      nextItems[index] = Object.assign({}, task, { due: nextDue, notified: false,
        subtasks: normalizeSubtasks(task.subtasks).map(function(item) { return { title: item.title, completed: false } }) })
      nextItems.push(Object.assign({}, task, { id: task.id + "-done-" + Date.now(),
        repeat: null, completed: true, completedAt: Date.now() }))
    } else {
      nextItems[index] = Object.assign({}, task, { completed: !task.completed,
        completedAt: task.completed ? null : Date.now(), notified: task.completed ? false : task.notified })
    }
    reminders = sortTasks(nextItems)
    save()
  }

  function remove(id: string): void {
    reminders = reminders.filter(function(task) { return task.id !== id })
    save()
  }

  function notificationTime(task) {
    if (task.due === null) return null
    if (task.hasTime !== false) return task.due
    const day = new Date(task.due)
    day.setHours(9, 0, 0, 0)
    return day.getTime()
  }

  function checkDue(): void {
    if (!loaded) return
    const now = Date.now()
    const due = reminders.filter(function(task) {
      return !task.completed && task.notify && !task.notified && task.due !== null && root.notificationTime(task) <= now
    })
    if (!due.length) return
    const ids = due.map(function(task) { return task.id })
    reminders = reminders.map(function(task) {
      return ids.indexOf(task.id) >= 0 ? Object.assign({}, task, { notified: true }) : task
    })
    save()
    for (let i = 0; i < due.length; i++) {
      Quickshell.execDetached(["notify-send", "--app-name=Atlas Tasks",
        "--urgency=normal", "--", "Task due", due[i].title])
    }
  }

  FileView {
    id: stateFile
    path: (Quickshell.env("XDG_CONFIG_HOME")
      || Quickshell.env("HOME") + "/.config") + "/atlas/reminders.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (Array.isArray(data.reminders))
          root.reminders = root.sortTasks(data.reminders.filter(function(reminder) {
            return reminder && typeof reminder.id === "string"
              && typeof reminder.title === "string" && reminder.title.trim().length > 0
              && (reminder.due === null || (typeof reminder.due === "number" && Number.isFinite(reminder.due)))
          }).map(function(reminder) {
            const task = Object.assign({}, reminder)
            delete task.priority
            return Object.assign(task, {
              completed: reminder.completed === true,
              hasTime: reminder.due !== null && reminder.hasTime !== false,
              subtasks: root.normalizeSubtasks(reminder.subtasks),
              notify: reminder.notify !== false && reminder.due !== null,
              notified: reminder.notified === true,
              repeat: reminder.due === null ? null : Schedule.normalizeRepeat(reminder.repeat),
              repeatAnchor: typeof reminder.repeatAnchor === "number"
                && Number.isFinite(reminder.repeatAnchor) ? reminder.repeatAnchor : reminder.due
            })
          }))
      } catch (error) {}
      root.loaded = true
      root.checkDue()
    }
    onLoadFailed: root.loaded = true
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.loaded
    onTriggered: root.checkDue()
  }
}
