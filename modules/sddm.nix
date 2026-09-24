{ pkgs, ... }:

let
  sddmTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "atlas-sddm-theme";
    version = "1";
    src = ../config/sddm;

    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/sddm/themes/atlas"
      cp -r . "$out/share/sddm/themes/atlas/"
      runHook postInstall
    '';
  };
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    theme = "atlas";
    extraPackages = with pkgs.kdePackages; [
      qtimageformats
      qtsvg
    ];
  };

  environment.systemPackages = [ sddmTheme ];
}
