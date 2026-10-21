import QtQuick
import QtQuick.Effects
import "../"

Item {
  id: root
  property url source
  property string style: "square"
  property bool cdStyle: style === "cd"
  readonly property bool vinylStyle: style === "vinyl"
  readonly property bool discStyle: cdStyle || vinylStyle
  readonly property bool animatedStyle: discStyle || style === "cassette"
  property bool playing: false
  property real spinAngle: 0

  function syncRotation(): void {
    if (!animatedStyle || !visible) {
      spin.stop()
      spinAngle = 0
    } else if (playing) {
      if (spin.paused) spin.resume()
      else if (!spin.running) spin.start()
    } else if (spin.running && !spin.paused) spin.pause()
  }
  onCdStyleChanged: syncRotation()
  onStyleChanged: syncRotation()
  onAnimatedStyleChanged: syncRotation()
  onPlayingChanged: syncRotation()
  onVisibleChanged: syncRotation()
  Component.onCompleted: syncRotation()

  NumberAnimation {
    id: spin
    target: root
    property: "spinAngle"
    from: 0
    to: 360
    duration: 20000
    loops: Animation.Infinite
  }
  property color surfaceColor: Theme.surfaceHover
  property color accentColor: Theme.accent

  // The mask has a transparent centre, so the spindle hole reveals the widget.
  Canvas {
    id: discMask
    anchors.fill: parent
    visible: false
    antialiasing: true
    layer.enabled: true
    layer.smooth: true
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
      const ctx = getContext("2d")
      ctx.setTransform(1, 0, 0, 1, 0, 0)
      ctx.clearRect(0, 0, width, height)
      const radius = Math.max(0, Math.min(width, height) / 2 - 0.75)
      const edge = ctx.createRadialGradient(width / 2, height / 2, Math.max(0, radius - 1),
        width / 2, height / 2, radius)
      edge.addColorStop(0, "white")
      edge.addColorStop(1, "transparent")
      ctx.fillStyle = edge
      ctx.beginPath()
      ctx.arc(width / 2, height / 2, radius, 0, Math.PI * 2)
      ctx.fill()
      ctx.globalCompositeOperation = "destination-out"
      const holeRadius = radius * 0.09
      const hole = ctx.createRadialGradient(width / 2, height / 2, Math.max(0, holeRadius - 0.5),
        width / 2, height / 2, holeRadius + 0.5)
      hole.addColorStop(0, "white")
      hole.addColorStop(1, "transparent")
      ctx.fillStyle = hole
      ctx.beginPath()
      ctx.arc(width / 2, height / 2, holeRadius + 0.5, 0, Math.PI * 2)
      ctx.fill()
      ctx.globalCompositeOperation = "source-over"
    }
  }

  Item {
    id: artwork
    anchors.fill: parent
    visible: root.style === "square"
    rotation: root.discStyle ? root.spinAngle : 0
    layer.enabled: root.discStyle
    layer.smooth: true
    layer.mipmap: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: discMask
    }
    Rectangle {
      anchors.fill: parent
      antialiasing: true
      radius: root.discStyle ? width / 2 : Theme.cornerRadius
      color: root.vinylStyle ? "#141418" : root.surfaceColor
      clip: true
      Repeater {
        model: root.vinylStyle ? 14 : 0
        Rectangle {
          required property int index
          anchors.centerIn: parent
          width: parent.width * (0.44 + index * 0.038)
          height: width
          radius: width / 2
          color: "transparent"
          antialiasing: true
          border.width: 1
          border.color: index % 3 === 0 ? "#38383f" : "#24242c"
        }
      }
      Text {
        anchors.centerIn: parent
        text: "♫"
        font.pixelSize: parent.width * 0.28
        color: root.accentColor
        visible: image.status !== Image.Ready
      }
      Image {
        id: image
        anchors.centerIn: parent
        width: root.vinylStyle ? parent.width * 0.37 : parent.width
        height: width
        layer.enabled: root.vinylStyle
        layer.effect: MultiEffect { maskEnabled: true; maskSource: labelMask }
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
      }
      Rectangle {
        id: labelMask
        width: image.width
        height: width
        radius: width / 2
        color: "white"
        visible: false
        layer.enabled: true
      }
      Rectangle {
        anchors.centerIn: parent
        visible: root.vinylStyle
        width: parent.width * 0.12
        height: width
        radius: width / 2
        color: root.accentColor
        antialiasing: true
      }
      Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        visible: root.cdStyle
        antialiasing: true
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, width * 0.012)
        border.color: Qt.rgba(1, 1, 1, 0.5)
      }
      Rectangle {
        anchors.centerIn: parent
        visible: root.cdStyle
        antialiasing: true
        width: parent.width * 0.23
        height: width
        radius: width / 2
        color: Qt.rgba(0.82, 0.84, 0.88, 0.75)
        border.width: Math.max(1, parent.width * 0.007)
        border.color: Qt.rgba(1, 1, 1, 0.8)
      }
    }

  }
  Item {
    id: vinylSleeve
    anchors.fill: parent
    visible: root.discStyle
    Rectangle {
      id: record
      x: parent.width * 0.25
      anchors.verticalCenter: parent.verticalCenter
      width: sleeve.height
      height: width
      radius: width / 2
      antialiasing: true
      rotation: root.spinAngle
      border.width: 1
      border.color: root.cdStyle ? "#e3e5ec" : "#414146"
      gradient: Gradient {
        GradientStop { position: 0; color: root.cdStyle ? "#b7becd" : "#101012" }
        GradientStop { position: 0.22; color: root.cdStyle ? "#e2d7f0" : "#202025" }
        GradientStop { position: 0.35; color: root.cdStyle ? "#ecf7f9" : "#303035" }
        GradientStop { position: 0.49; color: root.cdStyle ? "#969eae" : "#171719" }
        GradientStop { position: 0.7; color: root.cdStyle ? "#dae8d1" : "#28282d" }
        GradientStop { position: 1; color: root.cdStyle ? "#b6c3d7" : "#101012" }
      }
      Repeater {
        model: root.cdStyle ? 3 : 19
        Rectangle {
          required property int index
          anchors.centerIn: parent
          width: parent.width * (root.cdStyle ? 0.88 + index * 0.035 : 0.38 + index * 0.032)
          height: width
          radius: width / 2
          color: "transparent"
          antialiasing: true
          border.width: 0.7
          border.color: root.cdStyle ? "#66969eac" : index % 3 === 0 ? "#48484d" : "#303035"
        }
      }
      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.35
        height: width
        radius: width / 2
        color: root.cdStyle ? "#b8bdc8" : root.accentColor
        antialiasing: true
        border.width: 1
        border.color: root.cdStyle ? "#f2f4fa" : Qt.darker(root.accentColor, 1.25)
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: parent.height * 0.21
          text: root.cdStyle ? "COMPACT DISC" : "STEREO"
          color: "#202024"
          font.pixelSize: Math.max(4, parent.width * 0.11)
          font.weight: Font.Bold
        }
        Rectangle {
          anchors.centerIn: parent
          width: parent.width * 0.12
          height: width
          radius: width / 2
          color: "#101012"
          antialiasing: true
        }
      }
    }
    Rectangle {
      id: sleeve
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width * 0.72
      height: width
      color: root.surfaceColor
      clip: true
      Image {
        id: sleeveImage
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
      }
      Text {
        anchors.centerIn: parent
        visible: sleeveImage.status !== Image.Ready
        text: "♫"
        color: root.accentColor
        font.pixelSize: parent.width * 0.3
      }
      Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: "#44ffffff"
      }
      Rectangle {
        anchors.right: parent.right
        width: 2
        height: parent.height
        color: "#55000000"
      }
    }
  }

  Rectangle {
    id: cassette
    visible: root.style === "cassette"
    anchors.centerIn: parent
    width: parent.width
    height: width * 0.635
    radius: width * 0.025
    color: "#202123"
    border.width: 1.5
    border.color: "#727477"
    antialiasing: true

    Rectangle {
      anchors.fill: parent
      anchors.margins: 3
      radius: cassette.radius * 0.8
      color: "transparent"
      border.width: 1
      border.color: "#101112"
    }
    // Fine moulded ribs run across the shell, beneath the inset panels.
    Repeater {
      model: 45
      Rectangle {
        required property int index
        x: cassette.width * 0.025
        y: cassette.height * (0.035 + index * 0.021)
        width: cassette.width * 0.95
        height: 0.65
        color: index % 2 ? "#44464a" : "#393b3e"
      }
    }
    Rectangle {
      x: parent.width * 0.055
      y: parent.height * 0.075
      width: parent.width * 0.89
      height: parent.height * 0.245
      color: "#161719"
      border.width: 1
      border.color: "#626468"
      clip: true
      Image {
        anchors.fill: parent
        anchors.margins: 1
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        opacity: 0.5
      }
      Rectangle { anchors.fill: parent; color: "#44000000" }
      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: cassette.width * 0.025
        text: "A"
        color: "#ecebe5"
        font.pixelSize: cassette.width * 0.065
        font.weight: Font.Bold
      }
      Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4
        text: "NORMAL POSITION • TYPE I"
        color: "#e0dfd9"
        font.pixelSize: Math.max(4, cassette.width * 0.023)
        font.weight: Font.DemiBold
      }
    }
    Rectangle {
      id: tapeWindow
      x: parent.width * 0.12
      y: parent.height * 0.335
      width: parent.width * 0.76
      height: parent.height * 0.235
      radius: 3
      color: "#0d0e0f"
      border.width: 1
      border.color: "#636569"
      // Brown tape and the rectangular viewing aperture between the spindles.
      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.28
        height: parent.height * 0.78
        color: "#3c302b"
        border.width: 1
        border.color: "#85817b"
        Rectangle {
          x: parent.width * 0.12
          width: parent.width * 0.31
          height: parent.height
          color: "#221d1b"
        }
        Rectangle {
          anchors.right: parent.right
          width: parent.width * 0.27
          height: parent.height
          color: "#51423b"
        }
        Rectangle {
          anchors.top: parent.top
          width: parent.width
          height: 2
          color: "#776e65"
        }
      }
      Repeater {
        model: 2
        Rectangle {
          required property int index
          x: parent.width * (index === 0 ? 0.085 : 0.705)
          anchors.verticalCenter: parent.verticalCenter
          width: parent.height * 0.92
          height: width
          radius: width / 2
          color: "#141517"
          border.width: 1.2
          border.color: "#b1b2af"
          antialiasing: true
          rotation: root.spinAngle * 4
          Rectangle {
            anchors.fill: parent
            anchors.margins: parent.width * 0.12
            radius: width / 2
            color: "#08090a"
            border.width: 1
            border.color: "#4d5053"
            antialiasing: true
          }
          Repeater {
            model: 6
            Item {
              required property int index
              anchors.fill: parent
              rotation: index * 60
              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.12
                width: parent.width * 0.13
                height: parent.height * 0.18
                radius: 0.8
                color: "#c5c6bf"
                antialiasing: true
              }
            }
          }
        }
      }
    }
    Rectangle {
      x: parent.width * 0.055
      y: parent.height * 0.60
      width: parent.width * 0.89
      height: parent.height * 0.14
      color: "#bc3d38"
      border.width: 1
      border.color: "#e8a49b"
      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 5
        text: "ATLAS"
        color: "#f5dfd8"
        font.pixelSize: cassette.width * 0.036
        font.weight: Font.Bold
        font.letterSpacing: 1
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 5
        text: "STEREO  /  60"
        color: "#f5dfd8"
        font.pixelSize: cassette.width * 0.028
      }
    }
    Canvas {
      id: headPlate
      x: parent.width * 0.16
      y: parent.height * 0.775
      width: parent.width * 0.68
      height: parent.height * 0.21
      antialiasing: true
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.beginPath()
        ctx.moveTo(width * 0.08, 1)
        ctx.lineTo(width * 0.92, 1)
        ctx.lineTo(width - 1, height - 1)
        ctx.lineTo(1, height - 1)
        ctx.closePath()
        ctx.fillStyle = "#292b2e"
        ctx.fill()
        ctx.strokeStyle = "#626569"
        ctx.lineWidth = 1
        ctx.stroke()
      }
      Repeater {
        model: 4
        Rectangle {
          required property int index
          x: parent.width * [0.12, 0.27, 0.66, 0.81][index]
          y: parent.height * (index === 0 || index === 3 ? 0.59 : 0.45)
          width: cassette.width * (index === 0 || index === 3 ? 0.045 : 0.033)
          height: width
          radius: width / 2
          color: "#08090a"
          border.width: 0.6
          border.color: "#484a4e"
          antialiasing: true
        }
      }
    }
    Repeater {
      model: 4
      Rectangle {
        required property int index
        x: (index % 2 === 0 ? 0.022 : 0.95) * cassette.width
        y: (index < 2 ? 0.035 : 0.915) * cassette.height
        width: cassette.width * 0.027
        height: width
        radius: width / 2
        color: "#696968"
        border.width: 0.7
        border.color: "#101112"
        antialiasing: true
        Rectangle {
          anchors.centerIn: parent
          width: parent.width * 0.65
          height: 1
          rotation: 30
          color: "#161719"
        }
      }
    }
  }

}
