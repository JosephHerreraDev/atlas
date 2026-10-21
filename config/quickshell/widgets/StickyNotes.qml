// SPDX-License-Identifier: GPL-3.0-only
// Adapted from Ryoku NotesWidget.qml and WidgetSlot.qml:
// https://github.com/ryoku-dev/ryoku
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import "../"

// The note content stays a simple text plate while this host owns movement,
// resizing and persistence.
Scope {
  id: root

  readonly property bool opened: WidgetState.stickyNotesVisible
  property string noteTitle: "Default title"
  property string noteText: ""
  property bool editing: false
  property bool previewing: false
  property bool loaded: false
  property bool loading: false
  property int widgetX: 52
  property int widgetY: 52
  property int widgetWidth: 360
  property int widgetHeight: 360
  property bool locked: false
  property bool alwaysOnTop: false
  readonly property string colorChoice: WidgetState.stickyNotesColor
  readonly property bool themedColors: colorChoice === "theme"
  readonly property bool darkInk: ["yellow", "white", "green"]
    .indexOf(colorChoice) !== -1
  readonly property color solidColor: {
    switch (colorChoice) {
    case "yellow": return "#f6d365"
    case "white": return "#f4f4f2"
    case "red": return "#d95c5c"
    case "blue": return "#5b8def"
    case "green": return "#66b982"
    case "purple": return "#9b72cf"
    default: return Theme.surface
    }
  }
  readonly property color noteSurface: themedColors
    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.88)
    : solidColor
  readonly property color noteInk: themedColors ? Theme.foreground
    : (darkInk ? "#202124" : "#ffffff")
  readonly property color noteInkMuted: themedColors ? Theme.foregroundMuted
    : Qt.rgba(noteInk.r, noteInk.g, noteInk.b, 0.7)
  readonly property color noteAccent: themedColors ? Theme.accent : noteInk
  readonly property color noteBorder: themedColors ? Theme.border
    : Qt.rgba(noteInk.r, noteInk.g, noteInk.b, 0.28)
  readonly property color noteHover: themedColors ? Theme.surfaceHover
    : Qt.rgba(noteInk.r, noteInk.g, noteInk.b, 0.10)

  function open(): void { WidgetState.stickyNotesVisible = true }
  function close(): void { flush(); WidgetState.stickyNotesVisible = false }
  function toggle(): void {
    WidgetState.stickyNotesVisible = !WidgetState.stickyNotesVisible
  }
  function adoptActiveNote(preserveGeometry): void {
    let note = null
    for (let index = 0; index < NotesState.notes.length; ++index) {
      if (NotesState.notes[index].id === NotesState.activeId) {
        note = NotesState.notes[index]
        break
      }
    }
    if (!note)
      return
    loading = true
    noteTitle = typeof note.title === "string" && note.title !== ""
      ? note.title : "Default title"
    noteText = typeof note.markdown === "string" ? note.markdown
      : (typeof note.text === "string" ? note.text : "")
    if (!preserveGeometry) {
      widgetX = note.x
      widgetY = note.y
      widgetWidth = note.width
      widgetHeight = note.height
      locked = note.locked
      alwaysOnTop = note.alwaysOnTop === true
    }
    loading = false
    loaded = true
    if (preserveGeometry) {
      NotesState.updateActive({
        x: widgetX,
        y: widgetY,
        width: widgetWidth,
        height: widgetHeight,
        locked: locked,
        alwaysOnTop: alwaysOnTop
      })
    }
  }
  function save(): void {
    if (!loaded || loading || !NotesState.activeNote)
      return
    NotesState.updateActive({
      title: noteTitle === "" ? "Default title" : noteTitle,
      markdown: noteText,
      x: widgetX,
      y: widgetY,
      width: widgetWidth,
      height: widgetHeight,
      locked: locked,
      alwaysOnTop: alwaysOnTop
    })
  }
  function flush(): void {
    save()
  }

  function wrapSelection(textEditor, prefix, suffix, placeholder): void {
    const start = textEditor.selectionStart
    const end = textEditor.selectionEnd
    const selected = textEditor.selectedText
    const content = selected === "" ? placeholder : selected
    textEditor.remove(start, end)
    textEditor.insert(start, prefix + content + suffix)
    textEditor.select(start + prefix.length,
      start + prefix.length + content.length)
    textEditor.forceActiveFocus()
  }

  function prefixLine(textEditor, prefix): void {
    const position = textEditor.cursorPosition
    const lineStart = textEditor.text.lastIndexOf("\n",
      Math.max(0, position - 1)) + 1
    textEditor.insert(lineStart, prefix)
    textEditor.cursorPosition = position + prefix.length
    textEditor.forceActiveFocus()
  }

  function continueList(textEditor): bool {
    const position = textEditor.cursorPosition
    const lineStart = textEditor.text.lastIndexOf("\n",
      Math.max(0, position - 1)) + 1
    const lineBeforeCursor = textEditor.text.substring(lineStart, position)
    const checklist = lineBeforeCursor.match(/^(\s*)-\s+\[[ xX]\]\s+/)
    const bullet = lineBeforeCursor.match(/^(\s*)([-*+])\s+/)
    let prefix = ""

    if (checklist)
      prefix = checklist[1] + "- [ ] "
    else if (bullet)
      prefix = bullet[1] + bullet[2] + " "
    else
      return false

    if (textEditor.selectionStart !== textEditor.selectionEnd) {
      const selectionStart = textEditor.selectionStart
      textEditor.remove(selectionStart, textEditor.selectionEnd)
      textEditor.cursorPosition = selectionStart
    }

    const insertAt = textEditor.cursorPosition
    textEditor.insert(insertAt, "\n" + prefix)
    textEditor.cursorPosition = insertAt + prefix.length + 1
    return true
  }

  component FormatButton: Controls.Button {
    id: formatButton
    property string label: ""
    property string toolTip: ""
    property url iconSource: ""
    property bool availableInPreview: false
    enabled: !root.previewing || availableInPreview
    opacity: enabled ? 1 : 0.45
    width: 27
    height: 24
    focusPolicy: Qt.NoFocus
    Controls.ToolTip.visible: hovered && toolTip !== ""
    Controls.ToolTip.text: toolTip
    Controls.ToolTip.delay: 500
    background: Rectangle {
      radius: Theme.cornerRadius
      color: parent.checked || parent.hovered
        ? root.noteHover : "transparent"
      border.width: parent.checked ? Theme.borderWidth : 0
      border.color: root.noteAccent
    }
    contentItem: Item {
      Text {
        anchors.fill: parent
        visible: formatButton.iconSource.toString() === ""
        text: formatButton.label
        color: formatButton.checked ? root.noteAccent : root.noteInkMuted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: "monospace"
        font.pixelSize: 11
        font.weight: Font.DemiBold
      }
      IconImage {
        anchors.centerIn: parent
        width: 14
        height: 14
        visible: formatButton.iconSource.toString() !== ""
        source: formatButton.iconSource
        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: formatButton.checked
            ? root.noteAccent : root.noteInkMuted
        }
      }
    }
  }

  Component.onCompleted: adoptActiveNote(false)
  Component.onDestruction: flush()

  IpcHandler {
    target: "sticky-notes"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Connections {
    target: root
    function onNoteTitleChanged(): void {
      if (root.loaded && !root.loading) root.save()
    }
    function onNoteTextChanged(): void {
      if (root.loaded && !root.loading) root.save()
    }
    function onWidgetXChanged(): void { if (root.loaded && !root.loading) root.save() }
    function onWidgetYChanged(): void { if (root.loaded && !root.loading) root.save() }
    function onWidgetWidthChanged(): void { if (root.loaded && !root.loading) root.save() }
    function onWidgetHeightChanged(): void { if (root.loaded && !root.loading) root.save() }
    function onLockedChanged(): void { if (root.loaded && !root.loading) root.save() }
    function onAlwaysOnTopChanged(): void {
      if (root.loaded && !root.loading) root.save()
    }
  }

  Connections {
    target: NotesState
    function onActiveIdChanged(): void {
      root.adoptActiveNote(root.loaded)
    }
    function onLoadedChanged(): void {
      if (NotesState.loaded) root.adoptActiveNote(false)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData
      readonly property bool focusedScreen: Hyprland.focusedMonitor !== null
        && Hyprland.monitorFor(modelData) !== null
        && Hyprland.monitorFor(modelData).name === Hyprland.focusedMonitor.name

      screen: modelData
      visible: root.opened && focusedScreen
      color: "transparent"
      focusable: root.opened
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: root.alwaysOnTop
        ? WlrLayer.Overlay : WlrLayer.Bottom
      WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
      WlrLayershell.namespace: "atlas-sticky-notes"
      anchors { top: true; bottom: true; left: true; right: true }

      // The host spans the monitor for stable pointer coordinates, while the
      // input region remains restricted to the visible note.
      // Popup menus live in Qt's window overlay, outside the widget region.
      // Accept input across the window while a menu is open, including outside
      // clicks that dismiss it; restore click-through immediately on close.
      mask: (noteMenu.visible || textMenu.visible) ? null : widgetInputRegion
      property Region widgetInputRegion: Region {
        Region {
          intersection: Intersection.Combine
          x: Math.floor(noteSlot.x)
          y: Math.floor(noteSlot.y)
          width: Math.ceil(noteSlot.width)
          height: Math.ceil(noteSlot.height)
        }
      }

      onVisibleChanged: {
        if (!visible)
          root.flush()
      }

      Item {
        id: noteSlot

        property bool dragging: false
        property bool resizing: false
        property real dragX: root.widgetX
        property real dragY: root.widgetY
        property real resizeStartWidth: root.widgetWidth
        property real resizeStartHeight: root.widgetHeight

        function clampX(value) {
          if (window.width <= 0)
            return value
          return Math.max(0, Math.min(value, window.width - width))
        }
        function clampY(value) {
          if (window.height <= 0)
            return value
          return Math.max(0, Math.min(value, window.height - height))
        }
        function snap(value) {
          return Math.round(value / 16) * 16
        }

        x: dragging ? dragX : clampX(root.widgetX)
        y: dragging ? dragY : clampY(root.widgetY)
        width: root.widgetWidth
        height: root.widgetHeight
        scale: dragging ? 1.025 : 1
        transformOrigin: Item.Center

        Behavior on scale {
          NumberAnimation { duration: 140; easing.type: Easing.OutExpo }
        }

        MouseArea {
          id: moveGrip
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          hoverEnabled: true
          cursorShape: root.locked ? Qt.ArrowCursor
            : (noteSlot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor)

          property bool leftDown: false
          property real grabOffsetX: 0
          property real grabOffsetY: 0

          onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
              noteMenu.popup(mouse.x, mouse.y)
              return
            }
            if (root.locked)
              return
            leftDown = true
            const point = noteSlot.mapToItem(window.contentItem, mouse.x, mouse.y)
            grabOffsetX = point.x - noteSlot.x
            grabOffsetY = point.y - noteSlot.y
          }
          onPositionChanged: function(mouse) {
            if (!leftDown || root.locked)
              return
            const point = noteSlot.mapToItem(window.contentItem, mouse.x, mouse.y)
            const nextX = point.x - grabOffsetX
            const nextY = point.y - grabOffsetY
            if (!noteSlot.dragging
                && Math.abs(nextX - noteSlot.x) < 6
                && Math.abs(nextY - noteSlot.y) < 6)
              return
            noteSlot.dragging = true
            noteSlot.dragX = noteSlot.clampX(noteSlot.snap(nextX))
            noteSlot.dragY = noteSlot.clampY(noteSlot.snap(nextY))
          }
          onReleased: {
            if (noteSlot.dragging) {
              root.widgetX = Math.round(noteSlot.dragX)
              root.widgetY = Math.round(noteSlot.dragY)
              noteSlot.dragging = false
            }
            leftDown = false
          }
        }

        Rectangle {
          anchors.fill: parent
          radius: Theme.cornerRadius
          color: root.noteSurface
          border.width: Theme.borderWidth
          border.color: root.noteBorder
        }

        Item {
          id: noteHeader
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.topMargin: 12
          height: 26

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "QUICK NOTES"
            color: root.noteInk
            font.pixelSize: Theme.fontCaption
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
          }

          Controls.Button {
            id: addNoteButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 86
            height: 26
            onClicked: NotesState.addNote()
            background: Rectangle {
              radius: Theme.cornerRadius
              color: addNoteButton.hovered ? root.noteHover : "transparent"
              border.width: Theme.borderWidth
              border.color: root.noteBorder
            }
            contentItem: Text {
              text: "+ NEW NOTE"
              color: root.noteAccent
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              font.pixelSize: 9
              font.weight: Font.DemiBold
              font.letterSpacing: 0.7
            }
          }
        }

        ListView {
          id: noteList
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          anchors.topMargin: 46
          height: Math.max(30,
            Math.min(NotesState.notes.length, 4) * 33 - 3)
          spacing: 3
          clip: true
          model: NotesState.notes

          Behavior on height {
            NumberAnimation {
              duration: Theme.motionNormal
              easing.type: Easing.OutCubic
            }
          }

          delegate: Rectangle {
            id: noteRow
            required property var modelData
            required property int index
            width: noteList.width
            height: 30
            radius: Theme.cornerRadius
            color: modelData.id === NotesState.activeId
              ? root.noteHover : "transparent"

            Rectangle {
              visible: noteRow.modelData.id === NotesState.activeId
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: 2
              color: root.noteAccent
            }
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              text: (noteRow.index + 1 < 10 ? "0" : "")
                + String(noteRow.index + 1)
              color: root.noteInkMuted
              font.pixelSize: 9
            }
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 36
              anchors.right: deleteButton.left
              anchors.rightMargin: 6
              anchors.verticalCenter: parent.verticalCenter
              text: noteRow.modelData.title || "Default title"
              color: root.noteInk
              font.pixelSize: 11
              font.weight: noteRow.modelData.id === NotesState.activeId
                ? Font.DemiBold : Font.Normal
              elide: Text.ElideRight
            }
            MouseArea {
              anchors.fill: parent
              anchors.rightMargin: deleteButton.width + 4
              cursorShape: Qt.PointingHandCursor
              onClicked: NotesState.selectNote(noteRow.modelData.id)
            }
            Controls.Button {
              id: deleteButton
              visible: NotesState.notes.length > 1
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: 26
              height: 26
              onClicked: NotesState.removeNote(noteRow.modelData.id)
              background: Rectangle {
                radius: Theme.cornerRadius
                color: deleteButton.hovered ? root.noteHover : "transparent"
              }
              contentItem: Text {
                text: "×"
                color: root.noteInkMuted
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 15
              }
            }
          }
        }

        TextInput {
          id: titleEditor
          anchors.left: parent.left
          anchors.right: previewButton.left
          anchors.top: noteList.bottom
          anchors.leftMargin: 16
          anchors.rightMargin: 8
          anchors.topMargin: 10
          height: 24
          text: root.noteTitle
          color: root.noteInk
          selectionColor: root.noteAccent
          selectedTextColor: root.noteSurface
          selectByMouse: true
          font.pixelSize: 15
          font.weight: Font.DemiBold
          onActiveFocusChanged: {
            root.editing = activeFocus || editor.activeFocus
            if (!activeFocus) root.flush()
          }
          onTextChanged: {
            if (!root.loading && root.noteTitle !== text)
              root.noteTitle = text
          }
        }

        FormatButton {
          id: previewButton
          anchors.right: parent.right
          anchors.top: noteList.bottom
          anchors.rightMargin: 16
          anchors.topMargin: 10
          width: 72
          label: root.previewing ? "EDIT" : "PREVIEW"
          toolTip: root.previewing
            ? "Return to editing" : "Preview formatted markdown"
          availableInPreview: true
          checkable: true
          checked: root.previewing
          onClicked: {
            root.previewing = !root.previewing
            if (!root.previewing)
              Qt.callLater(function() { editor.forceActiveFocus() })
          }
        }

        Rectangle {
          id: titleDivider
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: titleEditor.bottom
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.topMargin: 8
          height: 1
          color: root.noteBorder
        }

        Row {
          id: formatToolbar
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.bottomMargin: 12
          height: 24
          spacing: 4

          FormatButton {
            iconSource: Qt.resolvedUrl("../assets/bold.svg")
            toolTip: "Bold"
            onClicked: root.wrapSelection(editor, "**", "**", "bold text")
          }
          FormatButton {
            iconSource: Qt.resolvedUrl("../assets/italic.svg")
            toolTip: "Italic"
            onClicked: root.wrapSelection(editor, "_", "_", "italic text")
          }
          FormatButton {
            iconSource: Qt.resolvedUrl("../assets/strikethrough.svg")
            toolTip: "Strikethrough"
            onClicked: root.wrapSelection(editor, "~~", "~~", "strikethrough")
          }
          FormatButton {
            iconSource: Qt.resolvedUrl("../assets/dot.svg")
            toolTip: "Bulleted list"
            onClicked: root.prefixLine(editor, "- ")
          }
          FormatButton {
            iconSource: Qt.resolvedUrl("../assets/checkmark.svg")
            toolTip: "Checklist"
            onClicked: root.prefixLine(editor, "- [ ] ")
          }
          FormatButton {
            iconSource: Qt.resolvedUrl("../assets/code.svg")
            toolTip: "Inline code"
            onClicked: root.wrapSelection(editor, "`", "`", "code")
          }
        }

        Rectangle {
          id: formatDivider
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: formatToolbar.top
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.bottomMargin: 6
          height: 1
          color: root.noteBorder
        }

        Flickable {
          id: viewport
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: titleDivider.bottom
          anchors.bottom: formatDivider.top
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.topMargin: 8
          anchors.bottomMargin: 8
          clip: true
          interactive: true
          flickableDirection: Flickable.VerticalFlick
          boundsBehavior: Flickable.StopAtBounds
          contentWidth: width
          contentHeight: root.previewing
            ? markdownPreview.height : editor.height

          Controls.ScrollBar.vertical: Controls.ScrollBar {
            policy: Controls.ScrollBar.AsNeeded
            width: 6
          }

          TextEdit {
            id: editor
            width: viewport.width - 10
            height: Math.max(implicitHeight, viewport.height)
            visible: !root.previewing
            enabled: root.opened
            text: root.noteText
            color: root.noteInk
            selectionColor: root.noteAccent
            selectedTextColor: root.noteSurface
            selectByMouse: true
            persistentSelection: true
            wrapMode: TextEdit.Wrap
            font.pixelSize: 15
            font.weight: Font.Medium

            onActiveFocusChanged: {
              root.editing = activeFocus || titleEditor.activeFocus
              if (!activeFocus)
                root.flush()
            }
            onTextChanged: {
              if (!root.loading && root.noteText !== text)
                root.noteText = text
            }
            onCursorRectangleChanged: {
              if (cursorRectangle.y < viewport.contentY)
                viewport.contentY = cursorRectangle.y
              else if (cursorRectangle.y + cursorRectangle.height
                  > viewport.contentY + viewport.height)
                viewport.contentY = cursorRectangle.y
                  + cursorRectangle.height - viewport.height
            }
            Keys.onEscapePressed: function(event) {
              editor.focus = false
              event.accepted = true
            }
            Keys.onReturnPressed: function(event) {
              event.accepted = root.continueList(editor)
            }
            Keys.onEnterPressed: function(event) {
              event.accepted = root.continueList(editor)
            }

            Text {
              anchors.fill: parent
              visible: editor.text.length === 0
              text: "Jot a note…"
              color: root.noteInkMuted
              opacity: 0.7
              font: editor.font
              wrapMode: Text.Wrap
            }
          }

          TextEdit {
            id: markdownConverter
            visible: false
            font.pixelSize: 15
          }

          TextEdit {
            id: markdownPreview
            width: viewport.width - 10
            height: Math.max(implicitHeight, viewport.height)
            visible: root.previewing
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            textFormat: TextEdit.RichText
            color: root.noteInk
            selectionColor: root.noteAccent
            selectedTextColor: root.noteSurface
            wrapMode: TextEdit.Wrap
            font.pixelSize: 15

            function refreshMarkdown() {
              markdownConverter.textFormat = TextEdit.MarkdownText
              markdownConverter.text = root.noteText === "" ? "*Nothing to preview*" : root.noteText
              markdownConverter.textFormat = TextEdit.RichText
              // Keep Qt's Markdown parser and formatting, but use compact
              // per-level list margins instead of its 40px indent units.
              text = markdownConverter.text
                .replace(/<body style="[^"]*">/, "<body>")
                .replace(/<(ul|ol) style="([^"]*)"/g, function(match, tag, style) {
                  return "<" + tag + " style=\"" + style
                    .replace(/margin-left:\s*[^;]+;/, "margin-left:16px;")
                    .replace(/-qt-list-indent:\s*\d+;/, "-qt-list-indent:0;") + "\""
                })
            }
            Component.onCompleted: refreshMarkdown()
            Connections {
              target: root
              function onNoteTextChanged(): void {
                if (root.previewing) markdownPreview.refreshMarkdown()
              }
              function onPreviewingChanged(): void {
                if (root.previewing) markdownPreview.refreshMarkdown()
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            z: 10
            acceptedButtons: Qt.RightButton
            onPressed: function(mouse) {
              const target = root.previewing ? markdownPreview : editor
              if (target.selectedText === "") {
                const point = mapToItem(target, mouse.x, mouse.y)
                target.cursorPosition = target.positionAt(point.x, point.y)
              }
              target.forceActiveFocus()
              textMenu.textTarget = target
              const menuPoint = mapToItem(noteSlot, mouse.x, mouse.y)
              textMenu.popup(menuPoint.x, menuPoint.y)
              mouse.accepted = true
            }
          }
        }

        HoverHandler { id: noteHover }

        Item {
          id: resizeHandle
          width: 24
          height: 24
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          opacity: ((noteHover.hovered && !root.locked
            && !noteSlot.dragging) || noteSlot.resizing) ? 1 : 0
          visible: opacity > 0

          Behavior on opacity { NumberAnimation { duration: 120 } }

          Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 14
            height: 2
            radius: 1
            color: resizeGrip.containsMouse || noteSlot.resizing
              ? root.noteAccent : root.noteInkMuted
          }
          Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 2
            height: 14
            radius: 1
            color: resizeGrip.containsMouse || noteSlot.resizing
              ? root.noteAccent : root.noteInkMuted
          }

          MouseArea {
            id: resizeGrip
            anchors.fill: parent
            enabled: !root.locked
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor

            property real originX: 0
            property real originY: 0

            onPressed: function(mouse) {
              const point = resizeGrip.mapToItem(window.contentItem,
                mouse.x, mouse.y)
              originX = point.x
              originY = point.y
              noteSlot.resizeStartWidth = root.widgetWidth
              noteSlot.resizeStartHeight = root.widgetHeight
              noteSlot.resizing = true
            }
            onPositionChanged: function(mouse) {
              if (!noteSlot.resizing)
                return
              const point = resizeGrip.mapToItem(window.contentItem,
                mouse.x, mouse.y)
              root.widgetWidth = Math.max(300,
                noteSlot.resizeStartWidth + point.x - originX)
              root.widgetHeight = Math.max(280,
                noteSlot.resizeStartHeight + point.y - originY)
            }
            onReleased: noteSlot.resizing = false
          }
        }

        Rectangle {
          visible: noteSlot.resizing
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.rightMargin: 28
          anchors.bottomMargin: 28
          width: sizeText.implicitWidth + 16
          height: 22
          radius: Theme.cornerRadius
          color: Qt.rgba(0, 0, 0, 0.68)

          Text {
            id: sizeText
            anchors.centerIn: parent
            text: Math.round(root.widgetWidth) + " × "
              + Math.round(root.widgetHeight)
            color: "white"
            font.pixelSize: 11
            font.weight: Font.DemiBold
          }
        }

        WidgetMenu {
          id: textMenu
          surfaceColor: root.noteSurface
          hoverColor: root.noteHover
          textColor: root.noteInk
          mutedTextColor: root.noteInkMuted
          accentColor: root.noteAccent
          borderColor: root.noteBorder
          separatorColor: root.noteBorder
          property var textTarget: editor
          WidgetMenuItem {
            menuColors: textMenu
            text: "Undo"
            hint: "Ctrl+Z"
            enabled: !textMenu.textTarget.readOnly && textMenu.textTarget.canUndo
            onTriggered: textMenu.textTarget.undo()
          }
          WidgetMenuItem {
            menuColors: textMenu
            text: "Redo"
            hint: "Ctrl+Shift+Z"
            enabled: !textMenu.textTarget.readOnly && textMenu.textTarget.canRedo
            onTriggered: textMenu.textTarget.redo()
          }
          WidgetMenuSeparator { menuColors: textMenu }
          WidgetMenuItem {
            menuColors: textMenu
            text: "Cut"
            hint: "Ctrl+X"
            enabled: !textMenu.textTarget.readOnly && textMenu.textTarget.selectedText !== ""
            onTriggered: textMenu.textTarget.cut()
          }
          WidgetMenuItem {
            menuColors: textMenu
            text: "Copy"
            hint: "Ctrl+C"
            enabled: textMenu.textTarget.selectedText !== ""
            onTriggered: textMenu.textTarget.copy()
          }
          WidgetMenuItem {
            menuColors: textMenu
            text: "Paste"
            hint: "Ctrl+V"
            enabled: !textMenu.textTarget.readOnly && textMenu.textTarget.canPaste
            onTriggered: textMenu.textTarget.paste()
          }
          WidgetMenuItem {
            menuColors: textMenu
            text: "Delete"
            enabled: !textMenu.textTarget.readOnly && textMenu.textTarget.selectedText !== ""
            onTriggered: textMenu.textTarget.remove(textMenu.textTarget.selectionStart,
              textMenu.textTarget.selectionEnd)
          }
          WidgetMenuSeparator { menuColors: textMenu }
          WidgetMenuItem {
            menuColors: textMenu
            text: "Select all"
            hint: "Ctrl+A"
            enabled: textMenu.textTarget.length > 0
            onTriggered: textMenu.textTarget.selectAll()
          }
        }

        WidgetMenu {
          id: noteMenu
          surfaceColor: root.noteSurface
          hoverColor: root.noteHover
          textColor: root.noteInk
          mutedTextColor: root.noteInkMuted
          accentColor: root.noteAccent
          borderColor: root.noteBorder
          separatorColor: root.noteBorder
          WidgetMenuItem {
            menuColors: noteMenu
            text: "New note"
            onTriggered: NotesState.addNote()
          }
          WidgetMenuItem {
            menuColors: noteMenu
            text: "Preview Markdown"
            checkable: true
            checked: root.previewing
            onTriggered: root.previewing = checked
          }
          WidgetMenuSeparator { menuColors: noteMenu }
          WidgetMenuItem {
            menuColors: noteMenu
            text: "Lock position and size"
            checkable: true
            checked: root.locked
            onTriggered: root.locked = checked
          }
          WidgetMenuItem {
            menuColors: noteMenu
            text: "Keep above windows"
            checkable: true
            checked: root.alwaysOnTop
            onTriggered: root.alwaysOnTop = checked
          }
          WidgetMenuItem {
            menuColors: noteMenu
            text: "Reset position"
            enabled: !root.locked
            onTriggered: { root.widgetX = 52; root.widgetY = 52 }
          }
          WidgetMenuItem {
            menuColors: noteMenu
            text: "Reset size"
            enabled: !root.locked
            onTriggered: {
              root.widgetWidth = 360
              root.widgetHeight = 360
            }
          }
          WidgetMenuSeparator { menuColors: noteMenu }
          WidgetMenuItem {
            menuColors: noteMenu
            enabled: NotesState.notes.length > 1
            text: "Delete current note"
            destructive: true
            onTriggered: NotesState.removeNote(NotesState.activeId)
          }
          WidgetMenuSeparator { menuColors: noteMenu }
          WidgetMenuItem {
            menuColors: noteMenu
            text: "Hide widget"
            onTriggered: root.close()
          }
        }
      }
    }
  }
}
