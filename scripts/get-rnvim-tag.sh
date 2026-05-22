#!/usr/bin/env bash

set -euo pipefail

flake_file="${1:-flake.nix}"
tag_regex='v[0-9]+\.[0-9]+\.[0-9]+[^"[:space:]]*'
tag="$(grep -Eo "github:R-nvim/R.nvim/${tag_regex}" "$flake_file" | head -n 1 | sed 's|^github:R-nvim/R.nvim/||')"

if [ -z "$tag" ]; then
  echo "Failed to detect R.nvim release tag from ${flake_file}" >&2
  exit 1
fi

printf '%s\n' "$tag"
