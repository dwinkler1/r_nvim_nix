{
  description = "Minimal R + Neovim + R.nvim dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    r-nvim.url = "path:../..";
  };

  outputs = { self, nixpkgs, r-nvim, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ r-nvim.overlays.default ];
      };
      treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [ p.r ]);
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.R
          pkgs.neovim
          pkgs."r-nvim"
          pkgs.rnvimserver
          pkgs.nvimcom
          treesitter
        ];

        shellHook = ''
          export R_LIBS_SITE="${pkgs.nvimcom}/library:${pkgs.R}/library"

          INIT_LUA=$(mktemp -t rnvim-init-XXXXXXXX).lua
          cat > "$INIT_LUA" << LUA
vim.g.R_path = "${pkgs.R}/bin/R"
vim.g.R_nvimcom_path = "${pkgs.nvimcom}/library"
vim.cmd("set rtp^=${treesitter}")
vim.cmd("set rtp^=${pkgs."r-nvim"}")
require("r").setup()
LUA

          alias rnvim="nvim -u '$INIT_LUA'"
          echo "R.nvim dev shell — run 'rnvim' to start Neovim with R.nvim"
        '';
      };
    };
}
