{
  description = "Atlas Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    quickshell.url = "github:quickshell-mirror/quickshell/v0.3.2";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, quickshell, ... }:
    let
      atlasSystemEnv = builtins.getEnv "ATLAS_SYSTEM";
      system = if atlasSystemEnv != "" then atlasSystemEnv else builtins.currentSystem;
      atlasUserEnv = builtins.getEnv "ATLAS_USER";
      atlasHomeEnv = builtins.getEnv "ATLAS_HOME";
      atlasUser = if atlasUserEnv != "" then atlasUserEnv else "atlas";
      atlasHome = if atlasHomeEnv != "" then atlasHomeEnv else "/home/${atlasUser}";
      atlasConfigEnv = builtins.getEnv "ATLAS_CONFIG";
      atlasConfigCandidate = if atlasConfigEnv != "" then atlasConfigEnv else "${atlasHome}/.config/atlas/config.nix";
      atlasConfigPaths = builtins.filter (path: path != null) [
        (if builtins.pathExists atlasConfigCandidate then builtins.toPath atlasConfigCandidate else null)
      ];
      atlasModules = {
        nvidia = ./modules/nvidia.nix;
        bluetooth = ./modules/bluetooth.nix;
        development = ./modules/development.nix;
        media = ./modules/media.nix;
        productivity = ./modules/productivity.nix;
        laptop = ./modules/laptop.nix;
      };
    in {
      nixosConfigurations.atlas = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit atlasUser atlasHome atlasConfigPaths atlasModules; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              (_: _: {
                quickshell = quickshell.packages.${system}.default;
              })
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit atlasUser atlasHome; };
              users.${atlasUser} = import ./home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
}
