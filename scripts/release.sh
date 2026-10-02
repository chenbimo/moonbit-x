#!/bin/bash
# Build (when needed) and run the workspace release tool.
# 用法:bash scripts/release.sh [--patch|--minor|--major] [--dry-run] [模块名...]
set -euo pipefail
export PATH="$HOME/.moon/bin:$PATH"

cd "$(dirname "$0")/.."
moon build --target native release
exec ./_build/native/debug/build/chensuiyi/release/release.exe "$@"
