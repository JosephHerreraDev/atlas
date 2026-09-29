import QtQuick
import QtQuick.Layouts
import ".."

Column {
  id: root

  required property bool shown
  property int animationDuration: Theme.motionQuick

  enabled: shown
  visible: shown
  opacity: shown ? 1 : 0

  onShownChanged: {
    if (shown)
      Qt.callLater(function() { root.forceActiveFocus() })
  }

  Behavior on opacity {
    NumberAnimation {
      duration: root.animationDuration
      easing.type: Easing.OutCubic
    }
  }

}
