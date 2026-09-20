{ config, pkgs, ... }:

let
atlasPath = "${config.home.homeDirectory}/.local/share/atlas";
dotfiles = "${atlasPath}/config";

create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

configs = {
  btop = "btop";
  fastfetch = "fastfetch";
  hypr = "hypr";
  kitty = "kitty";
  nvim = "nvim";
  quickshell = "quickshell";
  starship = "starship";
  tmux = "tmux";
  zathura = "zathura";
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
    cava
    kitty
    neovim 
    quickshell
    tree-sitter
    tmux 
    zathura 
  ];

  home.sessionVariables = {
    ATLAS_PATH = atlasPath;
  };

  home.sessionPath = [
    "${atlasPath}/bin"
  ];

  programs.bash = {
    enable = true;

    initExtra = ''
      fastfetch
    '';

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --impure --flake ~/.local/share/atlas#atlas";
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  xdg.configFile = builtins.mapAttrs
    (name: subpath: {
     source = create_symlink "${dotfiles}/${subpath}";
     })
  configs;
}
