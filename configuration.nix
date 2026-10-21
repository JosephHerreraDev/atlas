{ config, lib, pkgs, atlasUser, atlasConfigPaths, atlasModules, ... }:

{
  options.atlas = {
    fontFamily = lib.mkOption { type = lib.types.str; default = "FiraCode Nerd Font Mono"; };
    cursorTheme = lib.mkOption { type = lib.types.str; default = "Adwaita"; };
    cursorSize = lib.mkOption { type = lib.types.ints.between 12 64; default = 24; };
  };

  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ./modules/plymouth.nix
      ./modules/sddm.nix
    ] ++ atlasConfigPaths;

  config = {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = lib.mkDefault "atlas";
  networking.networkmanager.enable = true;

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      noto-fonts
    ];

    fontconfig.defaultFonts = {
      monospace = [ config.atlas.fontFamily ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };

  home-manager.users.${atlasUser} = {
    gtk.cursorTheme = {
      name = config.atlas.cursorTheme;
      package = if lib.hasPrefix "Bibata-" config.atlas.cursorTheme then pkgs.bibata-cursors
        else pkgs.adwaita-icon-theme;
      size = config.atlas.cursorSize;
    };
    home.sessionVariables = {
      XCURSOR_THEME = config.atlas.cursorTheme;
      XCURSOR_SIZE = toString config.atlas.cursorSize;
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true; 
  };

  programs.appimage = {
  enable = true;
  binfmt = true;
  };

  programs.dconf.enable = true;
  # Steam's client needs 32-bit OpenGL/Vulkan drivers, including on 64-bit systems.
  hardware.graphics.enable32Bit = true;
  services.xserver.enable = true;

  users.users.${atlasUser} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    packages = [ ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = (with pkgs; [
    cliamp
    hyprpaper
    hypridle
    quickshell
    libnotify
    hyprlock
    git
    btop
    vim
    fastfetch
    playerctl
    grim
    slurp
    wl-clipboard
    cliphist
    jq
    matugen
    hyprshot
    hyprpicker
    wf-recorder
    wget
    rsync
    python3
  ]);

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
  };
}
