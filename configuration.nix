{ lib, pkgs, atlasUser, atlasConfigPaths, ... }:

{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      ./modules/plymouth.nix
      ./modules/sddm.nix
    ] ++ atlasConfigPaths;

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
    hyprshot
    hyprpicker
    wf-recorder
    wget
    rsync
  ]);

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "26.05";
}
