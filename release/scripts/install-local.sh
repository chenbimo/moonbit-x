#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# Workspace-mode build: build this member's command, then install it the same
# way bm2's install-local.sh does. Builds only ever happen in WSL.
export PATH="$HOME/.moon/bin:$PATH"
build_dir="$(dirname "$root")/_build-wsl"
pkg="$root/src/cmd/release"

moon build "$pkg" --target-dir "$build_dir" --target native
source_exe="$build_dir/native/debug/build/chensuiyi/release/cmd/release/release.exe"
target_dir="$HOME/.local/bin"

mkdir -p "$target_dir"
cp "$source_exe" "$target_dir/release.new"
chmod +x "$target_dir/release.new"
mv -f "$target_dir/release.new" "$target_dir/release"
printf 'installed release to %s\n' "$target_dir"
