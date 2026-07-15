#!/usr/bin/env bash
# Install the recommended addon stack into godot/addons/. Every addon
# below is pure GDScript (no GDExtension) so the Web export target still
# works. Idempotent — re-running updates each addon to its pinned tag.
#
# Usage (from the repo root):
#   bash scripts/install_addons.sh              # install everything
#   bash scripts/install_addons.sh dialogue     # single addon
#
# Requires: git. Pins and enable steps: docs/ADDONS.md

set -euo pipefail
cd "$(dirname "$0")/.."

ADDONS_DIR="godot/addons"
mkdir -p "$ADDONS_DIR"

# Preserve the in-house Nakama stub; never wipe the whole addons dir.
install_from_git() {
	local name="$1"
	local repo="$2"
	local tag="$3"
	local subdir="$4"   # path inside clone; use "." when repo root IS the addon
	local dest="$ADDONS_DIR/$name"

	local tmp
	tmp="$(mktemp -d)"
	# shellcheck disable=SC2064
	trap "rm -rf '$tmp'" RETURN

	echo "→ $name  ($repo @ $tag)"
	if ! git clone --depth 1 --branch "$tag" "https://github.com/$repo.git" "$tmp/src" 2>/dev/null; then
		echo "  branch/tag $tag missing — cloning default branch"
		git clone --depth 1 "https://github.com/$repo.git" "$tmp/src"
	fi

	local src_path="$tmp/src"
	if [ "$subdir" != "." ]; then
		src_path="$tmp/src/$subdir"
	fi
	if [ ! -d "$src_path" ]; then
		echo "  ✗ path $subdir missing in $repo" >&2
		return 1
	fi

	rm -rf "$dest"
	mkdir -p "$(dirname "$dest")"
	cp -a "$src_path" "$dest"
	# Drop nested .git so the monorepo owns the tree
	rm -rf "$dest/.git"
	echo "  ✓ installed to $dest"
}

ONLY="${1:-all}"

install_all() {
	# Dialogue Manager v3.3.3 — Godot 4.3 compatible (not DM4 main)
	install_from_git "dialogue_manager" \
		"nathanhoad/godot_dialogue_manager" "v3.3.3" "addons/dialogue_manager"
	install_from_git "phantom_camera" \
		"ramokz/phantom-camera" "main" "addons/phantom_camera"
	install_from_git "beehave" \
		"bitbrain/beehave" "v2.9.2" "addons/beehave"
	install_from_git "maaacks_menus_template" \
		"Maaack/Godot-Menus-Template" "main" "addons/maaacks_menus_template"
	# Mirror repo root == addon folder
	install_from_git "panku_console" \
		"Ark2000/panku_console" "main" "."
	install_from_git "gdUnit4" \
		"MikeSchulze/gdUnit4" "v4.3.4" "addons/gdUnit4"
	# Gloot v2.4.x for Godot 4.3 (master requires 4.4+)
	install_from_git "gloot" \
		"peter-kish/gloot" "v2.4.13" "addons/gloot"
}

case "$ONLY" in
	all)      install_all ;;
	dialogue) install_from_git "dialogue_manager" "nathanhoad/godot_dialogue_manager" "v3.3.3" "addons/dialogue_manager" ;;
	phantom)  install_from_git "phantom_camera" "ramokz/phantom-camera" "main" "addons/phantom_camera" ;;
	beehave)  install_from_git "beehave" "bitbrain/beehave" "v2.9.2" "addons/beehave" ;;
	menus)    install_from_git "maaacks_menus_template" "Maaack/Godot-Menus-Template" "main" "addons/maaacks_menus_template" ;;
	panku)    install_from_git "panku_console" "Ark2000/panku_console" "main" "." ;;
	gdunit)   install_from_git "gdUnit4" "MikeSchulze/gdUnit4" "v4.3.4" "addons/gdUnit4" ;;
	gloot)    install_from_git "gloot" "peter-kish/gloot" "v2.4.13" "addons/gloot" ;;
	*)        echo "unknown addon: $ONLY (dialogue|phantom|beehave|menus|panku|gdunit|gloot|all)" >&2; exit 2 ;;
esac

echo
echo "✓ Done. In Godot: Project → Project Settings → Plugins → enable each."
echo "  Then Editor → Restart. Panku Console: enable only in debug builds."
echo "  See docs/ADDONS.md. Do not enable Terrain3D/LimboAI for Web export."
