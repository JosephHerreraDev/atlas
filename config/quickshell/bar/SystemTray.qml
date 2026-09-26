import Quickshell
import Quickshell.Services.SystemTray as TrayService
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

Item {
  id: root

  property bool revealed: false
  readonly property int motionFast: Theme.motionFast
  readonly property int motionNormal: Theme.motionNormal
  readonly property int totalCount: TrayService.SystemTray.items.values.length

  function toggle(): void {
    revealed = !revealed
  }

  implicitWidth: visible ? trayRow.implicitWidth : 0
  implicitHeight: Theme.barControlHeight
  Layout.preferredWidth: visible ? implicitWidth : 0
  visible: totalCount > 0

  onTotalCountChanged: {
    if (totalCount === 0)
      revealed = false
  }

  RowLayout {
    id: trayRow

    anchors.fill: parent
    spacing: 2
    layoutDirection: Qt.RightToLeft

    Repeater {
      model: TrayService.SystemTray.items

      delegate: Item {
        id: trayEntry

        required property var modelData

        Layout.preferredWidth: root.revealed ? 20 : 0
        Layout.preferredHeight: 20
        visible: opacity > 0
        opacity: root.revealed ? 1 : 0
        scale: trayMouse.pressed ? 0.96 : 1

        Behavior on Layout.preferredWidth {
          NumberAnimation {
            duration: root.motionNormal
            easing.type: Easing.OutCubic
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: root.motionFast
            easing.type: Easing.OutCubic
          }
        }

        Behavior on scale {
          NumberAnimation {
            duration: root.motionFast
            easing.type: Easing.OutCubic
          }
        }

        Rectangle {
          anchors.fill: parent
          radius: Theme.radiusSm
          color: trayMouse.containsMouse ? Theme.color1 : "transparent"
          border.width: trayEntry.modelData.status === TrayService.Status.NeedsAttention ? 1 : 0
          border.color: Theme.color13

          Behavior on color {
            ColorAnimation { duration: root.motionFast }
          }
        }

        IconImage {
          anchors.centerIn: parent
          implicitSize: 14
          source: trayEntry.modelData.icon
        }

        MouseArea {
          id: trayMouse

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton

          onClicked: function(mouse) {
            if (trayEntry.modelData.hasMenu)
              trayMenu.open()
            else if (mouse.button === Qt.LeftButton)
              trayEntry.modelData.activate()
          }
        }

        QsMenuAnchor {
          id: trayMenu
          anchor.item: trayEntry
          anchor.rect.y: trayEntry.height
          menu: trayEntry.modelData.menu
        }

        Tooltip {
          target: trayEntry
          text: trayEntry.modelData.tooltipTitle
            || trayEntry.modelData.title
            || trayEntry.modelData.id
          shown: trayMouse.containsMouse && !trayMenu.visible
        }
      }
    }

    Item {
      id: trayToggle

      Layout.preferredWidth: 22
      Layout.preferredHeight: 20

      Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: toggleMouse.containsMouse || root.revealed ? Theme.color1 : "transparent"
        border.width: root.revealed ? 1 : 0
        border.color: Theme.color8

        Behavior on color {
          ColorAnimation { duration: root.motionFast }
        }
      }

      IconImage {
        id: toggleIcon

        anchors.centerIn: parent
        implicitSize: 13
        source: Qt.resolvedUrl("../assets/chevron-left.svg")
        rotation: root.revealed ? 180 : 0

        Behavior on rotation {
          NumberAnimation {
            duration: root.motionNormal
            easing.type: Easing.OutCubic
          }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
          brightness: 1
          colorization: 1
          colorizationColor: toggleMouse.containsMouse || root.revealed
            ? Theme.color8
            : Theme.foreground
        }
      }

      MouseArea {
        id: toggleMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
      }

    }
  }
}
