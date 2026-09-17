pragma Singleton

import Quickshell

Singleton {
  property string displayMode: "numbers"

  readonly property var symbols: ({
    1: "󰎤",
    2: "󰎧",
    3: "󰎪",
    4: "󰎭",
    5: "󰎱",
    6: "󰎳",
    7: "󰎶",
    8: "󰎹",
    9: "󰎼",
    10: "󰽽"
  })

  function label(workspace): string {
    switch (displayMode) {
    case "symbols":
      return symbols[workspace.id] ?? workspace.name
    case "numbers":
    default:
      return workspace.name
    }
  }
}
