#!/usr/bin/env bash
# Install the recommended addon stack into godot/addons/. Every addon
# below is pure GDScript (no GDExtension) so the Web export target still
# works. Idempotent — re-running updates each addon to its pinned tag.
#
# Usage (from the repo root):
#   bash scripts/install_addons.sh              # install everything
#   bash scripts/install_addons.sh dialogue     # single addon
#
# Requires: git, unzip, curl. All addons ship a top-level addon folder
# and MIT-family licenses (details in docs/ADDONS.md).

set -euo pipefail
cd "$(dirname "$0")/.."

ADDONS_DIR="godot/addons"
mkdir -p "$ADDONS_DIR"

# ── Pinned versions ──────────────────────────────────────────────────
# Tags picked for Godot 4.3+ compatibility as of the AGENTS.md target
# window (mid-2026). Bump when a new stable of the addon lands.
DIALOGUE_MANAGER_REPO="nathanhoad/godot_dialogue_manager"
DIALOGUE_MANAGER_TAG="main"        # tagged releases lag the plugin store
PHANTOM_CAMERA_REPO="ramokz/phantom-camera"
PHANTOM_CAMERA_TAG="main"
BEEHAVE_REPO="bitbrain/beehave"
BEEHAVE_TAG="main"
MAAACK_MENUS_REPO="Maaack/Godot-Menus-Template"
MAAACK_MENUS_TAG="main"
VIRTUAL_JOYSTICK_REPO="MarcoFazioRandom/Virtual-Joystick-Godot"
VIRTUAL_JOYSTICK_TAG="master"      # upstream default is still master
KENNEY_INPUT_PROMPTS_REPO="unfoldedcat/godot-kenney-input-prompts"
KENNEY_INPUT_PROMPTS_TAG="main"
PANKU_CONSOLE_REPO="Ark2000/PankuConsole"
PANKU_CONSOLE_TAG="main"
GDUNIT4_REPO="MikeSchulze/gdUnit4"
GDUNIT4_TAG="master"

install_from_git() {
	local name="$1"
	local repo="$2"
	local tag="$3"
	local subdir="$4"
	local dest="$ADDONS_DIR/$name"

	local tmp
	tmp="$(mktemp -d)"
	trap "rm -rf $tmp" RETURN

	echo "→ $name  ($repo @ $tag)"
	git clone --depth 1 --branch "$tag" "https://github.com/$repo.git" "$tmp/src" 2>/dev/null \
		|| git clone --depth 1 "https://github.com/$repo.git" "$tmp/src"

	if [ ! -d "$tmp/src/$subdir" ]; then
		echo "  ✗ subdir $subdir missing in $repo" >&2
		return 1
	fi

	rm -rf "$dest"
	mv "$tmp/src/$subdir" "$dest"
	rm -rf "$tmp"
	echo "  ✓ installed to $dest"
}

# Pick either single addon or all
ONLY="${1:-all}"

install_all() {
	install_from_git "dialogue_manager"      "$DIALOGUE_MANAGER_REPO"      "$DIALOGUE_MANAGER_TAG"      "addons/dialogue_manager"
	install_from_git "phantom_camera"        "$PHANTOM_CAMERA_REPO"        "$PHANTOM_CAMERA_TAG"        "addons/phantom_camera"
	install_from_git "beehave"               "$BEEHAVE_REPO"               "$BEEHAVE_TAG"               "addons/beehave"
	install_from_git "maaacks_menus_template" "$MAAACK_MENUS_REPO"         "$MAAACK_MENUS_TAG"          "addons/maaacks_menus_template"
	install_from_git "virtual_joystick"      "$VIRTUAL_JOYSTICK_REPO"      "$VIRTUAL_JOYSTICK_TAG"      "addons/virtual_joystick"
	install_from_git "kenney_input_prompts"  "$KENNEY_INPUT_PROMPTS_REPO"  "$KENNEY_INPUT_PROMPTS_TAG"  "addons/kenney_input_prompts"
	install_from_git "panku_console"         "$PANKU_CONSOLE_REPO"         "$PANKU_CONSOLE_TAG"         "addons/panku_console"
	install_from_git "gdUnit4"               "$GDUNIT4_REPO"               "$GDUNIT4_TAG"               "addons/gdUnit4"
}

case "$ONLY" in
	all)               install_all ;;
	dialogue)          install_from_git "dialogue_manager" "$DIALOGUE_MANAGER_REPO" "$DIALOGUE_MANAGER_TAG" "addons/dialogue_manager" ;;
	phantom)           install_from_git "phantom_camera" "$PHANTOM_CAMERA_REPO" "$PHANTOM_CAMERA_TAG" "addons/phantom_camera" ;;
	beehave)           install_from_git "beehave" "$BEEHAVE_REPO" "$BEEHAVE_TAG" "addons/beehave" ;;
	menus)             install_from_git "maaacks_menus_template" "$MAAACK_MENUS_REPO" "$MAAACK_MENUS_TAG" "addons/maaacks_menus_template" ;;
	joystick)          install_from_git "virtual_joystick" "$VIRTUAL_JOYSTICK_REPO" "$VIRTUAL_JOYSTICK_TAG" "addons/virtual_joystick" ;;
	prompts)           install_from_git "kenney_input_prompts" "$KENNEY_INPUT_PROMPTS_REPO" "$KENNEY_INPUT_PROMPTS_TAG" "addons/kenney_input_prompts" ;;
	panku)             install_from_git "panku_console" "$PANKU_CONSOLE_REPO" "$PANKU_CONSOLE_TAG" "addons/panku_console" ;;
	gdunit)            install_from_git "gdUnit4" "$GDUNIT4_REPO" "$GDUNIT4_TAG" "addons/gdUnit4" ;;
	*)                 echo "unknown addon: $ONLY" >&2; exit 2 ;;
esac

echo
echo "✓ Done. In Godot: Project → Project Settings → Plugins → enable each."
echo "  Then Editor → Restart. Panku Console should be enabled only in"
echo "  dev/editor builds, never in the shipped Web export."
