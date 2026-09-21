import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

Scope {
  id: root

  property bool opened: false
  property bool mounted: false
  property string query: ""
  property var apps: []
  property var filteredApps: []
  property bool appsLoaded: false
  property int selectedIndex: -1
  property int focusRequest: 0

  readonly property int animationDuration: 140
  readonly property int maxVisibleRows: 6

  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null
      && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function open(): void {
    MenuState.activate(root)
    hideTimer.stop()
    mounted = true
    opened = false
    query = ""
    if (!appsLoaded)
      refresh()
    filter()
    Qt.callLater(function() {
      if (root.mounted) {
        opened = true
        requestFocus()
      }
    })
  }

  function close(): void {
    MenuState.deactivate(root)
    opened = false
    hideTimer.restart()
  }

  function toggle(): void {
    if (opened) {
      close()
    } else {
      open()
    }
  }

  function requestFocus(): void {
    focusRequest += 1
  }

  function refresh(): void {
    const results = []
    const entries = DesktopEntries.applications.values

    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i]
      if (entry.noDisplay || entry.name.length === 0)
        continue

      results.push({
        entry: entry,
        id: entry.id,
        name: entry.name,
        genericName: entry.genericName,
        comment: entry.comment,
        icon: entry.icon,
        search: [
          entry.name,
          entry.genericName,
          entry.comment,
          entry.id,
          entry.keywords.join(" ")
        ].join(" ").toLowerCase()
      })
    }

    results.sort(function(a, b) { return a.name.localeCompare(b.name) })
    apps = results
    appsLoaded = true
    filter()
  }

  function filter(): void {
    const needle = query.trim().toLowerCase()
    const results = []

    if (needle.length === 0) {
      filteredApps = apps
      resetSelection()
      return
    }

    for (let i = 0; i < apps.length; i++) {
      const app = apps[i]

      if (app.search.indexOf(needle) !== -1) {
        results.push(app)
      }
    }

    filteredApps = results
    resetSelection()
  }

  function resetSelection() {
    selectedIndex = filteredApps.length > 0 ? 0 : -1
  }

  function selectedApp() {
    if (selectedIndex >= 0 && selectedIndex < filteredApps.length) {
      return filteredApps[selectedIndex]
    }

    return null
  }

  function moveSelection(delta) {
    if (filteredApps.length === 0) {
      selectedIndex = -1
      return
    }

    selectedIndex = Math.max(0, Math.min(selectedIndex + delta, filteredApps.length - 1))
  }

  function launch(app) {
    if (app === null || app.id.length === 0) {
      return
    }

    close()
    app.entry.execute()
  }

  function iconSource(icon) {
    if (icon.length === 0) {
      return ""
    }

    return Quickshell.iconPath(icon)
  }

  Component.onCompleted: refresh()

  onQueryChanged: filter()

  IpcHandler {
    target: "launcher"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged(): void { root.refresh() }
  }

  Timer {
    id: hideTimer

    interval: root.animationDuration
    repeat: false
    onTriggered: {
      if (!root.opened) {
        root.mounted = false
      }
    }
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
      WlrLayershell.namespace: "prometheus-launcher"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      onVisibleChanged: {
        if (visible) {
          focusInput()
        }
      }

      function focusInput(): void {
        Qt.callLater(function() {
          input.forceActiveFocus()
          input.selectAll()
        })
      }

      Connections {
        target: root

        function onFocusRequestChanged(): void {
          if (window.visible) {
            window.focusInput()
          }
        }
      }

      Rectangle {
        id: scrim

        anchors.fill: parent
        color: "#66000000"
        opacity: root.opened ? 1.0 : 0.0

        Behavior on opacity {
          NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        MouseArea {
          anchors.fill: parent
          enabled: root.opened
          onClicked: root.close()
        }
      }

      Rectangle {
        id: panel

        opacity: root.opened ? 1.0 : 0.0
        scale: root.opened ? 1.0 : 0.96
        width: Math.min(480, window.width - 32)
        implicitHeight: content.implicitHeight + 32
        anchors.centerIn: parent

        radius: 8
        color: Theme.color0
        border.width: 1
        border.color: Theme.color2

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

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) { mouse.accepted = true }
          onWheel: function(wheel) { wheel.accepted = true }
        }

        ColumnLayout {
          id: content

          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
          }

          spacing: 12

          RowLayout {
            Layout.fillWidth: true

            Text {
              Layout.fillWidth: true
              text: "Applications"
              color: Theme.color6
              font.pixelSize: 18
              font.weight: Font.DemiBold
              elide: Text.ElideRight
            }

            Text {
              text: root.appsLoaded ? root.apps.length + " available" : "Loading"
              color: Theme.color4
              font.pixelSize: 12
            }
          }

          TextField {
            id: input

            Layout.fillWidth: true
            Layout.preferredHeight: 42
            text: root.query
            placeholderText: "Search applications"
            selectByMouse: true
            color: Theme.color6
            placeholderTextColor: Theme.color4
            font.pixelSize: 15
            leftPadding: 12
            rightPadding: 12
            background: Rectangle {
              radius: 6
              color: Theme.color1
              border.width: 1
              border.color: input.activeFocus ? Theme.color8 : Theme.color3
            }

            onTextChanged: root.query = text
            onAccepted: root.launch(root.selectedApp())

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Down && root.filteredApps.length > 0) {
                root.moveSelection(1)
                resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Up && root.filteredApps.length > 0) {
                root.moveSelection(-1)
                resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              }
            }
          }

          Text {
            visible: root.filteredApps.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            text: !root.appsLoaded ? "Loading apps..." : root.apps.length === 0 ? "No apps found" : "No matches"
            color: Theme.color4
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          ListView {
            id: resultsList

            visible: root.filteredApps.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(root.filteredApps.length, root.maxVisibleRows) * 72
            clip: true
            interactive: root.filteredApps.length > root.maxVisibleRows
            currentIndex: root.selectedIndex
            model: root.filteredApps
            boundsBehavior: Flickable.StopAtBounds
            spacing: 4

            onCurrentIndexChanged: {
              if (currentIndex >= 0) {
                positionViewAtIndex(currentIndex, ListView.Contain)
              }
            }

            ScrollBar.vertical: ScrollBar {
              policy: root.filteredApps.length > root.maxVisibleRows
                ? ScrollBar.AsNeeded
                : ScrollBar.AlwaysOff
            }

            delegate: Rectangle {
              id: appCard

              required property int index
              required property var modelData

              width: resultsList.width
              height: 68
              radius: 6
              color: ListView.isCurrentItem || cardMouse.containsMouse
                ? Theme.color1
                : Theme.color0
              border.width: ListView.isCurrentItem || cardMouse.containsMouse ? 1 : 0
              border.color: ListView.isCurrentItem ? Theme.color8 : Theme.color3

              RowLayout {
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  bottom: parent.bottom
                  margins: 12
                }

                spacing: 10

                IconImage {
                  id: appIcon

                  Layout.preferredWidth: 32
                  Layout.preferredHeight: 32
                  Layout.alignment: Qt.AlignVCenter
                  source: root.iconSource(appCard.modelData.icon)
                  asynchronous: true
                  mipmap: true
                  visible: status === Image.Ready
                }

                Rectangle {
                  Layout.preferredWidth: 32
                  Layout.preferredHeight: 32
                  Layout.alignment: Qt.AlignVCenter
                  visible: !appIcon.visible
                  radius: 6
                  color: Theme.color2
                  border.width: 1
                  border.color: Theme.color3

                  Text {
                    anchors.centerIn: parent
                    text: appCard.modelData.name.length > 0 ? appCard.modelData.name[0].toUpperCase() : "?"
                    color: Theme.color6
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  spacing: 2

                  Text {
                    Layout.fillWidth: true
                    text: appCard.modelData.name
                    color: ListView.isCurrentItem ? Theme.color6 : Theme.color4
                    font.pixelSize: 15
                    font.weight: ListView.isCurrentItem ? Font.DemiBold : Font.Medium
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    visible: appCard.modelData.comment.length > 0 || appCard.modelData.genericName.length > 0
                    text: appCard.modelData.comment.length > 0 ? appCard.modelData.comment : appCard.modelData.genericName
                    color: Theme.color4
                    font.pixelSize: 11
                    elide: Text.ElideRight
                  }
                }
              }

              MouseArea {
                id: cardMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  root.selectedIndex = appCard.index
                }
                onClicked: root.launch(appCard.modelData)
              }
            }
          }
        }
      }

      Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: root.close()
      }
    }
  }
}
