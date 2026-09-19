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

        Rectangle {
          anchors.fill: parent
          radius: 4
          color: pinnedMouse.containsMouse ? Theme.color1 : "transparent"
          border.width: pinnedEntry.modelData.status === TrayService.Status.NeedsAttention ? 1 : 0
          border.color: Theme.color13
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
      }

      IconImage {
        id: toggleIcon

        anchors.centerIn: parent
        implicitSize: 13
        source: Qt.resolvedUrl("../assets/chevron-left.svg")
        rotation: root.panelVisible ? -90 : 0

        Behavior on rotation {
          NumberAnimation {
            duration: 140
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

  RightPopup {
    id: trayPanel

    anchorItem: root.popupAnchor
    implicitWidth: 294
    visible: root.panelVisible && root.hiddenCount > 0

    onVisibleChanged: {
      if (!visible && root.panelVisible)
        root.panelVisible = false
    }

    Column {
      id: panelColumn

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 6

      Item {
        width: parent.width
        height: 20

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "TRAY APPS"
          color: Theme.foreground
          font.pixelSize: 11
          font.bold: true
          font.letterSpacing: 1
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
            height: visible ? 30 : 0
            visible: !root.isPinned(modelData)

            Rectangle {
              id: appButton
              anchors.left: parent.left
              width: 142
              height: parent.height
              radius: 4
              color: appMouse.containsMouse ? Theme.color1 : "transparent"
              border.color: appRow.modelData.status === TrayService.Status.NeedsAttention
                ? Theme.color13 : Theme.color2
              border.width: 1

              IconImage {
                id: appIcon
                anchors.left: parent.left
                anchors.leftMargin: 7
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                source: appRow.modelData.icon
              }

              Text {
                anchors.left: appIcon.right
                anchors.leftMargin: 7
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: appRow.modelData.title || appRow.modelData.id
                color: appRow.modelData.status === TrayService.Status.NeedsAttention
                  ? Theme.color13 : Theme.foreground
                font.pixelSize: 11
                elide: Text.ElideRight
              }

              MouseArea {
                id: appMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.panelVisible = false
                  if (appRow.modelData.onlyMenu)
                    appMenu.open()
                  else
                    appRow.modelData.activate()
                }
              }
            }

            Rectangle {
              id: pinButton
              anchors.left: appButton.right
              anchors.leftMargin: 6
              width: 58
              height: parent.height
              radius: 4
              color: pinMouse.containsMouse ? Theme.color1 : "transparent"
              border.color: pinMouse.containsMouse ? Theme.color8 : Theme.color2
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Pin"
                color: pinMouse.containsMouse ? Theme.color8 : Theme.foreground
                font.pixelSize: 10
              }

              MouseArea {
                id: pinMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePinned(appRow.modelData)
              }
            }

            Rectangle {
              id: menuButton
              anchors.left: pinButton.right
              anchors.leftMargin: 6
              width: 58
              height: parent.height
              radius: 4
              color: menuMouse.containsMouse && appRow.modelData.hasMenu
                ? Theme.color1 : "transparent"
              border.color: menuMouse.containsMouse && appRow.modelData.hasMenu
                ? Theme.color8 : Theme.color2
              border.width: 1
              opacity: appRow.modelData.hasMenu ? 1 : 0.4

              Text {
                anchors.centerIn: parent
                text: appRow.modelData.hasMenu ? "Menu" : "—"
                color: Theme.foreground
                font.pixelSize: 10
              }

              MouseArea {
                id: menuMouse
                anchors.fill: parent
                enabled: appRow.modelData.hasMenu
                hoverEnabled: enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: appMenu.open()
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
