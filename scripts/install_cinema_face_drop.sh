#!/usr/bin/env bash
# Install a cinema-face GLB drop into the shipped PeriHuman / MetaHuman slots.
#
# Owner trials: export from CC4 / MetaHuman (UE→Blender) / DAZ as GLB, then:
#   bash scripts/install_cinema_face_drop.sh path/to/player.glb path/to/npc.glb
#
# Copies into BOTH peri_human_* and metahuman_* so MetahumanCharacter resolves
# either name. Players never install the DCC tool — only these GLBs ship.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS="$ROOT/godot/assets/models"

PLAYER_SRC="${1:-}"
NPC_SRC="${2:-}"

if [[ -z "$PLAYER_SRC" || -z "$NPC_SRC" ]]; then
  echo "Usage: $0 <player.glb> <npc.glb>" >&2
  echo "Optional env: BACKUP=1 (default) keeps *.pre_cinema.glb copies." >&2
  exit 2
fi
[[ -f "$PLAYER_SRC" ]] || { echo "missing player GLB: $PLAYER_SRC" >&2; exit 1; }
[[ -f "$NPC_SRC" ]] || { echo "missing npc GLB: $NPC_SRC" >&2; exit 1; }

BACKUP="${BACKUP:-1}"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_one() {
  local dest="$1"
  if [[ "$BACKUP" == "1" && -f "$dest" ]]; then
    cp -f "$dest" "${dest%.glb}.pre_cinema.${stamp}.glb"
    echo "backed up $(basename "$dest") → $(basename "${dest%.glb}.pre_cinema.${stamp}.glb")"
  fi
}

for slot in peri_human_player metahuman_player; do
  dest="$MODELS/${slot}.glb"
  backup_one "$dest"
  cp -f "$PLAYER_SRC" "$dest"
  echo "installed player → $slot.glb ($(wc -c < "$dest") bytes)"
done
for slot in peri_human_npc metahuman_npc; do
  dest="$MODELS/${slot}.glb"
  backup_one "$dest"
  cp -f "$NPC_SRC" "$dest"
  echo "installed npc → $slot.glb ($(wc -c < "$dest") bytes)"
done

echo
echo "Done. Open Godot once so .import sidecars refresh, then Play Offline."
echo "See docs/OWNER_TRIALS.md for CC4 / MetaHuman / DAZ export notes."
