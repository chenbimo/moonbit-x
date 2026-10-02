#!/bin/bash
# The full gate before anything leaves the machine: every member runs its
# complete verification, regardless of what the push contains — a push is
# rare and cheap compared to a broken main.
#
#   bm2     -> scripts/verify.sh (fmt/check/unit/build/e2e)
#   notify  -> moon check --deny-warn + unit tests
#   release -> moon check --deny-warn + native build
#
# Runs inside WSL via scripts/hook-dispatch.sh.
set -euo pipefail

export PATH="$HOME/.moon/bin:$PATH"

root=$(pwd)
[ -f "$root/moon.work" ] || {
  echo "pre-push: no moon.work here; run from the workspace root"
  exit 1
}

echo "pre-push: bm2 全量验证(fmt/check/单测/构建/e2e)..."
bash "$root/bm2/scripts/verify.sh"

echo "pre-push: notify 检查与测试..."
moon check --target native --deny-warn --warn-list +implicit_impl_as_method notify/src
moon test -p chensuiyi/notify --target native

echo "pre-push: release 检查与构建..."
moon check --target native --deny-warn --warn-list +implicit_impl_as_method release/src
moon build --target native release/src

echo "pre-push: ok"
