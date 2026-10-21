import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../" as Global
import "../widgets" as DesktopWidgets
import "../shared" as Shared

Item {
  id: editor
  z: 100
  required property var itemGeometry
  property bool atBottom: false
  readonly property real railY: atBottom ? height - 30 : 0
  readonly property real shelfY: atBottom ? 4 : 36
  property string draggedId: ""
  property real pointerX: 0
  property real pointerY: 0
  property string dropZone: ""
  property string beforeId: ""
  property real insertionX: 0
  function updateDrop(x, y) {
    pointerX = x
    pointerY = y
    dropZone = ""
    beforeId = ""
    if (x < 0 || x > width || y < railY || y > railY + 30) return
    dropZone = x < width / 3 ? "left" : x < width * 2 / 3 ? "center" : "right"
    const group = BarStyle.items.filter(function(item) {
      return item.zone === editor.dropZone && item.id !== editor.draggedId
    })
    insertionX = dropZone === "left" ? 4 : dropZone === "center" ? width / 2 : width - 4
    for (const item of group) {
      const geometry = itemGeometry(item.id)
      if (x < geometry.x + geometry.width / 2) {
        beforeId = item.id
        insertionX = geometry.x - 3
        return
      }
      insertionX = geometry.x + geometry.width + 3
    }
  }

  function finishDrag() {
    // Changing the model can hide the source and cancel its MouseArea grab.
    // Snapshot the drop before updating any delegates.
    const id = draggedId
    const zone = dropZone
    const before = beforeId
    cancelDrag()
    if (id === "") return
    if (zone !== "") {
      BarStyle.insertItem(id, zone, before)
      if (id === "nowPlaying") DesktopWidgets.WidgetState.nowPlayingVisible = true
      if (id === "focusTimer") DesktopWidgets.WidgetState.focusTimerBarVisible = true
    }
  }

  function cancelDrag() { draggedId = ""; dropZone = ""; beforeId = "" }
  onVisibleChanged: if (!visible) cancelDrag()

  Rectangle {
    anchors.fill: parent
    color: Global.Theme.surface
    border.color: Global.Theme.accent
    border.width: 1
  }
  Repeater {
    model: ["left", "center", "right"]
    Rectangle {
      required property string modelData
      required property int index
      x: index * editor.width / 3
      y: editor.railY
      width: editor.width / 3
      height: 30
      color: editor.dropZone === modelData ? Global.Theme.surfaceHover : "transparent"
      border.width: 1
      border.color: editor.dropZone === modelData ? Global.Theme.accent : Global.Theme.border
      Text {
        anchors.centerIn: parent
        text: parent.modelData.toUpperCase()
        color: Global.Theme.foregroundMuted
        font.pixelSize: Global.Theme.fontCaption
      }
    }
  }

  component EditCard: Rectangle {
    id: card
    required property string itemId
    property bool available: false
    readonly property bool compact: !available
      && (itemId === "system" || BarStyle.buttonIds.indexOf(itemId) !== -1)
    readonly property string iconName: ({system: "chevron-left", display: "display",
      volume: "volume-med", internet: "wifi-high", bluetooth: "bluetooth-on",
      battery: "battery-full", notifications: "bell"})[itemId] || "widget"
    Accessible.role: Accessible.Button
    Accessible.name: BarStyle.itemLabel(itemId)
    height: 28
    radius: Global.Theme.radiusSm
    color: mouse.pressed ? Global.Theme.surfaceHover : Global.Theme.surface
    border.color: Global.Theme.accent
    border.width: 1
    opacity: editor.draggedId === itemId ? 0.4 : 1
    IconImage {
      visible: card.compact
      x: 7
      anchors.verticalCenter: parent.verticalCenter
      width: 16
      height: 16
      source: Qt.resolvedUrl("../assets/" + card.iconName + ".svg")
      layer.enabled: true
      layer.effect: MultiEffect {
        brightness: 1
        colorization: 1
        colorizationColor: Global.Theme.foreground
      }
    }
    HoverHandler { id: cardHover }
    Shared.Tooltip {
      target: card
      text: BarStyle.itemLabel(card.itemId)
      shown: card.compact && cardHover.hovered && editor.draggedId === ""
      edge: BarStyle.position
    }
    Text {
      visible: !card.compact
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: removeButton.left
      anchors.rightMargin: 4
      text: "⠿ " + BarStyle.itemLabel(card.itemId)
      elide: Text.ElideRight
      color: Global.Theme.foreground
      font.pixelSize: Global.Theme.fontCaption
    }
    MouseArea {
      id: mouse
      anchors.fill: parent
      anchors.rightMargin: card.available ? 0 : 28
      cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
      property real pressX: 0
      property real pressY: 0
      onPressed: function(event) { pressX = event.x; pressY = event.y }
      onPositionChanged: function(event) {
        if (!pressed) return
        if (editor.draggedId === "" && Math.abs(event.x - pressX) + Math.abs(event.y - pressY) < 6) return
        editor.draggedId = card.itemId
        const point = mapToItem(editor, event.x, event.y)
        editor.updateDrop(point.x, point.y)
      }
      onReleased: if (editor.draggedId === card.itemId) editor.finishDrag()
      onCanceled: editor.cancelDrag()
    }
    Shared.Button {
      id: removeButton
      visible: !card.available
      anchors.right: parent.right
      anchors.rightMargin: 4
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20
      accessibleName: "Remove " + BarStyle.itemLabel(card.itemId)
      onClicked: BarStyle.setZone(card.itemId, "")
      Text { anchors.centerIn: parent; text: "×"; color: Global.Theme.foreground }
    }
  }

  Repeater {
    // Keep delegates stable during a gesture; geometry updates only on release.
    model: BarStyle.itemIds
    EditCard {
      required property string modelData
      itemId: modelData
      visible: BarStyle.zoneFor(itemId) !== ""
      x: editor.itemGeometry(itemId).x
      y: editor.railY + 1
      width: editor.itemGeometry(itemId).width
    }
  }
  Repeater {
    model: BarStyle.itemIds
    Shared.Button {
      id: joinButton
      required property string modelData
      visible: BarStyle.zoneFor(modelData) !== "" && BarStyle.previousItem(modelData) !== ""
      x: editor.itemGeometry(modelData).x - 20
      y: editor.railY + 6
      width: 18
      height: 18
      accessibleName: (BarStyle.isJoined(modelData) ? "Separate " : "Join ")
        + BarStyle.itemLabel(modelData) + " and the previous item"
      buttonBorderColor: BarStyle.isJoined(modelData) ? Global.Theme.accent : Global.Theme.border
      onClicked: BarStyle.setJoined(modelData, !BarStyle.isJoined(modelData))
      Text {
        anchors.centerIn: parent
        text: BarStyle.isJoined(joinButton.modelData) ? "−" : "+"
        color: Global.Theme.foreground
        font.pixelSize: Global.Theme.fontCaption
      }
      HoverHandler { id: joinHover }
      Shared.Tooltip {
        target: joinButton
        text: BarStyle.isJoined(joinButton.modelData) ? "Separate pills" : "Join in one pill"
        shown: joinHover.hovered && editor.draggedId === ""
        edge: BarStyle.position
      }
    }
  }
  Text {
    x: 12
    y: editor.shelfY + 6
    text: "Available"
    color: Global.Theme.foregroundMuted
    font.pixelSize: Global.Theme.fontCaption
  }
  Flow {
    x: 100
    y: editor.shelfY
    width: Math.max(150, editor.width - 210)
    spacing: 6
    Repeater {
      model: BarStyle.itemIds
      EditCard {
        required property string modelData
        itemId: modelData
        available: true
        visible: BarStyle.zoneFor(itemId) === ""
        width: 150
      }
    }
  }
  Shared.Button {
    anchors.right: parent.right
    anchors.rightMargin: 12
    y: editor.shelfY
    width: 78
    height: 28
    accessibleName: "Finish editing bar"
    onClicked: BarStyle.editing = false
    Text { anchors.centerIn: parent; text: "Done"; color: Global.Theme.foreground; font.pixelSize: Global.Theme.fontBody }
  }
  Rectangle {
    visible: editor.draggedId !== "" && editor.dropZone !== ""
    x: Math.max(0, Math.min(editor.width - width, editor.insertionX))
    y: editor.railY
    width: 3
    height: 30
    color: Global.Theme.accent
    z: 5
  }
  Rectangle {
    visible: editor.draggedId !== ""
    x: Math.max(0, Math.min(editor.width - width, editor.pointerX - width / 2))
    y: Math.max(0, Math.min(editor.height - height, editor.pointerY - height / 2))
    width: 150
    height: 28
    radius: Global.Theme.radiusSm
    color: Global.Theme.surfaceHover
    border.width: 1
    border.color: Global.Theme.accent
    z: 10
    Text { anchors.centerIn: parent; text: BarStyle.itemLabel(editor.draggedId); color: Global.Theme.foreground; font.pixelSize: Global.Theme.fontCaption }
  }
}
