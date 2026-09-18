# Atlas

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![Nixos](https://img.shields.io/badge/NixOS-76B2DC)](https://nixos.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-58E1C2)](https://hypr.land)
[![Quickshell](https://img.shields.io/badge/Quickshell-359757)](https://quickshell.org/)

A modern, minimal, keyboard-centric NixOS configuration designed for speed, simplicity, and a focused workflow.

## Repository layout

| Path | Purpose |
| --- | --- |
| `bin/` | Scripts |
| `config/` | Application and desktop configuration |
| `modules/` | NVIDIA, GTK theme, and wallpaper modules |
| `themes/` | Color palettes and application templates |
| `configuration.nix` | NixOS system configuration and packages |
| `flake.nix` | Flake configuration for global package versioning |
| `home.nix` | Home Manager configuration and live config symlinks |

## Keybindings

See [Keybindings.md](Keybindings.md) for the complete reference. Common shortcuts include:

| Shortcut | Action |
| --- | --- |
| `Super + Enter` | Open Kitty |
| `Super + Space` | Open the application launcher |
| `Super + T` | Open the theme selector |
| `Super + W` | Open the wallpaper selector |
| `Super + L` | Lock the session |
| `Print` | Open the screenshot menu |

## License

Atlas is available under the [MIT License](LICENSE).
