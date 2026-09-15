{ config, lib, pkgs, ... }:

{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
    ];

  hardware.nvidia.modesetting.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "atlas";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Mexico_City";

  services.xserver.enable = true;

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
    extraGroups = [ "wheel" "networkmanager" ];
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
    wget
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}

