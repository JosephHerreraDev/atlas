{ pkgs, atlasUser, ... }:

{
  environment.systemPackages = with pkgs; [ tree ];

  home-manager.users.${atlasUser}.home.packages = with pkgs; [
    neovim
    tree-sitter
    tmux
    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = [ fzf nix-search-tv ];
      text = builtins.readFile "${nix-search-tv.src}/nixpkgs.sh";
    })
  ];
}
