import QtQuick

Item {
  id: visualizer

  property var spectrum: []
  property string style: "Rounded"
  property color accent: "white"
  readonly property int barCount: 24
  readonly property real gap: 3
  visible: style !== "Off"
  clip: true

  Repeater {
    model: visualizer.style === "Off" ? 0 : visualizer.barCount
    Item {
      id: bar
      required property int index
      readonly property real level: Math.max(0, Math.min(1,
        (visualizer.spectrum[Math.floor(index
          * visualizer.spectrum.length / visualizer.barCount)] || 0) / 100))
      property real amplitude: Math.max(2, (height - 4) * level)
      x: index * (width + visualizer.gap)
      width: Math.max(1, (visualizer.width
        - (visualizer.barCount - 1) * visualizer.gap) / visualizer.barCount)
      height: visualizer.height
      Behavior on amplitude {
        NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
      }

      Rectangle {
        width: parent.width
        height: bar.amplitude
        y: visualizer.style === "Mirror"
          ? (parent.height - height) / 2 : parent.height - height
        visible: visualizer.style !== "Dots"
        radius: visualizer.style === "Squared" || visualizer.style === "Outline"
          ? 0 : width / 2
        color: visualizer.style === "Outline" ? "transparent" : visualizer.accent
        border.width: visualizer.style === "Outline" ? 1 : 0
        border.color: visualizer.accent
        opacity: 0.5 + bar.level * 0.5
      }

      Repeater {
        model: visualizer.style === "Dots" ? Math.max(1,
          Math.floor(bar.height / (bar.width + visualizer.gap))) : 0
        Rectangle {
          required property int index
          width: bar.width
          height: width
          radius: width / 2
          y: bar.height - height - index * (height + visualizer.gap)
          color: visualizer.accent
          opacity: y + height >= bar.height - bar.amplitude ? 0.9 : 0.10
          Behavior on opacity { NumberAnimation { duration: 70 } }
        }
      }
    }
  }
}
