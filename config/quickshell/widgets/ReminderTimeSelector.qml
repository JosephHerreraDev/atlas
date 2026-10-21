import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../"

ColumnLayout {
  id: root
  property bool wheelEnabled: true
  property alias hour: hours.value
  property alias minute: minutes.value
  spacing: Theme.spaceXs

  RowLayout {
    Layout.fillWidth: true
    Text {
      Layout.fillWidth: true
      text: "Time"
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
      font.weight: Theme.weightStrong
    }
    Text {
      text: "24-hour clock"
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontCaption
    }
  }

  component TimePart: Controls.SpinBox {
    id: control
    from: 0
    wrap: true
    editable: true
    wheelEnabled: root.wheelEnabled
    implicitWidth: 140
    implicitHeight: 44
    font.pixelSize: Theme.fontDisplay
    leftPadding: 34
    rightPadding: 34
    textFromValue: function(value, locale) { return String(value).padStart(2, "0") }
    valueFromText: function(text, locale) { return Number(text) }
    validator: IntValidator { bottom: control.from; top: control.to }
    contentItem: TextInput {
      text: control.textFromValue(control.value, control.locale)
      color: Theme.foreground
      font: control.font
      readOnly: !control.editable
      validator: control.validator
      inputMethodHints: Qt.ImhDigitsOnly
      selectByMouse: true
      selectionColor: Theme.accent
      selectedTextColor: Theme.background
      activeFocusOnTab: true
      onActiveFocusChanged: {
        if (activeFocus) selectAll()
      }
      Keys.onUpPressed: control.increase()
      Keys.onDownPressed: control.decrease()
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
      color: Theme.surfaceHover
      radius: Theme.radiusMd
      border.width: Theme.borderWidth
      border.color: control.activeFocus || control.contentItem.activeFocus ? Theme.borderFocus : Theme.border
    }
    up.indicator: Rectangle {
      x: parent.width - width
      width: 32
      height: parent.height
      radius: Theme.radiusMd
      color: control.up.pressed ? Theme.selectionBackground : "transparent"
      Text {
        anchors.centerIn: parent
        text: "+"
        color: Theme.accent
        font.pixelSize: Theme.fontTitle
      }
    }
    down.indicator: Rectangle {
      width: 32
      height: parent.height
      radius: Theme.radiusMd
      color: control.down.pressed ? Theme.selectionBackground : "transparent"
      Text {
        anchors.centerIn: parent
        text: "−"
        color: Theme.accent
        font.pixelSize: Theme.fontTitle
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Theme.spaceSm

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Theme.spaceXs
      Text {
        text: "Hour"
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
      }
      TimePart {
        id: hours
        Layout.fillWidth: true
        to: 23
        Accessible.name: "Reminder hour, 24-hour clock"
      }
    }

    Text {
      Layout.alignment: Qt.AlignBottom
      Layout.preferredHeight: 44
      verticalAlignment: Text.AlignVCenter
      text: ":"
      color: Theme.foregroundMuted
      font.pixelSize: Theme.fontDisplay
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Theme.spaceXs
      Text {
        text: "Minute"
        color: Theme.foregroundMuted
        font.pixelSize: Theme.fontCaption
      }
      TimePart {
        id: minutes
        Layout.fillWidth: true
        to: 59
        Accessible.name: "Reminder minute"
      }
    }
  }
}
