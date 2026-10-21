import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../"

Controls.MenuItem {
  id: root
  property var menuColors: null
  property string hint: ""
  property bool destructive: false
  implicitHeight: 34
  implicitWidth: 236
  padding: 8
  hoverEnabled: true
  indicator: Item {}
  arrow: Item {}
  background: Rectangle {
    radius: Theme.radiusSm
    color: root.highlighted || root.down ? (root.menuColors ? root.menuColors.hoverColor : Theme.surfaceHover) : "transparent"
    border.width: root.activeFocus ? Theme.borderWidth : 0
    border.color: root.menuColors ? root.menuColors.accentColor : Theme.accent
  }
  contentItem: RowLayout {
    spacing: 8
    opacity: root.enabled ? 1 : 0.4
    Text {
      Layout.preferredWidth: 16
      text: root.checkable && root.checked ? "✓" : ""
      color: root.menuColors ? root.menuColors.accentColor : Theme.accent
      font.pixelSize: Theme.fontBody
      horizontalAlignment: Text.AlignHCenter
    }
    Text {
      Layout.fillWidth: true
      text: root.text
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: root.destructive ? Theme.error : root.menuColors ? root.menuColors.textColor : Theme.foreground
      font.pixelSize: Theme.fontBody
    }
    Text {
      text: root.hint
      color: root.menuColors ? root.menuColors.mutedTextColor : Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
    }
  }
}
