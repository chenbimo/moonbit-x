#!/bin/bash
# The fast gate on every commit, scoped to the members a change touches.
#
# Per changed member: moon fmt (auto-fixed and re-staged) + the strict
# type/warning check. bm2 additionally keeps its version invariant.
# The slow half — unit tests, native builds, the e2e run — belongs to
# scripts/pre-push.sh.
#
# Runs inside WSL via scripts/hook-dispatch.sh.
set -euo pipefail

export PATH="$HOME/.moon/bin:$PATH"

root=$(pwd)
[ -f "$root/moon.work" ] || {
  echo "pre-commit: no moon.work here; run from the workspace root"
  exit 1
}

# Per-environment build dir: hooks and manual WSL runs share it, and neither
# touches the tree the Windows IDE may be using.
build_dir="$root/_build-wsl"
mkdir -p "$build_dir"

source "$root/scripts/lib/common.sh"

# Which members does this commit touch?
staged=$(git diff --cached --name-only --diff-filter=d)
changed=$(members_from_paths $staged)
if [ -z "$changed" ] || [ "$changed" = "root" ]; then
  echo "pre-commit: only root-level files changed, nothing to check"
  exit 0
fi
echo "pre-commit: changed members: $(echo "$changed" | tr '\n' ' ')"

# Formatting is fixed automatically rather than reported. The snapshot pair
# tells apart files fmt rewrote (re-stage) from files that also carry the
# committer's own unstaged edits (needs a human decision).
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

dirty_snapshot() {
  git diff --name-only --diff-filter=d | while IFS= read -r file; do
    [ -n "$file" ] || continue
    printf '%s\t%s\n' "$file" "$(git hash-object -- "$file")"
  done | sort
}

pkgs=""
for dir in $changed; do
  # "root" is the pseudo-member for root-level files: no compile gate.
  [ "$dir" = "root" ] && continue
  pkgs="$pkgs $(member_pkgs "$dir")"
done

dirty_snapshot > "$tmp/before"
# shellcheck disable=SC2086
moon fmt $pkgs --target-dir "$build_dir" >/dev/null
dirty_snapshot > "$tmp/after"

awk -F'\t' '
  NR == FNR { before[$1] = $2; next }
  {
    after[$1] = 1
    if ($1 in before) {
      if (before[$1] != $2) print "dirty\t" $1
    } else {
      print "new\t" $1
    }
  }
  END { for (file in before) if (!(file in after)) print "reverted\t" file }
' "$tmp/before" "$tmp/after" > "$tmp/reformatted"

needs_attention=0
while IFS=$'\t' read -r kind file; do
  [ -n "$kind" ] || continue
  case "$kind" in
    new)
      echo "pre-commit: moon fmt reformatted and re-staged: $file"
      git add -- "$file"
      ;;
    reverted)
      echo "pre-commit: moon fmt normalized back to the committed content: $file"
      ;;
    dirty)
      echo "pre-commit: moon fmt reformatted $file, which also has your own unstaged edits."
      echo "            git add -- $file   # then commit again"
      needs_attention=1
      ;;
  esac
done < "$tmp/reformatted"
[ "$needs_attention" = 0 ] || exit 1

# Per-member strict checks.
for dir in $changed; do
  [ "$dir" = "root" ] && continue
  echo "pre-commit: checking $dir ..."
  if ! member_check "$dir" "$build_dir"; then
    echo "pre-commit: $dir failed moon check; commit aborted."
    echo "            (git commit --no-verify skips this gate)"
    exit 1
  fi
done

# bm2's version invariant: moon.mod and the CLI's VERSION constant agree.
case "$changed" in
  *bm2*)
    source "$root/bm2/scripts/lib/checks.sh"
    if ! check_version_sync "$root/bm2"; then
      echo "pre-commit: fix the version invariant above before committing."
      exit 1
    fi
    ;;
esac

echo "pre-commit: ok"
