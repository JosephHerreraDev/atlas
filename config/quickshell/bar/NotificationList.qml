import QtQuick
import QtQuick.Layouts
import ".."
import "../shared/"

Rectangle {
  id: root

  required property var notifications
  readonly property bool hasNotifications: notifications.history.count > 0

  width: parent?.width ?? implicitWidth
  implicitHeight: contentColumn.implicitHeight + Theme.spaceMd * 2
  radius: Theme.radiusSm
  color: Theme.surface
  border.width: Theme.borderWidth
  border.color: Theme.border

  Column {
    id: contentColumn

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Theme.spaceMd
    spacing: Theme.spaceSm

    RowLayout {
      width: parent.width
      height: 32
      spacing: Theme.spaceSm

      Text {
        Layout.fillWidth: true
        text: "Notifications"
        color: Theme.foreground
        font.pixelSize: Theme.fontTitle
        font.weight: Theme.weightStrong
      }

      Button {
        Layout.preferredWidth: 84
        Layout.preferredHeight: Theme.controlHeight
        enabled: root.hasNotifications
        accessibleName: "Clear all notifications"
        buttonBorderColor: hovered ? Theme.error : Theme.border
        onClicked: root.notifications.history.clear()

        Text {
          anchors.centerIn: parent
          text: "Clear all"
          color: parent.enabled ? Theme.error : Theme.border
          font.pixelSize: Theme.fontCaption
        }
      }
    }

    ListView {
      id: notificationList

      width: parent.width
      height: Math.min(contentHeight, 240)
      visible: root.hasNotifications
      clip: true
      spacing: Theme.spaceSm
      boundsBehavior: Flickable.StopAtBounds
      model: root.notifications.history

      delegate: Rectangle {
        id: historyCard

        required property int index
        required property string summary
        required property string body
        required property string appName
        required property string time

        width: notificationList.width
        height: cardColumn.implicitHeight + Theme.spaceLg * 2
        radius: Theme.radiusSm
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border

        ColumnLayout {
          id: cardColumn

          anchors.fill: parent
          anchors.margins: Theme.spaceLg
          spacing: Theme.spaceXs

          RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spaceSm

            Text {
              Layout.fillWidth: true
              text: historyCard.summary
              textFormat: Text.PlainText
              color: Theme.foreground
              font.pixelSize: Theme.fontBody
              font.weight: Theme.weightStrong
              elide: Text.ElideRight
            }

            Text {
              text: historyCard.time
              textFormat: Text.PlainText
              color: Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
            }

            Button {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              horizontalPadding: 0
              accessibleName: "Dismiss " + historyCard.summary
              buttonBorderColor: hovered ? Theme.error : Theme.border
              onClicked: root.notifications.history.remove(historyCard.index)

              Text {
                anchors.centerIn: parent
                text: "×"
                color: parent.hovered ? Theme.error : Theme.foreground
                font.pixelSize: Theme.fontBody
              }
            }
          }

          Text {
            Layout.fillWidth: true
            visible: historyCard.appName !== ""
            text: historyCard.appName
            textFormat: Text.PlainText
            color: Theme.foregroundMuted
            font.pixelSize: Theme.fontCaption
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            visible: historyCard.body !== ""
            text: historyCard.body
            textFormat: Text.PlainText
            color: Theme.foreground
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: !root.hasNotifications
      text: "You're all caught up"
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
