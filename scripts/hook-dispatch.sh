#!/bin/bash
# Git hook dispatcher: run one hook stage inside the environment that actually
# has the toolchain.
#
# The workspace's checks need the MoonBit toolchain, which lives in WSL; git,
# however, is usually driven from Windows. The hook crosses that boundary
# instead of demanding a toolchain on both sides.
#
# Activated via: git config core.hooksPath .githooks
set -u

stage=${1:?usage: hook-dispatch.sh <stage> [args...]}
shift || true

root=$(git rev-parse --show-toplevel)

case "$(uname -s)" in
  Linux*)
    cd "$root"
    exec bash "scripts/$stage.sh" "$@"
    ;;
  *)
    if ! command -v wsl.exe >/dev/null 2>&1; then
      echo "git-hook: wsl.exe not found, but the checks need the WSL toolchain."
      echo "          Commit from WSL, or skip this hook with --no-verify."
      exit 1
    fi
    # Keep MSYS/Git Bash from rewriting the Unix paths we pass through.
    MSYS2_ARG_CONV_EXCL='*'
    export MSYS2_ARG_CONV_EXCL
    wsl_root=$(wsl.exe -d Debian -- wslpath -u "$root" 2>/dev/null | tr -d '\r')
    if [ -z "$wsl_root" ]; then
      echo "git-hook: cannot translate '$root' to a WSL path."
      exit 1
    fi
    # Extra arguments (the commit-msg file path) are translated to WSL paths
    # and handed over through the environment, so no shell quoting of values
    # ever crosses the boundary.
    exported=""
    index=1
    for arg in "$@"; do
      translated=$(wsl.exe -d Debian -- wslpath -u "$arg" 2>/dev/null | tr -d '\r')
      [ -n "$translated" ] || translated="$arg"
      exported="$exported MOONBIT_HOOK_ARG$index=$translated"
      index=$((index + 1))
    done
    exec wsl.exe -d Debian -- env $exported bash -lc "cd '$wsl_root' && bash scripts/$stage.sh \"\$MOONBIT_HOOK_ARG1\""
    ;;
esac
