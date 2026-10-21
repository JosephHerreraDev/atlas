pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property var notes: []
  property string activeId: ""
  property bool loaded: false
  readonly property var activeNote: {
    for (let index = 0; index < notes.length; ++index) {
      if (notes[index].id === activeId)
        return notes[index]
    }
    return notes.length > 0 ? notes[0] : null
  }

  function defaultNote() {
    return {
      id: String(Date.now()) + "-" + String(Math.floor(Math.random() * 100000)),
      title: "Default title",
      markdown: "",
      x: 52,
      y: 52,
      width: 360,
      height: 360,
      locked: false,
      alwaysOnTop: false
    }
  }

  function normalize(note) {
    return {
      id: typeof note.id === "string" && note.id !== "" ? note.id
        : String(Date.now()) + "-" + String(Math.floor(Math.random() * 100000)),
      title: typeof note.title === "string" && note.title !== ""
        ? note.title : "Default title",
      markdown: typeof note.markdown === "string" ? note.markdown
        : (typeof note.text === "string" ? note.text : ""),
      x: Number.isFinite(Number(note.x)) ? Math.max(0, Number(note.x)) : 52,
      y: Number.isFinite(Number(note.y)) ? Math.max(0, Number(note.y)) : 52,
      width: Number.isFinite(Number(note.width)) ? Math.max(300, Number(note.width)) : 360,
      height: Number.isFinite(Number(note.height)) ? Math.max(280, Number(note.height)) : 360,
      locked: note.locked === true,
      alwaysOnTop: note.alwaysOnTop === true
    }
  }

  function addNote(title) {
    const note = defaultNote()
    if (typeof title === "string" && title !== "")
      note.title = title
    if (activeNote) {
      note.x = activeNote.x
      note.y = activeNote.y
      note.width = activeNote.width
      note.height = activeNote.height
      note.locked = activeNote.locked
      note.alwaysOnTop = activeNote.alwaysOnTop
    }
    const next = notes.slice()
    next.push(note)
    notes = next
    activeId = note.id
    WidgetState.stickyNotesVisible = true
    saveTimer.restart()
  }

  function openOrAddNote(title) {
    const existing = notes.find(function(note) {
      return note.title === title
    })
    if (existing) {
      activeId = existing.id
      WidgetState.stickyNotesVisible = true
      return
    }
    addNote(title)
  }

  function selectNote(id) {
    if (notes.some(function(note) { return note.id === id }))
      activeId = id
  }

  function updateActive(values) {
    if (!activeNote)
      return
    const next = notes.slice()
    const index = next.findIndex(function(note) { return note.id === activeId })
    if (index < 0)
      return
    next[index] = normalize(Object.assign({}, next[index], values))
    notes = next
    saveTimer.restart()
  }

  function removeNote(id) {
    if (notes.length <= 1)
      return
    const index = notes.findIndex(function(note) { return note.id === id })
    if (index < 0)
      return
    const next = notes.filter(function(note) { return note.id !== id })
    notes = next
    if (activeId === id)
      activeId = next[Math.min(index, next.length - 1)].id
    saveTimer.restart()
  }

  function save() {
    if (!loaded)
      return
    notesFile.setText(JSON.stringify({
      format: "markdown",
      notes: notes,
      activeId: activeId
    }, null, 2) + "\n")
  }

  Timer { id: saveTimer; interval: 300; onTriggered: root.save() }

  FileView {
    id: notesFile
    path: (Quickshell.env("XDG_CONFIG_HOME")
      || Quickshell.env("HOME") + "/.config")
      + "/atlas/stickynotes.txt"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      let parsed = null
      try { parsed = JSON.parse(text()) } catch (error) {}
      let loadedNotes = []
      if (parsed && Array.isArray(parsed.notes))
        loadedNotes = parsed.notes.map(function(note) { return root.normalize(note) })
      else if (parsed && typeof parsed === "object")
        loadedNotes = [root.normalize(parsed)]
      else if (text() !== "") {
        const migrated = root.defaultNote()
        migrated.markdown = text()
        loadedNotes = [migrated]
      }
      if (loadedNotes.length === 0)
        loadedNotes = [root.defaultNote()]
      root.notes = loadedNotes
      root.activeId = parsed && typeof parsed.activeId === "string"
        && loadedNotes.some(function(note) { return note.id === parsed.activeId })
        ? parsed.activeId : loadedNotes[0].id
      root.loaded = true
      root.save()
    }
    onLoadFailed: {
      const note = root.defaultNote()
      root.notes = [note]
      root.activeId = note.id
      root.loaded = true
      root.save()
    }
  }
}
