#!/usr/bin/env bash

set -euo pipefail

flake_file="${1:-flake.nix}"
tag_regex='v[0-9]+\.[0-9]+\.[0-9]+[^"]*'

tag="$(sed -E -n "s/.*url = \"github:R-nvim\\/R.nvim\\/(${tag_regex})\".*/\\1/p" "$flake_file" | head -n 1)"

if [ -z "$tag" ]; then
  echo "Failed to detect R.nvim release tag from ${flake_file}" >&2
  exit 1
fi

printf '%s\n' "$tag"
