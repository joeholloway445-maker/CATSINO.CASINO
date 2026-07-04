-- PersonaMatrix backbone: tenants, persona identities, execution ledger.
-- Personas are DATA ONLY — identity + history live here, never running state
-- (spawn -> execute -> terminate happens entirely in-process, per request).

create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  api_key text not null unique,
  matrix_config jsonb not null default '{}'::jsonb, -- per-tenant override of config/matrix.json (Vision white-label)
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.personas (
  id integer primary key,                  -- 0..20479, matches total_capacity
  module text not null,                    -- dream / hope / no_one / vision / apex
  name text,
  tier text,                               -- e.g. Moeru line, Kage/Dono/Kami tiers
  lore_summary text,
  voice_style text,
  behavioral_traits jsonb default '[]'::jsonb,
  source text default 'entity_roster',     -- where the identity came from
  created_at timestamptz not null default now()
);

create table if not exists public.persona_ledger (
  id bigint generated always as identity primary key,
  ts timestamptz not null default now(),
  module text not null,
  role text not null,
  persona_id integer references public.personas(id),
  persona_uid text not null,               -- unique per spawn, not per identity
  cost_usd numeric(12, 8) not null default 0,
  tenant_id uuid references public.tenants(id),
  task jsonb,
  result jsonb
);

create index if not exists persona_ledger_tenant_idx on public.persona_ledger (tenant_id, ts desc);
create index if not exists persona_ledger_module_idx on public.persona_ledger (module, ts desc);
create index if not exists personas_module_idx on public.personas (module);

alter table public.tenants enable row level security;
alter table public.personas enable row level security;
alter table public.persona_ledger enable row level security;

-- Personas are public read (the Dex is public SEO content); writes are service-role only.
create policy "personas readable by anyone" on public.personas
  for select using (true);

-- Tenants and ledger are never client-readable — service role only (no policy = no access via anon/auth key).
