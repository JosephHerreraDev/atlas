import Quickshell
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Pill {
  id: root

  property var controller: null
  required property var notifications
  readonly property bool trayRevealed: systemTray.revealed

  function toggleTray(): void {
    if (!systemTray.revealed)
      if (controller) controller.closePanel()
    systemTray.toggle()
  }

  function collapseTray(): void {
    systemTray.collapse()
  }

  RowLayout {
    spacing: 0
    SystemTray {
      id: systemTray

      onRevealedChanged: {
        if (revealed)
          if (controller) controller.closePanel()
      }
    }
    Connections {
      target: root.controller
      function onPanelVisibleChanged(): void {
        if (root.controller.panelVisible) systemTray.collapse()
      }
    }
  }
}
