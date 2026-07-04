#!/usr/bin/env bash
# CATSINO.CASINO — one-click Godot + Nakama dev setup
set -e

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║     CATSINO.CASINO  Setup Script         ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── 1. Prerequisites ────────────────────────────────────────────────────────
echo -e "${BOLD}[1/5] Checking prerequisites...${RESET}"

check_cmd() {
  if command -v "$1" &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} $1"
  else
    echo -e "  ${RED}✗${RESET} $1 — NOT FOUND"
    MISSING="$MISSING $1"
  fi
}

MISSING=""
check_cmd docker
check_cmd docker-compose || check_cmd "docker compose"
check_cmd node
check_cmd npm

if [ -n "$MISSING" ]; then
  echo -e "${RED}Install missing tools and re-run.${RESET}"
  exit 1
fi

# ── 2. Nakama TypeScript modules ────────────────────────────────────────────
echo -e "${BOLD}[2/5] Building Nakama TypeScript modules...${RESET}"
if [ -f "src/networking/nakama_modules/package.json" ]; then
  if (cd src/networking/nakama_modules && npm install && npm run build); then
    echo -e "  ${GREEN}✓${RESET} Nakama TS compiled to build/index.js"
  else
    echo -e "  ${RED}✗${RESET} TypeScript build failed — fix errors above before continuing"
    exit 1
  fi
else
  echo -e "  ${RED}✗${RESET} No package.json found in nakama_modules — cannot build RPCs"
  exit 1
fi

# ── 3. Start Docker (Nakama + Postgres) ─────────────────────────────────────
echo -e "${BOLD}[3/5] Starting Nakama + Postgres via Docker...${RESET}"
if [ -f "docker-compose.yml" ]; then
  docker-compose up -d
  echo -e "  ${GREEN}✓${RESET} Containers started"
  echo -e "  Nakama console → ${BOLD}http://localhost:7351${RESET}"
  echo -e "  Nakama gRPC    → localhost:7349"
  echo -e "  Nakama HTTP    → localhost:7350"
else
  echo -e "  ${RED}✗${RESET} docker-compose.yml not found in $SCRIPT_DIR"
  exit 1
fi

# ── 4. Wait for Nakama health ─────────────────────────────────────────────
echo -e "${BOLD}[4/5] Waiting for Nakama to be ready...${RESET}"
MAX=30
COUNT=0
until curl -sf http://localhost:7350/healthcheck &>/dev/null; do
  sleep 2
  COUNT=$((COUNT+1))
  if [ $COUNT -ge $MAX ]; then
    echo -e "  ${YELLOW}⚠${RESET}  Nakama not ready after ${MAX} attempts — check Docker logs"
    break
  fi
  echo -n "."
done
echo ""
echo -e "  ${GREEN}✓${RESET} Nakama ready"

# ── 5. Done ───────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}[5/5] Setup complete!${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  1. Open Godot 4.3, import ${BOLD}$(pwd)/project.godot${RESET}"
echo -e "  2. In Project → Project Settings → Plugins, enable ${BOLD}Nakama${RESET}"
echo -e "  3. Press ${BOLD}F5${RESET} to run — login via DeviceID happens automatically"
echo -e "  4. Web dashboard: run ${BOLD}npm run dev${RESET} from the repo root"
echo ""
echo -e "  Nakama console: ${BOLD}http://localhost:7351${RESET}  (admin / password)"
echo ""
