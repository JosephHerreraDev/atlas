import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import ".."
import "../shared/"

Rectangle {
  id: root

  required property var notifications
  readonly property bool hasNotifications: notifications.history.count > 0

  width: parent?.width ?? implicitWidth
  implicitHeight: contentColumn.implicitHeight
  color: "transparent"
  border.width: 0

  function urgencyColor(urgency): color {
    if (urgency === NotificationUrgency.Critical) return Theme.error
    if (urgency === NotificationUrgency.Low) return Theme.foregroundMuted
    return Theme.accent
  }

  Column {
    id: contentColumn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Theme.spaceSm

    RowLayout {
      width: parent.width
      height: 30
      spacing: Theme.spaceSm

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
          text: root.hasNotifications ? "Recent" : "Notifications"
          color: Theme.foreground
          font.pixelSize: Theme.fontBody
          font.weight: Theme.weightStrong
        }

        Text {
          visible: root.hasNotifications
          text: root.notifications.history.count + " saved"
            + (root.notifications.unreadCount > 0
              ? " · " + root.notifications.unreadCount + " unread" : "")
          color: Theme.foregroundMuted
          font.pixelSize: Theme.fontCaption
        }
      }

      Button {
        id: clearButton
        Layout.preferredWidth: clearButtonContent.implicitWidth + Theme.spaceSm * 2
        Layout.minimumWidth: clearButtonContent.implicitWidth + Theme.spaceSm * 2
        Layout.preferredHeight: Theme.controlHeight
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        enabled: root.hasNotifications
        accessibleName: "Clear all notifications"
        buttonColor: hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
        buttonBorderColor: hovered ? Theme.error : Theme.border
        onClicked: root.notifications.clearHistory()

        Row {
          id: clearButtonContent
          anchors.centerIn: parent
          spacing: Theme.spaceXs

          IconImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            source: Qt.resolvedUrl("../assets/clear.svg")
            layer.enabled: true
            layer.effect: MultiEffect {
              brightness: 1
              colorization: 1
              colorizationColor: clearButton.enabled ? Theme.error : Theme.border
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Clear all"
            color: clearButton.enabled ? Theme.error : Theme.border
            font.pixelSize: Theme.fontCaption
          }
        }
      }
    }

    ListView {
      id: notificationList
      width: parent.width
      height: Math.min(contentHeight, 360)
      visible: root.hasNotifications
      clip: true
      spacing: Theme.spaceSm
      boundsBehavior: Flickable.StopAtBounds
      model: root.notifications.history

      delegate: Rectangle {
        id: historyCard

        required property int index
        required property int notificationId
        required property string summary
        required property string body
        required property string appName
        required property string icon
        required property int urgency
        required property string time
        required property string date
        required property bool read

        width: notificationList.width
        height: cardColumn.implicitHeight + Theme.spaceLg * 2
        radius: Theme.radiusLg
        color: historyCard.read ? Theme.surface : Theme.surfaceHover
        border.width: Theme.borderWidth
        border.color: historyCard.activeFocus ? Theme.accent : Theme.border

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 3
          radius: parent.radius
          color: root.urgencyColor(historyCard.urgency)
        }

        ColumnLayout {
          id: cardColumn
          anchors.fill: parent
          anchors.margins: Theme.spaceLg
          anchors.leftMargin: Theme.spaceLg + 3
          spacing: Theme.spaceXs

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            Rectangle {
              Layout.preferredWidth: 32
              Layout.preferredHeight: 32
              Layout.alignment: Qt.AlignTop
              radius: Theme.radiusSm
              color: Theme.background
              border.width: Theme.borderWidth
              border.color: Theme.border

              Image {
                id: historyIcon
                anchors.fill: parent
                anchors.margins: 4
                source: historyCard.icon
                fillMode: Image.PreserveAspectFit
                visible: source.toString() !== ""
              }

              Text {
                anchors.centerIn: parent
                visible: historyIcon.status !== Image.Ready
                text: (historyCard.appName || "S").charAt(0).toUpperCase()
                color: Theme.accent
                font.pixelSize: Theme.fontBody
                font.weight: Theme.weightStrong
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceXs

                Text {
                  Layout.fillWidth: true
                  text: historyCard.appName
                  textFormat: Text.PlainText
                  color: root.urgencyColor(historyCard.urgency)
                  font.pixelSize: Theme.fontCaption
                  font.weight: Theme.weightMedium
                  elide: Text.ElideRight
                }

                Rectangle {
                  visible: !historyCard.read
                  Layout.preferredWidth: 6
                  Layout.preferredHeight: 6
                  radius: 3
                  color: Theme.accent
                }

                Text {
                  text: historyCard.time
                  textFormat: Text.PlainText
                  color: Theme.foregroundMuted
                  font.pixelSize: Theme.fontCaption
                }
              }

              Text {
                Layout.fillWidth: true
                text: historyCard.summary
                textFormat: Text.PlainText
                color: Theme.foreground
                font.pixelSize: Theme.fontBody
                font.weight: Theme.weightStrong
                elide: Text.ElideRight
              }
            }

            Button {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              Layout.alignment: Qt.AlignTop
              horizontalPadding: 0
              accessibleName: "Remove " + historyCard.summary
              buttonColor: hovered ? Theme.background : "transparent"
              buttonBorderColor: hovered ? Theme.error : "transparent"
              onClicked: root.notifications.removeHistory(historyCard.index)

              Text {
                anchors.centerIn: parent
                text: "×"
                color: parent.hovered ? Theme.error : Theme.foregroundMuted
                font.pixelSize: Theme.fontBody
              }
            }
          }

          Text {
            Layout.fillWidth: true
            visible: historyCard.body !== ""
            text: historyCard.body
            textFormat: Text.PlainText
            color: Theme.foreground
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
          }
        }
      }
    }

    Column {
      width: parent.width
      visible: !root.hasNotifications
      topPadding: Theme.spaceXl
      bottomPadding: Theme.spaceXl
      spacing: Theme.spaceSm

      Text {
        width: parent.width
        text: "✓"
        color: Theme.success
        font.pixelSize: 24
        font.weight: Theme.weightStrong
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width
        text: "You're all caught up"
        color: Theme.foreground
        font.pixelSize: Theme.fontBody
        font.weight: Theme.weightMedium
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        width: parent.width
        text: root.notifications.doNotDisturb
          ? "Do not disturb is on"
          : "New notifications will appear here"
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
