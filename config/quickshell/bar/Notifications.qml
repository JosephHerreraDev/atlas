import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../"
import "../shared/"

Scope {
  id: root

  property alias history: history
  property bool doNotDisturb: false
  property int unreadCount: 0
  property bool stateLoaded: false
  readonly property int maximumHistory: 100

  function saveState(): void {
    if (!stateLoaded)
      return
    const entries = []
    for (let index = 0; index < history.count; ++index)
      entries.push(history.get(index))
    stateFile.setText(JSON.stringify({
      doNotDisturb: doNotDisturb,
      history: entries
    }, null, 2) + "\n")
  }

  onDoNotDisturbChanged: stateSaveTimer.restart()

  function refreshUnreadCount(): void {
    let count = 0
    for (let index = 0; index < history.count; ++index) {
      if (!history.get(index).read)
        count += 1
    }
    unreadCount = count
    stateSaveTimer.restart()
  }

  function markAllRead(): void {
    for (let index = 0; index < history.count; ++index)
      history.setProperty(index, "read", true)
    refreshUnreadCount()
  }

  function clearHistory(): void {
    history.clear()
    refreshUnreadCount()
  }

  function removeHistory(index): void {
    if (index >= 0 && index < history.count)
      history.remove(index)
    refreshUnreadCount()
  }

  function historyIndex(notificationId): int {
    for (let index = 0; index < history.count; ++index) {
      if (history.get(index).notificationId === notificationId)
        return index
    }
    return -1
  }

  function record(notification): void {
    if (notification.transient)
      return
    const now = new Date()
    const entry = {
      notificationId: notification.id,
      summary: notification.summary || "Notification",
      body: notification.body || "",
      appName: notification.appName || "System",
      icon: notification.image || notification.appIcon || "",
      urgency: notification.urgency,
      time: Qt.formatDateTime(now, "HH:mm"),
      date: Qt.formatDateTime(now, "ddd, MMM d"),
      read: false
    }
    const previousIndex = historyIndex(notification.id)
    if (previousIndex >= 0)
      history.remove(previousIndex)
    history.insert(0, entry)
    if (history.count > maximumHistory)
      history.remove(maximumHistory, history.count - maximumHistory)
    refreshUnreadCount()
  }

  function urgencyColor(urgency): color {
    if (urgency === NotificationUrgency.Critical) return Theme.error
    if (urgency === NotificationUrgency.Low) return Theme.foregroundMuted
    return Theme.accent
  }

  ListModel {
    id: history
    onCountChanged: root.refreshUnreadCount()
  }

  FileView {
    id: stateFile
    path: (Quickshell.env("XDG_CONFIG_HOME")
      || Quickshell.env("HOME") + "/.config") + "/atlas/notifications.json"
    preload: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        const data = JSON.parse(text())
        if (typeof data.doNotDisturb === "boolean")
          root.doNotDisturb = data.doNotDisturb
        if (Array.isArray(data.history)) {
          const entries = data.history.slice(0, root.maximumHistory)
          for (let index = entries.length - 1; index >= 0; --index) {
            const entry = entries[index]
            if (entry && typeof entry.summary === "string"
                && typeof entry.appName === "string")
              history.insert(0, entry)
          }
        }
      } catch (error) {}
      root.stateLoaded = true
      root.refreshUnreadCount()
    }
    onLoadFailed: {
      root.stateLoaded = true
      root.saveState()
    }
  }

  Timer {
    id: stateSaveTimer
    interval: 150
    onTriggered: root.saveState()
  }

  NotificationServer {
    id: server
    keepOnReload: true
    persistenceSupported: true
    actionsSupported: true
    bodySupported: true
    imageSupported: true
    inlineReplySupported: true
    bodyMarkupSupported: false

    onNotification: notification => {
      root.record(notification)
      notification.tracked = !root.doNotDisturb
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor

      anchors { top: true; right: true }
      margins { top: 32; right: 12 }
      implicitWidth: 390
      implicitHeight: Math.max(1, Math.min(toastColumn.implicitHeight, screen.height - 64))
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore

      ColumnLayout {
        id: toastColumn
        width: parent.width
        spacing: Theme.spaceSm

        Repeater {
          model: server.trackedNotifications

          delegate: Rectangle {
            id: card
            required property var modelData
            readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
            readonly property bool pointerInside: cardHover.hovered

            Layout.fillWidth: true
            Layout.preferredHeight: toastLayout.implicitHeight + Theme.spaceLg * 2
            radius: Theme.radiusLg
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: card.critical ? Theme.error : Theme.border
            layer.enabled: true

            Timer {
              running: !card.critical && !card.pointerInside
              interval: card.modelData.expireTimeout > 0
                ? Math.max(3000, Math.min(10000, card.modelData.expireTimeout))
                : 6000
              onTriggered: card.modelData.expire()
            }

            HoverHandler { id: cardHover }

            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: 4
              radius: parent.radius
              color: root.urgencyColor(card.modelData.urgency)
            }

            ColumnLayout {
              id: toastLayout
              anchors.fill: parent
              anchors.margins: Theme.spaceLg
              anchors.leftMargin: Theme.spaceLg + 4
              spacing: Theme.spaceSm

              RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spaceSm

                Rectangle {
                  Layout.preferredWidth: 36
                  Layout.preferredHeight: 36
                  Layout.alignment: Qt.AlignTop
                  radius: Theme.radiusSm
                  color: Theme.surfaceHover
                  border.width: Theme.borderWidth
                  border.color: Theme.border

                  Image {
                    id: toastIcon
                    anchors.fill: parent
                    anchors.margins: 4
                    fillMode: Image.PreserveAspectFit
                    source: card.modelData.image || card.modelData.appIcon || ""
                    visible: source.toString() !== ""
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: toastIcon.status !== Image.Ready
                    text: (card.modelData.appName || "S").charAt(0).toUpperCase()
                    color: Theme.accent
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.weightStrong
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceXs

                    Text {
                      Layout.fillWidth: true
                      text: card.modelData.appName || "System"
                      textFormat: Text.PlainText
                      color: root.urgencyColor(card.modelData.urgency)
                      font.pixelSize: Theme.fontCaption
                      font.weight: Theme.weightMedium
                      elide: Text.ElideRight
                    }

                    Text {
                      visible: card.critical
                      text: "Important"
                      color: Theme.error
                      font.pixelSize: Theme.fontCaption
                      font.weight: Theme.weightStrong
                    }
                  }

                  Text {
                    Layout.fillWidth: true
                    text: card.modelData.summary || "Notification"
                    textFormat: Text.PlainText
                    color: Theme.foreground
                    font.pixelSize: Theme.fontBody
                    font.weight: Theme.weightStrong
                    elide: Text.ElideRight
                  }
                }

                Button {
                  Layout.preferredWidth: 26
                  Layout.preferredHeight: 26
                  horizontalPadding: 0
                  accessibleName: "Dismiss notification"
                  buttonColor: hovered ? Theme.surfaceHover : "transparent"
                  buttonBorderColor: hovered ? Theme.error : "transparent"
                  onClicked: card.modelData.dismiss()
                  Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: parent.hovered ? Theme.error : Theme.foregroundMuted
                    font.pixelSize: Theme.fontTitle
                  }
                }
              }

              Text {
                Layout.fillWidth: true
                visible: card.modelData.body !== ""
                text: card.modelData.body
                textFormat: Text.PlainText
                color: Theme.foreground
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
                maximumLineCount: 5
                elide: Text.ElideRight
              }

              RowLayout {
                Layout.fillWidth: true
                visible: card.modelData.actions.length > 0
                spacing: Theme.spaceSm

                Repeater {
                  model: card.modelData.actions
                  delegate: Button {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.controlHeight
                    accessibleName: modelData.text
                    buttonColor: hovered ? Theme.surfaceHover : Theme.surface
                    buttonBorderColor: Theme.border
                    onClicked: {
                      modelData.invoke()
                      if (!card.modelData.resident)
                        card.modelData.dismiss()
                    }
                    Text {
                      anchors.centerIn: parent
                      text: parent.modelData.text
                      color: Theme.foreground
                      font.pixelSize: Theme.fontCaption
                      font.weight: Theme.weightMedium
                      elide: Text.ElideRight
                    }
                  }
                }
              }

              RowLayout {
                Layout.fillWidth: true
                visible: card.modelData.hasInlineReply
                spacing: Theme.spaceSm

                Controls.TextField {
                  id: replyField
                  Layout.fillWidth: true
                  Layout.preferredHeight: Theme.controlHeight
                  placeholderText: card.modelData.inlineReplyPlaceholder || "Reply…"
                  color: Theme.foreground
                  placeholderTextColor: Theme.foregroundMuted
                  font.pixelSize: Theme.fontCaption
                  background: Rectangle {
                    radius: Theme.radiusSm
                    color: Theme.surfaceHover
                    border.width: Theme.borderWidth
                    border.color: replyField.activeFocus ? Theme.accent : Theme.border
                  }
                  onAccepted: sendReplyButton.clicked()
                }

                Button {
                  id: sendReplyButton
                  Layout.preferredWidth: 54
                  Layout.preferredHeight: Theme.controlHeight
                  enabled: replyField.text.trim() !== ""
                  accessibleName: "Send reply"
                  onClicked: {
                    const message = replyField.text.trim()
                    if (message === "") return
                    card.modelData.sendInlineReply(message)
                    replyField.text = ""
                    if (!card.modelData.resident)
                      card.modelData.dismiss()
                  }
                  Text {
                    anchors.centerIn: parent
                    text: "Send"
                    color: parent.enabled ? Theme.foreground : Theme.foregroundMuted
                    font.pixelSize: Theme.fontCaption
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
