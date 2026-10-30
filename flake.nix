{
  description = "Wallpaper Engine plugin for KDE Plasma 6";

  inputs = {
    # Consumers should set inputs.nixpkgs.follows = "nixpkgs" to match Plasma's Qt.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Requires Nix 2.27+; fetch the renderer's pinned Git submodules as well.
    self.submodules = true;
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          package = pkgs.callPackage ./nix/package.nix { src = self; };
        in
        {
          wallpaper-engine-kde-plugin = package;
          default = package;
        }
      );

      checks = forAllSystems (system: {
        package = self.packages.${system}.default;
      });
    };
}
