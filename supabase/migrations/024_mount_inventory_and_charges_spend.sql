-- Build the missing "spend charges on companions/mounts" side of the economy:
-- companion summon currently spends wallets.coins (the gambling chip
-- balance) instead of charges, and there is no mount system at all. Add a
-- mount_inventory table mirroring companion_inventory, plus a starter mount
-- grant trigger, and switch companion unlocks to be charges-priced via the
-- existing spend_currency RPC from 021_currency_foundation.sql.

create table if not exists public.mount_inventory (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  mount_id text not null,
  faction text not null default 'FL',
  rarity text not null default 'common',
  equipped boolean not null default false,
  acquired_at timestamptz default now(),
  unique(user_id, mount_id)
);

alter table public.mount_inventory enable row level security;

drop policy if exists "Users own mounts" on public.mount_inventory;
create policy "Users own mounts" on public.mount_inventory
  for all using (auth.uid() = user_id);

create or replace function public.grant_starter_mount()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.mount_inventory (user_id, mount_id, faction, rarity, equipped)
  values (new.id, 'FL_MOUNT_001', 'FL', 'common', true)
  on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_starter_mount on auth.users;
create trigger on_auth_user_starter_mount
  after insert on auth.users
  for each row execute procedure public.grant_starter_mount();

revoke all on function public.grant_starter_mount() from public;
