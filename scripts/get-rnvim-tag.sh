#!/usr/bin/env bash

set -euo pipefail

tag_regex='v[0-9]+\.[0-9]+\.[0-9]+[^"[:space:]]*'

if [ "${1:-}" = "--tag-regex" ]; then
  printf '%s\n' "$tag_regex"
  exit 0
fi

flake_file="${1:-flake.nix}"
matches="$(grep -Eo "github:R-nvim/R.nvim/${tag_regex}" "$flake_file" || true)"
match_count="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l)"

if [ "$match_count" -ne 1 ]; then
  echo "Expected exactly one R.nvim source match in ${flake_file}, found ${match_count}" >&2
  exit 1
fi

tag="$(printf '%s\n' "$matches" | sed '/^$/d' | sed 's|^github:R-nvim/R.nvim/||')"

if [ -z "$tag" ]; then
  echo "Failed to detect R.nvim release tag from ${flake_file}" >&2
  exit 1
fi

printf '%s\n' "$tag"
