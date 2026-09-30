# Atlas

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![NixOS](https://img.shields.io/badge/NixOS-76B2DC)](https://nixos.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-58E1C2)](https://hypr.land/)
[![Quickshell](https://img.shields.io/badge/Quickshell-359757)](https://quickshell.org/)

Atlas is a modern, minimal, keyboard-centric NixOS configuration designed for speed, simplicity, and a focused workflow. Built around Hyprland and Quickshell, it provides an installable system configuration while keeping machine-specific settings and configurations under the user's control.

## Features

- Hyprland session with keyboard-focused navigation and window management
- Quickshell bar, launcher, notifications, power menu, and system controls
- Bundled themes with matching application colors and wallpapers
- SDDM login screen and Plymouth boot theme
- Home Manager configuration for terminal and desktop applications
- Optional modules for Bluetooth, development tools, media, productivity, etc
- Hardware-aware installation that enables modules only
  when matching hardware is detected
- Maintenance commands for checking, rebuilding, updating, diagnosing,
  and rolling back the system

## Requirements

Atlas is intended for an existing NixOS installation. Before installing, the
system must have:

- NixOS with flakes available
- A normal user with `sudo` access
- An existing `/etc/nixos/hardware-configuration.nix`
- Internet access for downloading Atlas and Nix packages
- An EFI system configured for systemd-boot

Run the installer as the target desktop user, not as root. The installer
performs a NixOS rebuild and therefore changes the active system generation.

## Installation

Install the latest version from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/JosephHerreraDev/atlas/main/install.sh | bash
```

Alternatively, install from a local checkout:

```bash
./install.sh
```

The installer:

1. Copies Atlas to `~/.local/share/atlas` when it is not already installed.
2. Creates `~/.config/atlas/config.nix` if it does not exist.
3. Detects the hostname, time zone, battery, and NVIDIA hardware.
4. Enables the applicable optional modules in the user configuration.
5. Rebuilds and activates the NixOS system.
6. Initializes the bundled Nord theme.

Existing `~/.config/atlas/config.nix` files are preserved. Log out and back in
after installation to start the Hyprland session.

## Configuration

### NixOS configuration

Machine-specific configuration lives at:

```text
~/.config/atlas/config.nix
```

It is an ordinary NixOS module. Optional Atlas modules are enabled through
`imports`:

```nix
{ atlasModules, ... }:

{
  imports = [
    atlasModules.bluetooth
    atlasModules.development
    atlasModules.media
    atlasModules.productivity
    atlasModules.laptop
    # atlasModules.nvidia
  ];

  networking.hostName = "my-machine";
  time.timeZone = "America/Mexico_City";
}
```

Add or remove imports to control optional features. Native NixOS options and
personal modules can be used in the same file.

Check a change before activating it:

```bash
atlas config check
atlas rebuild
```

### Hyprland configuration

Atlas seeds missing files into `~/.config/hypr` during activation. Files that
already exist are not overwritten, so monitor, input, application, keybinding,
window-rule, and appearance settings can be edited directly.

## Usage

### Atlas commands

| Command | Description |
| --- | --- |
| `atlas config check` | Evaluate the configuration without activating it |
| `atlas rebuild` | Build and activate the current Atlas configuration |
| `atlas rollback` | Activate the previous NixOS generation |
| `atlas doctor` | Check dependencies, configuration, Hyprland, and themes |
| `atlas update` | Download the latest Atlas source without rebuilding |

### Themes and wallpapers

Atlas loads bundled themes from `themes/<name>` and custom themes from:

```text
~/.config/atlas/themes/<name>
```

A custom theme must contain a complete `colors.toml` and a `wallpapers/`
directory with at least one `.jpg`, `.jpeg`, `.png`, or `.webp` image:

```text
~/.config/atlas/themes/my-theme/
├── colors.toml
└── wallpapers/
    └── background.jpg
```

Custom theme names must not duplicate bundled theme names. The custom theme
directory is optional and does not need to exist when it is unused.

Open the theme selector with `Super + T`. Applying a theme generates its
application styles and randomly selects a wallpaper from that theme's
wallpaper directory.

Generated theme state is stored under:

```text
~/.config/atlas/style
```

Open the general wallpaper selector with `Super + W`. General wallpapers are
read from `~/Pictures/wallpapers`. Use `Super + Alt + W` to select from the
current theme's wallpapers.

Atlas does not create or import custom themes; users manage them directly in
the directory above.

### Keybindings

`Super` refers to the Windows or Command key. The most common shortcuts are:

| Shortcut | Action |
| --- | --- |
| `Super + Enter` | Open Kitty |
| `Super + Space` | Open the application launcher |
| `Super + T` | Open the theme selector |
| `Super + W` | Open the general wallpaper selector |
| `Super + Alt + W` | Open the current-theme wallpaper selector |
| `Super + A` | Open quick settings |
| `Super + L` | Lock the session |
| `Print` | Open the screenshot menu |

See [Keybindings.md](Keybindings.md) for the full reference.

## Updating

Run:

```bash
atlas update
atlas config check
atlas rebuild
```

For Git installations, `atlas update` performs a fast-forward-only pull. For
archive installations, it downloads the current `main` branch and stores
replaced files under `~/.local/state/atlas/backups/<timestamp>`.

Updates do not overwrite the user configuration. An update is not active until `atlas rebuild` succeeds.

## Rollback and recovery

If an activated generation causes problems, return to the previous generation:

```bash
atlas rollback
```

For general diagnostics, run:

```bash
atlas doctor
```

The doctor checks required commands, evaluates the NixOS configuration, tests
the running Hyprland session when available, and verifies theme colors
and wallpapers.

## Troubleshooting

### Configuration check fails

Run `atlas config check` and review the Nix error. Correct
`~/.config/atlas/config.nix` before rebuilding. Optional hardware modules such
as `atlasModules.nvidia` should only be imported on compatible systems.

### Hyprland changes do not appear

Atlas only copies missing Hyprland files. Edit the active files under
`~/.config/hypr`, then reload Hyprland or log out and back in.

### Theme or wallpaper does not load

Run `atlas doctor` to validate themes. Each theme must contain a valid
`colors.toml` and at least one wallpaper.

## Project structure

| Path | Purpose |
| --- | --- |
| `bin/` | Atlas, theme, wallpaper, refresh, and screenshot commands |
| `config/` | Hyprland, Quickshell, terminal, editor, and application configuration |
| `modules/` | Optional NixOS modules plus desktop integration modules |
| `themes/` | Bundled palettes, wallpapers, and application style templates |
| `configuration.nix` | Base NixOS desktop configuration |
| `home.nix` | Home Manager packages, links, variables, and activation behavior |
| `flake.nix` | Nixpkgs inputs, module registry, and the Atlas system output |
| `install.sh` | Installer, hardware detection, and initial rebuild |

## Contributing

Changes should remain declarative where practical, preserve user-owned files,
and keep optional hardware support out of the base configuration. Before
submitting a change, run the relevant shell syntax checks.

## License

Atlas is available under the [MIT License](LICENSE).
