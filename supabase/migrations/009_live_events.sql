-- Live events table for admin-triggered events
create table if not exists public.active_events (
  id uuid default gen_random_uuid() primary key,
  event_id text not null unique,
  name text not null,
  description text not null default '',
  multiplier numeric not null default 1.0,
  started_at timestamptz default now(),
  ends_at timestamptz not null
);

alter table public.active_events enable row level security;

create policy "Anyone can read active events" on public.active_events
  for select using (true);

create policy "Admins can manage events" on public.active_events
  for all using (
    exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
  );

-- Function to get current active event multipliers
create or replace function public.get_event_multipliers()
returns json language plpgsql security definer as $$
declare
  v_slot_mult numeric := 1.0;
  v_xp_mult numeric := 1.0;
  v_race_mult numeric := 1.0;
begin
  select coalesce(max(case when event_id = 'jackpot_hour' then multiplier end), 1.0) into v_slot_mult
  from public.active_events where ends_at > now();

  select coalesce(max(case when event_id = 'double_xp' then multiplier end), 1.0) into v_xp_mult
  from public.active_events where ends_at > now();

  select coalesce(max(case when event_id = 'race_championship' then multiplier end), 1.0) into v_race_mult
  from public.active_events where ends_at > now();

  return json_build_object(
    'slots', v_slot_mult,
    'xp', v_xp_mult,
    'race', v_race_mult
  );
end;
$$;
