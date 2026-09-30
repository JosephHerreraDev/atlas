{ config, pkgs, lib, atlasUser, atlasHome, ... }:

let
  atlasPath = "${config.home.homeDirectory}/.local/share/atlas";
  dotfiles = "${atlasPath}/config";

  createSymlink = path:
    config.lib.file.mkOutOfStoreSymlink path;

  configs = {
    btop = "btop";
    fastfetch = "fastfetch";
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
    kitty
    quickshell
  ];

  home.sessionVariables = {
    ATLAS_PATH = atlasPath;
    ATLAS_CONFIG = "${config.home.homeDirectory}/.config/atlas/config.nix";
  };

  home.sessionPath = [
    "${atlasPath}/bin"
  ];

  programs.bash = {
    enable = true;

    initExtra = ''
      fastfetch
    '';
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  xdg.configFile =
    (builtins.mapAttrs
      (_: subpath: {
        source = createSymlink "${dotfiles}/${subpath}";
      })
      configs)
    // {
      "starship.toml".source =
        createSymlink "${dotfiles}/starship/starship.toml";

    };

  home.activation.installHyprConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      source_dir="${dotfiles}/hypr"
      target_dir="${config.home.homeDirectory}/.config/hypr"
      skip_install=false

      if [ -L "$target_dir" ]; then
        symlink_target="$(${pkgs.coreutils}/bin/readlink -f "$target_dir")"
        atlas_target="$(${pkgs.coreutils}/bin/readlink -f "${dotfiles}/hypr")"
        if [ "$symlink_target" = "$atlas_target" ]; then
          echo "Atlas: migrating the old Hyprland directory symlink."
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm "$target_dir"
        else
          echo "Atlas: ~/.config/hypr is a user-managed symlink; leaving it untouched."
          skip_install=true
        fi
      fi

      if [ "$skip_install" = false ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$target_dir"

        # Seed every missing file once. Existing user configuration is never
        # overwritten by later Atlas rebuilds.
        $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync \
          -a \
          --ignore-existing \
          "$source_dir/" \
          "$target_dir/"
      fi
    '';
}
