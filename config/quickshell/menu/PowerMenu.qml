import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import "../"

Scope {
  id: root

  property bool opened: false
  property bool requestedOpen: false
  property bool mounted: false
  property int selectedIndex: 0
  property int focusRequest: 0
  property int transitionGeneration: 0
  property int pendingConfirmationIndex: -1
  property string runningActionName: ""

  readonly property int animationDuration: Theme.motionNormal - 20
  readonly property int actionSize: 76
  readonly property int actionSpacing: Theme.radiusMd
  readonly property var actions: [
    { name: "Lock", description: "Lock the current session", icon: "lock.svg", command: ["hyprlock"], confirm: false },
    { name: "Log out", description: "End the current session", icon: "logout.svg", command: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"], confirm: true },
    { name: "Suspend", description: "Suspend this computer", icon: "suspend.svg", command: ["systemctl", "suspend"], confirm: false },
    { name: "Restart", description: "Restart this computer", icon: "restart.svg", command: ["systemctl", "reboot"], confirm: true },
    { name: "Shut down", description: "Power off this computer", icon: "power.svg", command: ["systemctl", "poweroff"], confirm: true }
  ]

  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function open(): void {
    MenuState.activate(root)
    hideTimer.stop()
    confirmationTimer.stop()
    requestedOpen = true
    mounted = true
    opened = false
    selectedIndex = 0
    pendingConfirmationIndex = -1
    const generation = ++transitionGeneration
    Qt.callLater(function() {
      if (root.requestedOpen && root.mounted
          && root.transitionGeneration === generation) {
        opened = true
        focusRequest += 1
      }
    })
  }

  function close(): void {
    MenuState.deactivate(root)
    requestedOpen = false
    transitionGeneration += 1
    opened = false
    pendingConfirmationIndex = -1
    confirmationTimer.stop()
    hideTimer.restart()
  }

  function toggle(): void { requestedOpen ? close() : open() }

  function selectIndex(index: int): void {
    if (index < 0 || index >= actions.length)
      return
    if (selectedIndex !== index) {
      pendingConfirmationIndex = -1
      confirmationTimer.stop()
    }
    selectedIndex = index
  }

  function moveHorizontal(delta: int): void {
    const count = actions.length
    if (count === 0)
      return
    selectIndex((selectedIndex + delta + count) % count)
  }

  function moveVertical(delta: int, columns: int): void {
    if (actions.length === 0 || columns < 1)
      return
    const rows = Math.ceil(actions.length / columns)
    const column = selectedIndex % columns
    const row = Math.floor(selectedIndex / columns)
    const nextRow = (row + delta + rows) % rows
    selectIndex(Math.min(nextRow * columns + column, actions.length - 1))
  }

  function runAction(action, index: int): void {
    if (!action || actionProcess.running)
      return
    if (action.confirm && pendingConfirmationIndex !== index) {
      pendingConfirmationIndex = index
      confirmationTimer.restart()
      return
    }
    pendingConfirmationIndex = -1
    confirmationTimer.stop()
    runningActionName = action.name
    close()
    actionProcess.exec(action.command)
  }

  IpcHandler {
    target: "powermenu"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Timer {
    id: hideTimer
    interval: root.animationDuration
    onTriggered: if (!root.requestedOpen) root.mounted = false
  }

  Timer {
    id: confirmationTimer
    interval: 4000
    onTriggered: root.pendingConfirmationIndex = -1
  }

  Process {
    id: actionProcess

    onExited: function(exitCode) {
      const actionName = root.runningActionName
      root.runningActionName = ""
      if (exitCode !== 0) {
        Quickshell.execDetached([
          "notify-send",
          "Power action failed",
          actionName + " exited with code " + exitCode
        ])
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData

      screen: modelData
      visible: root.mounted && root.screenFocused(modelData)
      color: "#00000000"
      aboveWindows: true
      focusable: true
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None
      WlrLayershell.namespace: "powermenu"
      anchors { top: true; bottom: true; left: true; right: true }

      function focusMenu(): void {
        Qt.callLater(function() {
          if (root.requestedOpen && window.visible)
            keyboardHandler.forceActiveFocus()
        })
      }

      onVisibleChanged: if (visible) focusMenu()

      Connections {
        target: root
        function onFocusRequestChanged(): void {
          if (window.visible) window.focusMenu()
        }
      }

      Rectangle {
        anchors.fill: parent
        color: "#66000000"
        opacity: root.opened ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        MouseArea { anchors.fill: parent; enabled: root.opened; onClicked: root.close() }
      }

      Rectangle {
        id: panel
        readonly property int availableContentWidth: Math.max(
          root.actionSize, window.width - 60)
        readonly property int gridColumns: Math.max(1, Math.min(
          root.actions.length,
          Math.floor((availableContentWidth + root.actionSpacing)
            / (root.actionSize + root.actionSpacing))))
        readonly property int gridWidth: gridColumns * root.actionSize
          + (gridColumns - 1) * root.actionSpacing

        width: Math.min(gridWidth + 28, window.width - 32)
        implicitHeight: content.implicitHeight + 28
        height: implicitHeight
        anchors.centerIn: parent
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.96
        radius: Theme.radiusLg
        color: Qt.rgba(
          Theme.color0.r,
          Theme.color0.g,
          Theme.color0.b,
          Theme.popupOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.border
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        Behavior on scale { NumberAnimation { duration: root.animationDuration } }
        MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

        ColumnLayout {
          id: content
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
          }
          spacing: Theme.spaceSm

          Item {
            id: keyboardHandler
            Layout.fillWidth: true
            Layout.preferredHeight: actionGrid.implicitHeight
            focus: true

            Accessible.role: Accessible.Pane
            Accessible.name: "Power menu"
            Accessible.description: root.actions[root.selectedIndex].description

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Right) {
                root.moveHorizontal(1)
                event.accepted = true
              } else if (event.key === Qt.Key_Left) {
                root.moveHorizontal(-1)
                event.accepted = true
              } else if (event.key === Qt.Key_Down) {
                root.moveVertical(1, panel.gridColumns)
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                root.moveVertical(-1, panel.gridColumns)
                event.accepted = true
              } else if (event.key === Qt.Key_Home) {
                root.selectIndex(0)
                event.accepted = true
              } else if (event.key === Qt.Key_End) {
                root.selectIndex(root.actions.length - 1)
                event.accepted = true
              } else if (event.key === Qt.Key_Return
                         || event.key === Qt.Key_Enter
                         || event.key === Qt.Key_Space) {
                root.runAction(root.actions[root.selectedIndex],
                  root.selectedIndex)
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              }
            }

            Grid {
              id: actionGrid
              anchors.horizontalCenter: parent.horizontalCenter
              columns: panel.gridColumns
              columnSpacing: root.actionSpacing
              rowSpacing: root.actionSpacing

              Repeater {
                model: root.actions

                Rectangle {
                  id: actionRow
                  required property int index
                  required property var modelData
                  readonly property bool selected: index === root.selectedIndex
                  width: root.actionSize
                  height: root.actionSize
                  radius: Theme.radiusMd
                  color: selected || actionMouse.containsMouse
                    ? Theme.color3 : Theme.color1
                  border.width: selected || actionMouse.containsMouse
                    ? Theme.borderWidth : 0
                  border.color: root.pendingConfirmationIndex === index
                    ? Theme.color11
                    : (selected ? Theme.selectionForeground : Theme.color3)

                  Accessible.role: Accessible.Button
                  Accessible.name: modelData.name
                  Accessible.description: modelData.description
                  Accessible.focusable: true
                  Accessible.selected: selected
                  Accessible.onPressAction: {
                    root.selectIndex(actionRow.index)
                    root.runAction(actionRow.modelData, actionRow.index)
                  }

                  Column {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 3

                    IconImage {
                      anchors.horizontalCenter: parent.horizontalCenter
                      width: 28
                      height: 28
                      source: Qt.resolvedUrl(
                        "../assets/" + actionRow.modelData.icon)
                      layer.enabled: true
                      layer.effect: MultiEffect {
                        brightness: 1
                        colorization: 1
                        colorizationColor: actionRow.selected
                          || actionMouse.containsMouse
                          ? Theme.selectionForeground : Theme.foreground
                      }
                    }

                    Text {
                      width: parent.width
                      text: root.pendingConfirmationIndex === actionRow.index
                        ? "Confirm?" : actionRow.modelData.name
                      color: root.pendingConfirmationIndex === actionRow.index
                        ? Theme.color11
                        : (actionRow.selected || actionMouse.containsMouse
                          ? Theme.selectionForeground : Theme.foreground)
                      font.pixelSize: Theme.fontBody
                      font.weight: root.pendingConfirmationIndex
                        === actionRow.index
                        ? Theme.weightStrong : Theme.weightRegular
                      horizontalAlignment: Text.AlignHCenter
                      elide: Text.ElideRight
                    }
                  }

                  ToolTip.visible: actionMouse.containsMouse
                  ToolTip.text: actionRow.modelData.description

                  MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.selectIndex(actionRow.index)
                      root.runAction(actionRow.modelData, actionRow.index)
                    }
                  }
                }
              }
            }
          }
        }
      }

      Shortcut { sequence: "Escape"; enabled: root.opened; onActivated: root.close() }
    }
  }
}
