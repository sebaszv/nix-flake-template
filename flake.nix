{
  outputs = _: {
      templates = rec {
        default = flake-parts;

        flake-parts = {
          path = ./flake-parts;
          description = "Starter development environment using `flake-parts`";
        };
        vanilla = {
          path = ./flake-parts;
          description = "Starter development environment";
        };
      };
    };
}
