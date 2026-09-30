{ pkgs, atlasUser, ... }:

{
  environment.systemPackages = with pkgs; [ brave obsidian yazi zathura ];
  home-manager.users.${atlasUser}.home.packages = with pkgs; [ zathura ];
}
