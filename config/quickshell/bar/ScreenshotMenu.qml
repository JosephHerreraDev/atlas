import Quickshell.Widgets
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../"
import "../shared/"

FocusScope {
  id: root
  required property bool screenshotVisible
  required property bool recordingVisible
  required property bool operationBusy
  readonly property bool presented: screenshotVisible || recordingVisible
  property int captureMode: 0
  property bool openAbove: false
  readonly property real dropdownExtent: modePicker.popup.visible ? modePicker.popup.height + 6 : 0
  readonly property var modeIcons: ["../assets/screenshot-region.svg", "../assets/screenshot-window.svg", "../assets/screenshot-display.svg"]
  readonly property var screenshotModes: [ClockState.captureRegionMode, ClockState.captureWindowMode, ClockState.captureDisplayMode]
  readonly property var recordingModes: [ClockState.recordRegionMode, ClockState.recordWindowMode, ClockState.recordDisplayMode]
  signal captureRequested(string mode)
  signal recordingMenuRequested()
  signal screenshotMenuRequested()
  signal closeRequested()
  implicitWidth: toolbar.implicitWidth
  implicitHeight: 44

  function capture(): void {
    if (!operationBusy)
      captureRequested((recordingVisible ? recordingModes : screenshotModes)[captureMode])
  }
  Shortcut { sequence: "Escape"; enabled: root.presented; onActivated: root.closeRequested() }
  Shortcut { sequence: "Return"; enabled: root.presented && !root.operationBusy && !modePicker.popup.visible; onActivated: root.capture() }
  Shortcut { sequence: "1"; enabled: root.presented; onActivated: { root.captureMode = 0; root.capture() } }
  Shortcut { sequence: "2"; enabled: root.presented; onActivated: { root.captureMode = 1; root.capture() } }
  Shortcut { sequence: "3"; enabled: root.presented; onActivated: { root.captureMode = 2; root.capture() } }

  component ToolButton: Button {
    id: tool
    property string icon: ""
    property string glyph: ""
    property string tooltip: ""
    property bool selected: false
    readonly property color contentColor: selected ? Theme.selectionForeground : Theme.foreground
    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    buttonColor: selected ? Theme.selectionBackground : hovered ? Theme.surfaceHover : "transparent"
    buttonBorderColor: activeFocus ? Theme.accent : "transparent"
    accessibleName: tooltip
    Item {
      implicitWidth: 20
      implicitHeight: 20
      anchors.centerIn: parent
      IconImage {
        anchors.fill: parent
        visible: tool.icon !== ""
        source: tool.icon ? Qt.resolvedUrl(tool.icon) : ""
        layer.enabled: true
        layer.effect: MultiEffect { brightness: 1; colorization: 1; colorizationColor: tool.contentColor }
      }
      Text {
        anchors.centerIn: parent
        visible: tool.glyph !== ""
        text: tool.glyph
        color: tool.contentColor
        font.pixelSize: 20
      }
    }
    Tooltip { target: tool; shown: tool.hovered; text: tool.tooltip }
  }

  RowLayout {
    id: toolbar
    anchors.centerIn: parent
    spacing: 4
    ToolButton {
      icon: "../assets/screenshot-region.svg"
      tooltip: "Screenshot"
      selected: root.screenshotVisible
      enabled: !root.operationBusy
      onClicked: root.screenshotMenuRequested()
    }
    ToolButton {
      icon: "../assets/screen-record.svg"
      tooltip: "Screen recording"
      selected: root.recordingVisible
      enabled: !root.operationBusy
      onClicked: root.recordingMenuRequested()
    }
    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Theme.border }
    Controls.ComboBox {
      id: modePicker
      Layout.preferredWidth: 148
      Layout.preferredHeight: 36
      model: ["Rectangle", "Window", "Full screen"]
      currentIndex: root.captureMode
      enabled: !root.operationBusy
      Accessible.name: "Capture mode, " + currentText
      leftPadding: 10
      rightPadding: 22
      onActivated: function(index) {
        root.captureMode = index
        popup.close()
        Qt.callLater(root.capture)
      }
      background: Rectangle {
        color: modePicker.hovered ? Theme.surfaceHover : "transparent"
        radius: Theme.radiusSm
        border.width: Theme.borderWidth
        border.color: modePicker.activeFocus ? Theme.accent : Theme.border
      }
      contentItem: RowLayout {
        spacing: 8
        IconImage {
          Layout.preferredWidth: 18
          Layout.preferredHeight: 18
          source: Qt.resolvedUrl(root.modeIcons[Math.max(0, modePicker.currentIndex)])
          layer.enabled: true
          layer.effect: MultiEffect { brightness: 1; colorization: 1; colorizationColor: Theme.foreground }
        }
        Text {
          Layout.fillWidth: true
          text: modePicker.currentText
          color: Theme.foreground
          font.pixelSize: Theme.fontCaption
          elide: Text.ElideRight
        }
      }
      indicator: Text {
        x: parent.width - width - 8
        anchors.verticalCenter: parent.verticalCenter
        text: "⌄"
        color: Theme.foregroundMuted
      }
      popup: Controls.Popup {
        y: root.openAbove ? -height - 6 : modePicker.height + 6
        width: modePicker.width
        height: 116
        padding: 4
        modal: true
        dim: false
        enter: Transition {}
        exit: Transition {}
        background: Rectangle { color: Theme.surface; radius: Theme.radiusSm; border.width: 1; border.color: Theme.borderFocus }
        contentItem: ListView {
          clip: true
          model: modePicker.popup.visible ? modePicker.delegateModel : null
          currentIndex: modePicker.highlightedIndex
        }
      }
      delegate: Controls.ItemDelegate {
        id: option
        required property int index
        required property string modelData
        width: modePicker.width - 8
        height: 36
        highlighted: modePicker.highlightedIndex === index
        background: Rectangle { radius: Theme.radiusSm; color: option.highlighted ? Theme.surfaceHover : "transparent" }
        contentItem: RowLayout {
          spacing: 8
          IconImage {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: Qt.resolvedUrl(root.modeIcons[option.index])
            layer.enabled: true
            layer.effect: MultiEffect { brightness: 1; colorization: 1; colorizationColor: Theme.foreground }
          }
          Text { Layout.fillWidth: true; text: option.modelData; color: Theme.foreground; font.pixelSize: Theme.fontCaption }
        }
      }
    }
    ToolButton {
      visible: root.screenshotVisible
      icon: "../assets/color-picker.svg"
      tooltip: "Pick a color"
      enabled: !root.operationBusy
      onClicked: root.captureRequested(ClockState.captureColorMode)
    }
    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Theme.border }
    ToolButton { glyph: "×"; tooltip: "Close (Esc)"; onClicked: root.closeRequested() }
  }
}
