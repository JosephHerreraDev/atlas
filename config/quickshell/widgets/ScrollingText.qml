import QtQuick

Item {
  id: root

  property alias text: label.text
  property alias color: label.color
  property alias font: label.font
  property bool scrollingEnabled: true
  property int horizontalAlignment: Text.AlignLeft
  readonly property real overflow: Math.max(0, label.implicitWidth - width)
  implicitHeight: label.implicitHeight
  implicitWidth: label.implicitWidth
  clip: true

  Accessible.role: Accessible.StaticText
  Accessible.name: text

  function resetScroll(): void {
    scroll.stop()
    label.x = overflow > 0 || horizontalAlignment !== Text.AlignHCenter
      ? 0 : Math.max(0, (width - label.implicitWidth) / 2)
    if (scrollingEnabled && visible && width > 0 && overflow > 0)
      scroll.start()
  }

  onTextChanged: Qt.callLater(resetScroll)
  onOverflowChanged: Qt.callLater(resetScroll)
  onVisibleChanged: Qt.callLater(resetScroll)
  onScrollingEnabledChanged: Qt.callLater(resetScroll)
  onHorizontalAlignmentChanged: Qt.callLater(resetScroll)
  Component.onCompleted: Qt.callLater(resetScroll)

  Text {
    id: label
    wrapMode: Text.NoWrap
  }

  SequentialAnimation {
    id: scroll
    loops: Animation.Infinite
    PauseAnimation { duration: 1200 }
    NumberAnimation {
      target: label
      property: "x"
      from: 0
      to: -root.overflow
      duration: Math.max(1600, root.overflow * 35)
      easing.type: Easing.Linear
    }
    PauseAnimation { duration: 1600 }
    PropertyAction { target: label; property: "x"; value: 0 }
  }
}
