{ config, lib, pkgs, ... }:

{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ./modules/nvidia.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "atlas";
  networking.networkmanager.enable = true;

  services.upower.enable = true;

  time.timeZone = "America/Mexico_City";

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true; 
  };

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
    wget
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
