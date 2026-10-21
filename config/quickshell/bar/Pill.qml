import QtQuick
import ".."

Item {
  id: wrapper

  property bool followsBarStyle: true
  property real margin: followsBarStyle && !BarStyle.pillMode
    ? 0 : Theme.spaceXxs
  property real leftPadding: margin
  property real rightPadding: margin
  property real backgroundOpacity: 1
  property bool borderEnabled: true
  property bool backgroundEnabled: true
  required default property Item child

  implicitWidth: child.implicitWidth + leftPadding + rightPadding
  implicitHeight: child.implicitHeight + margin * 2

  Rectangle {
    id: bg

    anchors.fill: parent

    color: !wrapper.backgroundEnabled || (wrapper.followsBarStyle && !BarStyle.pillMode)
      ? "transparent"
      : Qt.rgba(
        Theme.surface.r,
        Theme.surface.g,
        Theme.surface.b,
        wrapper.backgroundOpacity)
    radius: Theme.radiusSm
    border.color: Theme.borderStrong
    border.width: wrapper.backgroundEnabled && wrapper.borderEnabled
      && (!wrapper.followsBarStyle || BarStyle.pillMode)
      ? Theme.borderWidth : 0

    Item {
      anchors.fill: parent
      anchors.topMargin: wrapper.margin
      anchors.bottomMargin: wrapper.margin
      anchors.leftMargin: wrapper.leftPadding
      anchors.rightMargin: wrapper.rightPadding
      data: [child]
    }
  }
}
