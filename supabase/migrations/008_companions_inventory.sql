-- Companion inventory table
create table if not exists public.companion_inventory (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  companion_id text not null,
  faction text not null default 'FL',
  rarity text not null default 'common',
  level int not null default 1,
  xp int not null default 0,
  equipped boolean not null default false,
  slot int, -- 1, 2, or 3
  acquired_at timestamptz default now(),
  unique(user_id, companion_id)
);

alter table public.companion_inventory enable row level security;

create policy "Users own companions" on public.companion_inventory
  for all using (auth.uid() = user_id);

-- Grant a starter companion on signup via trigger
create or replace function public.grant_starter_companion()
returns trigger language plpgsql security definer as $$
begin
  insert into public.companion_inventory (user_id, companion_id, faction, rarity, equipped, slot)
  values (new.id, 'FL001', 'FL', 'common', true, 1)
  on conflict do nothing;
  return new;
end;
$$;

create or replace trigger on_auth_user_starter_companion
  after insert on auth.users
  for each row execute procedure public.grant_starter_companion();

-- Unlock a companion (server-authoritative)
create or replace function public.unlock_companion(p_companion_id text, p_faction text default 'FL', p_rarity text default 'common')
returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.companion_inventory (user_id, companion_id, faction, rarity)
  values (v_user_id, p_companion_id, p_faction, p_rarity)
  on conflict (user_id, companion_id) do nothing;

  return json_build_object('success', true, 'companion_id', p_companion_id);
end;
$$;
