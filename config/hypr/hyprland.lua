require("hyprland/monitors")
require("hyprland/programs")
require("hyprland/autostart")
require("hyprland/variables")
require("hyprland/permissions")
require("hyprland/looknfeel")

local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local themeConfig = configHome .. "/atlas/style/current/hyprland.lua"
local themeFile = io.open(themeConfig, "r")
if themeFile ~= nil then
  themeFile:close()
  dofile(themeConfig)
end

require("hyprland/input")
require("hyprland/keybindings")
require("hyprland/windowsnworkspaces")
