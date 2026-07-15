-- Align profiles.frame default with OmniDex registry (033).
-- Legacy default 'basic' is rejected by set_player_frame after 033.

alter table public.profiles
  alter column frame set default 'skirmisher';

update public.profiles
set frame = 'skirmisher'
where frame is null
   or frame in ('basic', 'veil', '');
