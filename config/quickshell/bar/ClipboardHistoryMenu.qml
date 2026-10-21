import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

FocusScope {
  id: root

  required property bool clipboardVisible
  property string query: ""
  property var entries: []
  property var filteredEntries: []
  property var pinnedIds: []
  property int selectedIndex: -1
  property bool confirmClear: false
  readonly property int maxVisibleRows: 7

  signal closeRequested()

  implicitWidth: 620
  implicitHeight: content.implicitHeight + Theme.spaceLg * 2
  focus: clipboardVisible

  function open(): void {
    query = ""
    refresh()
    Qt.callLater(function() { input.forceActiveFocus(); input.selectAll() })
  }

  function close(): void { query = "" }

  function refresh(): void {
    if (!listProcess.running)
      listProcess.exec(["cliphist", "list"])
  }

  function filter(): void {
    const needle = query.trim().toLowerCase()
    filteredEntries = entries.filter(function(entry) {
      return needle.length === 0
        || entry.searchablePreview.toLowerCase().indexOf(needle) !== -1
    }).sort(function(left, right) {
      const leftPinned = isPinned(left)
      const rightPinned = isPinned(right)
      return leftPinned === rightPinned ? 0 : (leftPinned ? -1 : 1)
    })
    selectedIndex = filteredEntries.length > 0 ? 0 : -1
  }

  function moveSelection(delta): void {
    if (filteredEntries.length === 0) {
      selectedIndex = -1
      return
    }
    selectedIndex = Math.max(0,
      Math.min(selectedIndex + delta, filteredEntries.length - 1))
  }

  function selectedEntry() {
    return selectedIndex >= 0 && selectedIndex < filteredEntries.length
      ? filteredEntries[selectedIndex] : null
  }

  function isPinned(entry): bool {
    return entry && pinnedIds.indexOf(entry.id) !== -1
  }

  function togglePin(entry): void {
    if (!entry)
      return
    const next = pinnedIds.slice()
    const index = next.indexOf(entry.id)
    if (index === -1)
      next.push(entry.id)
    else
      next.splice(index, 1)
    pinnedIds = next
    pinsFile.setText(JSON.stringify({ ids: pinnedIds }))
    filter()
  }

  function imageCachePath(entry): string {
    return "/tmp/atlas-clipboard-" + entry.id.replace(/[^a-zA-Z0-9_-]/g, "_")
      + "." + (entry.imageFormat || "png")
  }

  function visibleListHeight(): real {
    let height = 0
    const count = Math.min(filteredEntries.length, maxVisibleRows)
    for (let i = 0; i < count; i++)
      height += filteredEntries[i].isImage ? 136 : 62
    return height
  }

  function requestClear(): void {
    if (!confirmClear) {
      confirmClear = true
      clearConfirmTimer.restart()
      return
    }
    const ids = entries.filter(function(entry) { return !isPinned(entry) })
      .map(function(entry) { return entry.id })
    confirmClear = false
    if (ids.length > 0 && !clearProcess.running)
      clearProcess.exec(["sh", "-c",
        "for id do printf '%s\\n' \"$id\" | cliphist delete; done",
        "clipboard-clear"].concat(ids))
  }

  function act(command, entry, closeAfter): void {
    if (!entry || actionProcess.running)
      return
    if (command === "copy")
      actionProcess.exec(["sh", "-c",
        "cliphist decode \"$1\" | wl-copy", "clipboard", entry.id])
    else if (command === "delete") {
      if (isPinned(entry))
        togglePin(entry)
      actionProcess.exec(["sh", "-c",
        "printf '%s\\n' \"$1\" | cliphist delete", "clipboard", entry.id])
    }
    if (closeAfter)
      closeRequested()
  }

  onQueryChanged: filter()

  Keys.onEscapePressed: function(event) {
    closeRequested()
    event.accepted = true
  }

  Process {
    id: listProcess
    stdout: StdioCollector {
      onStreamFinished: {
        const parsed = []
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
          const separator = lines[i].indexOf("\t")
          if (separator < 1)
            continue
          const rawPreview = lines[i].slice(separator + 1)
          if (rawPreview.indexOf("\u0000") !== -1)
            continue
          const isImage = /image\//i.test(rawPreview)
            || /binary data.*(png|jpe?g|webp|gif|bmp|svg)/i.test(rawPreview)
          const formatMatch = rawPreview.match(/(?:image\/)?(png|jpe?g|webp|gif|bmp|svg(?:\+xml)?)/i)
          let imageFormat = formatMatch ? formatMatch[1].toLowerCase() : "png"
          if (imageFormat === "jpeg") imageFormat = "jpg"
          if (imageFormat === "svg+xml") imageFormat = "svg"
          parsed.push({
            id: lines[i].slice(0, separator),
            preview: isImage ? "" : rawPreview,
            searchablePreview: rawPreview,
            isImage: isImage,
            imageFormat: imageFormat
          })
        }
        root.entries = parsed
        root.filter()
      }
    }
  }

  Process {
    id: clearProcess
    onExited: function(exitCode) {
      if (root.clipboardVisible)
        root.refresh()
    }
  }

  Timer {
    id: clearConfirmTimer
    interval: 3000
    onTriggered: root.confirmClear = false
  }

  FileView {
    id: pinsFile
    path: (Quickshell.env("XDG_CONFIG_HOME")
      || Quickshell.env("HOME") + "/.config") + "/atlas/clipboard-pins.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (Array.isArray(data.ids))
          root.pinnedIds = data.ids.map(function(id) { return String(id) })
      } catch (error) {}
      root.filter()
    }
    onLoadFailed: setText(JSON.stringify({ ids: [] }))
  }

  Process {
    id: actionProcess
    onExited: function(exitCode) {
      if (root.clipboardVisible)
        root.refresh()
    }
  }

  ColumnLayout {
    id: content
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceLg }
    spacing: Theme.spaceSm

    RowLayout {
      Layout.fillWidth: true

      ColumnLayout {
        spacing: 0
        Text {
          text: "Clipboard history"
          color: Theme.foreground
          font.pixelSize: Theme.fontTitle
          font.weight: Theme.weightStrong
        }
        Text {
          text: root.entries.length === 0
            ? "Your recent copies will appear here"
            : root.filteredEntries.length + " of " + root.entries.length + " items"
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
      }

      Item { Layout.fillWidth: true }

      Button {
        id: clearButton
        Layout.preferredWidth: clearButtonContent.implicitWidth + Theme.spaceSm * 2
        Layout.minimumWidth: clearButtonContent.implicitWidth + Theme.spaceSm * 2
        Layout.preferredHeight: Theme.controlHeight
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        enabled: root.entries.some(function(entry) { return !root.isPinned(entry) })
          && !clearProcess.running
        accessibleName: root.confirmClear ? "Confirm clearing clipboard history" : "Clear clipboard history"
        buttonColor: hovered
          ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
        buttonBorderColor: root.confirmClear || hovered ? Theme.error : Theme.border
        onClicked: root.requestClear()

        Row {
          id: clearButtonContent
          anchors.centerIn: parent
          spacing: Theme.spaceXs

          IconImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            source: Qt.resolvedUrl("../assets/clear.svg")
            layer.enabled: true
            layer.effect: MultiEffect {
              brightness: 1
              colorization: 1
              colorizationColor: clearButton.enabled ? Theme.error : Theme.border
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.confirmClear ? "Confirm" : "Clear all"
            color: clearButton.enabled ? Theme.error : Theme.border
            font.pixelSize: Theme.fontCaption
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: 38

      Controls.TextField {
        id: input
        anchors.fill: parent
        placeholderText: "Search copied text and images"
        selectByMouse: true
        color: Theme.foreground
        placeholderTextColor: Theme.foregroundMuted
        leftPadding: 38
        rightPadding: 12
        onTextChanged: root.query = text
        onAccepted: root.act("copy", root.selectedEntry(), true)
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Down) {
            root.moveSelection(1); event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.moveSelection(-1); event.accepted = true
          } else if (event.key === Qt.Key_Delete) {
            root.act("delete", root.selectedEntry(), false); event.accepted = true
          } else if (event.key === Qt.Key_P) {
            root.togglePin(root.selectedEntry()); event.accepted = true
          } else if (event.key === Qt.Key_Escape) {
            root.closeRequested(); event.accepted = true
          }
          if (event.accepted && root.selectedIndex >= 0)
            clipboardList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        }
        background: Rectangle {
          radius: Theme.radiusMd
          color: Theme.surfaceHover
          border.width: Theme.borderWidth
          border.color: input.activeFocus ? Theme.borderFocus : Theme.border
        }
      }

      IconImage {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 15; height: 15
        source: Qt.resolvedUrl("../assets/search.svg")
        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: input.activeFocus ? Theme.accent : Theme.foregroundMuted
        }
      }
    }

    Text {
      visible: root.filteredEntries.length === 0
      Layout.fillWidth: true
      Layout.preferredHeight: 64
      text: root.entries.length === 0 ? "Clipboard history is empty" : "No matching items"
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontBody
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }

    ListView {
      id: clipboardList
      visible: root.filteredEntries.length > 0
      Layout.fillWidth: true
      Layout.preferredHeight: root.visibleListHeight()
      clip: true
      model: root.filteredEntries
      currentIndex: root.selectedIndex
      spacing: Theme.spaceXxs
      boundsBehavior: Flickable.StopAtBounds
      Controls.ScrollBar.vertical: Controls.ScrollBar {
        policy: root.filteredEntries.length > root.maxVisibleRows
          ? Controls.ScrollBar.AsNeeded : Controls.ScrollBar.AlwaysOff
      }

      delegate: Rectangle {
        id: card
        required property int index
        required property var modelData
        property string decodedImage: ""
        width: clipboardList.width
        height: card.modelData.isImage ? 132 : 58
        radius: Theme.radiusMd
        color: ListView.isCurrentItem || cardMouse.containsMouse ? Theme.surfaceHover : Theme.surface
        border.width: ListView.isCurrentItem ? Theme.borderWidth : 0
        border.color: Theme.borderFocus

        RowLayout {
          anchors.fill: parent
          anchors.margins: Theme.spaceSm
          spacing: Theme.spaceSm

          Rectangle {
            visible: card.modelData.isImage
            Layout.preferredWidth: card.modelData.isImage ? 190 : 0
            Layout.preferredHeight: 116
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.radiusSm
            color: ListView.isCurrentItem
              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) : Theme.background
            border.width: Theme.borderWidth
            border.color: ListView.isCurrentItem ? Theme.accent : Theme.border
            Image {
              id: imagePreview
              anchors.fill: parent
              anchors.margins: 2
              visible: card.modelData.isImage
              source: card.decodedImage
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              cache: false
              sourceSize.width: 96
              sourceSize.height: 96
            }

            Text {
              anchors.centerIn: parent
              visible: imagePreview.status !== Image.Ready
              text: "▧"
              color: ListView.isCurrentItem ? Theme.accent : Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
              font.weight: Theme.weightStrong
            }
          }

          ColumnLayout {
            visible: !card.modelData.isImage
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            Text {
              Layout.fillWidth: true
              text: card.modelData.preview
              color: Theme.foreground
              font.pixelSize: Theme.fontBody
              maximumLineCount: card.modelData.isImage ? 1 : 2
              wrapMode: Text.Wrap
              elide: Text.ElideRight
            }
          }

          Item { visible: card.modelData.isImage; Layout.fillWidth: true }

          Rectangle {
            z: 2
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.radiusSm
            color: pinMouse.containsMouse || root.isPinned(card.modelData)
              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
              : "transparent"

            IconImage {
              anchors.centerIn: parent
              width: 15; height: 15
              source: Qt.resolvedUrl("../assets/pin.svg")
              layer.enabled: true
              layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: root.isPinned(card.modelData)
                  ? Theme.accent : Theme.foregroundMuted
              }
            }

            MouseArea {
              id: pinMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.togglePin(card.modelData)
            }
          }

          Rectangle {
            z: 2
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.radiusSm
            color: deleteMouse.containsMouse
              ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
            IconImage {
              anchors.centerIn: parent
              width: 15; height: 15
              source: Qt.resolvedUrl("../assets/trash.svg")
              layer.enabled: true
              layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: deleteMouse.containsMouse ? Theme.error : Theme.foregroundMuted
              }
            }
            MouseArea {
              id: deleteMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.act("delete", card.modelData, false)
            }
          }
        }

        MouseArea {
          id: cardMouse
          z: 0
          anchors.fill: parent
          anchors.rightMargin: 84
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.selectedIndex = card.index
          onClicked: root.act("copy", card.modelData, true)
        }

        Process {
          id: imageDecodeProcess
          onExited: function(exitCode) {
            if (exitCode === 0)
              card.decodedImage = "file://" + root.imageCachePath(card.modelData)
          }
        }

        Component.onCompleted: {
          if (card.modelData.isImage)
            imageDecodeProcess.exec(["sh", "-c",
              "cliphist decode \"$1\" > \"$2\"", "clipboard-image",
              card.modelData.id, root.imageCachePath(card.modelData)])
        }
      }
    }

    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

    Text {
      Layout.fillWidth: true
      text: "↑ ↓  Navigate    Enter  Copy    P  Pin    Delete  Remove    Esc  Close"
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
