import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"
import "../shared/"

Button {
  id: notificationButton

  required property var notifications
  required property var shellScreen
  property bool centerOpen: false

  readonly property bool hasNotifications: notifications.history.count > 0
  readonly property bool isFocusedMonitor:
    Hyprland.monitorFor(shellScreen) === Hyprland.focusedMonitor

  Layout.preferredWidth: 24
  Layout.preferredHeight: 20

  onClicked: {
    if (hasNotifications)
      centerOpen = !centerOpen
  }

  onHasNotificationsChanged: {
    if (!hasNotifications)
      centerOpen = false
  }

  onIsFocusedMonitorChanged: {
    if (!isFocusedMonitor)
      centerOpen = false
  }

  Connections {
    target: notifications

    function onToggleRequested() {
      if (notificationButton.isFocusedMonitor && notificationButton.hasNotifications)
        notificationButton.centerOpen = !notificationButton.centerOpen
      else
        notificationButton.centerOpen = false
    }

    function onShowRequested() {
      notificationButton.centerOpen = notificationButton.isFocusedMonitor
        && notificationButton.hasNotifications
    }

    function onHideRequested() {
      notificationButton.centerOpen = false
    }
  }

  IconImage {
    anchors.centerIn: parent

    implicitWidth: 14
    implicitHeight: 14
    source: Qt.resolvedUrl(notificationButton.hasNotifications
      ? "../assets/bell-filled.svg"
      : "../assets/bell.svg")

    layer.enabled: true
    layer.effect: MultiEffect {
      brightness: 1
      colorizationColor: Theme.foreground
    }
  }

  RightPopup {
    id: notificationCenter

    anchorItem: notificationButton
    implicitWidth: 380
    visible: notificationButton.centerOpen && notificationButton.hasNotifications

    onVisibleChanged: {
      if (!visible && notificationButton.centerOpen)
        notificationButton.centerOpen = false
    }

    ColumnLayout {
      id: centerColumn

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 10

      RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
          Layout.fillWidth: true
          anchors.verticalCenter: parent.verticalCenter
          text: "NOTIFICATIONS"
          color: Theme.foreground
          font.pixelSize: 11
          font.bold: true
          font.letterSpacing: 1
        }
        Rectangle {
          id: deleteButton
          width: 58
          height: 20
          radius: 4
          color: deleteMouse.containsMouse ? Theme.color1 : "transparent"
          border.color: deleteMouse.containsMouse ? Theme.color11 : Theme.color2
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "Clear all"
            color: Theme.color11
            font.pixelSize: 10
          }

          MouseArea {
            id: deleteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: notifications.history.clear()
          }
        }
      }
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Theme.color2
      }

      Repeater {
        model: notifications.history

        delegate: Rectangle {
          id: historyCard

          required property int index
          required property string summary
          required property string body
          required property string appName
          required property string time

          Layout.fillWidth: true
          Layout.preferredHeight: cardColumn.implicitHeight + 16
          radius: 4
          color: Theme.background
          border.width: 1
          border.color: Theme.color2

          ColumnLayout {
            id: cardColumn

            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                Layout.fillWidth: true
                text: historyCard.summary
                color: Theme.foreground
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                text: historyCard.time
                color: Theme.color5
              }

              Rectangle {
                id: deleteItemButton
                width: 20
                height: 20
                radius: 4
                color: deleteItemMouse.containsMouse ? Theme.color1 : "transparent"
                border.color: deleteItemMouse.containsMouse ? Theme.color11 : Theme.color2
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "x"
                  color: deleteItemMouse.containsMouse ? Theme.color11 : Theme.color2
                  font.pixelSize: 10
                }

                MouseArea {
                  id: deleteItemMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: notifications.history.remove(historyCard.index)
                }
              }
            }

            Text {
              visible: historyCard.appName !== ""
              text: historyCard.appName
              color: Theme.color5
            }

            Text {
              Layout.fillWidth: true
              visible: historyCard.body !== ""
              text: historyCard.body
              color: Theme.foreground
              wrapMode: Text.WordWrap
            }
          }
        }
      }
    }
  }
}
