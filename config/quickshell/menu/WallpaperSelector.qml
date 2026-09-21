import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../"

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

  readonly property int animationDuration: 180
  readonly property int selectionDuration: 240

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
    Quickshell.execDetached(["wallpaper-set", path])
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
        color: "#66000000"
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
        anchors {
          horizontalCenter: parent.horizontalCenter
          bottom: parent.bottom
          bottomMargin: 16
        }
        width: Math.min(820, window.width - 48)
        height: Math.min(300, window.height * 0.34)
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.97
        radius: 8
        color: Theme.color0
        border.width: 1
        border.color: Theme.color2

        transform: Translate {
          y: root.opened ? 0 : 18

          Behavior on y {
            NumberAnimation {
              duration: root.animationDuration
              easing.type: Easing.OutCubic
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
          NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

        ColumnLayout {
          id: content
          anchors.fill: parent
          spacing: 10
          opacity: root.opened ? 1 : 0

          transform: Translate {
            y: root.opened ? 0 : 6
            Behavior on y {
              NumberAnimation {
                duration: root.animationDuration + 40
                easing.type: Easing.OutCubic
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
              color: Theme.color6
              font.pixelSize: 18
              font.weight: Font.DemiBold
            }
            Text {
              text: root.wallpapers.length + " available"
              color: Theme.color4
              font.pixelSize: 12
            }
          }

          Text {
            visible: root.wallpapers.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: listProcess.running ? "Loading wallpapers..." : "No wallpapers available"
            color: Theme.color4
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          ListView {
            id: wallpaperList
            readonly property real cardWidth: Math.min(560, width * 0.68)
            readonly property real sidePeek: Math.max(0, (width - cardWidth) / 2)

            visible: root.wallpapers.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            orientation: ListView.Horizontal
            model: root.wallpapers
            currentIndex: root.selectedIndex
            spacing: 10
            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.SnapOneItem
            highlightMoveDuration: root.selectionDuration
            highlightResizeDuration: root.selectionDuration
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: sidePeek
            preferredHighlightEnd: preferredHighlightBegin + cardWidth

            header: Item {
              width: Math.max(0, wallpaperList.sidePeek - wallpaperList.spacing)
              height: 1
            }

            footer: Item {
              width: Math.max(0, wallpaperList.sidePeek - wallpaperList.spacing)
              height: 1
            }

            onCurrentIndexChanged: {
              if (currentIndex >= 0 && root.selectedIndex !== currentIndex)
                root.selectedIndex = currentIndex
            }

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                root.moveSelection(1)
                event.accepted = true
              } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                root.moveSelection(-1)
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
              height: wallpaperList.height - 16
              anchors.verticalCenter: parent.verticalCenter
              z: selected ? 2 : (hovered ? 1 : 0)
              radius: 8
              color: selected || hovered ? Theme.color2 : Theme.color1
              opacity: selected ? 1 : (hovered ? 0.92 : 0.72)
              scale: selected ? 1 : (hovered ? 0.97 : 0.94)
              clip: true

              Behavior on color {
                ColorAnimation { duration: root.selectionDuration }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.selectionDuration; easing.type: Easing.OutCubic }
              }
              Behavior on scale {
                NumberAnimation { duration: root.selectionDuration; easing.type: Easing.OutBack }
              }

              Image {
                anchors.fill: parent
                source: root.imageSource(wallpaperCard.modelData)
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
                opacity: status === Image.Ready ? 1 : 0
                scale: wallpaperCard.selected ? 1 : 1.04

                Behavior on opacity {
                  NumberAnimation { duration: root.animationDuration }
                }
                Behavior on scale {
                  NumberAnimation { duration: root.selectionDuration; easing.type: Easing.OutCubic }
                }
              }

              Rectangle {
                anchors.fill: parent
                z: 2
                radius: parent.radius
                color: "transparent"
                border.width: wallpaperCard.selected ? 2 : 1
                border.color: wallpaperCard.selected ? Theme.color8
                  : (wallpaperCard.hovered ? Theme.color9 : Theme.color2)

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
