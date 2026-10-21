{ pkgs, atlasUser, ... }:

let
  mutableWallpaper = "/var/lib/atlas/sddm/wallpaper.jpg";
  sddmTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "atlas-sddm-theme";
    version = "1";
    src = ../config/sddm;

    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/sddm/themes/atlas"
      cp -r . "$out/share/sddm/themes/atlas/"
      rm "$out/share/sddm/themes/atlas/backgrounds/wallpaper.jpg"
      ln -s ${mutableWallpaper} "$out/share/sddm/themes/atlas/backgrounds/wallpaper.jpg"
      runHook postInstall
    '';
  };
in {
  services.displayManager.sddm = {
    enable = true;
    # X11 can start an empty NVIDIA screen on hybrid laptops when the external
    # monitor is unplugged. KWin discovers outputs across the available DRM GPUs.
    wayland = {
      enable = true;
      compositor = "kwin";
    };
    theme = "atlas";
    extraPackages = with pkgs.kdePackages; [
      qtimageformats
      qtsvg
    ];
  };

  environment.systemPackages = [ sddmTheme ];

  systemd.tmpfiles.rules = [
    "d /var/lib/atlas/sddm 0755 ${atlasUser} users -"
  ];

  system.activationScripts.atlasSddmWallpaper = {
    deps = [ "users" "groups" ];
    text = ''
      ${pkgs.coreutils}/bin/install -d -m 0755 -o ${atlasUser} -g users /var/lib/atlas/sddm
      if [ ! -e ${mutableWallpaper} ]; then
        ${pkgs.coreutils}/bin/install -m 0644 -o ${atlasUser} -g users \
          ${../config/sddm/backgrounds/wallpaper.jpg} ${mutableWallpaper}
      fi
    '';
  };
}
