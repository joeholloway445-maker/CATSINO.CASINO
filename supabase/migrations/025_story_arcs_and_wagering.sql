-- Mirror of THE-HDV-CORE's 007_story_arcs_and_wagering.sql for parity --
-- the shared canonical DB (Periliminal.Space) already has these tables
-- and RPCs applied; this file just keeps both repos' migration history in
-- sync. See that file for the full design rationale.

create table if not exists public.story_arcs (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  description text not null,
  status text not null default 'voting' check (status in ('voting', 'resolved')),
  opens_at timestamptz not null default now(),
  closes_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.story_choices (
  id uuid primary key default gen_random_uuid(),
  arc_id uuid not null references public.story_arcs(id) on delete cascade,
  choice_key text not null,
  label text not null,
  description text,
  unique (arc_id, choice_key)
);

alter table public.story_arcs
  add column if not exists winning_choice_id uuid references public.story_choices(id);

create table if not exists public.story_wagers (
  id uuid primary key default gen_random_uuid(),
  arc_id uuid not null references public.story_arcs(id) on delete cascade,
  choice_id uuid not null references public.story_choices(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  faction text not null default 'Factionless',
  currency text not null check (currency in ('chip', 'renown')),
  amount bigint not null check (amount > 0),
  payout bigint,
  created_at timestamptz not null default now()
);

create index if not exists story_wagers_arc_idx on public.story_wagers (arc_id);
create index if not exists story_wagers_choice_idx on public.story_wagers (choice_id);

alter table public.story_arcs enable row level security;
alter table public.story_choices enable row level security;
alter table public.story_wagers enable row level security;

drop policy if exists "anyone can read arcs" on public.story_arcs;
create policy "anyone can read arcs" on public.story_arcs for select using (true);

drop policy if exists "anyone can read choices" on public.story_choices;
create policy "anyone can read choices" on public.story_choices for select using (true);

drop policy if exists "anyone can read wager tallies" on public.story_wagers;
create policy "anyone can read wager tallies" on public.story_wagers for select using (true);

create or replace function public.place_story_wager(p_arc_id uuid, p_choice_id uuid, p_currency text, p_amount bigint)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_status text;
  v_closes_at timestamptz;
  v_faction text;
  v_wager_id uuid;
  v_new_balance bigint;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  if p_currency not in ('chip', 'renown') then
    raise exception 'Invalid currency for story wager';
  end if;

  if p_amount <= 0 then
    raise exception 'Invalid amount';
  end if;

  select status, closes_at into v_status, v_closes_at
  from public.story_arcs where id = p_arc_id for update;

  if v_status is null then
    raise exception 'Story arc not found';
  end if;

  if v_status <> 'voting' then
    raise exception 'Story arc voting has closed';
  end if;

  if v_closes_at is not null and v_closes_at <= now() then
    raise exception 'Story arc voting has closed';
  end if;

  if not exists (select 1 from public.story_choices where id = p_choice_id and arc_id = p_arc_id) then
    raise exception 'Choice does not belong to this arc';
  end if;

  select faction into v_faction from public.profiles where id = v_user;

  perform public.spend_currency(p_currency, p_amount);

  insert into public.story_wagers (arc_id, choice_id, user_id, faction, currency, amount)
  values (p_arc_id, p_choice_id, v_user, coalesce(v_faction, 'Factionless'), p_currency, p_amount)
  returning id into v_wager_id;

  select (case when p_currency = 'chip' then chip else renown end) into v_new_balance
  from public.player_currencies where user_id = v_user;

  return jsonb_build_object('wager_id', v_wager_id, 'currency', p_currency, 'balance', v_new_balance);
end;
$$;

revoke all on function public.place_story_wager(uuid, uuid, text, bigint) from public;
grant execute on function public.place_story_wager(uuid, uuid, text, bigint) to authenticated;

create or replace function public.resolve_story_arc(p_arc_id uuid, p_winning_choice_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_currency text;
  v_total_pool bigint;
  v_winning_pool bigint;
  v_wager record;
  v_payout bigint;
begin
  if not coalesce((select is_admin from public.profiles where id = auth.uid()), false) then
    raise exception 'Not authorized';
  end if;

  select status into v_status from public.story_arcs where id = p_arc_id for update;
  if v_status is null then
    raise exception 'Story arc not found';
  end if;
  if v_status <> 'voting' then
    raise exception 'Story arc already resolved';
  end if;

  if not exists (select 1 from public.story_choices where id = p_winning_choice_id and arc_id = p_arc_id) then
    raise exception 'Winning choice does not belong to this arc';
  end if;

  foreach v_currency in array array['chip', 'renown'] loop
    select coalesce(sum(amount), 0) into v_total_pool
    from public.story_wagers where arc_id = p_arc_id and currency = v_currency;

    select coalesce(sum(amount), 0) into v_winning_pool
    from public.story_wagers where arc_id = p_arc_id and choice_id = p_winning_choice_id and currency = v_currency;

    if v_winning_pool > 0 then
      for v_wager in
        select id, user_id, amount from public.story_wagers
        where arc_id = p_arc_id and choice_id = p_winning_choice_id and currency = v_currency
      loop
        v_payout := floor(v_wager.amount::numeric * v_total_pool / v_winning_pool);
        update public.story_wagers set payout = v_payout where id = v_wager.id;
        if v_payout > 0 then
          update public.player_currencies
          set "chip" = "chip" + (case when v_currency = 'chip' then v_payout else 0 end),
              renown = renown + (case when v_currency = 'renown' then v_payout else 0 end),
              updated_at = now()
          where user_id = v_wager.user_id;
        end if;
      end loop;
    end if;

    update public.story_wagers set payout = 0
    where arc_id = p_arc_id and currency = v_currency and choice_id <> p_winning_choice_id and payout is null;
  end loop;

  update public.story_arcs
  set status = 'resolved', winning_choice_id = p_winning_choice_id, resolved_at = now()
  where id = p_arc_id;

  return jsonb_build_object('arc_id', p_arc_id, 'winning_choice_id', p_winning_choice_id);
end;
$$;

revoke all on function public.resolve_story_arc(uuid, uuid) from public;
grant execute on function public.resolve_story_arc(uuid, uuid) to authenticated;
