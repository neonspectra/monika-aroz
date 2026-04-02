{
  description = "Aroz — web desktop environment (ArozOS fork)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
      f nixpkgs.legacyPackages.${system}
    );
  in {
    packages = forAllSystems (pkgs: {
      default = pkgs.callPackage ./nix/package.nix {};
      aroz = pkgs.callPackage ./nix/package.nix {};
    });

    nixosModules.default = import ./nix/module.nix;
    nixosModules.aroz = import ./nix/module.nix;

    overlays.default = final: prev: {
      aroz = final.callPackage ./nix/package.nix {};
    };
  };
}
