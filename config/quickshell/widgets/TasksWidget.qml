import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../"
import "../shared/"
import "../bar/" as Bar

Scope {
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

  property int widgetX: 440
  property int widgetY: 80
  property int widgetWidth: 360
  property int widgetHeight: 420
  property bool locked: false
  property bool alwaysOnTop: false
  property bool loaded: false

  function save(): void {
    if (!loaded) return
    geometryFile.setText(JSON.stringify({ x: widgetX, y: widgetY,
      width: widgetWidth, height: widgetHeight, locked: locked,
      alwaysOnTop: alwaysOnTop }, null, 2) + "\n")
  }

  onWidgetXChanged: saveTimer.restart()
  onWidgetYChanged: saveTimer.restart()
  onWidgetWidthChanged: saveTimer.restart()
  onWidgetHeightChanged: saveTimer.restart()
  onLockedChanged: saveTimer.restart()
  onAlwaysOnTopChanged: saveTimer.restart()
  Component.onDestruction: save()
  Timer { id: saveTimer; interval: 300; onTriggered: root.save() }
  FileView {
    id: geometryFile
    path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config")
      + "/atlas/reminders-widget.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (typeof data.x === "number" && Number.isFinite(data.x)) root.widgetX = Math.max(0, data.x)
        if (typeof data.y === "number" && Number.isFinite(data.y)) root.widgetY = Math.max(0, data.y)
        if (typeof data.width === "number" && Number.isFinite(data.width)) root.widgetWidth = Math.max(320, data.width)
        if (typeof data.height === "number" && Number.isFinite(data.height)) root.widgetHeight = Math.max(280, data.height)
        root.locked = data.locked === true
        root.alwaysOnTop = data.alwaysOnTop === true
      } catch (error) {}
      root.loaded = true
    }
    onLoadFailed: root.loaded = true
  }

  IpcHandler {
    target: "tasks"
    function open(): void { Bar.ReminderState.taskFilter = "open"; WidgetState.tasksVisible = true }
    function close(): void { root.save(); WidgetState.tasksVisible = false }
    function toggle(): void { WidgetState.tasksVisible = !WidgetState.tasksVisible }
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
      visible: WidgetState.tasksVisible && focusedScreen
      color: "transparent"
      focusable: WidgetState.tasksVisible
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: root.alwaysOnTop || WidgetState.tasksRaised ? WlrLayer.Overlay : WlrLayer.Bottom
      WlrLayershell.keyboardFocus: visible
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
      WlrLayershell.namespace: "atlas-tasks"
      anchors { top: true; bottom: true; left: true; right: true }
      // Popup menus live in Qt's window overlay, outside the widget region.
      // Accept input across the window while a menu is open, including outside
      // clicks that dismiss it; restore click-through immediately on close.
      mask: (widgetMenu.visible) ? null : widgetInputRegion
      property Region widgetInputRegion: Region {
        Region {
          intersection: Intersection.Combine
          x: Math.floor(card.x)
          y: Math.floor(card.y)
          width: Math.ceil(card.width)
          height: Math.ceil(card.height)
        }
      }
      onVisibleChanged: { if (!visible) root.save() }

      Rectangle {
        id: card
        focus: true
        property bool dragging: false
        property bool resizing: false
        property real dragX: root.widgetX
        property real dragY: root.widgetY
        property real resizeStartWidth: root.widgetWidth
        property real resizeStartHeight: root.widgetHeight
        function clampX(value) { return Math.max(0, Math.min(value, window.width - width)) }
        function clampY(value) { return Math.max(0, Math.min(value, window.height - height)) }
        function snap(value) { return Math.round(value / 16) * 16 }
        x: dragging ? dragX : clampX(root.widgetX)
        y: dragging ? dragY : clampY(root.widgetY)
        width: Math.min(root.widgetWidth, window.width)
        height: Math.min(root.widgetHeight, window.height)
        scale: dragging ? 1.025 : 1
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutExpo } }
        color: colors.backgroundColor
        radius: Theme.radiusLg
        border.width: colors.borderColorWidth
        border.color: colors.borderColor

        MouseArea {
          id: moveGrip
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          hoverEnabled: true
          cursorShape: root.locked ? Qt.ArrowCursor
            : (card.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor)

          property bool leftDown: false
          property real grabOffsetX: 0
          property real grabOffsetY: 0

          onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
              widgetMenu.popup(mouse.x, mouse.y)
              return
            }
            if (root.locked)
              return
            leftDown = true
            const point = card.mapToItem(window.contentItem, mouse.x, mouse.y)
            grabOffsetX = point.x - card.x
            grabOffsetY = point.y - card.y
          }
          onPositionChanged: function(mouse) {
            if (!leftDown || root.locked)
              return
            const point = card.mapToItem(window.contentItem, mouse.x, mouse.y)
            const nextX = point.x - grabOffsetX
            const nextY = point.y - grabOffsetY
            if (!card.dragging
                && Math.abs(nextX - card.x) < 6
                && Math.abs(nextY - card.y) < 6)
              return
            card.dragging = true
            card.dragX = card.clampX(card.snap(nextX))
            card.dragY = card.clampY(card.snap(nextY))
          }
          onReleased: {
            if (card.dragging) {
              root.widgetX = Math.round(card.dragX)
              root.widgetY = Math.round(card.dragY)
              card.dragging = false
            }
            leftDown = false
          }
          onCanceled: { leftDown = false; card.dragging = false }
        }


        RowLayout {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 12
          height: 36
          Text {
            Layout.fillWidth: true
            text: editor.editorOpen ? (editor.editingId ? "EDIT TASK" : "NEW TASK") : "TASKS"
            color: colors.textColor
            font.pixelSize: Theme.fontBody + 1
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
          }
          ColorButton {
            visible: !editor.editorOpen
            accessibleName: "New task"
            onClicked: editor.startNew()
            Text {
              anchors.centerIn: parent
              text: "+ NEW"
              color: colors.accentColor
              font.pixelSize: Theme.fontBody + 1
            }
          }
          ColorButton {
            accessibleName: "Tasks widget options"
            onClicked: widgetMenu.popup()
            Text { anchors.centerIn: parent; text: "⋯"; color: colors.textColor }
          }
        }

        Flickable {
          id: taskScroller
          anchors.fill: parent
          anchors.margins: Theme.spaceSm
          anchors.topMargin: 56
          anchors.bottomMargin: 24
          contentHeight: content.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          Controls.ScrollBar.vertical: Controls.ScrollBar {
            policy: Controls.ScrollBar.AsNeeded
            active: taskScroller.contentHeight > taskScroller.height
          }

          ColumnLayout {
            id: content
            width: parent.width
            spacing: Theme.spaceSm

            TaskEditor {
              id: editor
              Layout.fillWidth: true
              selectedDate: Bar.ReminderState.selectedDate
              onEditorOpenChanged: taskScroller.contentY = 0
            }
          }
        }

        HoverHandler { id: cardHover }

        Item {
          id: resizeHandle
          width: 24
          height: 24
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          opacity: ((cardHover.hovered && !root.locked
            && !card.dragging) || card.resizing) ? 1 : 0
          visible: opacity > 0

          Behavior on opacity { NumberAnimation { duration: 120 } }

          Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 14
            height: 2
            radius: 1
            color: resizeGrip.containsMouse || card.resizing
              ? colors.accentColor : colors.mutedColor
          }
          Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 2
            height: 14
            radius: 1
            color: resizeGrip.containsMouse || card.resizing
              ? colors.accentColor : colors.mutedColor
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
              card.resizeStartWidth = root.widgetWidth
              card.resizeStartHeight = root.widgetHeight
              card.resizing = true
            }
            onPositionChanged: function(mouse) {
              if (!card.resizing)
                return
              const point = resizeGrip.mapToItem(window.contentItem,
                mouse.x, mouse.y)
              root.widgetWidth = Math.max(320,
                card.resizeStartWidth + point.x - originX)
              root.widgetHeight = Math.max(280,
                card.resizeStartHeight + point.y - originY)
            }
            onReleased: card.resizing = false
            onCanceled: card.resizing = false
          }
        }

        Rectangle {
          visible: card.resizing
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

        MouseArea {
          anchors.fill: parent
          z: 20
          acceptedButtons: Qt.RightButton
          onPressed: function(mouse) {
            const point = mapToItem(card, mouse.x, mouse.y)
            widgetMenu.popup(point.x, point.y)
            mouse.accepted = true
          }
        }

        WidgetMenu {
          id: widgetMenu
          surfaceColor: colors.surfaceColor
          hoverColor: colors.hoverColor
          textColor: colors.textColor
          mutedTextColor: colors.mutedColor
          accentColor: colors.accentColor
          borderColor: colors.borderColor
          separatorColor: colors.borderColor
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "New task"
            onTriggered: editor.startNew()
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Show open tasks"
            checkable: true
            checked: Bar.ReminderState.taskFilter === "open"
            onTriggered: Bar.ReminderState.taskFilter = "open"
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Show completed tasks"
            checkable: true
            checked: Bar.ReminderState.taskFilter === "done"
            onTriggered: Bar.ReminderState.taskFilter = "done"
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Show all tasks"
            checkable: true
            checked: Bar.ReminderState.taskFilter === "all"
            onTriggered: Bar.ReminderState.taskFilter = "all"
          }
          WidgetMenuSeparator { menuColors: widgetMenu }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Lock position and size"
            checkable: true
            checked: root.locked
            onTriggered: root.locked = checked
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Keep above windows"
            checkable: true
            checked: root.alwaysOnTop
            onTriggered: root.alwaysOnTop = checked
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Reset position"
            enabled: !root.locked
            onTriggered: { root.widgetX = 52; root.widgetY = 52 }
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Reset size"
            enabled: !root.locked
            onTriggered: { root.widgetWidth = 360; root.widgetHeight = 420 }
          }
          WidgetMenuSeparator { menuColors: widgetMenu }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Hide widget"
            onTriggered: { root.save(); WidgetState.tasksVisible = false }
          }
        }

        Connections {
          target: Bar.ReminderState
          function onDayOpened(): void { editor.startNew(true) }
        }
        Keys.onEscapePressed: function(event) {
          card.focus = false
          event.accepted = true
        }
      }
    }
  }


}
