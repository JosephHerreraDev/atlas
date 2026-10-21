import QtQuick
import QtQuick.Controls as Controls
import "../"

Controls.Menu {
  id: root
  property color surfaceColor: Theme.surface
  property color hoverColor: Theme.surfaceHover
  property color textColor: Theme.foreground
  property color mutedTextColor: Theme.foregroundMuted
  property color accentColor: Theme.accent
  property color borderColor: Theme.borderFocus
  property color separatorColor: Theme.border
  width: 248
  padding: 6
  margins: 8
  overlap: 0
  modal: true
  dim: false
  closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
  background: Rectangle {
    color: root.surfaceColor
    radius: Theme.radiusMd
    border.width: Theme.borderWidth
    border.color: root.borderColor
  }
}
