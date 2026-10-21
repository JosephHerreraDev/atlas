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
  property real backgroundOpacity: 1
  property bool openAbove: false
  // Screen edge occupied by the control which owns this popup. The popup
  // opens inward, away from that edge. Keep openAbove as a compatibility
  // shorthand for callers which only distinguish top and bottom bars.
  property string edge: openAbove ? "bottom" : "top"
  property bool presentationVisible: false
  property real transitionProgress: 0

  readonly property bool shouldShow: root.shown
    && PopupState.activePopup === root

  readonly property Item contentItem: contentHost.children.length > 0
    ? contentHost.children[0]
    : null

  default property alias content: contentHost.data

  anchor {
    item: root.anchorItem
    rect.x: root.edge === "left"
      ? (root.anchorItem ? root.anchorItem.width : 0) + root.gap
      : root.edge === "right" ? -root.gap
      : (root.anchorItem ? root.anchorItem.width : 0)
    rect.y: root.edge === "left" || root.edge === "right"
      ? Math.round((root.anchorItem ? root.anchorItem.height : 0) / 2)
      : root.edge === "bottom" ? -root.gap
      : (root.anchorItem ? root.anchorItem.height : 0) + root.gap
    rect.width: 1
    rect.height: 1
    edges: root.edge === "left" ? Edges.Left
      : root.edge === "right" ? Edges.Right
      : (root.edge === "bottom" ? Edges.Bottom : Edges.Top) | Edges.Right
    gravity: root.edge === "left" ? Edges.Right
      : root.edge === "right" ? Edges.Left
      : (root.edge === "bottom" ? Edges.Top : Edges.Bottom) | Edges.Left
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
      if (!presentationVisible) {
        transitionProgress = 0
        presentationVisible = true
      }
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

  SpringAnimation {
    id: openAnimation

    target: root
    property: "transitionProgress"
    to: 1
    spring: Theme.motionSpring
    damping: Theme.motionDamping
    epsilon: Theme.motionEpsilon
  }

  SpringAnimation {
    id: closeAnimation

    target: root
    property: "transitionProgress"
    to: 0
    spring: Theme.motionSpring
    damping: Theme.motionDamping
    epsilon: Theme.motionEpsilon

    onFinished: {
      if (!root.shouldShow)
        root.presentationVisible = false
    }
  }

  Rectangle {
    anchors.fill: parent
    enabled: root.shouldShow
    opacity: Math.max(0, Math.min(1, root.transitionProgress))
    scale: 0.96 + root.transitionProgress * 0.04
    transformOrigin: root.edge === "left" ? Item.Left
      : root.edge === "right" ? Item.Right
      : root.edge === "bottom" ? Item.BottomRight : Item.TopRight
    color: Qt.rgba(
      Theme.surface.r,
      Theme.surface.g,
      Theme.surface.b,
      root.backgroundOpacity)
    border.color: Theme.text
    border.width: Theme.borderWidth
    radius: Theme.radiusMd
    transform: Translate {
      x: (root.edge === "left" ? -8 : root.edge === "right" ? 8 : 0)
        * (1 - root.transitionProgress)
      y: (root.edge === "bottom" ? 8 : root.edge === "top" ? -8 : 0)
        * (1 - root.transitionProgress)
    }

    Item {
      id: contentHost

      anchors.fill: parent
      anchors.margins: root.padding
    }
  }
}
