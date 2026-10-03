#!/bin/bash
# Enforce the workspace commit-message convention (see AGENTS.md):
#
#   [项目名](类型) 提交内容
#
# Merge and revert commits are exempt — git generates their first line.
# Runs inside WSL via scripts/hook-dispatch.sh. The message file is the repo's
# .git/COMMIT_EDITMSG (git always prepares it there for -m/-F; MERGE_MSG for
# merges), derived from the repository root rather than passed across the
# Windows/WSL boundary.
set -euo pipefail

msgfile="${1:-.git/COMMIT_EDITMSG}"
if [ ! -f "$msgfile" ]; then
  echo "commit-msg: no commit message file received"
  exit 1
fi

first=$(head -n 1 "$msgfile" | tr -d '\r')

case "$first" in
  "Merge "*|"Revert "*)
    echo "commit-msg: merge/revert commit, format check skipped"
    exit 0
    ;;
esac

# 允许的项目名 = moon.work 全体成员目录名 + root。成员列表动态解析,
# 新增成员无需再改本钩子(与 AGENTS.md"项目名=成员目录名自动适用"一致)。
members=$(grep -oE '^  "[^"]+"' moon.work | tr -d ' "' | paste -sd '|' - || true)

if ! printf '%s' "$first" | grep -qE "^\[(${members}|root)\]\((feat|fix|docs|refactor|test|chore)\) [^ ].*$"; then
  cat <<EOF
commit-msg: 提交说明不符合工作区约定(见根目录 AGENTS.md)。

  实际首行: $first
  要求格式: [项目名](类型) 提交内容
    项目名: moon.work 成员(${members})或 root
    类型:   feat | fix | docs | refactor | test | chore
  示例:    [bm2](feat) 新增 reload 命令

(确实需要跳过: git commit --no-verify)
EOF
  exit 1
fi

echo "commit-msg: ok"
