{ config, pkgs, atlasUser, atlasHome, ... }:

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
  tmux = "tmux";
  zathura = "zathura";
};
in

{
  home.username = atlasUser;
  home.homeDirectory = atlasHome;
  home.stateVersion = "26.05";

  imports = [
    ./modules/theme.nix
  ];

  home.packages = with pkgs; [
    cava
      kitty
      neovim
      quickshell
      tree-sitter
      tmux
      zathura
      (pkgs.writeShellApplication {
       name = "ns";
       runtimeInputs = with pkgs; [
       fzf
       nix-search-tv
       ];
       text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
       })
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
      nrs = "sudo env ATLAS_USER=${atlasUser} ATLAS_HOME=${atlasHome} nixos-rebuild switch --impure --flake ${atlasPath}#atlas";
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  xdg.configFile = (builtins.mapAttrs
    (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
    })
    configs) // {
      "starship.toml".source =
        create_symlink "${dotfiles}/starship/starship.toml";
    };
}
