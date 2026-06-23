#!/usr/bin/env bash
# CATSINO.CASINO — Repo Factory Script
# Usage: ./repo_factory.sh [--full|--addons-only|--structure-only]
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERR]${NC}   $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}━━━ $* ━━━${NC}\n"; }

# ── Flags ─────────────────────────────────────────────────────────────────────
MODE="full"
for arg in "$@"; do
  case "$arg" in
    --full)           MODE="full" ;;
    --addons-only)    MODE="addons" ;;
    --structure-only) MODE="structure" ;;
    *) error "Unknown flag: $arg"; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GODOT_DIR="$REPO_ROOT/periliminal-0623"

# ── Structure ─────────────────────────────────────────────────────────────────
create_structure() {
  header "Creating Godot Project Structure"

  local dirs=(
    "src/core"
    "src/character"
    "src/combat"
    "src/companion"
    "src/games"
    "src/world"
    "src/social"
    "src/liveops"
    "assets/characters/races"
    "assets/shaders"
    "assets/audio/music"
    "assets/audio/sfx"
    "assets/fonts"
    "assets/ui"
    "scenes/world/districts"
    "scenes/games/slots"
    "scenes/games/racing"
    "scenes/games/sports"
    "scenes/games/cards"
    "scenes/games/puzzle"
    "scenes/games/arcade"
    "scenes/ui/hud"
    "scenes/ui/menus"
    "scenes/character"
    "addons"
    "shaders"
  )

  for d in "${dirs[@]}"; do
    local path="$GODOT_DIR/$d"
    if [[ ! -d "$path" ]]; then
      mkdir -p "$path"
      info "Created $d"
    else
      warn "Exists  $d"
    fi
  done

  # Race subdirectories
  local races=(Keth Lumari Vex Ferox Azhul Sylva Geara Nyx Aquis Igni
               Kryos Myco Volt Petra Sanguis Chimera Astra Ferros Etherea Glyphe)
  for race in "${races[@]}"; do
    local rpath="$GODOT_DIR/assets/characters/races/$race"
    mkdir -p "$rpath"
    touch "$rpath/.gitkeep"
  done
  success "Race directories created (${#races[@]} races)"

  # .gitkeep for leaf dirs
  local keep_dirs=(
    "assets/shaders" "assets/audio/music" "assets/audio/sfx"
    "scenes/world/districts" "scenes/games/slots" "scenes/games/racing"
    "scenes/games/sports" "scenes/games/cards" "scenes/games/puzzle"
    "scenes/games/arcade" "scenes/ui/hud" "scenes/ui/menus"
    "scenes/character" "shaders"
  )
  for d in "${keep_dirs[@]}"; do
    touch "$GODOT_DIR/$d/.gitkeep"
  done
  success "Directory structure complete"
}

# ── Git Submodules ─────────────────────────────────────────────────────────────
add_submodule() {
  local url="$1" path="$2" name="$3"
  if [[ -d "$GODOT_DIR/addons/$path/.git" ]] || git -C "$REPO_ROOT" submodule status "periliminal-0623/addons/$path" &>/dev/null 2>&1; then
    warn "Submodule already exists: $name"
    return 0
  fi
  info "Adding submodule: $name"
  git -C "$REPO_ROOT" submodule add --force "$url" "periliminal-0623/addons/$path" 2>&1 | tail -1 || {
    warn "git submodule add failed for $name — trying plain clone"
    git clone --depth 1 "$url" "$GODOT_DIR/addons/$path"
  }
  success "Added: $name -> periliminal-0623/addons/$path"
}

clone_addons() {
  header "Cloning External Addons"

  # Ensure we're in a git repo
  if [[ ! -d "$REPO_ROOT/.git" ]]; then
    warn "Not a git repo — initializing"
    git -C "$REPO_ROOT" init
    git -C "$REPO_ROOT" commit --allow-empty -m "chore: init repo"
  fi

  # Heroic Labs — Nakama server (Go backend, for reference)
  add_submodule \
    "https://github.com/heroiclabs/nakama" \
    "nakama-server" \
    "Nakama Server"

  # Heroic Labs — Godot 4 client
  add_submodule \
    "https://github.com/heroiclabs/nakama-godot-4" \
    "nakama-godot-4" \
    "Nakama Godot 4 Client"

  # Slot Machine prototype
  add_submodule \
    "https://github.com/CadanoX/Godot-Slot-Machine" \
    "godot-slot-machine" \
    "Godot Slot Machine"

  # Talo analytics / backend
  add_submodule \
    "https://github.com/TaloDev/backend" \
    "talo-backend" \
    "Talo Backend"

  # LiveKit (WebRTC)
  add_submodule \
    "https://github.com/livekit/livekit" \
    "livekit" \
    "LiveKit"

  # PostHog analytics
  add_submodule \
    "https://github.com/PostHog/posthog" \
    "posthog" \
    "PostHog"

  # Dialogue manager
  add_submodule \
    "https://github.com/nathanhoad/godot_dialogue_manager" \
    "dialogue-manager" \
    "Godot Dialogue Manager"

  success "All addons processed"
}

# ── Docker Compose (Nakama) ────────────────────────────────────────────────────
create_docker_compose() {
  header "Writing Nakama Docker Compose"
  local compose_path="$REPO_ROOT/docker/nakama/docker-compose.yml"
  mkdir -p "$(dirname "$compose_path")"
  cat > "$compose_path" <<'YAML'
version: "3.9"

services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: nakama
      POSTGRES_PASSWORD: localdb
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres", "-d", "nakama"]
      interval: 5s
      timeout: 5s
      retries: 5

  nakama:
    image: registry.heroiclabs.com/heroiclabs/nakama:3.22.0
    entrypoint:
      - "/bin/sh"
      - "-ecx"
      - >
        /nakama/nakama migrate up --database.address postgres:localdb@postgres:5432/nakama &&
        exec /nakama/nakama --name catsino --database.address postgres:localdb@postgres:5432/nakama
        --socket.port 7350 --api.port 7351 --console.port 7352
        --runtime.path /nakama/data/modules
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "7349:7349"   # game socket
      - "7350:7350"   # HTTP API
      - "7351:7351"   # gRPC API
      - "7352:7352"   # admin console
    volumes:
      - ./modules:/nakama/data/modules
    restart: unless-stopped

volumes:
  pgdata:
YAML
  success "docker/nakama/docker-compose.yml written"
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
  echo -e "${BOLD}${CYAN}"
  echo "  ╔═══════════════════════════════════════╗"
  echo "  ║   CATSINO.CASINO — Repo Factory       ║"
  echo "  ║   Mode: $MODE$(printf '%*s' $((30 - ${#MODE})) '')║"
  echo "  ╚═══════════════════════════════════════╝"
  echo -e "${NC}"

  case "$MODE" in
    full)
      create_structure
      clone_addons
      create_docker_compose
      ;;
    addons)
      clone_addons
      ;;
    structure)
      create_structure
      create_docker_compose
      ;;
  esac

  echo -e "\n${GREEN}${BOLD}✓ CATSINO.CASINO scaffold ready!${NC}"
  echo -e "  Godot project: ${CYAN}$GODOT_DIR${NC}"
  echo -e "  Next steps:"
  echo -e "    1. Open $GODOT_DIR in Godot 4.x"
  echo -e "    2. cd docker/nakama && docker compose up -d"
  echo -e "    3. Enable addons in Project > Project Settings > Plugins"
}

main
