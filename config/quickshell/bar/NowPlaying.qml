import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import "../"
import "../shared/"
import "../widgets/"

Pill {
  id: root

  property var spectrum: Array(12).fill(0)
  readonly property var player: {
    const players = Mpris.players.values
    return players.find(function(candidate) { return candidate.isPlaying })
      || players[0] || null
  }
  readonly property bool present: player !== null
  readonly property bool playing: present && player.isPlaying

  visible: WidgetState.nowPlayingVisible && present
  implicitWidth: visible ? content.implicitWidth + leftPadding + rightPadding : 0
  borderEnabled: BarStyle.pillMode

  function acceptSpectrum(line): void {
    const values = String(line).trim().split(";")
      .map(function(value) { return Math.max(0, Math.min(100, Number(value) || 0)) })
    if (values.length >= 8)
      spectrum = values
  }

  Item {
    id: content
    implicitWidth: 68 + labelViewport.width
    implicitHeight: Theme.barControlHeight

    Process {
      command: ["cava", "-p", (Quickshell.env("HOME") || "")
        + "/.config/quickshell/widgets/cava.conf"]
      running: root.present && root.playing
      stdout: SplitParser {
        onRead: function(line) { root.acceptSpectrum(line) }
      }
    }

    MouseArea {
      id: playerMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: WidgetState.toggleWidget("player")
    }

    PopupWindow {
      id: trackPopup

      anchor {
        item: root
        rect.x: BarStyle.position === "left" ? root.width + 8
          : BarStyle.position === "right" ? -8 : Math.round(root.width / 2)
        rect.y: BarStyle.position === "left" || BarStyle.position === "right"
          ? Math.round(root.height / 2)
          : BarStyle.position === "bottom" ? -8 : root.height + 8
        rect.width: 1
        rect.height: 1
        edges: BarStyle.position === "left" ? Edges.Left
          : BarStyle.position === "right" ? Edges.Right
          : BarStyle.position === "bottom" ? Edges.Bottom : Edges.Top
        gravity: BarStyle.position === "left" ? Edges.Right
          : BarStyle.position === "right" ? Edges.Left
          : BarStyle.position === "bottom" ? Edges.Top : Edges.Bottom
      }

      implicitWidth: 320
      implicitHeight: popupContent.implicitHeight + 16
      visible: playerMouse.containsMouse && root.present
      color: "transparent"
      grabFocus: false

      Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.borderFocus

        Column {
          id: popupContent
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          anchors.topMargin: 8
          anchors.bottomMargin: 8
          spacing: 8

          Row {
            id: popupHeader
            width: parent.width
            height: 68
            spacing: 12

            Rectangle {
              id: albumThumb
              width: 68
              height: 68
              radius: Theme.radiusSm
              color: Theme.surfaceHover
              clip: true
              border.width: Theme.borderWidth
              border.color: Theme.border

              Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                mipmap: true
              }
              Text {
                anchors.centerIn: parent
                visible: !root.player || !root.player.trackArtUrl
                text: "♫"
                color: Theme.foregroundMuted
                font.pixelSize: 28
              }
            }

            Column {
              width: popupHeader.width - albumThumb.width - popupHeader.spacing
              anchors.verticalCenter: parent.verticalCenter
              spacing: 4

              Text {
                width: parent.width
                text: root.player ? (root.player.trackTitle || "Unknown title") : ""
                color: Theme.foreground
                elide: Text.ElideRight
                font.pixelSize: Theme.fontTitle
                font.weight: Font.Bold
              }
              Text {
                width: parent.width
                text: root.player ? (root.player.trackArtist || "Unknown artist") : ""
                color: Theme.accent
                elide: Text.ElideRight
                font.pixelSize: Theme.fontBody
                font.weight: Font.DemiBold
              }
              Text {
                width: parent.width
                text: root.player && root.player.trackAlbum
                  ? root.player.trackAlbum : "Unknown album"
                color: Theme.foregroundMuted
                elide: Text.ElideRight
                font.pixelSize: Theme.fontCaption
              }
            }
          }


        }
      }
    }

    Row {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: 9
      anchors.rightMargin: 9
      spacing: 8

      Row {
        id: visualizer
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 16
        spacing: 2

        Repeater {
          model: 8
          Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: 3
            height: root.playing
              ? Math.max(2, visualizer.height
                * (root.spectrum[Math.floor(index
                  * root.spectrum.length / 8)] || 0) / 100)
              : 2
            radius: 0
            color: Theme.accent
            Behavior on height {
              NumberAnimation { duration: 65; easing.type: Easing.OutCubic }
            }
          }
        }
      }

      Item {
        id: labelViewport
        width: Math.min(150, songLabel.implicitWidth)
        height: Theme.barControlHeight
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        Text {
          id: songLabel
          anchors.verticalCenter: parent.verticalCenter
          x: 0
          text: {
            if (!root.player)
              return ""
            return root.player.trackTitle || "Unknown title"
          }
          color: Theme.foreground
          font.pixelSize: Theme.fontCaption
          font.weight: Font.DemiBold

          onTextChanged: {
            Qt.callLater(function() {
              if (songLabel.implicitWidth > labelViewport.width) {
                songLabel.x = 0
                marquee.restart()
              } else {
                marquee.stop()
                songLabel.x = 0
              }
            })
          }
        }

        SequentialAnimation {
          id: marquee
          loops: 1

          PauseAnimation { duration: 1000 }
          NumberAnimation {
            target: songLabel
            property: "x"
            from: 0
            to: labelViewport.width - songLabel.implicitWidth
            duration: Math.max(1800,
              (songLabel.implicitWidth - labelViewport.width) * 35)
            easing.type: Easing.Linear
          }
          PauseAnimation { duration: 1200 }
          NumberAnimation {
            target: songLabel
            property: "x"
            to: 0
            duration: Math.max(1800,
              (songLabel.implicitWidth - labelViewport.width) * 35)
            easing.type: Easing.Linear
          }
        }
      }
    }
  }
}
