-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function () 
  hl.exec_cmd("quickshell")
  hl.exec_cmd("hyprpaper")
--  hl.exec_cmd("bash -lc 'prometheus-clipboard-watch restart'")
end)
