import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "../"
import "../shared/"

Scope {
  id: root
  property alias history: history
  property bool doNotDisturb: false

  ListModel {
    id: history
  }

  NotificationServer {
    id: server
    actionsSupported: true
    bodySupported: true
    imageSupported: true

    onNotification: n => 
    {
      history.insert(0, {
        summary: n.summary,
        body: n.body,
        appName: n.appName,
        urgency: n.urgency,
        time: Qt.formatDateTime(new Date(), "HH:mm")
      })
      n.tracked = !root.doNotDisturb
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor

      anchors { top: true; right: true }
      margins {top: 32; right: 12}

      implicitWidth: 380
      implicitHeight: Math.max(1, column.implicitHeight)
      color: "transparent"

      exclusionMode: ExclusionMode.Ignore

      ColumnLayout {
        id: column
        width: parent.width
        spacing: 10

        Repeater {
          model: server.trackedNotifications
          delegate: Rectangle {
          id: card
          required property var modelData

          Timer {
            running: card.modelData.urgency !== NotificationUrgency.Critical
            interval: 5000
            onTriggered: card.modelData.dismiss()
          }
          Layout.fillWidth: true
          Layout.preferredHeight: layout.implicitHeight + 20
          radius: Theme.radiusSm
          color: Theme.background
          border.width: Theme.borderWidth
          border.color: modelData.urgency === NotificationUrgency.Critical 
            ? Theme.color11 : Theme.foreground

          RowLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Image {
              Layout.preferredHeight: 36
              Layout.preferredWidth: 36
              Layout.alignment: Qt.AlignTop
              fillMode: Image.PreserveAspectFit
              visible: source.toString() !== ""
              source: card.modelData.image || card.modelData.appIcon || ""
            }

            ColumnLayout{
              Layout.fillWidth: true
              spacing: 2

              Text{
                Layout.fillWidth: true
                text: card.modelData.summary
                color: Theme.foreground
                font.bold: true
                elide: Text.ElideRight
              }

              Text{
                Layout.fillWidth: true
                visible: text !== ""
                text: card.modelData.body
                color: Theme.foreground
                wrapMode: Text.WordWrap
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: card.modelData.dismiss()
          }
          }
        }
      }
    }
  }

}
