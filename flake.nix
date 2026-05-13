{
  description = "R.nvim Overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rnvimsrc = {
      url = "github:R-nvim/R.nvim/v0.99.4";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    rnvimsrc,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: let
      rnvimVersion = "v0.99.4";

      pkgs = import nixpkgs {inherit system;};
    in rec {
      nvimcom = pkgs.rPackages.buildRPackage {
        pname = "nvimcom";
        version = rnvimVersion;
        src = "${rnvimsrc}/nvimcom";
      };

      rnvimserver = pkgs.stdenv.mkDerivation {
        pname = "rnvimserver";
        version = rnvimVersion;
        src = rnvimsrc;

        nativeBuildInputs = [pkgs.gnumake pkgs.gcc];

        preBuild = ''
          cp -r rnvimserver rnvimserver-src
          chmod -R +w rnvimserver-src
        '';

        buildPhase = ''
          runHook preBuild
          make -C rnvimserver-src
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -Dm755 rnvimserver-src/rnvimserver $out/bin/rnvimserver
          runHook postInstall
        '';
      };

      r-nvim = (pkgs.vimUtils.buildVimPlugin {
        pname = "R.nvim";
        version = rnvimVersion;
        src = rnvimsrc;
      }).overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/rnvimserver
          cp ${rnvimserver}/bin/rnvimserver $out/rnvimserver/rnvimserver
          chmod +x $out/rnvimserver/rnvimserver
        '';
      });

      default = r-nvim;
    });

    overlays.default = final: prev: {
      nvimcom = self.packages.${final.stdenv.hostPlatform.system}.nvimcom;
      rnvimserver = self.packages.${final.stdenv.hostPlatform.system}.rnvimserver;
      r-nvim = self.packages.${final.stdenv.hostPlatform.system}.r-nvim;
    };
  };
}
