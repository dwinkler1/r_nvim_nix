{
  description = "R.nvim packaging";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rnvimsrc =let
  rnvimVersion = "v0.99.4";
in
 {
      url = "github:R-nvim/R.nvim/$rnvimVersion";
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

  rnvimVersion = "v0.99.4";


          pkgs = import nixpkgs { inherit system; };
        in
        rec {
          nvimcom = pkgs.rPackages.buildRPackage {
            pname = "nvimcom";
            version = rnvimVersion;
            src = "${rnvimsrc}/nvimcom";
          };

          rnvimserver = pkgs.stdenv.mkDerivation {
            pname = "rnvimserver";
            version = rnvimVersion;
            src = rnvimsrc;

            nativeBuildInputs = [ pkgs.gnumake pkgs.gcc ];

            buildPhase = ''
              runHook preBuild
              make -C rnvimserver
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              install -Dm755 rnvimserver/rnvimserver $out/bin/rnvimserver
              runHook postInstall
            '';
          };

          r-nvim = pkgs.vimUtils.buildVimPlugin {
            pname = "R.nvim";
            version = rnvimVersion;
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
