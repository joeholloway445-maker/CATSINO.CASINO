#!/usr/bin/env bash
# Build Nakama TypeScript modules into the volume mount used by
# docker-compose.dev.yml (Gate 8 local multiplayer).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOD="$ROOT/godot/src/networking/nakama_modules"
cd "$MOD"
if [[ ! -d node_modules ]]; then
  npm ci
fi
npm run build
echo "Nakama modules built → $MOD/build"
ls -la "$MOD/build" | head -20
