-- Quest progress tracking
create table if not exists public.quest_progress (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  quest_id text not null,
  status text not null default 'locked' check (status in ('locked', 'active', 'complete')),
  progress int not null default 0,
  started_at timestamptz,
  completed_at timestamptz,
  unique(user_id, quest_id)
);

alter table public.quest_progress enable row level security;

create policy "Users own quest progress" on public.quest_progress
  for all using (auth.uid() = user_id);

-- Accept a quest
create or replace function public.accept_quest(p_quest_id text)
returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  insert into public.quest_progress (user_id, quest_id, status, started_at)
  values (v_user_id, p_quest_id, 'active', now())
  on conflict (user_id, quest_id)
  do update set status = 'active', started_at = coalesce(public.quest_progress.started_at, now())
  where public.quest_progress.status = 'locked';

  return json_build_object('success', true, 'quest_id', p_quest_id);
end;
$$;

-- Complete a quest and award rewards
create or replace function public.complete_quest(p_quest_id text, p_reward_coins int default 0, p_reward_xp int default 0)
returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_current_status text;
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;

  select status into v_current_status
  from public.quest_progress
  where user_id = v_user_id and quest_id = p_quest_id;

  if v_current_status is null or v_current_status != 'active' then
    raise exception 'Quest not active';
  end if;

  update public.quest_progress
  set status = 'complete', completed_at = now()
  where user_id = v_user_id and quest_id = p_quest_id;

  -- Award coins
  if p_reward_coins > 0 then
    update public.wallets set coins = coins + p_reward_coins where user_id = v_user_id;
  end if;

  -- Award XP
  if p_reward_xp > 0 then
    perform public.add_profile_xp(p_reward_xp);
  end if;

  return json_build_object('success', true, 'coins_awarded', p_reward_coins, 'xp_awarded', p_reward_xp);
end;
$$;
