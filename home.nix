{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/atlas/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    hypr = "hypr";
  };
in

{
  home.username = "joe";
  home.homeDirectory = "/home/joe";
  home.stateVersion = "26.05";
  
  imports = [
    ./modules/theme.nix
    ./modules/wallpapers.nix
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch";
    };
    initExtra = ''
       export PS1='\[\e[38;5;76m\]\u\[\e[0m\] in \[\e[38;5;32m\]\w\[\e[0m\] \\$ '
    '';
  };

  programs.kitty = {
    enable = true;
    settings = {
      background_opacity = 0.9;
    };
  };
  
  xdg.configFile = builtins.mapAttrs
	  (name: subpath: {
	   source = create_symlink "${dotfiles}/${subpath}";
	   recursive = true;
	   })
  configs;
  
  # wayland.windowManager.hyprland.enable = true;
  # home.file.".config/hypr".source = /home/joe/dotfiles/hypr;
}

