//@ pragma UseQApplication

import Quickshell
import Quickshell.Io

import "bar" as Bar
import "menu" as Menu
import "shared" as Shared
import "widgets" as Widgets

Scope {
  // Keep task notifications alive even while the calendar is closed.
  readonly property bool remindersReady: Bar.ReminderState.loaded
  Process {
    command: ["wallpaper-rotate"]
    running: true
  }

  Bar.Notifications {
    id: notifications
  }

  Bar.Bar {
    notifications: notifications
  }

  Bar.ClipboardWindow {
  }

  Shared.OsdWindow {
  }

  Menu.GlobalMenu {
  }

  Menu.ThemeSelector {
  }

  Menu.PowerMenu {
  }

  Menu.Settings {
  }

  Widgets.StickyNotes {
  }

  Widgets.TasksWidget {
  }

  Widgets.FocusTimerWidget {
  }

  Widgets.PlayerWidget {
  }

  Menu.WallpaperSelector {
    ipcTarget: "wallpaper"
    mode: "general"
    title: "Wallpapers"
  }

  Menu.WallpaperSelector {
    ipcTarget: "themewallpaper"
    mode: "theme"
    title: "Theme wallpapers"
  }

  Bar.RecordingMenu {
  }

}
