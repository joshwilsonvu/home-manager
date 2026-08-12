{
  description = "Josh's Home Manager configuration";

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned to the "cachix" branch, which always tracks the latest commit
    # that CI has pre-built. Using nixpkgs.follows causes cache misses.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

  };

  outputs =
    { self, nixpkgs, home-manager, nixgl, noctalia, ... }@inputs:
    {
      homeConfigurations.josh = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [
            nixgl.overlays.default
            noctalia.overlays.default
          ];
        };

        extraSpecialArgs = { inherit inputs; };

        modules = [
          ./home.nix
          noctalia.homeModules.default
        ];
      };
    };
}
