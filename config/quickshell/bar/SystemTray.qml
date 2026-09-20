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

  property var pinnedIds: []
  property bool panelVisible: false
  required property Item popupAnchor
  readonly property int spaceXs: 4
  readonly property int spaceSm: 8
  readonly property int spaceMd: 8
  readonly property int spaceLg: 12
  readonly property int controlHeight: 28
  readonly property int listRowHeight: 34
  readonly property int bodyFontSize: 12
  readonly property int captionFontSize: 11
  readonly property int titleFontSize: 14
  readonly property int motionFast: 100
  readonly property int motionNormal: 160

  readonly property int totalCount: TrayService.SystemTray.items.values.length
  readonly property int hiddenCount: {
    let count = 0
    for (const item of TrayService.SystemTray.items.values) {
      if (!isPinned(item))
        count++
    }
    return count
  }

  function itemId(item) {
    return item.id || item.title
  }

  function isPinned(item) {
    return pinnedIds.indexOf(itemId(item)) >= 0
  }

  function togglePinned(item) {
    const id = itemId(item)
    const updated = pinnedIds.slice()
    const index = updated.indexOf(id)
    if (index >= 0)
      updated.splice(index, 1)
    else
      updated.push(id)
    pinnedIds = updated
  }

  implicitWidth: visible ? trayRow.implicitWidth : 0
  implicitHeight: 20
  Layout.preferredWidth: visible ? implicitWidth : 0
  visible: totalCount > 0

  onHiddenCountChanged: {
    if (hiddenCount === 0)
      panelVisible = false
  }

  RowLayout {
    id: trayRow

    anchors.fill: parent
    spacing: 2

    Repeater {
      id: trayRepeater
      model: TrayService.SystemTray.items

      delegate: Item {
        id: pinnedEntry

        required property var modelData

        Layout.preferredWidth: visible ? 20 : 0
        Layout.preferredHeight: 20
        visible: root.isPinned(modelData)
        scale: pinnedMouse.pressed ? 0.96 : 1

        Behavior on scale {
          NumberAnimation {
            duration: root.motionFast
            easing.type: Easing.OutCubic
          }
        }

        Rectangle {
          anchors.fill: parent
          radius: 4
          color: pinnedMouse.containsMouse ? Theme.color1 : "transparent"
          border.width: pinnedEntry.modelData.status === TrayService.Status.NeedsAttention ? 1 : 0
          border.color: Theme.color13

          Behavior on color {
            ColorAnimation { duration: root.motionFast }
          }
        }

        IconImage {
          anchors.centerIn: parent
          implicitSize: 14
          source: pinnedEntry.modelData.icon
        }

        MouseArea {
          id: pinnedMouse

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton

          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
              root.togglePinned(pinnedEntry.modelData)
            else if (pinnedEntry.modelData.hasMenu)
              pinnedMenu.open()
            else
              pinnedEntry.modelData.activate()
          }
        }

        QsMenuAnchor {
          id: pinnedMenu
          anchor.item: pinnedEntry
          anchor.rect.y: pinnedEntry.height
          menu: pinnedEntry.modelData.menu
        }

        Tooltip {
          target: pinnedEntry
          text: (pinnedEntry.modelData.tooltipTitle
            || pinnedEntry.modelData.title
            || pinnedEntry.modelData.id) + "\nRight-click to unpin"
          shown: pinnedMouse.containsMouse && !pinnedMenu.visible
        }
      }
    }

    Item {
      id: trayToggle

      Layout.preferredWidth: visible ? 22 : 0
      Layout.preferredHeight: 20
      visible: root.hiddenCount > 0

      Rectangle {
        anchors.fill: parent
        radius: 4
        color: toggleMouse.containsMouse || root.panelVisible ? Theme.color1 : "transparent"
        border.width: root.panelVisible ? 1 : 0
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
        rotation: root.panelVisible ? -90 : 0

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
          colorizationColor: toggleMouse.containsMouse || root.panelVisible
            ? Theme.color8
            : Theme.foreground
        }
      }

      MouseArea {
        id: toggleMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.panelVisible = !root.panelVisible
      }

      Tooltip {
        target: trayToggle
        text: root.hiddenCount + (root.hiddenCount === 1 ? " tray app" : " tray apps")
        shown: toggleMouse.containsMouse && !root.panelVisible
      }
    }
  }

  Popup {
    id: trayPanel

    anchorItem: root.popupAnchor
    implicitWidth: 320
    padding: root.spaceLg
    shown: root.panelVisible && root.hiddenCount > 0

    onVisibleChanged: {
      if (!visible && root.panelVisible)
        root.panelVisible = false
    }

    Column {
      id: panelColumn

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: root.spaceMd

      Item {
        width: parent.width
        height: 24

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "System tray"
          color: Theme.foreground
          font.pixelSize: root.titleFontSize
          font.weight: Font.DemiBold
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Theme.color2
      }

      Repeater {
        model: TrayService.SystemTray.items

        delegate: Item {
          id: appRow

          required property var modelData

          width: panelColumn.width
          height: root.isPinned(modelData) ? 0 : root.listRowHeight
          opacity: root.isPinned(modelData) ? 0 : 1
          visible: opacity > 0

          Behavior on height {
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

          RowLayout {
            anchors.fill: parent
            spacing: root.spaceSm

            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true

              IconImage {
                id: appIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 18
                source: appRow.modelData.icon
              }

              Text {
                anchors.left: appIcon.right
                anchors.leftMargin: root.spaceMd
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: appRow.modelData.title || appRow.modelData.id
                color: appRow.modelData.status === TrayService.Status.NeedsAttention
                  ? Theme.color13 : Theme.foreground
                font.pixelSize: root.bodyFontSize
                elide: Text.ElideRight
              }
            }

            Button {
              Layout.preferredWidth: 56
              Layout.preferredHeight: root.controlHeight
              buttonBorderColor: hovered ? Theme.color8 : Theme.color2
              onClicked: root.togglePinned(appRow.modelData)

              Text {
                anchors.centerIn: parent
                text: "Pin"
                color: parent.hovered ? Theme.color8 : Theme.foreground
                font.pixelSize: root.captionFontSize
              }
            }

            Button {
              id: menuButton

              Layout.preferredWidth: 56
              Layout.preferredHeight: root.controlHeight
              enabled: appRow.modelData.hasMenu
              opacity: enabled ? 1 : 0.4
              buttonBorderColor: hovered ? Theme.color8 : Theme.color2
              onClicked: appMenu.open()

              Text {
                anchors.centerIn: parent
                text: appRow.modelData.hasMenu ? "Menu" : "—"
                color: Theme.foreground
                font.pixelSize: root.captionFontSize
              }
            }
          }

          QsMenuAnchor {
            id: appMenu
            anchor.item: menuButton
            anchor.rect.y: menuButton.height
            menu: appRow.modelData.menu
          }
        }
      }
    }
  }
}
