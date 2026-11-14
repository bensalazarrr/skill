#!/usr/bin/env sh
# Bounded project scan for bootstrapping .agent/PROJECT_MAP.md.
# Prunes dependency, build, and VCS directories; caps output so it stays cheap to read.
# Lists pruned directories (with shallow entry counts) so generated folders stay visible.
# Usage: sh scripts/scan-project.sh [root] [max_files] [depth]
set -eu

ROOT="${1:-.}"
MAX="${2:-200}"
DEPTH="${3:-6}"

cd "$ROOT" || { echo "scan-project: cannot enter '$ROOT'"; exit 1; }
ROOT_ABS=$(pwd)

SKIP_DIRS="node_modules .git .hg .svn dist build out .next .nuxt .svelte-kit vendor .venv venv env __pycache__ .mypy_cache .pytest_cache .ruff_cache target coverage .nyc_output .dart_tool .pub-cache Pods .gradle obj bin .idea .vscode .turbo .cache .expo .terraform DerivedData .parcel-cache"
SKIP_FILES="package-lock.json pnpm-lock.yaml yarn.lock poetry.lock Cargo.lock composer.lock go.sum bun.lockb Pipfile.lock"

prune_expr=""
for d in $SKIP_DIRS; do
  prune_expr="$prune_expr${prune_expr:+ -o }-name $d"
done

skip_file_expr=""
for f in $SKIP_FILES; do
  skip_file_expr="$skip_file_expr${skip_file_expr:+|}^${f}\$"
done

list=$(find . -type d \( $prune_expr \) -prune -o -type f -print 2>/dev/null \
  | sed 's|^\./||' \
  | awk -F/ -v d="$DEPTH" 'NF-1 <= d' \
  | grep -Ev "$skip_file_expr" \
  | sort || true)

pruned=$(find . -maxdepth 3 -type d \( $prune_expr \) -print 2>/dev/null \
  | sed 's|^\./||' | awk '!seen[$0]++' | sort || true)

total=$(printf '%s\n' "$list" | grep -c . || true)
shown=$(printf '%s\n' "$list" | head -n "$MAX")
shown_count=$(printf '%s\n' "$shown" | grep -c . || true)
: "${total:=0}"
: "${shown_count:=0}"

echo "ROOT:  $ROOT_ABS"
echo "FILES: $total matched, $shown_count shown (cap $MAX, depth $DEPTH)"
echo ""
echo "MANIFESTS"
hints=0
if [ -f package.json ]; then
  name=$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' package.json | head -n 1)
  keys=$(sed -n '/"scripts"/,/}/p' package.json | sed -n 's/^[[:space:]]*"\([^"]*\)"[[:space:]]*:.*/\1/p' | grep -vx 'scripts' | tr '\n' ' ')
  echo "  package.json   name=${name:-?}   scripts=[${keys:-none}]"
  hints=$((hints + 1))
fi
for f in pyproject.toml requirements.txt setup.py Pipfile pubspec.yaml go.mod Cargo.toml Gemfile composer.json Makefile tsconfig.json vite.config.ts; do
  if [ -f "$f" ]; then echo "  $f   present"; hints=$((hints + 1)); fi
done
[ "$hints" -eq 0 ] && echo "  (none found - the stack may be uninitialized)"
echo ""
echo "PRUNED (not scanned - dependencies, build output, VCS)"
if [ -z "$pruned" ]; then
  echo "  (none)"
else
  printf '%s\n' "$pruned" | head -n 15 | while IFS= read -r d; do
    n=$(ls -A "$d" 2>/dev/null | wc -l | tr -d ' ')
    echo "  $d/  ($n items)"
  done
  pruned_count=$(printf '%s\n' "$pruned" | grep -c . || true)
  if [ "$pruned_count" -gt 15 ]; then echo "  ... $((pruned_count - 15)) more"; fi
fi
echo ""
echo "FILES"
printf '%s\n' "$shown" | sed 's/^/  /'
if [ "$total" -gt "$MAX" ]; then echo "  ... $((total - MAX)) more not shown"; fi
echo ""
echo "Next: write .agent/PROJECT_MAP.md from directories and entry points, not from every file."
