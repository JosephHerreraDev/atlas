{ config, lib, pkgs, ... }:

{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ./modules/nvidia.nix
      ./modules/sddm.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "atlas";
  networking.networkmanager.enable = true;

  services.upower.enable = true;

  time.timeZone = "America/Mexico_City";

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      noto-fonts
    ];

    fontconfig.defaultFonts = {
      monospace = [ "FiraCode Nerd Font Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true; 
  };

  programs.dconf.enable = true;

  hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

  services.blueman.enable = true;

  users.users.joe = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    packages = with pkgs; [
      tree
    ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    hyprpaper
    quickshell
    libnotify
    hyprlock
    yazi
    obsidian
    brave
    git
    btop
    vim
    fastfetch
    spotify
    brightnessctl
    playerctl
    mpv
    grim
    slurp
    wl-clipboard
    cliphist
    jq
    hyprshot
    hyprpicker
    wf-recorder
    wget
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
