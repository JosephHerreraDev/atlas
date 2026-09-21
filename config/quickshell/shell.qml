//@ pragma UseQApplication

import Quickshell

import "bar" as Bar
import "menu" as Menu

Scope {
  Bar.Notifications {
    id: notifications
  }

  Bar.Bar {
    notifications: notifications
  }

  Menu.Launcher {
  }

  Menu.ThemeSelector {
  }

  Menu.PowerMenu {
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

}
