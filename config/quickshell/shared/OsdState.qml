pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  property string iconType: "volume"
  property real value: 0
  property bool shown: false

  function show(iconType, value) {
    root.iconType = iconType
    root.value = Math.max(0, Math.min(1, value))
    root.shown = true
    hideTimer.restart()
  }

  Timer {
    id: hideTimer

    interval: 1500
    onTriggered: root.shown = false
  }
}
