{
  description = "Flake for Andrew's KochiFOSS Talk about Nix in April 2025";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        nodejs = pkgs.nodejs_22;
        pnpm = pkgs.pnpm_10;

        packageJSON = pkgs.lib.importJSON ./package.json;

        devCommand = pkgs.writeShellScriptBin "dev" /* sh */ ''
          pnpm run dev
        '';
      in
        rec {
          packages.slides-bundle = pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "andrew-kochifoss-apr-2025-slides";
            version = packageJSON.version;

            src = ./.;

            nativeBuildInputs = [
              nodejs
              pnpm.configHook
            ];

            pnpmDeps = pnpm.fetchDeps {
              inherit (finalAttrs) pname version src;

              hash = "sha256-FmxYBsRYl4miQ7UNcBvQ+yZuApD0Ehx3V5gyb1+cVjo=";
            };

            buildPhase = /* sh */ ''
              runHook preBuild

              pnpm i --offline
              pnpm run build

              cp -r dist $out
            '';
          });

          packages.default = pkgs.writeShellScriptBin "andrew-slides" /* sh */ ''
            ${pkgs.http-server}/bin/http-server ${packages.slides-bundle}
          '';

          devShells.default = pkgs.mkShell {
            packages = [
              nodejs
              pnpm
              devCommand
            ];
          };
        }
    );
}
