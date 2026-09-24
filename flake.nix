{
  description = "Atlas Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      atlasUserEnv = builtins.getEnv "ATLAS_USER";
      atlasHomeEnv = builtins.getEnv "ATLAS_HOME";
      atlasUser = if atlasUserEnv != "" then atlasUserEnv else "atlas";
      atlasHome = if atlasHomeEnv != "" then atlasHomeEnv else "/home/${atlasUser}";
    in {
      nixosConfigurations.atlas = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit atlasUser atlasHome; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
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
