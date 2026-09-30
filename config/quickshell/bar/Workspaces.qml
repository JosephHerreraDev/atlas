import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQml
import "../"
import "../shared/"

Pill {
  id: root

  borderEnabled: false

  property var shellScreen
  property var hyprMonitor: shellScreen ? Hyprland.monitorFor(shellScreen) : null

  implicitWidth: row.implicitWidth + root.margin * 2
  implicitHeight: row.implicitHeight + root.margin * 2

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: 1

    Button {
      id: menuButton

      Layout.preferredWidth: 24
      Layout.preferredHeight: 20

      IconImage {
        anchors.centerIn: parent

        implicitWidth: 14
        implicitHeight: 14
        source: Qt.resolvedUrl("../assets/nix-snowflake.svg")
      }
    }

    Repeater {
      model: Hyprland.workspaces

      Button {
        id: workspaceButton

        required property var modelData
        property var workspace: modelData

        visible: workspace.id > 0
        && root.hyprMonitor !== null
        && workspace.monitor !== null
        && workspace.monitor.name === root.hyprMonitor.name

        Layout.preferredWidth: content.implicitWidth + 12
        Layout.preferredHeight: 20

        buttonColor: workspace.focused
        ? Theme.border
        : workspace.active
        ? Theme.surfaceHover
        : Theme.surface

        buttonBorderColor: workspace.focused
        ? Theme.accent
        : workspace.active
        ? Theme.accent
        : Theme.surface

        onClicked: workspaceButton.workspace.activate()

        RowLayout {
          id: content

          anchors.centerIn: parent
          spacing: 5

          Text {
            text: WorkspaceDisplay.label(workspaceButton.workspace)

            font.pixelSize: Theme.fontBody
            font.weight: workspaceButton.workspace.focused
            ? Font.DemiBold
            : Font.Medium

            color: workspaceButton.workspace.focused
            ? Theme.foreground
            : Theme.foreground
          }
        }
      }
    }
  }
}
