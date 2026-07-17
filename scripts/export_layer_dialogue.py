#!/usr/bin/env python3
"""Export per-layer NPC dialogue JSON from NpcDialogueLibrary.LINES.

Writes godot/src/dialogue/<archetype>_<layer>.json in NPCDialogueSystem format.
Hyperliminal trees prefer the richer hub JSON (quest options, multi-branch)
when present; other layers use library greeting + lore lines.

Run from repo root:
  python3 scripts/export_layer_dialogue.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "godot/src/world/npc_dialogue_library.gd"
OUT = ROOT / "godot/src/dialogue"
ARCHETYPES = ["barista", "archivist", "authority", "lover", "reflection"]
LAYERS = [
    "subliminal",
    "liminal",
    "supraliminal",
    "hyperliminal",
    "extraliminal",
    "periliminal",
]

# Short disposition variants keyed by archetype → layer → (friendly, hostile).
# Kept brief so the greeting/lore lines remain the lore carriers.
DISPOSITION: dict[str, dict[str, tuple[str, str]]] = {
    "barista": {
        "subliminal": (
            "Sit. I'll remake it. No questions asked.",
            "We're done for the night. Door's that way.",
        ),
        "liminal": (
            "You took the cup. Good. That keeps the loop kind.",
            "Don't take the cup. Don't come back. The hallway prefers that.",
        ),
        "supraliminal": (
            "You're within tolerance. Enjoy the pour.",
            "Deviation logged. Service denied.",
        ),
        "hyperliminal": (
            "Your usual — already steaming. On the house this once.",
            "We're closing. Take a seat somewhere else.",
        ),
        "extraliminal": (
            "Banner or not, you're welcome at my counter.",
            "Wrong colors for this ground. Keep walking.",
        ),
        "periliminal": (
            "Stay. One more cup. You always stay.",
            "Craving denied. Leave before you remember why you came.",
        ),
    },
    "archivist": {
        "subliminal": (
            "Pull up a binder. I trust your eyes.",
            "Those files are not for you. Close the drawer.",
        ),
        "liminal": (
            "I'll show you the wing that grew last night.",
            "The exit map is sealed. So is this conversation.",
        ),
        "supraliminal": (
            "You're cleared for the permitted shelves.",
            "Clearance revoked. Gaps stay gaps.",
        ),
        "hyperliminal": (
            "Ah — a fellow keeper of records. Sit. The files like you.",
            "Those binders are sealed. Walk away.",
        ),
        "extraliminal": (
            "Our history, then. The accurate one.",
            "Factionless ears don't get our records.",
        ),
        "periliminal": (
            "I'll read back what you filed. Gently.",
            "You don't want those memories tonight. Leave them buried.",
        ),
    },
    "authority": {
        "subliminal": (
            "Friendly advice, then: stick to the lit streets.",
            "I said go home. That was the soft version.",
        ),
        "liminal": (
            "You followed the rules. The hallway noticed.",
            "You asked a question. That was the mistake.",
        ),
        "supraliminal": (
            "You look like someone who does their part. Good.",
            "Off-grid behavior. Step away from the desk.",
        ),
        "hyperliminal": (
            "You're on the list. Don't make me take you off it.",
            "You're not on the floor. You're not on the list. Leave.",
        ),
        "extraliminal": (
            "State accepted. Walk with the banner.",
            "No allegiance, no passage. Move.",
        ),
        "periliminal": (
            "Straighten up. Try again. I'll watch.",
            "Disappoint me again and there is no again.",
        ),
    },
    "lover": {
        "subliminal": (
            "Hey. Stay close a minute. You seem far away.",
            "Not tonight. Don't make me say it twice.",
        ),
        "liminal": (
            "You came back. That means something here.",
            "Don't remember me like this. Just go.",
        ),
        "supraliminal": (
            "Reservations still hold. I always save you a place.",
            "I can't want what you want tonight. Leave.",
        ),
        "hyperliminal": (
            "There you are. I saved you a seat that isn't on the floor plan.",
            "Don't look at me like that. Not tonight.",
        ),
        "extraliminal": (
            "Walk with me. Report later — or never.",
            "Recruitment's off. So is the charm.",
        ),
        "periliminal": (
            "I see all of it. I'm still here. Say that's enough.",
            "Don't ask me to stay if you won't believe me.",
        ),
    },
    "reflection": {
        "subliminal": (
            "You can stare. I'll tell you which pause is yours.",
            "Stop looking. You won't sleep either way.",
        ),
        "liminal": (
            "Hand on the glass, then. I'll show you the cost.",
            "No trade. Knock somewhere else.",
        ),
        "supraliminal": (
            "Borrow my silence for an hour. It fits.",
            "Keep your noise. I already optimized past you.",
        ),
        "hyperliminal": (
            "Oh. You came back to the glass. Most people don't.",
            "You don't want to know which one of us is losing time.",
        ),
        "extraliminal": (
            "Same face, my flag. Walk under it a while.",
            "Factionless mirror — I have nothing for you.",
        ),
        "periliminal": (
            "Take my hand. Integration hurts less than pretending.",
            "Fight me or run. Don't stand there pretending I'm not yours.",
        ),
    },
}


def parse_lines_from_gd(text: str) -> dict[str, dict[str, list[str]]]:
    """Extract LINES const: archetype → layer → [greeting, lore]."""
    m = re.search(r"const LINES := \{([\s\S]*?)\n\}", text)
    if not m:
        raise SystemExit("Could not find const LINES in npc_dialogue_library.gd")
    body = m.group(1)
    lines: dict[str, dict[str, list[str]]] = {}
    current_arch: str | None = None
    current_layer: str | None = None
    pair: list[str] = []
    for raw in body.splitlines():
        line = raw.strip()
        arch_m = re.match(r'"(\w+)": \{', line)
        if arch_m and arch_m.group(1) in ARCHETYPES:
            current_arch = arch_m.group(1)
            lines.setdefault(current_arch, {})
            current_layer = None
            pair = []
            continue
        layer_m = re.match(r'"(\w+)": \[', line)
        if layer_m and current_arch and layer_m.group(1) in LAYERS:
            current_layer = layer_m.group(1)
            pair = []
            continue
        str_m = re.match(r'"((?:\\.|[^"\\])*)"', line)
        if str_m and current_arch and current_layer:
            # Keep UTF-8 as-is; only unescape GD string quotes/backslashes.
            raw_s = str_m.group(1).replace("\\\\", "\0").replace('\\"', '"').replace("\0", "\\")
            pair.append(raw_s)
            if len(pair) >= 2:
                lines[current_arch][current_layer] = pair[:2]
                current_layer = None
                pair = []
    return lines


def tree_from_library(greeting: str, lore: str, friendly: str, hostile: str) -> dict:
    return {
        "greeting": {
            "line": greeting,
            "line_friendly": friendly,
            "line_hostile": hostile,
            "allow_social_options": True,
            "options": [
                {
                    "text": "Tell me more.",
                    "next_key": "lore",
                    "effect": {"disposition": 3},
                },
                {
                    "text": "Just passing through.",
                    "next_key": None,
                    "effect": {},
                },
            ],
        },
        "lore": {
            "line": lore,
            "allow_social_options": False,
            "options": [
                {
                    "text": "I'll remember that.",
                    "next_key": None,
                    "effect": {"disposition": 5},
                }
            ],
        },
    }


def load_hub(archetype: str) -> dict | None:
    path = OUT / f"{archetype}.json"
    if not path.exists():
        return None
    data = json.loads(path.read_text())
    return data if isinstance(data, dict) else None


def main() -> int:
    lib_text = LIB.read_text()
    lines = parse_lines_from_gd(lib_text)
    written = 0
    for arch in ARCHETYPES:
        if arch not in lines:
            print(f"FAIL missing archetype in LINES: {arch}", file=sys.stderr)
            return 1
        for layer in LAYERS:
            pair = lines[arch].get(layer)
            if not pair or len(pair) < 2:
                print(f"FAIL missing {arch}/{layer}", file=sys.stderr)
                return 1
            friendly, hostile = DISPOSITION[arch][layer]
            if layer == "hyperliminal":
                hub = load_hub(arch)
                tree = hub if hub else tree_from_library(
                    pair[0], pair[1], friendly, hostile
                )
            else:
                tree = tree_from_library(pair[0], pair[1], friendly, hostile)
            out_path = OUT / f"{arch}_{layer}.json"
            out_path.write_text(json.dumps(tree, indent=2, ensure_ascii=False) + "\n")
            written += 1
            print(f"  wrote {out_path.relative_to(ROOT)}")
    print(f"Exported {written} layer dialogue trees.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
