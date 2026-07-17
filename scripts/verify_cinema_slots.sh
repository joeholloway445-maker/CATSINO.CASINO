#!/usr/bin/env bash
# Verify PeriHuman / MetaHuman ship slots are present and non-trivial.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS="$ROOT/godot/assets/models"
ok=0
fail=0
min_bytes="${MIN_BYTES:-50000}"

check() {
  local f="$1"
  local path="$MODELS/$f"
  if [[ ! -f "$path" ]]; then
    echo "FAIL missing $f"
    fail=$((fail + 1))
    return
  fi
  local n
  n="$(wc -c < "$path")"
  if (( n < min_bytes )); then
    echo "FAIL $f too small ($n < $min_bytes) — placeholder?"
    fail=$((fail + 1))
    return
  fi
  echo "ok $f ($n bytes)"
  ok=$((ok + 1))
}

for f in peri_human_player.glb peri_human_npc.glb metahuman_player.glb metahuman_npc.glb; do
  check "$f"
done

echo "RESULT slots ok=$ok fail=$fail"
exit "$([[ $fail -eq 0 ]] && echo 0 || echo 1)"
