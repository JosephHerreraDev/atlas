import Quickshell
import Quickshell.Hyprland
import QtQuick
import ".."

PopupWindow {
  id: root

  required property Item anchorItem
  property real gap: 8
  property real padding: 10
  property bool shown: false
  property real slideOffset: 0
  property bool presentationVisible: false

  readonly property bool shouldShow: root.shown
    && PopupState.activePopup === root

  readonly property Item contentItem: contentHost.children.length > 0
    ? contentHost.children[0]
    : null

  default property alias content: contentHost.data

  anchor {
    item: root.anchorItem
    rect.x: root.anchorItem ? root.anchorItem.width : 0
    rect.y: (root.anchorItem ? root.anchorItem.height : 0) + root.gap
    rect.width: 1
    rect.height: 1
    edges: Edges.Top | Edges.Right
    gravity: Edges.Bottom | Edges.Left
  }

  implicitHeight: (contentItem ? contentItem.implicitHeight : 0) + root.padding * 2
  visible: root.presentationVisible
  color: "transparent"
  grabFocus: false

  onShownChanged: {
    if (shown)
      PopupState.activePopup = root
    else if (PopupState.activePopup === root)
      PopupState.activePopup = null
  }

  onShouldShowChanged: {
    if (shouldShow) {
      closeAnimation.stop()
      presentationVisible = true
      slideOffset = -12
      openAnimation.restart()
    } else if (presentationVisible) {
      openAnimation.stop()
      closeAnimation.restart()
    }
  }

  HyprlandFocusGrab {
    windows: [root]
    active: root.shouldShow

    onCleared: {
      if (PopupState.activePopup === root)
        PopupState.activePopup = null
    }
  }

  Shortcut {
    sequence: "Escape"
    context: Qt.WindowShortcut
    enabled: root.shouldShow

    onActivated: {
      if (PopupState.activePopup === root)
        PopupState.activePopup = null
    }
  }

  NumberAnimation {
    id: openAnimation

    target: root
    property: "slideOffset"
    to: 0
    duration: 160
    easing.type: Easing.OutCubic
  }

  NumberAnimation {
    id: closeAnimation

    target: root
    property: "slideOffset"
    to: -12
    duration: 140
    easing.type: Easing.InCubic

    onFinished: {
      if (!root.shouldShow)
        root.presentationVisible = false
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.color0
    border.color: Theme.foreground
    border.width: 1
    radius: 6
    transform: Translate {
      y: root.slideOffset
    }

    Item {
      id: contentHost

      anchors.fill: parent
      anchors.margins: root.padding
    }
  }
}

