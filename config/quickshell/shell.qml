import Quickshell // for PanelWindow
import Quickshell.Io // for Process
import QtQuick // for Text

Scope {
  id: root

  // add a property in the root
  property string time

  Variants {
    model: Quickshell.screens;

    delegate: Component {
      PanelWindow {
        //the screen from the screens list will be injected into this
        //property
        required property var modelData
        // we can the set the window's screen to the injected property
        screen: modelData

        anchors {
          top: true
          left: true
          right: true
        }

        implicitHeight: 30

        Text {
          // center the bar in its parent component (the window)
          anchors.centerIn: parent
          
          // bind the text to the root object's time propery
          text: root.time
        }
      }
    }
  }

  // create a process management object
  Process {
    // give the process object an id so we can talk
    // about it from the timer
    id: dateProc
    //the command it will run, every argument is its own string 
    command: ["date"]
    // run the command immediately
    running: true

    // process the stdout stream using StdioCollector
    // Use StdioCollector to retrieve the text the process sends
    stdout: StdioCollector {
      // Listen for the streamFinished signal, which is sent
      // when the process closes stdout or exits.
      onStreamFinished: root.time = this.text // this can be omitted 
    }
  }

  // use a timer to rerun the process at an interval
  Timer {
    // 1000 milliseconds is 1 second
    interval: 1000 
    // start the timer immediately
    running: true
    // run the timer again when it ends
    repeat: true
    // when the timer is triggered, set the running property of the
    // process to true, which reruns it if stopped.
    onTriggered: dateProc.running = true
  }
}

