#!/bin/bash
# The full gate before anything leaves the machine: every member runs its
# complete verification, regardless of what the push contains — a push is
# rare and cheap compared to a broken main.
#
#   bm2     -> scripts/verify.sh (fmt/check/unit/build; e2e 属发布流程)
#   notify  -> moon check --deny-warn + unit tests
#   release -> moon check --deny-warn + native build
#
# Runs inside WSL via scripts/hook-dispatch.sh.
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

root=$(pwd)
[ -f "$root/moon.work" ] || {
  echo "pre-push: no moon.work here; run from the workspace root"
  exit 1
}

echo "pre-push: bm2 验证(fmt/check/单测/构建;e2e 仅发布时跑)..."
bash "$root/bm2/scripts/verify.sh"

echo "pre-push: notify 检查与测试..."
moon check --target native --deny-warn --warn-list +implicit_impl_as_method notify/src
moon test -p chensuiyi/notify --target native

echo "pre-push: release 检查与构建..."
moon check --target native --deny-warn --warn-list +implicit_impl_as_method release/src
moon build --target native release/src

echo "pre-push: ok"
