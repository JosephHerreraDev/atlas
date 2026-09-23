import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

FocusScope {
  id: root

  required property bool clipboardVisible
  property string query: ""
  property var entries: []
  property var filteredEntries: []
  property int selectedIndex: -1
  readonly property int maxVisibleRows: 5

  signal closeRequested()

  implicitWidth: 540
  implicitHeight: content.implicitHeight + 16
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
        || entry.preview.toLowerCase().indexOf(needle) !== -1
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

  function act(command, entry, closeAfter): void {
    if (!entry || actionProcess.running)
      return
    if (command === "copy")
      actionProcess.exec(["sh", "-c",
        "cliphist decode \"$1\" | wl-copy", "clipboard", entry.id])
    else if (command === "delete")
      actionProcess.exec(["sh", "-c",
        "printf '%s\\n' \"$1\" | cliphist delete", "clipboard", entry.id])
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
          const preview = lines[i].slice(separator + 1)
          if (preview.indexOf("image/") !== -1)
            continue
          parsed.push({
            id: lines[i].slice(0, separator),
            preview: preview
          })
        }
        root.entries = parsed
        root.filter()
      }
    }
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
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      margins: 8
    }
    spacing: Theme.spaceXs

    RowLayout {
      Layout.fillWidth: true

      Text {
        Layout.fillWidth: true
        text: "Clipboard history"
        color: Theme.foreground
        font.pixelSize: Theme.fontBody
        font.weight: Theme.weightStrong
      }
      Text {
        text: root.entries.length + " items"
        color: Theme.color4
        font.pixelSize: Theme.fontCaption
      }
    }

    TextField {
      id: input
      Layout.fillWidth: true
      Layout.preferredHeight: 34
      placeholderText: "Search clipboard"
      selectByMouse: true
      color: Theme.foreground
      placeholderTextColor: Theme.color4
      leftPadding: 10
      rightPadding: 10
      onTextChanged: root.query = text
      onAccepted: root.act("copy", root.selectedEntry(), true)
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Down) {
          root.moveSelection(1); event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          root.moveSelection(-1); event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
          root.act("delete", root.selectedEntry(), false); event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
          root.closeRequested(); event.accepted = true
        }
        if (event.accepted && root.selectedIndex >= 0)
          clipboardList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
      }
      background: Rectangle {
        radius: Theme.radiusMd
        color: Theme.color1
        border.width: Theme.borderWidth
        border.color: input.activeFocus ? Theme.borderFocus : Theme.color3
      }
    }

    Text {
      visible: root.filteredEntries.length === 0
      Layout.fillWidth: true
      Layout.preferredHeight: 48
      text: root.entries.length === 0 ? "Clipboard history is empty" : "No matches"
      color: Theme.color4
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }

    ListView {
      id: clipboardList
      visible: root.filteredEntries.length > 0
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(root.filteredEntries.length,
        root.maxVisibleRows) * 58
      clip: true
      model: root.filteredEntries
      currentIndex: root.selectedIndex
      spacing: Theme.spaceXxs
      boundsBehavior: Flickable.StopAtBounds
      ScrollBar.vertical: ScrollBar {
        policy: root.filteredEntries.length > root.maxVisibleRows
          ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
      }

      delegate: Rectangle {
        id: card
        required property int index
        required property var modelData
        width: clipboardList.width
        height: 54
        radius: Theme.radiusMd
        color: ListView.isCurrentItem || cardMouse.containsMouse
          ? Theme.color1 : Theme.color0
        border.width: ListView.isCurrentItem ? Theme.borderWidth : 0
        border.color: Theme.borderFocus

        RowLayout {
          anchors.fill: parent
          anchors.margins: 6
          spacing: Theme.spaceSm

          Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: card.modelData.preview
            color: ListView.isCurrentItem ? Theme.foreground : Theme.color4
            font.pixelSize: Theme.fontBody
            maximumLineCount: 2
            wrapMode: Text.Wrap
            elide: Text.ElideRight
          }

          Text {
            z: 2
            text: "×"
            color: Theme.color11
            font.pixelSize: 20
            MouseArea {
              anchors.fill: parent
              anchors.margins: -8
              cursorShape: Qt.PointingHandCursor
              onClicked: root.act("delete", card.modelData, false)
            }
          }
        }

        MouseArea {
          id: cardMouse
          z: 0
          anchors.fill: parent
          anchors.rightMargin: 42
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.selectedIndex = card.index
          onClicked: root.act("copy", card.modelData, true)
        }
      }
    }

    Text {
      Layout.fillWidth: true
      text: "↑/↓ navigate   Enter copy   Delete remove   Esc close"
      color: Theme.color4
      font.pixelSize: Theme.fontCaption
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
