# The Periliminal Space ecosystem

This monorepo is the canonical home for Periliminal Space, but it isn't the
only repository in the account that touches this universe. This doc maps
every related repo to its actual role, so "where does X live" has one
answer instead of eight scattered READMEs that don't cross-reference each
other.

## Canonical (this repo)

**CATSINO.CASINO** — the single Periliminal.Space monorepo: `apps/catsino-casino`
and `apps/hdv-core` (the two Next.js skins), `godot/` (the canonical Godot 4
client, including the preserved-but-unwired `godot/hdv_lore/` subtree),
`services/psychology` (the LangGraph behavioral engine), `supabase/`
(the one shared Postgres schema), and the Nakama/Docker deploy stack.
Everything under `docs/reference/periliminal_space_v0.0.1/` is the original
Google Apps Script design-scaffolding for this project — races, morphology,
crowns, guilds, and the AI-companion vision that `godot/src/companion/hope.gd`
and `services/psychology` are the real implementation of.

## Already merged (tombstone)

**THE-HDV-CORE** — the repo this monorepo was split out of. Fully absorbed;
its own README says as much ("kept for history only; do not open new work
here"). No remaining action — mentioned here only so nobody goes looking
for active HDV-core work in the wrong place.

## Reference-only (not vendored, on purpose)

**tps-demo** — an unmodified upstream clone of `godotengine/tps-demo`.
Code is MIT, but the ~934MB of models/textures/audio are CC-BY and not
worth vendoring for a differently-branded game — this repo already reached
that conclusion (see the "asset-free" note in this file's own history).
What *is* worth borrowing, as rewritten patterns rather than copied files,
to fill the gap `docs/SHIPPING.md` §5 flags ("PvE/PvXC combat is
simulated/statted, not real gameplay"):
- `enemies/red_robot/red_robot.gd` — IDLE→APPROACH→AIM→SHOOTING enemy FSM
  with line-of-sight gating before firing.
- `enemies/red_robot/parts/part.gd` — detachable-ragdoll death VFX.
- `player/camera_noise_shake_effect.gd` — trauma-based camera shake via
  `FastNoiseLite`, asset-free and directly portable.

No port has been done yet; this is a pointer for whoever picks up the
combat-AI gap next.

## Sister apps (separately deployed, same universe)

**AdultKidsSite** — the live consumer front end for this monorepo's
**PersonaMatrix** system (`apps/hdv-core/lib/personamatrix/*`, Supabase
migration `027_*` — the Dream/Hope/No_One/Vision/Apex persona/tenant
model). Two age-gated PWA consoles ("Google Antigravity" adult console,
"My Friend & AI" kids console) served from `hopedreamvision.com` and
`myfriendand.ai` via plain nginx — a different deploy target than this
repo's Vercel+Hostinger-docker-compose stack, which is why it stays a
separate repo rather than an `apps/` entry here. If PersonaMatrix's
API contract changes, AdultKidsSite is the consumer that breaks.

**hope-studio** — currently just a one-line README ("Exported from
Taskade"), no other content. Name strongly suggests it's meant to hold
product/design docs for the Hope companion line, but nothing has been
seeded there yet — treat it as reserved, not populated.

**THE-HDV-test** — currently empty (zero commits). Reserved name/repo
with no defined purpose yet.

## Concrete unresolved integration points

The original design doc (`docs/reference/periliminal_space_v0.0.1/Gameplay_AI_World.gs`)
calls a webhook (`UrlFetchApp.fetch("31.97.98.79:5678/webhook/generate-asset",
{model_link: "robbyant/lingbot-world-base-cam"})`) that was never resolved
anywhere else in this codebase. Two repos in this account are the actual
candidates for closing that gap and were evaluated for this purpose:

**lingbot-world** — this account's own actively-customized Apache-2.0 fork
of an image+text-conditioned world-model video diffusion model (forked from
Wan2.2, the exact `lingbot-world-base-cam` model the `.gs` webhook names).
Local commits already add a WASD/IJKL action-string playground
(`run_playground.py`, `assets/playground.html`) and a CPU/quantized
low-resource path (`setup_kvm4.sh`). A realistic integration: an async
service that takes a scene image + an action sequence and returns a short
explorable video clip per reality layer — not real-time in-engine
steering, but a buildable "world preview / dream sequence" generator.
Not yet wired into this repo; no `services/world-model` exists.

**mistral-APEX-Nodes** — a pristine upstream clone of `mistral-inference`.
Apache-2.0 code; weight licenses are mixed (7B/Nemo/Small-3.1/Mathstral/
Codestral-Mamba are commercially usable, Codestral and Large-2 are not).
Ships its own vLLM Docker image exposing an OpenAI-compatible endpoint.
Candidate as a self-hosted alternative to `apps/hdv-core/app/api/hope/route.ts`,
which currently hardcodes the Anthropic API for Hope's conversational
dialogue, and to `services/psychology`, which is currently a pure heuristic
with no LLM at all. Not yet wired into this repo.

Both are documented here as the identified candidates; neither has been
deployed or integrated yet — that's a real architecture decision (hosting
cost, latency, license scope for the LLM) for whoever picks it up.
