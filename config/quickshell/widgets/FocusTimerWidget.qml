import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../"
import "../shared/"

Scope {
  id: root

  WidgetPalette { id: colors; choice: WidgetState.focusTimerColor }
  component ColorButton: Button {
    buttonColor: hovered ? colors.hoverColor : colors.surfaceColor
    buttonBorderColor: colors.borderColor
  }

  property int widgetX: 824
  property int widgetY: 80
  property int widgetWidth: 360
  property int widgetHeight: 400
  property bool locked: false
  property bool alwaysOnTop: false
  property bool loaded: false
  property bool durationsVisible: false
  readonly property bool timerReady: FocusTimerState.loaded

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
      + "/atlas/focus-timer-widget.json"
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
    target: "focus-timer"
    function open(): void { WidgetState.focusTimerVisible = true }
    function startPause(): void { FocusTimerState.startPause() }
    function reset(): void { FocusTimerState.reset() }
    function quit(): void { root.save(); FocusTimerState.quit() }
    function close(): void { root.save(); WidgetState.focusTimerVisible = false }
    function toggle(): void { WidgetState.focusTimerVisible = !WidgetState.focusTimerVisible }
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
      visible: WidgetState.focusTimerVisible && focusedScreen
      color: "transparent"
      focusable: WidgetState.focusTimerVisible
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: root.alwaysOnTop || WidgetState.focusTimerRaised ? WlrLayer.Overlay : WlrLayer.Bottom
      WlrLayershell.keyboardFocus: visible
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
      WlrLayershell.namespace: "atlas-focus-timer"
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
          height: 26
          Text {
            Layout.fillWidth: true
            text: "FOCUS TIMER"
            color: colors.textColor
            font.pixelSize: Theme.fontCaption
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
          }
          ColorButton {
            accessibleName: "Focus timer options"
            onClicked: widgetMenu.popup()
            Text { anchors.centerIn: parent; text: "⋯"; color: colors.textColor }
          }
        }

        Flickable {
          anchors.fill: parent
          anchors.margins: Theme.spaceSm
          anchors.topMargin: 46
          anchors.bottomMargin: 24
          contentHeight: content.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          Controls.ScrollBar.vertical: Controls.ScrollBar {
            policy: Controls.ScrollBar.AsNeeded
          }

          ColumnLayout {
            id: content
            width: parent.width
            spacing: Theme.spaceSm

            ColumnLayout {
              Layout.fillWidth: true
              visible: !root.durationsVisible
              spacing: Theme.spaceSm

              RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceXs
                Repeater {
                  model: ["focus", "short", "long"]
                  ColorButton {
                    id: sessionButton
                    required property string modelData
                    readonly property bool selected: FocusTimerState.phase === modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    enabled: FocusTimerState.loaded
                    buttonColor: selected
                      ? (hovered ? Qt.lighter(colors.accentColor, 1.08) : colors.accentColor)
                      : (hovered ? colors.hoverColor : colors.surfaceColor)
                    buttonBorderColor: selected || activeFocus ? colors.accentColor : colors.borderColor
                    buttonBorderWidth: activeFocus ? 2 : colors.borderColorWidth
                    accessibleName: "Select " + modelData + " session and reset timer"
                    onClicked: FocusTimerState.selectPhase(modelData)
                    Text {
                      anchors.centerIn: parent
                      text: modelData === "focus" ? "Focus" : modelData === "short" ? "Short break" : "Long break"
                      color: sessionButton.selected ? colors.surfaceColor : colors.textColor
                      font.pixelSize: Theme.fontCaption
                      font.weight: sessionButton.selected ? Theme.weightStrong : Font.Normal
                    }
                  }
                }
              }

              Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.spaceSm
                text: FocusTimerState.phaseLabel.toUpperCase()
                color: colors.accentColor
                font.pixelSize: Theme.fontCaption
                font.weight: Theme.weightStrong
                font.letterSpacing: 1.5
              }
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: String(Math.floor(FocusTimerState.secondsRemaining / 60)).padStart(2, "0")
                  + ":" + String(FocusTimerState.secondsRemaining % 60).padStart(2, "0")
                color: colors.textColor
                font.pixelSize: Math.min(72, card.width / 5)
                font.weight: Theme.weightStrong
                font.family: "monospace"
                Accessible.name: FocusTimerState.phaseLabel + " time remaining " + text
              }
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                radius: 3
                color: colors.hoverColor
                Rectangle {
                  width: parent.width * FocusTimerState.progress
                  height: parent.height
                  radius: parent.radius
                  color: colors.accentColor
                }
              }
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: FocusTimerState.running ? "In progress"
                  : FocusTimerState.pausedSeconds < FocusTimerState.durationSeconds ? "Paused" : "Ready when you are"
                color: colors.mutedColor
                font.pixelSize: Theme.fontCaption
              }
              RowLayout {
                Layout.fillWidth: true
                ColorButton {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 40
                  enabled: FocusTimerState.loaded
                  buttonColor: colors.accentColor
                  accessibleName: FocusTimerState.running ? "Pause timer" : "Start or resume timer"
                  onClicked: FocusTimerState.startPause()
                  Text {
                    anchors.centerIn: parent
                    text: FocusTimerState.running ? "Pause"
                      : FocusTimerState.pausedSeconds < FocusTimerState.durationSeconds ? "Resume" : "Start"
                    color: colors.surfaceColor
                    font.pixelSize: Theme.fontBody
                    font.weight: Theme.weightStrong
                  }
                }
                ColorButton {
                  Layout.preferredHeight: 40
                  visible: FocusTimerState.running
                    || FocusTimerState.pausedSeconds < FocusTimerState.durationSeconds
                  accessibleName: "Reset current session"
                  onClicked: FocusTimerState.reset()
                  Text { anchors.centerIn: parent; text: "Reset"; color: colors.textColor; font.pixelSize: Theme.fontBody }
                }

              }
              RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Repeater {
                  model: 4
                  Rectangle {
                    required property int index
                    width: 8
                    height: 8
                    radius: 4
                    color: index < FocusTimerState.completedSessions % 4 ? colors.accentColor : colors.hoverColor
                    border.width: colors.borderColorWidth
                    border.color: colors.borderColor
                  }
                }
                Text {
                  text: FocusTimerState.completedSessions + " completed"
                  color: colors.mutedColor
                  font.pixelSize: Theme.fontCaption
                }
              }
              Text {
                Layout.fillWidth: true
                text: "Long break after every 4 focus sessions.\nHiding the widget keeps the timer running."
                horizontalAlignment: Text.AlignHCenter
                color: colors.mutedColor
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.WordWrap
              }
            }
            Rectangle {
              Layout.fillWidth: true
              visible: root.durationsVisible
              implicitHeight: durationSettings.implicitHeight + 24
              radius: Theme.radiusMd
              color: colors.hoverColor
              border.width: colors.borderColorWidth
              border.color: colors.borderColor

              ColumnLayout {
                id: durationSettings
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: Theme.spaceSm
                RowLayout {
                  Layout.fillWidth: true
                  Text {
                    Layout.fillWidth: true
                    text: "Session durations"
                    color: colors.textColor
                    font.pixelSize: Theme.fontBody
                    font.weight: Theme.weightStrong
                  }
                  ColorButton {
                    enabled: FocusTimerState.loaded && !FocusTimerState.running
                    opacity: enabled ? 1 : 0.4
                    accessibleName: "Restore default durations: 25, 5, and 15 minutes"
                    onClicked: FocusTimerState.restoreDurations()
                    Text { anchors.centerIn: parent; text: "Defaults"; color: colors.accentColor; font.pixelSize: Theme.fontCaption }
                  }
                }
                Repeater {
                  model: ["focus", "short", "long"]
                  RowLayout {
                    id: durationRow
                    required property string modelData
                    Layout.fillWidth: true
                    spacing: 8
                    readonly property string title: modelData === "focus" ? "Focus"
                      : modelData === "short" ? "Short break" : "Long break"
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 2
                      Text {
                        text: durationRow.title
                        color: colors.textColor
                        font.pixelSize: Theme.fontBody
                      }
                      Text {
                        Layout.fillWidth: true
                        text: durationRow.modelData === "focus" ? "Time to concentrate"
                          : durationRow.modelData === "short" ? "Between sessions" : "After four sessions"
                        color: colors.mutedColor
                        font.pixelSize: Theme.fontCaption
                        wrapMode: Text.WordWrap
                      }
                    }
                    Controls.SpinBox {
                      id: durationControl
                      Layout.preferredWidth: 122
                      Layout.preferredHeight: 40
                      from: 1
                      to: 180
                      editable: true
                      enabled: FocusTimerState.loaded && !FocusTimerState.running
                      opacity: enabled ? 1 : 0.4
                      leftPadding: 30
                      rightPadding: 30
                      value: durationRow.modelData === "focus" ? FocusTimerState.focusMinutes
                        : durationRow.modelData === "short" ? FocusTimerState.shortMinutes : FocusTimerState.longMinutes
                      Accessible.name: durationRow.title + " duration in minutes, 1 to 180"
                      onValueModified: FocusTimerState.setDuration(durationRow.modelData, value)
                      background: Rectangle {
                        radius: Theme.radiusSm
                        color: colors.surfaceColor
                        border.width: colors.borderColorWidth
                        border.color: durationInput.activeFocus || durationControl.activeFocus ? colors.accentColor : colors.borderColor
                      }
                      contentItem: TextInput {
                        id: durationInput
                        text: String(durationControl.value)
                        color: colors.textColor
                        font.pixelSize: Theme.fontTitle
                        font.weight: Theme.weightStrong
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        readOnly: !durationControl.editable
                        selectByMouse: true
                        selectionColor: colors.accentColor
                        selectedTextColor: colors.surfaceColor
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1; top: 180 }
                        function commit(): void {
                          if (acceptableInput) FocusTimerState.setDuration(durationRow.modelData, Number(text))
                          text = Qt.binding(function() { return String(durationControl.value) })
                        }
                        onEditingFinished: commit()
                        onActiveFocusChanged: { if (activeFocus) selectAll() }
                        Keys.onUpPressed: durationControl.increase()
                        Keys.onDownPressed: durationControl.decrease()
                      }
                      up.indicator: Rectangle {
                        x: durationControl.width - width
                        width: 28
                        height: durationControl.height
                        radius: Theme.radiusSm
                        color: durationControl.up.pressed ? colors.selectionColor : "transparent"
                        Text { anchors.centerIn: parent; text: "+"; color: colors.accentColor; font.pixelSize: Theme.fontTitle }
                      }
                      down.indicator: Rectangle {
                        width: 28
                        height: durationControl.height
                        radius: Theme.radiusSm
                        color: durationControl.down.pressed ? colors.selectionColor : "transparent"
                        Text { anchors.centerIn: parent; text: "−"; color: colors.accentColor; font.pixelSize: Theme.fontTitle }
                      }
                    }
                    Text { text: "min"; color: colors.mutedColor; font.pixelSize: Theme.fontCaption }
                  }
                }
                Text {
                  Layout.fillWidth: true
                  text: FocusTimerState.running ? "Pause the timer to adjust durations."
                    : "1–180 minutes · Type a value or use − / +. Changing the current session resets its countdown."
                  color: FocusTimerState.running ? Theme.warning : colors.mutedColor
                  font.pixelSize: Theme.fontCaption
                  wrapMode: Text.WordWrap
                }
                ColorButton {
                  Layout.fillWidth: true
                  visible: FocusTimerState.running
                  accessibleName: "Pause timer to edit durations"
                  onClicked: FocusTimerState.startPause()
                  Text { anchors.centerIn: parent; text: "Pause to adjust"; color: colors.accentColor; font.pixelSize: Theme.fontCaption }
                }
              }
            }
            ColorButton {
              Layout.fillWidth: true
              Layout.preferredHeight: 32
              enabled: FocusTimerState.loaded
              opacity: enabled ? 1 : 0.45
              buttonColor: hovered ? colors.hoverColor : "transparent"
              buttonBorderColor: activeFocus ? colors.accentColor : "transparent"
              visible: root.durationsVisible
              accessibleName: "Back to focus timer"
              onClicked: root.durationsVisible = false
              Text {
                anchors.centerIn: parent
                text: "Back to timer"
                color: colors.accentColor
                font.pixelSize: Theme.fontCaption
              }
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
            text: FocusTimerState.running ? "Pause timer" : "Start / resume timer"
            enabled: FocusTimerState.loaded
            onTriggered: FocusTimerState.startPause()
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Reset current session"
            enabled: FocusTimerState.loaded
            onTriggered: FocusTimerState.reset()
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Skip current session"
            enabled: FocusTimerState.loaded
            onTriggered: FocusTimerState.skip()
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Adjust durations"
            checkable: true
            checked: root.durationsVisible
            onTriggered: root.durationsVisible = checked
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
            onTriggered: { root.widgetWidth = 360; root.widgetHeight = 400 }
          }
          WidgetMenuSeparator { menuColors: widgetMenu }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Hide widget"
            onTriggered: { root.save(); WidgetState.focusTimerVisible = false }
          }
          WidgetMenuItem {
            menuColors: widgetMenu
            text: "Quit Focus Timer"
            destructive: true
            enabled: FocusTimerState.loaded
            onTriggered: { root.save(); FocusTimerState.quit() }
          }
        }

        Keys.onEscapePressed: function(event) {
          card.focus = false
          event.accepted = true
        }
      }
    }
  }

}
