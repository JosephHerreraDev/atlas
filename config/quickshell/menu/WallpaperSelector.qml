import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../"
import "../bar" as Bar

Scope {
  id: root

  required property string ipcTarget
  required property string mode
  required property string title
  property bool opened: false
  property bool mounted: false
  property var wallpapers: []
  property int selectedIndex: -1
  property int focusRequest: 0

  readonly property int animationDuration: Theme.motionNormal + 20
  readonly property int selectionDuration: Theme.motionSlow

  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function open(): void {
    MenuState.activate(root)
    hideTimer.stop()
    mounted = true
    opened = false
    refresh()
    Qt.callLater(function() {
      if (root.mounted) {
        opened = true
        focusRequest += 1
      }
    })
  }

  function close(): void {
    MenuState.deactivate(root)
    opened = false
    hideTimer.restart()
  }

  function toggle(): void { opened ? close() : open() }

  function refresh(): void {
    if (!listProcess.running)
      listProcess.exec(["wallpaper-list", mode])
  }

  function category(path): string {
    const parts = path.split("/")
    return parts.length > 1 ? parts[parts.length - 2] : ""
  }

  function imageSource(path): string {
    return "file://" + path.split("/").map(encodeURIComponent).join("/")
  }

  function moveSelection(delta): void {
    if (wallpapers.length === 0)
      return
    selectedIndex = Math.max(0, Math.min(selectedIndex + delta,
      wallpapers.length - 1))
  }

  function applyWallpaper(path): void {
    if (!path)
      return
    close()
    const command = root.mode === "theme"
      ? ["wallpaper-set", "--no-theme", path]
      : ["wallpaper-set", path]
    Quickshell.execDetached(command)
  }

  Process {
    id: listProcess
    stdout: StdioCollector {
      onStreamFinished: {
        root.wallpapers = text.split("\n").filter(function(path) {
          return path.length > 0
        })
        root.selectedIndex = root.wallpapers.length > 0 ? 0 : -1
      }
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Timer {
    id: hideTimer
    interval: root.animationDuration
    repeat: false
    onTriggered: if (!root.opened) root.mounted = false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: root.mounted && root.screenFocused(modelData)
      color: "#00000000"
      aboveWindows: true
      focusable: true
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.namespace: root.ipcTarget
      anchors { top: true; bottom: true; left: true; right: true }

      function focusCarousel(): void {
        Qt.callLater(function() { wallpaperList.forceActiveFocus() })
      }
      onVisibleChanged: if (visible) focusCarousel()

      Connections {
        target: root
        function onFocusRequestChanged(): void {
          if (window.visible) window.focusCarousel()
        }
      }

      Rectangle {
        anchors.fill: parent
        // Keep the desktop and its current wallpaper legible behind the picker.
        color: "#24000000"
        opacity: root.opened ? 1 : 0

        Behavior on opacity {
          NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        MouseArea { anchors.fill: parent; enabled: root.opened; onClicked: root.close() }
      }

      Rectangle {
        id: panel
        readonly property string horizontalPlacement: Placement.horizontal(Placement.wallpaperSelector)
        readonly property string verticalPlacement: Placement.vertical(Placement.wallpaperSelector)
        readonly property bool sidePlacement: horizontalPlacement !== "center"
        width: sidePlacement
          ? Math.min(440, window.width - 48)
          : Math.min(920, window.width - 48)
        height: sidePlacement
          ? Math.min(680, window.height - 48 - Bar.BarStyle.topClearance
            - Bar.BarStyle.bottomClearance)
          : Math.min(460, window.height * 0.52)
        x: Placement.itemX(Placement.wallpaperSelector, window.width, width, Placement.edgeMargin)
        y: Placement.itemY(Placement.wallpaperSelector, window.height, height,
          Placement.edgeMargin + Bar.BarStyle.topClearance,
          Placement.edgeMargin + Bar.BarStyle.bottomClearance)
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.97
        radius: Theme.radiusLg
        color: Qt.rgba(
          Theme.surface.r,
          Theme.surface.g,
          Theme.surface.b,
          Theme.popupOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.border

        transform: Translate {
          y: root.opened ? 0 : 18

          Behavior on y {
            SpringAnimation {
              spring: Theme.motionSpring
              damping: Theme.motionDamping
              epsilon: Theme.motionEpsilon
            }
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        Behavior on scale {
          SpringAnimation {
            spring: Theme.motionSpring
            damping: Theme.motionDamping
            epsilon: Theme.motionEpsilon
          }
        }

        MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

        ColumnLayout {
          id: content
          anchors.fill: parent
          spacing: Theme.spaceSm
          opacity: root.opened ? 1 : 0

          transform: Translate {
            y: root.opened ? 0 : 6
            Behavior on y {
              SpringAnimation {
                spring: Theme.motionSpring
                damping: Theme.motionDamping
                epsilon: Theme.motionEpsilon
              }
            }
          }

          Behavior on opacity {
            NumberAnimation {
              duration: root.animationDuration + 40
              easing.type: Easing.OutCubic
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 12
            Text {
              Layout.fillWidth: true
              text: root.title
              color: Theme.foreground
              font.pixelSize: Theme.fontDisplay
              font.weight: Theme.weightStrong
            }
            Text {
              text: root.wallpapers.length + " available"
              color: Theme.foregroundMuted
              font.pixelSize: Theme.fontCaption
            }
          }

          Text {
            visible: root.wallpapers.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: listProcess.running ? "Loading wallpapers..." : "No wallpapers available"
            color: Theme.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          GridView {
            id: wallpaperList
            readonly property int columns: panel.sidePlacement
              ? (width >= 390 ? 2 : 1)
              : Math.max(2, Math.min(4, Math.floor(width / 190)))
            readonly property real gridGap: Theme.spaceSm
            readonly property real cardWidth: Math.floor(
              (width - Theme.spaceMd * 2 - gridGap * (columns - 1)) / columns)
            readonly property real cardHeight: Math.round(cardWidth * 0.625)

            visible: root.wallpapers.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Theme.spaceMd
            Layout.rightMargin: Theme.spaceMd
            Layout.bottomMargin: Theme.spaceMd
            clip: true
            focus: true
            model: root.wallpapers
            currentIndex: root.selectedIndex
            cellWidth: cardWidth + gridGap
            cellHeight: cardHeight + gridGap
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: root.selectionDuration
            keyNavigationWraps: true

            onCurrentIndexChanged: {
              if (currentIndex >= 0 && root.selectedIndex !== currentIndex)
                root.selectedIndex = currentIndex
            }

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Right) {
                root.moveSelection(1)
                event.accepted = true
              } else if (event.key === Qt.Key_Left) {
                root.moveSelection(-1)
                event.accepted = true
              } else if (event.key === Qt.Key_Down) {
                root.moveSelection(wallpaperList.columns)
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                root.moveSelection(-wallpaperList.columns)
                event.accepted = true
              } else if (event.key === Qt.Key_Return
                  || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (root.selectedIndex >= 0)
                  root.applyWallpaper(root.wallpapers[root.selectedIndex])
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              }
            }

            delegate: Rectangle {
              id: wallpaperCard
              required property int index
              required property string modelData
              readonly property bool selected: index === root.selectedIndex
              readonly property bool hovered: cardMouse.containsMouse

              width: wallpaperList.cardWidth
              height: wallpaperList.cardHeight
              z: selected ? 2 : (hovered ? 1 : 0)
              radius: Theme.radiusMd
              color: Theme.surfaceHover
              opacity: selected ? 1 : (hovered ? 0.96 : 0.86)
              scale: selected ? 1 : (hovered ? 0.985 : 0.97)
              clip: true

              Behavior on color {
                ColorAnimation { duration: root.selectionDuration }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.selectionDuration; easing.type: Easing.OutCubic }
              }
              Behavior on scale {
                SpringAnimation {
                  spring: Theme.motionSpring
                  damping: Theme.motionDamping
                  epsilon: Theme.motionEpsilon
                }
              }

              Image {
                anchors.fill: parent
                source: root.imageSource(wallpaperCard.modelData)
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
                opacity: status === Image.Ready ? 1 : 0
                scale: wallpaperCard.hovered ? 1.035 : 1

                Behavior on opacity {
                  NumberAnimation { duration: root.animationDuration }
                }
                Behavior on scale {
                  SpringAnimation {
                    spring: Theme.motionSpring
                    damping: Theme.motionDamping
                    epsilon: Theme.motionEpsilon
                  }
                }
              }

              Rectangle {
                anchors.fill: parent
                z: 2
                radius: parent.radius
                color: "transparent"
                border.width: wallpaperCard.selected
                  ? 3 : Theme.borderWidth
                border.color: wallpaperCard.selected ? Theme.accent
                  : (wallpaperCard.hovered ? Theme.accent : Theme.border)

                Behavior on border.color {
                  ColorAnimation { duration: root.selectionDuration }
                }
              }

              MouseArea {
                id: cardMouse
                anchors.fill: parent
                z: 3
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (wallpaperCard.selected)
                    root.applyWallpaper(wallpaperCard.modelData)
                  else
                    root.selectedIndex = wallpaperCard.index
                }
              }
            }
          }
        }
      }

      Shortcut { sequence: "Escape"; enabled: root.opened; onActivated: root.close() }
    }
  }
}
