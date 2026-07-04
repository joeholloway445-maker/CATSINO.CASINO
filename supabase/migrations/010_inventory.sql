-- Player inventory table
create table if not exists public.inventory (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  item_id text not null,
  item_type text not null default 'consumable',
  quantity int not null default 1 check (quantity >= 0),
  equipped boolean not null default false,
  acquired_at timestamptz default now(),
  unique(user_id, item_id)
);

alter table public.inventory enable row level security;

create policy "Users own inventory" on public.inventory
  for all using (auth.uid() = user_id);

-- Grant item function (called from shop_purchase etc.)
create or replace function public.grant_item(p_user_id uuid, p_item_id text, p_item_type text, p_quantity int default 1)
returns void language plpgsql security definer as $$
begin
  insert into public.inventory (user_id, item_id, item_type, quantity)
  values (p_user_id, p_item_id, p_item_type, p_quantity)
  on conflict (user_id, item_id)
  do update set quantity = public.inventory.quantity + excluded.quantity;
end;
$$;
