-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
  hl.exec_cmd("quickshell")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
end)
