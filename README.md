# R.nvim Overlay

Nix flake overlay for [R.nvim](https://github.com/R-nvim/R.nvim) v1.0.0 — a Neovim plugin for R development.

## Packages

All built for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`:

| Package | Type | Description |
|---------|------|-------------|
| `r-nvim` | Neovim plugin (`vimUtils.buildVimPlugin`) | The R.nvim plugin itself. This is the `default` package. |
| `nvimcom` | R package (`rPackages.buildRPackage`) | R-side companion package from `nvimcom/` subdirectory. |
| `rnvimserver` | C binary (`stdenv.mkDerivation`) | Compiled from `rnvimserver/` via `make` using `gnumake` + `gcc`. Installed to `$out/bin/rnvimserver`. |

## Usage

### As a flake input

```nix
{
  inputs.r-nvim.url = "github:dwinkle1/r_nvim_nix";

  outputs = { self, nixpkgs, r-nvim, ... }: {
    devShells.x86_64-linux.default =
      nixpkgs.legacyPackages.x86_64-linux.mkShell {
        buildInputs = [
          r-nvim.packages.x86_64-linux.r-nvim
        ];
      };
  };
}
```

### As an overlay

```nix
nixpkgs.overlays = [ r-nvim.overlays.default ];
```

This adds `r-nvim`, `nvimcom`, and `rnvimserver` to `pkgs`.

### With `home-manager`

```nix
{ config, pkgs, ... }: {
  nixpkgs.overlays = [ inputs.r-nvim.overlays.default ];

  programs.neovim.plugins = [ pkgs.r-nvim ];
}
```

## Wiring the components

R.nvim uses all three packages together. The communication flow (from [upstream docs](https://github.com/R-nvim/R.nvim)):

```
Neovim  ←─stdin/stdout─→  rnvimserver  ←─TCP─→  nvimcom (inside R session)
```

### `rnvimserver` — on `$PATH`

`rnvimserver` is a C binary that Neovim launches as a background job. It must be
available on `$PATH`. Add it to your environment:

```nix
# home-manager
home.packages = [ pkgs.rnvimserver ];

# Or in a devShell
buildInputs = [ pkgs.rnvimserver ];
```

R.nvim discovers `rnvimserver` automatically when it's on `$PATH`.

### `nvimcom` — installable in R

`nvimcom` is an R package that must be installed in R's library so the R session
can load it. Since the flake builds it with `rPackages.buildRPackage`, you can
install it into your R environment:

```nix
# As a system R package (if using nixpkgs.rWrapper or similar)
buildInputs = [ pkgs.rnvimserver pkgs.nvimcom ];

# Or install manually into a user or project library:
# R CMD INSTALL /nix/store/...-nvimcom-v1.0.0
```

Alternatively, add `nvimcom` to your `R_LIBS_SITE` or `R_LIBS_USER` so R can
find it:

```nix
home.sessionVariables = {
  R_LIBS_SITE = "${pkgs.nvimcom}/library:${pkgs.R}/library";
};
```

R.nvim tells R where `nvimcom` lives when it starts the R session, so
installing it anywhere in R's library path suffices.

## Structure

```
flake.nix        # Package definitions + overlay
nvimcom/         # R package source (bundled from upstream)
rnvimserver/     # C server source (bundled from upstream)
```
