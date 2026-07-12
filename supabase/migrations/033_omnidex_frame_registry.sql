-- Align set_player_frame validation with OmniDex identity frames (exactly 20).
-- Previous list mixed racing cosmetics / placeholders and did not match the
-- Master OmniDex registry (skirmisher…architect).

create or replace function public.set_player_frame(p_frame text)
returns json language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_valid_frames text[] := array[
    'skirmisher','strider','skybound','flicker','marshal',
    'bloom','rewind','conduit','shade','fabricator',
    'bastion','juggernaut','gravemind','riftbreaker','sovereign',
    'worldroot','epoch','overlord','obscura','architect'
  ];
begin
  if v_user_id is null then raise exception 'Not authenticated'; end if;
  if array_length(v_valid_frames, 1) <> 20 then
    raise exception 'OmniDex frame registry must contain exactly 20 frames';
  end if;
  if not (p_frame = any(v_valid_frames)) then raise exception 'Invalid frame'; end if;
  update public.profiles set frame = p_frame where id = v_user_id;
  return json_build_object('success', true, 'frame', p_frame);
end;
$$;
