import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQml
import "../"
import "../shared/"

Pill {
  id: root

  borderEnabled: true

  property var shellScreen
  property bool vertical: false
  property var hyprMonitor: shellScreen ? Hyprland.monitorFor(shellScreen) : null

  function workspaceSvg(style, active, color): string {
    const red = Math.round(color.r * 255)
    const green = Math.round(color.g * 255)
    const blue = Math.round(color.b * 255)
    const fill = "rgb(" + red + "," + green + "," + blue + ")"
    let shape
    if (style === "pacman") {
      shape = active
        ? '<path d="M49 13A24 24 0 1 0 49 43L28 28Z" fill="' + fill + '"/>'
        : '<path d="M9 49V27a19 19 0 0 1 38 0v22l-6-6-6 6-7-6-7 6-6-6Z" fill="' + fill + '"/>'
          + '<circle cx="21" cy="27" r="3" fill="black"/>'
          + '<circle cx="35" cy="27" r="3" fill="black"/>'
    } else {
      shape = active
        ? '<rect x="7" y="7" width="42" height="42" rx="6" fill="' + fill + '"/>'
        : '<circle cx="28" cy="28" r="21" fill="' + fill + '"/>'
    }
    return "data:image/svg+xml;utf8," + encodeURIComponent(
      '<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 56 56">'
      + shape + "</svg>")
  }

  implicitWidth: row.implicitWidth + root.leftPadding + root.rightPadding
  implicitHeight: row.implicitHeight + root.margin * 2

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: 1

    Button {
      id: menuButton

      // Side bars rotate the rail and then rotate this control back upright.
      // Swap its layout footprint so the rotated 24px side stays inside the
      // workspace pill instead of extending across its outer border.
      Layout.preferredWidth: root.vertical ? 20 : 24
      Layout.preferredHeight: root.vertical ? 24 : 20
      Layout.leftMargin: BarStyle.pillMode ? Theme.spaceXxs : 0
      rotation: root.vertical ? -90 : 0
      accessibleName: "Open Start menu"
      onClicked: Quickshell.execDetached(["qs", "ipc", "call", "global-menu", "toggle"])

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
        readonly property bool current: workspace.focused || workspace.active
        readonly property color indicatorColor: current
          ? Theme.accent : Theme.foreground

        function applicationClass(toplevel): string {
          const details = toplevel && toplevel.lastIpcObject
            ? toplevel.lastIpcObject : ({})
          return String(details["class"]
            || details.initialClass || "").trim()
        }

        function normalizedAppId(value): string {
          return String(value || "").toLowerCase()
            .replace(/\.desktop$/, "").replace(/[^a-z0-9]/g, "")
        }

        function desktopEntry(toplevel) {
          const applicationId = normalizedAppId(applicationClass(toplevel))
          if (applicationId === "") return null
          const entries = DesktopEntries.applications.values
          for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            if (normalizedAppId(entry.id) === applicationId)
              return entry
          }
          return null
        }

        function programName(toplevel): string {
          const entry = desktopEntry(toplevel)
          const applicationId = applicationClass(toplevel)
          return entry && entry.name ? String(entry.name)
            : applicationId !== "" ? applicationId
            : String(toplevel && toplevel.title
              ? toplevel.title : "Unknown application")
        }

        function programIcon(toplevel): string {
          const entry = desktopEntry(toplevel)
          const icon = entry && entry.icon ? String(entry.icon)
            : applicationClass(toplevel)
          return icon !== "" ? Quickshell.iconPath(icon) : ""
        }

        visible: workspace.id > 0
        && root.hyprMonitor !== null
        && workspace.monitor !== null
        && workspace.monitor.name === root.hyprMonitor.name

        Layout.preferredWidth: content.implicitWidth + 8
        Layout.preferredHeight: 20
        rotation: root.vertical ? -90 : 0

        buttonColor: Theme.surface

        buttonBorderColor: Theme.surface
        accessibleName: (current ? "Active workspace " : "Workspace ")
          + workspace.name

        onClicked: workspaceButton.workspace.activate()

        RowLayout {
          id: content

          anchors.centerIn: parent
          spacing: 5

          Item {
            visible: WorkspaceDisplay.displayMode === "shapes"
              || WorkspaceDisplay.displayMode === "pacman"
            implicitWidth: 14
            implicitHeight: 14

            IconImage {
              anchors.fill: parent
              source: root.workspaceSvg(WorkspaceDisplay.displayMode,
                workspaceButton.current, workspaceButton.indicatorColor)
            }
          }

          Text {
            visible: WorkspaceDisplay.displayMode !== "shapes"
              && WorkspaceDisplay.displayMode !== "pacman"
            text: WorkspaceDisplay.label(workspaceButton.workspace)

            font.pixelSize: WorkspaceDisplay.displayMode === "symbols"
              ? Theme.fontTitle + 2 : Theme.fontBody
            font.weight: workspaceButton.workspace.focused
            ? Font.DemiBold
            : Font.Medium

            color: workspaceButton.indicatorColor
          }
        }

        PopupWindow {
          id: workspacePopup

          anchor {
            item: workspaceButton
            rect.x: BarStyle.position === "left" ? workspaceButton.width + 8
              : BarStyle.position === "right" ? -8
              : Math.round(workspaceButton.width / 2)
            rect.y: BarStyle.position === "left" || BarStyle.position === "right"
              ? Math.round(workspaceButton.height / 2)
              : BarStyle.position === "bottom" ? -8 : workspaceButton.height + 8
            rect.width: 1
            rect.height: 1
            edges: BarStyle.position === "left" ? Edges.Left
              : BarStyle.position === "right" ? Edges.Right
              : BarStyle.position === "bottom" ? Edges.Bottom : Edges.Top
            gravity: BarStyle.position === "left" ? Edges.Right
              : BarStyle.position === "right" ? Edges.Left
              : BarStyle.position === "bottom" ? Edges.Top : Edges.Bottom
          }

          implicitWidth: Math.max(120, Math.min(320,
            popupColumn.implicitWidth + Theme.spaceMd * 2))
          implicitHeight: popupColumn.implicitHeight + Theme.spaceMd * 2
          visible: workspaceButton.hovered
          color: "transparent"
          grabFocus: false

          Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b,
              Theme.popupOpacity)
            border.width: Theme.borderWidth
            border.color: Theme.borderFocus
            radius: Theme.radiusMd

            Column {
              id: popupColumn

              anchors.left: parent.left
              anchors.top: parent.top
              anchors.margins: Theme.spaceMd
              spacing: Theme.spaceSm

              Text {
                visible: windowRepeater.count === 0
                text: "No open windows"
                color: Theme.foregroundMuted
                font.pixelSize: Theme.fontCaption
              }

              Repeater {
                id: windowRepeater
                model: workspaceButton.workspace.toplevels

                RowLayout {
                  required property HyprlandToplevel modelData
                  spacing: Theme.spaceSm

                  Rectangle {
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: 6
                    radius: 3
                    color: modelData.activated ? Theme.accent
                      : modelData.urgent ? Theme.error : Theme.foregroundMuted
                  }

                  IconImage {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    source: workspaceButton.programIcon(modelData)
                    asynchronous: true
                    mipmap: true
                    visible: status === Image.Ready
                  }

                  Text {
                    Layout.preferredWidth: Math.min(implicitWidth, 250)
                    text: workspaceButton.programName(modelData)
                    color: Theme.foreground
                    font.pixelSize: Theme.fontCaption
                    font.weight: Theme.weightStrong
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
