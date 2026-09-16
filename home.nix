{ config, pkgs, ... }:

let
  atlasPath = "${config.home.homeDirectory}/.local/share/atlas";
  dotfiles = "${atlasPath}/config";

  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    hypr = "hypr";
    fastfetch = "fastfetch";
    kitty = "kitty";
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

  home.packages = with pkgs; [
    kitty
  ];

  home.sessionVariables = {
    ATLAS_PATH = atlasPath;
  };

  home.sessionPath = [
    "${atlasPath}/bin"
  ];

  programs.bash = {
    enable = true;

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --impure --flake ~/.local/share/atlas#atlas";
    };

    initExtra = ''
      export PS1='\[\e[38;5;76m\]\u\[\e[0m\] in \[\e[38;5;32m\]\w\[\e[0m\] \\$ '
    '';
  };

  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
    })
    configs;
}
