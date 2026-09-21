pragma Singleton

import Quickshell
import QtQuick

Singleton {
  property var activeMenu: null

  function activate(menu): void {
    if (activeMenu !== null && activeMenu !== menu)
      activeMenu.close()

    activeMenu = menu
  }

  function deactivate(menu): void {
    if (activeMenu === menu)
      activeMenu = null
  }
}
