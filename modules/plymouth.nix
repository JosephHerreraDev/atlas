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

      magick \
        -size 8x8 xc:none \
        -fill '#65d1ff' \
        -draw 'circle 4,4 4,1' \
        "$themeDir/dot.png"

      runHook postInstall
    '';
  };
in
{
  boot = {
    plymouth = {
      enable = true;
      theme = "atlas";
      themePackages = [ atlasPlymouthTheme ];
    };

    # Keep console output from replacing the splash during a normal boot.
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
  };
}
