# Periliminal monorepo

See `README.md` for the layout. The runnable pieces are:

- `apps/catsino-casino/` — Next.js 16 social-casino web app (the cleanest, fully
  functional web product). Scripts in its `package.json`: `dev`, `build`,
  `start`, `lint`.
- `apps/hdv-core/` — Next.js 16 sci-fi web skin. Same scripts. Degrades
  gracefully without Supabase; `/`, `/login`, `/signup`, `/studio`, `/builder`
  are public client-side routes.
- `services/psychology/` — Python (LangGraph) background poller. Not a web
  service; needs Supabase env + telemetry schema to do anything.
- `godot/` — the Godot 4.x game client (GUI engine). `supabase/` — shared
  Postgres schema/migrations. `docker-compose*.yml` — Nakama game server.

## Cursor Cloud specific instructions

Node 22 / npm 10, Python 3.12, Docker (fuse-overlayfs), and the Supabase CLI are
available. The update script only refreshes app dependencies (`npm install` in
both apps, `pip install` into `services/psychology/.venv`). It does **not** start
any service — start those yourself as below.

### Running the two Next.js apps

Both default to port 3000, so run them on different ports:

- catsino: `cd apps/catsino-casino && npm run dev` (→ http://localhost:3000)
- hdv-core: `cd apps/hdv-core && PORT=3001 npm run dev` (→ http://localhost:3001)

`npm run lint` works in both apps but each has **pre-existing** lint
errors/warnings unrelated to the environment; `next build` does not fail on
them. There are no automated JS test suites (no `test` script).

### Supabase (required for the apps to be functional)

Both apps read `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` (and
a service-role key) from a gitignored `apps/<app>/.env.local` — see each app's
`ENV_SETUP.md`. No Supabase secrets are present in the environment by default.
You have two options:

1. **Hosted shared project** (`Periliminal.Space`) — needs the real project URL +
   keys as secrets. This is the only way to exercise hdv-core's full
   PersonaMatrix schema and the psychology service.
2. **Local Supabase** (self-contained, no secrets) — what the setup demo used.
   This gives catsino a fully working auth + wallet + slots flow.

#### Bringing up local Supabase (gotchas)

- Start Docker first (it is not auto-started):
  `sudo dockerd >/tmp/dockerd.log 2>&1 &` then `sudo chmod 666 /var/run/docker.sock`.
  The daemon is pre-configured for `fuse-overlayfs` + `iptables-legacy`
  (`/etc/docker/daemon.json`), which is required for Docker-in-Docker here.
- `supabase init` (answer `n`/`n` to the editor prompts) then `supabase start`.
  `config.toml` is intentionally **not** committed.
- **The 36 files in `supabase/migrations/` do NOT apply linearly to a fresh DB.**
  They were appended to a shared live DB and applied out of band, so a normal
  `supabase start` fails at `006` (`relation "public.spin_results" does not
  exist`). For a working local DB sufficient for catsino's core loop (auth,
  wallets, spins, daily bonus), apply **only** `001_initial_schema.sql`: move the
  other `*.sql` out of `supabase/migrations/` to a temp dir, `supabase start`,
  then move them back (leaves the repo untouched).
- **Newer Supabase local is secure-by-default and does not grant table
  privileges to `anon`/`authenticated`.** Hosted does, so the app expects them.
  Without this, PostgREST reads fail with `permission denied for table wallets`
  (though `security definer` RPCs like `spin_slot` still work). Fix on the local
  DB only:
  `docker exec supabase_db_workspace psql -U postgres -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;"`
- Local Supabase disables email confirmation, so signup logs the user straight
  into `/dashboard`.
- Put the CLI's printed `API_URL` / `ANON_KEY` / `SERVICE_ROLE_KEY` into each
  app's `.env.local`.

### Other services

- `services/psychology/` runs via `services/psychology/.venv/bin/python main.py`
  but requires `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` and the telemetry schema
  (migrations `031`/`032`/`034`), which a `001`-only local DB does not have. It's
  a background poller, optional for web dev.
- Godot client / Nakama (`docker-compose*.yml`) are outside the web dev loop.
  Godot 4.x is not installed here; Nakama needs its Docker images.
