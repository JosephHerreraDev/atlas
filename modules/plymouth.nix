{ pkgs, ... }:

let
  logoSource = ../logo.txt;

  atlasPlymouthTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "atlas-plymouth-theme";
    version = "1.0.0";

    src = ../config/plymouth;
    nativeBuildInputs = [ pkgs.imagemagick ];

    installPhase = ''
      runHook preInstall

      themeDir="$out/share/plymouth/themes/atlas"
      mkdir -p "$themeDir"
      cp atlas.script "$themeDir/"
      substitute atlas.plymouth "$themeDir/atlas.plymouth" \
        --replace-fail '@themeDir@' "$themeDir"

      magick \
        -background none \
        -fill '#d7e3f4' \
        -font '${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode/FiraCodeNerdFontMono-Regular.ttf' \
        -pointsize 27 \
        -interline-spacing 4 \
        'label:@${logoSource}' \
        -trim +repage \
        -bordercolor none -border 2 \
        "$themeDir/logo.png"

      magick -size 180x4 xc:'#263447' "$themeDir/progress-track.png"
      magick -size 180x4 xc:'#65d1ff' "$themeDir/progress-fill.png"

      runHook postInstall
    '';
  };
in {
  boot = {
    plymouth = {
      enable = true;
      theme = "atlas";
      themePackages = [ atlasPlymouthTheme ];
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
  };
}
