#!/bin/bash
# Build (when needed) and run the workspace release tool.
# 用法:bash scripts/release.sh [--patch|--minor|--major] [--dry-run] [模块名...]
set -euo pipefail
# The hook may run from Windows git through WSL as any user; probe the
# well-known toolchain locations instead of trusting $HOME.
if ! command -v moon > /dev/null 2>&1; then
  for candidate in /root/.moon/bin /home/*/.moon/bin "$HOME/.moon/bin"; do
    if [ -x "$candidate/moon" ]; then
      export PATH="$candidate:$PATH"
      break
    fi
  done
fi

cd "$(dirname "$0")/.."

# Releasing bm2 runs its full gate (fmt/check/unit/build + e2e) first.
case " $* " in
  *" bm2 "*)
    echo "release: bm2 完整验证(含 e2e)..."
    bash bm2/scripts/verify.sh --with-e2e
    ;;
esac

moon build --target-dir _build-wsl --target native release
exec ./_build-wsl/native/debug/build/chensuiyi/release/release.exe "$@"
