{ pkgs, atlasUser, ... }:

{
  environment.systemPackages = with pkgs; [ mpv spotify ];
  home-manager.users.${atlasUser}.home.packages = with pkgs; [ cava ];
}
