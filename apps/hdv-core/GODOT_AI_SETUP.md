# Wiring Godot into the PersonaMatrix backbone

This repo (`hdv-core`) is now the single backbone: PersonaMatrix's API lives
at `/api/personamatrix/*`, Supabase holds `tenants` / `personas` / `persona_ledger`.
The CATSINO.CASINO Godot client (and any future Godot client) talks to this
backbone over plain HTTP — Godot needs no Python, no FastAPI, nothing extra.

## Which AI to use with Godot, and why

**Use Claude Code itself, running inside the Godot project folder, as a
separate session from this one.** Not a Godot-specific AI plugin. Reasons:

- Godot's own in-editor AI options (GDAI, Godot MCP plugins) are
  GDScript-autocomplete tools — fine for small edits, but they can't run
  shell commands, can't manage your build pipeline, and don't share context
  with the backend work you're doing here.
- Claude Code already has full filesystem + bash access to the `godot/`
  folder in CATSINO.CASINO, and you're already using it for the Nakama
  backend. The *same tool* should drive the Godot-side HTTP client code —
  one agent, two folders, no context lost translating between tools.
- If you specifically want an in-editor assistant for quick GDScript
  autocomplete while you hand-edit scenes, install the **Godot MCP server**
  (`github.com/Coding-Solo/godot-mcp` or similar) and point Claude Code at it
  via `claude mcp add` — this lets Claude Code itself drive the Godot editor
  (open scenes, run the project, read the debugger output) instead of just
  editing files blind. Optional, not required to get started.

## Setup (do this once)

1. Open a terminal in the Godot project root (`CATSINO.CASINO/godot`).
2. Run `claude` there (a fresh session, separate from this backbone session).
3. Set the backend URL the Godot client will call. In Godot, this is just a
   constant — no env vars needed inside GDScript itself:
   - Local dev: `http://localhost:3000/api/personamatrix`
   - Deployed: `https://<your-vercel-domain>/api/personamatrix`
4. (Optional, for in-editor scene control) install a Godot MCP server and run:
   ```
   claude mcp add godot -- npx -y @your-chosen-godot-mcp-package
   ```
   Check that package's own README for its exact run command — there are a
   few competing implementations; pick one and use its install command, not
   this one verbatim.

## The prompt to paste into that Claude Code session

```
Read GODOT_AI_SETUP.md in the hdv-core repo (ask me for it if you don't have
it) — it explains the PersonaMatrix backbone you're connecting to. I need an
HTTP client autoload in this Godot project, src/networking/persona_matrix_client.gd,
that talks to the backbone at /api/personamatrix:

1. POST {base_url}/request with body {module, role, task} and optional header
   X-Api-Key for tenant billing. Returns {result, cost_usd}. Wrap it as
   `request_persona(module: String, role: String, task: Dictionary, on_done: Callable)`
   using HTTPRequest, matching the async callback style already used by
   NetworkManager.call_rpc for Nakama calls in this project — look at how that's
   implemented and follow the same pattern, don't invent a new one.
2. GET {base_url}/personas?module=X to list persona identities (for displaying
   Dream/Hope NPCs sourced from the Entity Roster instead of hardcoded names).
3. GET {base_url}/ledger to show running session cost, same idea as the Nakama
   wallet display already in the UI.
4. Add base_url as an exported constant so it's a one-line edit between local
   dev and the deployed Vercel URL.
5. Do NOT touch the existing Nakama networking code — this is a second,
   independent backend the game talks to, not a replacement.
```

That session will read the existing `NetworkManager` / `call_rpc` pattern in
this codebase and produce a matching client — you don't need to write any
GDScript yourself.
