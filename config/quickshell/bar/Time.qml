pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  function displayPattern(): string {
    if (BarStyle.timeFormat === "time-seconds") return "hh:mm:ss"
    if (BarStyle.timeFormat === "day-time") return "ddd  hh:mm"
    if (BarStyle.timeFormat === "date-time") return "MMM d  ·  hh:mm"
    if (BarStyle.timeFormat === "day-date-time")
      return "ddd, MMM d  ·  hh:mm"
    return "hh:mm"
  }

  function sideDisplayPattern(): string {
    if (BarStyle.timeFormat === "time-seconds") return "hh:\nmm:\nss"
    if (BarStyle.timeFormat === "day-time") return "ddd\nhh:\nmm"
    if (BarStyle.timeFormat === "date-time") return "MMM\nd\nhh:\nmm"
    if (BarStyle.timeFormat === "day-date-time")
      return "ddd\nMMM\nd\nhh:\nmm"
    return "hh:\nmm"
  }

  readonly property string time: {
    Qt.formatDateTime(clock.date, displayPattern())
  }
  readonly property string sideTime: Qt.formatDateTime(clock.date,
    sideDisplayPattern())

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
