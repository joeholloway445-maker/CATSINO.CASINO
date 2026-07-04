# PersonaMatrix — Build Tutorial & Walkthrough

This is the big one, so here's the whole thing in plain steps: what got built,
how to turn each piece on, and how the surfaces connect. No prior context needed.

---

## The one-paragraph mental model

`hdv-core` is now **one backbone with several surfaces**. The backbone is
PersonaMatrix: a registry of up to 20,480 **ephemeral personas** that each
*spawn → do one task → terminate*, with every execution's cost logged to a
ledger. Nothing runs idle. Everything — the Dream streaming tool, the
periliminal.space site, the Godot game client, future enterprise tenants —
talks to that backbone through **one HTTP endpoint**. Build the endpoint once,
and every surface gets persona logic + billing for free. That's the automation
keystone you asked to tackle first.

```
                 POST /api/personamatrix/request
                 { module, role, task } → { result, cost_usd }
                              │
        ┌──────────┬──────────┼───────────┬─────────────┐
     DREAM       HOPE       NO_ONE      VISION         (Godot)
   streaming  site/content  security  white-label    game client
   filters    personas      audit     tenants        over HTTP
```

---

## Part 1 — See the backbone working (30 seconds, no setup)

The core is a 1:1 TypeScript port of the original Python `core/`. Run the live
demo — it spawns a real Dream session (a `filter_director` reads "energy" and
picks a filter chain each beat; `commenter` personas burst in and chatter; the
Apex ledger tallies cost):

```bash
cd hdv-core
npx tsx scripts/demo-backbone.ts
```

You'll see ~50 personas spawn, react, and die in one run, ending with a billing
report. Cost is effectively $0 because each execution is sub-millisecond — that
*is* the design: compute is borrowed for one breath, never held.

**This is the same code the API route runs.** `lib/personamatrix/persona.ts`
(lifecycle + role handlers) and `lib/personamatrix/matrix.ts` (Apex orchestrator)
are imported by both the demo and `app/api/personamatrix/request/route.ts`.

---

## Part 2 — See the Dream module *visually* (open one file)

Open **`public/dream-deck.html`** in any browser — double-click it, no server
needed. It's the Dream control deck:

- A live canvas runs the **filter chains** ported from `filters/engine.py` to
  real-time canvas math: `scarecrow_proceedings`, `squid_round`, `full_breakdown`.
- The **persona chat** overlay is the simulated audience — commenter personas
  spawn, drop a line, and terminate. The chat rate scales with the energy slider.
- The **filter_director** reads the energy slider and auto-switches chains
  (energy > 0.8 → full_breakdown, > 0.5 → scarecrow, else squid) — exactly the
  logic in `core/persona.py`.
- The **Apex billing ledger** panel ticks up executions and cost live.
- Keys `1/2/3` switch chains, `0` = standby, `space` = burst the chat, and
  "use my webcam" swaps the synthetic subject for your real camera (optional).

> **Guardrail baked in:** the simulated audience is rendered *into the video
> frame* as theater — it never posts to a real platform's chat. That's the line
> from the handoff doc: personas perform on surfaces you own.

In the desktop build (Antigravity), this same pipeline outputs through
`pyvirtualcam` so OBS sees a "PersonaMatrix Cam" — the web deck is the visual
proof of that exact filter stack.

---

## Part 3 — Turn the API on for real (Supabase-backed)

The endpoints are already live on Vercel (both `the-hdv-core` and
`periliminal.space` deploy green). To make the ledger persist, point it at
Supabase:

1. **Apply the migration.** In the Supabase SQL editor, run
   `supabase/migrations/002_personamatrix.sql`. This creates `tenants`,
   `personas`, and `persona_ledger`.
2. **Set env vars** (locally in `.env.local`, and in the Vercel project
   dashboard → Settings → Environment Variables — *not* legacy Secrets):
   ```
   NEXT_PUBLIC_SUPABASE_URL=...
   NEXT_PUBLIC_SUPABASE_ANON_KEY=...
   SUPABASE_SERVICE_ROLE_KEY=...      # server-only, powers ledger/tenant writes
   ANTHROPIC_API_KEY=...              # persona "brains" when they need to think
   ```
3. **Call it:**
   ```bash
   curl -X POST http://localhost:3000/api/personamatrix/request \
     -H 'content-type: application/json' \
     -d '{"module":"dream","role":"commenter","task":{"context":"the proceedings"}}'
   # → {"result":{"persona":0,"type":"chat","text":"...","persona_uid":"a1b2c3d4"},"cost_usd":0}
   ```
4. **Read the billing report:** `GET /api/personamatrix/ledger` →
   `{ executions, total_spend_usd, by_module }`.

> Note: `/api/*` sits behind the auth middleware (`proxy.ts`). For
> machine-to-machine calls (Godot, the desktop app), the cleanest path is the
> per-tenant `X-Api-Key` header — see Part 5 — rather than a user session.

---

## Part 4 — Populate the personas (your worldbuilding = the content)

Your Entity Roster + Omni Dex are the moat: 4,096 personas with real mythology.

1. In Google Drive, export the roster as JSON — an array of
   `{ id, module, name, tier, lore_summary, voice_style, behavioral_traits }`.
2. Save it to `scripts/entity-roster.json` (gitignored — it's content, not code).
3. Run `npx tsx scripts/import-entity-roster.ts` (needs `SUPABASE_SERVICE_ROLE_KEY`).

Now `GET /api/personamatrix/personas?module=hope` returns your real identities —
that endpoint will power the public **Dex** pages (free SEO, lore-driven
audience) when the periliminal.space surface gets built out.

---

## Part 5 — Wire in Godot (which AI to use + the prompt)

Full instructions are in **`GODOT_AI_SETUP.md`**. The short version:

- **Use Claude Code running inside the `godot/` folder** as a *separate* session
  — not a Godot-native autocomplete plugin. It already has filesystem + shell
  access and knows your existing Nakama networking pattern, so it can produce an
  HTTP client that matches your codebase instead of generic boilerplate.
- That doc contains a **ready-to-paste prompt** that tells it to build
  `persona_matrix_client.gd` — an autoload that calls `/request`, `/personas`,
  and `/ledger`, mirroring your existing `NetworkManager.call_rpc` style, with
  the backbone URL as a one-line-editable constant.
- Optionally add a Godot MCP server so Claude Code can drive the editor itself
  (open scenes, run the project) — also covered in the doc.

You don't write any GDScript yourself; that session reads your patterns and does it.

---

## What's built vs. what's next

| Piece | Status |
|---|---|
| PersonaMatrix core (persona lifecycle, Apex orchestrator) — TS port | ✅ working (`scripts/demo-backbone.ts`) |
| `POST /request`, `GET /ledger`, `GET /personas` | ✅ deployed (Vercel green) |
| Supabase schema (tenants / personas / persona_ledger) | ✅ migration ready to apply |
| Dream visual deck (filters + chat + director + cost) | ✅ `public/dream-deck.html` |
| Entity Roster importer | ✅ ready — needs the roster JSON exported from Drive |
| Godot client | 📋 prompt ready in `GODOT_AI_SETUP.md` |
| **Dream Studio** (`/studio`): filter chains + face filters + live persona chat + TTS + mic voice-changer + record | ✅ built — `components/studio/DreamStudio.tsx` |
| SSE persona-chat automation route | ✅ `GET /api/personamatrix/stream` (verified live) |
| VS Code-replica builder surface (from OKComputer zip) | ✅ built — `components/builder/BuilderShell.tsx` (`/builder`) |
| periliminal.space /dex + /matrix (GLSL filter ports, Three.js) | ⏭️ next phase |

Like the studio, the builder surface is "just another caller" of the backbone —
see Part 7 below for how its terminal wires into real PersonaMatrix traffic.

---

## Part 6 — The Dream Studio (`/studio`) — the live streaming surface

`/studio` is the full streaming/chat layer, all on one canvas, all browser-native
(no extra services, no keys to run it):

- **Filter chains** — the same `scarecrow_proceedings` / `squid_round` /
  `full_breakdown` stack, now a reusable TS module
  (`lib/personamatrix/filters/engine.ts`) shared with the standalone deck.
- **Face filters** — turn on the webcam + "track my face" to load MediaPipe's
  468-point FaceLandmarker (lazy-loaded from CDN) and pin **entity eyes**, a
  **scarecrow seam**, or a **third eye** to your real face
  (`lib/streaming/faceFilters.ts`).
- **Live persona chat** — the studio opens **one** SSE connection to
  `GET /api/personamatrix/stream`; the server spawns commenter + filter_director
  personas through the *same Apex backbone* and pushes each line down. Chat rate
  scales with the energy slider; every spawn lands in the ledger. One connection,
  the backbone decides who speaks — that's the automation route.
- **Voice** — toggle "personas speak" for per-persona TTS (Web Speech API), and
  pick an **entity / demon / chipmunk** preset to run *your* mic through a
  real-time Web Audio pitch-shifter (`lib/streaming/voice.ts`).
- **Record / go live** — `canvas.captureStream()` + the processed mic →
  `MediaRecorder` downloads a `.webm` of the whole production.

> Same guardrail as the deck: the simulated audience renders **into the frame**
> as theater — it never posts to a real platform's chat.

`/studio` sits behind the auth proxy like `/game`, so sign in first. The SSE
route is verified end-to-end (200 `text/event-stream`, real persona bursts whose
cadence tracks the energy param).

---

## Part 7 — The Builder (`/builder`) — a VS Code-replica surface on the backbone

`/builder` ports a standalone VS Code Web clone (title bar, activity bar,
explorer/search/SCM/run-debug/extensions sidebar, tab bar + Monaco editor,
bottom panel, status bar, command palette) into this app as a self-contained
client surface:

- **Shell** — `components/builder/BuilderShell.tsx` assembles the title bar,
  activity bar, sidebar, tab bar, Monaco editor area, bottom panel, and status
  bar, plus a `cmdk`-powered command palette (`Cmd/Ctrl+Shift+P` for commands,
  `Cmd/Ctrl+P` for go-to-file). It's mounted via `next/dynamic` with
  `ssr: false` (through `BuilderShellLoader.tsx`, a client wrapper — this
  Next.js version requires that option to be set from a Client Component) so
  IndexedDB, `window`, and Monaco's worker bootstrapping never run during SSR.
- **State** — Zustand stores under `lib/builder/store/*` hold the file tree,
  open tabs, sidebar view, git/SCM demo state, extensions, terminal tabs, and
  theme; `lib/builder/utils/persistence.ts` persists files/tabs/settings to an
  `idb`-backed IndexedDB database. The file tree, SCM panel, and problems panel
  are cosmetic demo content, same as the source project.
- **Editor** — `@monaco-editor/react` renders the active tab with VS
  Code-style themes (dark/light/solarized/monokai/github) registered on mount.
- **Real backend wiring — the Claude REPL terminal.** Typing `claude` in the
  bottom-panel terminal drops you into a REPL mode. In the original surface
  this just chopped the user's own typed line into fake streamed tokens and
  echoed it back. Here, every prompt instead fires a real
  `POST /api/personamatrix/request` (module `"apex"`, role `"commenter"`,
  `task: { context: <prompt> }`) and types out the actual `result.text` it
  gets back (`components/builder/terminal/streamClaude.ts`, typed via a
  `PersonaMatrixResponse` interface — no `any`). The token-by-token reveal is
  still done locally for the streaming visual effect, but the content
  originates from a persona that was actually spawned, executed, and
  terminated by `lib/personamatrix/matrix.ts`, with its cost landing in the
  `persona_ledger` table — not replayed or canned text.

`/builder` is not gated by the auth proxy (it's a local dev-tool surface), but
its one live network call goes through the same Apex backbone as everything
else in this app.

---

## Using your Google AI tooling for the rest

Per your note, the remaining phases lean on free Google AI Pro / developer tools:

- **Colab** — tune filter params visually (ipywidgets sliders over
  `config/filters.json`) and prototype GPU style-transfer to replace
  `deep_dream_lite`. CPU/synthetic-safe, no webcam needed.
- **AI Studio / Gemini** — already used by HOPE Cleaner (`GEMINI_API_KEY`);
  reuse it for free-tier persona triage/captioning in the Hope content module.
- **Antigravity** — the agentic IDE for the Dream *desktop* app (real webcam →
  `pyvirtualcam` → OBS). The prompt for it is in `CONTEXT_HANDOFF.md` §4.

Each of those produces config or assets that drop into this repo — the backbone
doesn't change, it just gets more callers and richer filters.
