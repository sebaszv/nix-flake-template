{
  inputs = {
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "nixpkgs/nixos-24.11";

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem = { lib, pkgs, system, ... }:
        let
          treefmt = (inputs.treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.lock";
            programs.nixpkgs-fmt.enable = true;
          }).config.build.wrapper;

          pre-commit = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks.treefmt = {
              enable = true;
              package = treefmt;
              pass_filenames = false;
            };
          };
        in
        rec {
          checks.pre-commit = pre-commit;
          formatter = treefmt;
          devShells.default = pkgs.mkShellNoCC {
            inherit (pre-commit) shellHook;

            packages = [
              pkgs.git

              pkgs.nil
              pkgs.deadnix
              pkgs.statix

              (pkgs.writeShellApplication {
                name = "ff";
                text = lib.getExe formatter;
              })
            ];
          };
        };
    };
}
