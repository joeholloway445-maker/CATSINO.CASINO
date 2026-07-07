-- First-discovery ledger for unlabeled in-game secrets (the Recall Walk).
-- Written only by the service-role client via /api/secret/discovery; one row
-- per (secret, player) — the unique constraint is what turns repeat reports
-- into no-ops server-side.

create table if not exists public.secret_discoveries (
  id uuid primary key default gen_random_uuid(),
  secret_id text not null,
  player_name text not null,
  layer text,
  found_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (secret_id, player_name)
);

alter table public.secret_discoveries enable row level security;

-- No anon/authenticated write policies on purpose: inserts come exclusively
-- through the service-role key. Admins may read from the site.
create policy "admins read secret discoveries"
  on public.secret_discoveries for select
  using (coalesce((select is_admin from public.profiles where id = auth.uid()), false));
