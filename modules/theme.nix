{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra
  ];

  gtk = {
    enable = true;
    theme.name = lib.mkDefault "Adwaita-dark";
    iconTheme.name = lib.mkDefault "Adwaita";
    cursorTheme = {
      name = lib.mkDefault "Adwaita";
      package = lib.mkDefault pkgs.adwaita-icon-theme;
      size = lib.mkDefault 24;
    };
  };

  home.sessionVariables = {
    XCURSOR_THEME = lib.mkDefault "Adwaita";
    XCURSOR_SIZE = lib.mkDefault "24";
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = lib.mkDefault "prefer-dark";
    gtk-theme = lib.mkDefault "Adwaita-dark";
  };
}
