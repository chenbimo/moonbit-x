#!/bin/bash
# Workspace member registry and shared helpers for the git hooks.
#
# The monorepo holds several independently checkable members. Every hook is
# scoped by which top-level directories a change actually touches, so a
# notify-only commit never pays for bm2's suite.

# Members with gates: directory names parsed from moon.work, so a newly
# added member is gated automatically. Root-level files (moon.work,
# README.md, AGENTS.md) map to the pseudo-member "root": they have no
# compile gate, only the commit-message format.

workspace_root=$(git rev-parse --show-toplevel)
member_dirs=($(grep -oE '^  "[^"]+"' "$workspace_root/moon.work" | tr -d ' "'))

# Package paths fed to `moon fmt` / `moon check` for one member directory.
# bm2 has multiple packages; every other member is the single src package.
member_pkgs() {
  case "$1" in
    bm2)
      printf '%s\n' "bm2/src bm2/src/config bm2/src/core bm2/src/process bm2/src/ipc bm2/src/cmd/bm2 bm2/src/cmd/bm2d"
      ;;
    *)
      printf '%s\n' "$1/src"
      ;;
  esac
}

# Map staged/changed paths (one per line) to the set of member directories
# they belong to. Paths outside the known members map to "root".
members_from_paths() {
  for file in "$@"; do
    [ -n "$file" ] || continue
    matched=0
    for dir in "${member_dirs[@]}"; do
      case "$file" in
        "$dir"/*|"$dir")
          echo "$dir"
          matched=1
          break
          ;;
      esac
    done
    [ "$matched" = 1 ] || echo "root"
  done | sort -u
}

# Per-member fast gate: the type/warning check that must pass before any
# commit of that member. Formatting is handled by the caller.
member_check() {
  local dir="$1" build_dir="$2" pkgs
  pkgs=$(member_pkgs "$dir")
  # shellcheck disable=SC2086
  moon check $pkgs --target-dir "$build_dir" --target native --deny-warn --warn-list +implicit_impl_as_method
}

# Per-member full gate for pre-push. bm2 runs its own verify.sh (unit tests,
# native build, end-to-end); every other member runs its package tests.
member_verify() {
  local root="$1" dir="$2"
  case "$dir" in
    bm2)
      bash "$root/bm2/scripts/verify.sh"
      ;;
    *)
      moon test "$dir/src" --target native
      ;;
  esac
}
