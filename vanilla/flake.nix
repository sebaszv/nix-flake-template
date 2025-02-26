{
  inputs = {
    systems.url = "github:nix-systems/default";

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
    let
      eachSystem = f:
        inputs.nixpkgs.lib.genAttrs
          (import inputs.systems)
          (system: f inputs.nixpkgs.legacyPackages.${system});

      treefmt = eachSystem (pkgs:
        (inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.lock";
          programs.nixpkgs-fmt.enable = true;
        }).config.build.wrapper);

      pre-commit = eachSystem (pkgs:
        inputs.pre-commit-hooks.lib.${pkgs.system}.run {
          src = ./.;
          hooks.treefmt = {
            enable = true;
            package = treefmt.${pkgs.system};
            pass_filenames = false;
          };
        }
      );
    in
    rec {
      checks = eachSystem (pkgs: {
        pre-commit = pre-commit.${pkgs.system};
      });
      formatter = eachSystem (pkgs: treefmt.${pkgs.system});
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShellNoCC {
          inherit (pre-commit.${pkgs.system}) shellHook;

          packages = [
            pkgs.git

            pkgs.nil
            pkgs.deadnix
            pkgs.statix

            (pkgs.writeShellApplication {
              name = "ff";
              text = pkgs.lib.getExe formatter.${pkgs.system};
            })
          ];
        };
      });
    };
}
