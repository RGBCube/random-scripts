{
  description = "random-scripts";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
    inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      let
        inherit (lib.filesystem) listFilesRecursive;
        inherit (lib.lists) filter;
        inherit (lib.strings) hasSuffix;
      in
      {
        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ];

        imports = filter (hasSuffix ".mod.nix") (listFilesRecursive ./.);
      }
    );
}
