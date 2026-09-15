{ config, pkgs, lib, ... }:

{
  home.packages = [
    pkgs.git
  ];

  home.activation.installWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    pictures="$HOME/Pictures"
    wallpapers="$pictures/wallpapers"

    mkdir -p "$pictures"

    if [ ! -d "$wallpapers/.git" ]; then
      ${pkgs.git}/bin/git clone \
        https://github.com/JosephHerreraDev/wallpapers.git \
        "$wallpapers"
    fi
  '';
}
