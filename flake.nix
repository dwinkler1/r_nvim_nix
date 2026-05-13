{
  description = "R.nvim packaging";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rnvimsrc = {
      url = "github:R-nvim/R.nvim/v0.99.4";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rnvimsrc }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        rec {
          nvimcom = pkgs.rPackages.buildRPackage {
            pname = "nvimcom";
            version = "0.99.4";
            src = "${rnvimsrc}/nvimcom";
          };

          rnvimserver = pkgs.stdenv.mkDerivation {
            pname = "rnvimserver";
            version = "0.99.4";
            src = rnvimsrc;

            nativeBuildInputs = [
              pkgs.gnumake
              pkgs.gcc
            ];

            buildPhase = ''
              runHook preBuild
              cd rnvimserver
              make
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              install -Dm755 rnvimserver $out/bin/rnvimserver
              runHook postInstall
            '';
          };

          r-nvim = pkgs.vimUtils.buildVimPlugin {
            pname = "R.nvim";
            version = "0.99.4";
            src = rnvimsrc;
          };

          default = r-nvim;
        });

      overlays.default = final: prev: {
        nvimcom = self.packages.${final.system}.nvimcom;
        rnvimserver = self.packages.${final.system}.rnvimserver;
        r-nvim = self.packages.${final.system}.r-nvim;
      };
    };
}
