-- PvP campaigns: unlike PvE (which has closed/instanced zones), PvP has no
-- closed zones at all -- it happens anywhere in the open world, all the
-- time. So instead of a per-zone instance, this is a single always-running
-- campaign clock that ticks 24/7: every PvP kill anywhere logs to whichever
-- campaign is currently active, and faction "score" is just a live
-- aggregate over those kills. Campaigns/MOBA/Conflict/Zombies/dungeons are
-- all meant to eventually feed kills into this same tracker.
--
-- Also wires the long-deferred "tokens" currency earn-side (PvP kills) and
-- the spec'd drop-on-death mechanic: a kill drops half the victim's tokens
-- onto the body; the victim has a 2-minute head start to reclaim them
-- before anyone else can loot the corpse.

create table if not exists public.pvp_campaigns (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  status text not null default 'active' check (status in ('active', 'ended')),
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

-- Only one campaign should ever be active at a time.
create unique index if not exists pvp_campaigns_one_active
  on public.pvp_campaigns ((status)) where (status = 'active');

create table if not exists public.pvp_campaign_kills (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.pvp_campaigns(id) on delete cascade,
  killer_id uuid not null references auth.users(id) on delete cascade,
  victim_id uuid not null references auth.users(id) on delete cascade,
  killer_faction text not null default 'Factionless',
  victim_faction text not null default 'Factionless',
  zone_id text,
  dropped_tokens bigint not null default 0,
  claimed_by uuid references auth.users(id),
  claimed_at timestamptz,
  occurred_at timestamptz not null default now()
);

create index if not exists pvp_campaign_kills_campaign_idx on public.pvp_campaign_kills (campaign_id);
create index if not exists pvp_campaign_kills_unclaimed_idx on public.pvp_campaign_kills (claimed_by) where claimed_by is null;

alter table public.pvp_campaigns enable row level security;
alter table public.pvp_campaign_kills enable row level security;

drop policy if exists "anyone can read campaigns" on public.pvp_campaigns;
create policy "anyone can read campaigns" on public.pvp_campaigns for select using (true);

drop policy if exists "anyone can read kill feed" on public.pvp_campaign_kills;
create policy "anyone can read kill feed" on public.pvp_campaign_kills for select using (true);

create or replace function public.record_pvp_kill(p_victim_id uuid, p_zone_id text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_killer uuid := auth.uid();
  v_campaign_id uuid;
  v_killer_faction text;
  v_victim_faction text;
  v_victim_tokens bigint;
  v_dropped bigint;
  v_kill_id uuid;
begin
  if v_killer is null then
    raise exception 'Not authenticated';
  end if;

  if p_victim_id = v_killer then
    raise exception 'Cannot record a kill against yourself';
  end if;

  select id into v_campaign_id from public.pvp_campaigns where status = 'active' limit 1;
  if v_campaign_id is null then
    raise exception 'No active PvP campaign';
  end if;

  select faction into v_killer_faction from public.profiles where id = v_killer;
  select faction into v_victim_faction from public.profiles where id = p_victim_id;

  select tokens into v_victim_tokens from public.player_currencies where user_id = p_victim_id for update;
  v_dropped := floor(coalesce(v_victim_tokens, 0) * 0.5);
  if v_dropped > 0 then
    update public.player_currencies set tokens = tokens - v_dropped, updated_at = now()
    where user_id = p_victim_id;
  end if;

  insert into public.pvp_campaign_kills
    (campaign_id, killer_id, victim_id, killer_faction, victim_faction, zone_id, dropped_tokens)
  values
    (v_campaign_id, v_killer, p_victim_id, coalesce(v_killer_faction, 'Factionless'), coalesce(v_victim_faction, 'Factionless'), p_zone_id, v_dropped)
  returning id into v_kill_id;

  perform public.grant_currency('tokens', 5);

  return jsonb_build_object('kill_id', v_kill_id, 'dropped_tokens', v_dropped);
end;
$$;

revoke all on function public.record_pvp_kill(uuid, text) from public;
grant execute on function public.record_pvp_kill(uuid, text) to authenticated;

-- The victim gets a 2-minute head start to reclaim their own dropped
-- tokens before the body becomes lootable by anyone else.
create or replace function public.claim_kill_loot(p_kill_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_victim_id uuid;
  v_dropped bigint;
  v_claimed_by uuid;
  v_occurred_at timestamptz;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  select victim_id, dropped_tokens, claimed_by, occurred_at
  into v_victim_id, v_dropped, v_claimed_by, v_occurred_at
  from public.pvp_campaign_kills where id = p_kill_id for update;

  if v_victim_id is null then
    raise exception 'Kill not found';
  end if;

  if v_claimed_by is not null then
    raise exception 'Already looted';
  end if;

  if v_dropped <= 0 then
    raise exception 'Nothing was dropped';
  end if;

  if v_user <> v_victim_id and v_occurred_at > now() - interval '2 minutes' then
    raise exception 'The victim still has a chance to recover this';
  end if;

  update public.pvp_campaign_kills set claimed_by = v_user, claimed_at = now() where id = p_kill_id;

  perform public.grant_currency('tokens', v_dropped);

  return jsonb_build_object('kill_id', p_kill_id, 'tokens_looted', v_dropped);
end;
$$;

revoke all on function public.claim_kill_loot(uuid) from public;
grant execute on function public.claim_kill_loot(uuid) to authenticated;

-- Admin-only: ends whatever campaign is active and starts a new one.
create or replace function public.start_new_pvp_campaign(p_label text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_id uuid;
begin
  if not coalesce((select is_admin from public.profiles where id = auth.uid()), false) then
    raise exception 'Not authorized';
  end if;

  update public.pvp_campaigns set status = 'ended', ended_at = now() where status = 'active';

  insert into public.pvp_campaigns (label) values (p_label) returning id into v_new_id;

  return jsonb_build_object('campaign_id', v_new_id);
end;
$$;

revoke all on function public.start_new_pvp_campaign(text) from public;
grant execute on function public.start_new_pvp_campaign(text) to authenticated;

insert into public.pvp_campaigns (label)
select 'The Open-World Campaign'
where not exists (select 1 from public.pvp_campaigns where status = 'active');
