import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../"
import "../bar" as Bar

Scope {
  id: root

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData
      readonly property bool focused: {
        const monitor = Hyprland.monitorFor(modelData)
        return monitor !== null && Hyprland.focusedMonitor !== null
          && monitor.name === Hyprland.focusedMonitor.name
      }

      screen: modelData
      visible: focused
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "atlas-osd"

      anchors {
        top: true
        left: true
        right: true
        bottom: true
      }

      mask: Region {}

      Rectangle {
        id: card
        readonly property string horizontalPlacement: Placement.horizontal(Placement.osd)
        readonly property string verticalPlacement: Placement.vertical(Placement.osd)
        readonly property bool sidePlacement: horizontalPlacement !== "center"
        width: sidePlacement ? 52 : 248
        height: sidePlacement ? 248 : 36
        x: Placement.itemX(Placement.osd, window.width, width, Placement.edgeMargin)
        y: Placement.itemY(Placement.osd, window.height, height,
          Placement.edgeMargin + Bar.BarStyle.topClearance,
          Placement.edgeMargin + Bar.BarStyle.bottomClearance)
        radius: Theme.radiusLg
        color: Qt.rgba(
          Theme.surface.r,
          Theme.surface.g,
          Theme.surface.b,
          Theme.popupOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.borderFocus
        opacity: OsdState.shown ? 1 : 0

        transform: Translate {
          x: OsdState.shown ? 0 : (card.horizontalPlacement === "left"
            ? -card.width - 18 : (card.horizontalPlacement === "right"
              ? card.width + 18 : 0))
          y: OsdState.shown ? 0 : (card.horizontalPlacement !== "center" ? 0
            : (card.verticalPlacement === "top" ? -card.height - 18
              : card.height + 18))

          Behavior on x {
            SpringAnimation {
              spring: 12
              damping: 0.75
              epsilon: 0.01
            }
          }

          Behavior on y {
            SpringAnimation {
              spring: 12
              damping: 0.75
              epsilon: 0.01
            }
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: 70
            easing.type: Easing.OutQuad
          }
        }

        Osd {
          anchors.centerIn: parent
          iconType: OsdState.iconType
          value: OsdState.value
          vertical: card.sidePlacement
        }
      }
    }
  }
}
