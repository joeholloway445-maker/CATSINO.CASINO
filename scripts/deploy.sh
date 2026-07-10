#!/usr/bin/env bash
# deploy.sh — Deploy Periliminal.Space to the Hostinger VPS
# Run from the repo root after SSH-ing in:
#   git pull && bash scripts/deploy.sh
set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Periliminal.Space — VPS Deploy         ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── 1. Prerequisites ──────────────────────────────────────────────────────────
echo -e "${BOLD}[1/5] Checking prerequisites...${RESET}"
for cmd in docker docker-compose node npm; do
  if command -v "$cmd" &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} $cmd"
  else
    echo -e "  ${RED}✗${RESET} $cmd — NOT FOUND. Install it and re-run."
    exit 1
  fi
done

# ── 2. Env file ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/5] Checking .env...${RESET}"
if [ ! -f ".env" ]; then
  echo -e "  ${RED}✗${RESET} .env not found. Copy .env.example to .env and fill in values."
  exit 1
fi
# Warn if still using placeholder values
if grep -q "REPLACE_WITH" .env 2>/dev/null; then
  echo -e "  ${YELLOW}⚠${RESET}  .env has unfilled placeholder values — check it before continuing."
fi
echo -e "  ${GREEN}✓${RESET} .env present"

# ── 3. Build Nakama TypeScript RPC modules ────────────────────────────────────
echo -e "${BOLD}[3/5] Building Nakama RPC modules...${RESET}"
NAKAMA_MODULES="godot/src/networking/nakama_modules"
if [ -f "$NAKAMA_MODULES/package.json" ]; then
  (cd "$NAKAMA_MODULES" && npm install --silent && npm run build)
  echo -e "  ${GREEN}✓${RESET} Nakama modules compiled"
else
  echo -e "  ${RED}✗${RESET} $NAKAMA_MODULES/package.json not found"
  exit 1
fi

# ── 4. Create build/web directory if Godot export was not done yet ─────────────
echo -e "${BOLD}[4/5] Checking Godot HTML5 build...${RESET}"
if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
  echo -e "  ${GREEN}✓${RESET} build/web/ found"
else
  mkdir -p build/web
  cat > build/web/index.html <<'EOF'
<!DOCTYPE html>
<html><head><title>Game loading...</title></head>
<body style="background:#000;color:#fff;font-family:monospace;text-align:center;padding-top:20%">
  <h2>🐱 CATSINO.CASINO</h2>
  <p>Game build not yet deployed. Run the Godot headless export and copy build/web/ here.</p>
  <pre>godot --headless --export-release "Web" build/web/index.html</pre>
</body></html>
EOF
  echo -e "  ${YELLOW}⚠${RESET}  No Godot HTML5 build found. Placeholder page deployed."
  echo -e "     Run: godot --headless --export-release \"Web\" build/web/index.html"
fi

# ── 5. Start / rebuild services ───────────────────────────────────────────────
echo -e "${BOLD}[5/5] Starting services...${RESET}"
docker-compose pull nakama-db nakama 2>/dev/null || true
docker-compose up -d --build
echo -e "  ${GREEN}✓${RESET} Services started"

echo ""
echo -e "${BOLD}Deployment complete!${RESET}"
echo ""
echo -e "  Catsino web:   http://localhost:3000  (behind proxy: \$CATSINO_DOMAIN)"
echo -e "  HDV Core web:  http://localhost:3001  (behind proxy: \$HDV_DOMAIN)"
echo -e "  Godot game:    http://localhost:8080  (behind proxy: \$PLAY_DOMAIN)"
echo -e "  Nakama API:    http://localhost:7350"
echo -e "  Nakama admin:  http://localhost:7351  (SSH tunnel only)"
echo ""
echo -e "  ${YELLOW}HTTPS setup (first deploy only):${RESET}"
echo -e "  Run scripts/setup_certs.sh to obtain Let's Encrypt certs, then"
echo -e "  uncomment the HTTPS server blocks in nginx/proxy.conf."
echo ""
