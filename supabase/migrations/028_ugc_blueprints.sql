-- Periliminal.Space — Companion Blueprints & UGC Economy
-- Implements the deconstruct-to-create / deconstruct-to-charges loop:
--   1. Collect N copies of Entity #X
--   2. Deconstruct N copies -> unlock a new player creation built on Blueprint #X
--      (locked stats = faction/role/tier of the blueprint; visuals are free)
--   3. Deconstruct further duplicates of Entity #X -> shared "#X Charges" pool
--   4. Spend #X Charges on ANY of the player's creations derived from Blueprint #X
--      (any faction skin or fully custom UGC skin)

-- ── COMPANION BLUEPRINTS (locked gameplay template, one per entity) ─────────
create table public.companion_blueprints (
  blueprint_id text primary key,
  faction text not null check (faction in ('veiled_current', 'sovereign_crown', 'wildlands_ascendants')),
  role text not null check (role in ('warrior', 'guardian', 'trickster')),
  tier int not null check (tier between 1 and 5)
);

-- ── PLAYER CREATIONS (UGC companions/items derived from a blueprint) ────────
create table public.player_creations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  blueprint_id text not null references public.companion_blueprints(blueprint_id),
  name text not null,
  skin text not null default 'custom' check (skin in ('veiled_current', 'sovereign_crown', 'wildlands_ascendants', 'custom')),
  visual jsonb not null default '{}'::jsonb,
  power_level int not null default 0,
  created_at timestamptz default now()
);

-- ── PER-BLUEPRINT CHARGE POOL ────────────────────────────────────────────────
create table public.player_blueprint_charges (
  user_id uuid not null references public.profiles(id) on delete cascade,
  blueprint_id text not null references public.companion_blueprints(blueprint_id),
  charge_count int not null default 0,
  updated_at timestamptz default now(),
  primary key (user_id, blueprint_id)
);

-- ── TIER-BASED ECONOMY FORMULAS ───────────────────────────────────────────────
create or replace function public.blueprint_creation_cost(p_tier int)
returns int language sql immutable as $$
  select case p_tier
    when 1 then 5
    when 2 then 8
    when 3 then 12
    when 4 then 18
    when 5 then 25
    else 5
  end;
$$;

create or replace function public.blueprint_charge_rate(p_tier int)
returns int language sql immutable as $$
  select case p_tier
    when 1 then 1
    when 2 then 1
    when 3 then 2
    when 4 then 2
    when 5 then 3
    else 1
  end;
$$;

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
alter table public.companion_blueprints enable row level security;
alter table public.player_creations enable row level security;
alter table public.player_blueprint_charges enable row level security;

create policy "blueprints readable by all" on public.companion_blueprints
  for select using (true);

create policy "own creations" on public.player_creations
  for all using (auth.uid() = user_id);

create policy "own blueprint charges" on public.player_blueprint_charges
  for all using (auth.uid() = user_id);

-- ── DECONSTRUCT: copies -> new creation ──────────────────────────────────────
create or replace function public.deconstruct_for_creation(
  p_entity_id text,
  p_name text,
  p_skin text default 'custom',
  p_visual jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_tier int;
  v_cost int;
  v_owned int;
  v_creation_id uuid;
begin
  select tier into v_tier from public.companion_blueprints where blueprint_id = p_entity_id;
  if v_tier is null then
    raise exception 'Unknown blueprint: %', p_entity_id;
  end if;

  v_cost := public.blueprint_creation_cost(v_tier);

  select count into v_owned from public.player_entities
    where user_id = v_user_id and entity_id = p_entity_id;

  if v_owned is null or v_owned < v_cost then
    raise exception 'Not enough % copies to deconstruct (need %, have %)', p_entity_id, v_cost, coalesce(v_owned, 0);
  end if;

  update public.player_entities
    set count = count - v_cost
    where user_id = v_user_id and entity_id = p_entity_id;

  insert into public.player_creations (user_id, blueprint_id, name, skin, visual)
    values (v_user_id, p_entity_id, p_name, p_skin, p_visual)
    returning id into v_creation_id;

  return v_creation_id;
end;
$$;

-- ── DECONSTRUCT: extra copies -> shared blueprint charge pool ───────────────
create or replace function public.deconstruct_for_charges(
  p_entity_id text,
  p_quantity int
) returns int language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_tier int;
  v_rate int;
  v_owned int;
  v_gained int;
  v_total int;
begin
  if p_quantity <= 0 then
    raise exception 'Quantity must be positive';
  end if;

  select tier into v_tier from public.companion_blueprints where blueprint_id = p_entity_id;
  if v_tier is null then
    raise exception 'Unknown blueprint: %', p_entity_id;
  end if;

  v_rate := public.blueprint_charge_rate(v_tier);

  select count into v_owned from public.player_entities
    where user_id = v_user_id and entity_id = p_entity_id;

  if v_owned is null or v_owned < p_quantity then
    raise exception 'Not enough % copies to deconstruct (have %)', p_entity_id, coalesce(v_owned, 0);
  end if;

  update public.player_entities
    set count = count - p_quantity
    where user_id = v_user_id and entity_id = p_entity_id;

  v_gained := p_quantity * v_rate;

  insert into public.player_blueprint_charges (user_id, blueprint_id, charge_count)
    values (v_user_id, p_entity_id, v_gained)
    on conflict (user_id, blueprint_id)
    do update set charge_count = public.player_blueprint_charges.charge_count + v_gained, updated_at = now();

  select charge_count into v_total from public.player_blueprint_charges
    where user_id = v_user_id and blueprint_id = p_entity_id;

  return v_total;
end;
$$;

-- ── SPEND: blueprint charges -> power up any creation from that blueprint ──
create or replace function public.spend_blueprint_charges(
  p_creation_id uuid,
  p_amount int
) returns int language plpgsql security definer as $$
declare
  v_user_id uuid := auth.uid();
  v_blueprint_id text;
  v_remaining int;
begin
  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  select blueprint_id into v_blueprint_id from public.player_creations
    where id = p_creation_id and user_id = v_user_id;

  if v_blueprint_id is null then
    raise exception 'Creation not found';
  end if;

  update public.player_blueprint_charges
    set charge_count = charge_count - p_amount, updated_at = now()
    where user_id = v_user_id and blueprint_id = v_blueprint_id and charge_count >= p_amount
    returning charge_count into v_remaining;

  if v_remaining is null then
    raise exception 'Not enough % charges', v_blueprint_id;
  end if;

  update public.player_creations
    set power_level = power_level + p_amount
    where id = p_creation_id;

  return v_remaining;
end;
$$;

-- ── SEED: blueprints for the currently-implemented entity roster ────────────
insert into public.companion_blueprints (blueprint_id, faction, role, tier) values
  ('vc_fujin', 'veiled_current', 'warrior', 1),
  ('vc_raijin', 'veiled_current', 'warrior', 1),
  ('vc_susanoo', 'veiled_current', 'warrior', 2),
  ('vc_kagutsuchi', 'veiled_current', 'warrior', 2),
  ('vc_takemikazuchi', 'veiled_current', 'warrior', 3),
  ('vc_bishamon', 'veiled_current', 'warrior', 3),
  ('vc_hachiman', 'veiled_current', 'warrior', 4),
  ('vc_ryujin', 'veiled_current', 'warrior', 4),
  ('vc_amaterasu', 'veiled_current', 'guardian', 5),
  ('vc_izanagi', 'veiled_current', 'guardian', 4),
  ('vc_inari', 'veiled_current', 'guardian', 2),
  ('vc_benzaiten', 'veiled_current', 'guardian', 3),
  ('vc_ebisu', 'veiled_current', 'guardian', 1),
  ('vc_tsukuyomi', 'veiled_current', 'guardian', 3),
  ('vc_kitsune', 'veiled_current', 'trickster', 2),
  ('vc_tengu', 'veiled_current', 'trickster', 1),
  ('vc_tanuki', 'veiled_current', 'trickster', 1),
  ('vc_oni', 'veiled_current', 'trickster', 2),
  ('vc_jorougumo', 'veiled_current', 'trickster', 3),
  ('vc_yamabiko', 'veiled_current', 'trickster', 1),
  ('vc_izanami', 'veiled_current', 'guardian', 5),
  ('sc_shiva', 'sovereign_crown', 'warrior', 5),
  ('sc_durga', 'sovereign_crown', 'warrior', 4),
  ('sc_kali', 'sovereign_crown', 'warrior', 4),
  ('sc_indra', 'sovereign_crown', 'warrior', 3),
  ('sc_hanuman', 'sovereign_crown', 'warrior', 3),
  ('sc_kartikeya', 'sovereign_crown', 'warrior', 3),
  ('sc_varuna', 'sovereign_crown', 'warrior', 2),
  ('sc_agni', 'sovereign_crown', 'warrior', 2),
  ('sc_vishnu', 'sovereign_crown', 'guardian', 5),
  ('sc_brahma', 'sovereign_crown', 'guardian', 4),
  ('sc_lakshmi', 'sovereign_crown', 'guardian', 3),
  ('sc_saraswati', 'sovereign_crown', 'guardian', 3),
  ('sc_ganesha', 'sovereign_crown', 'guardian', 3),
  ('sc_parvati', 'sovereign_crown', 'guardian', 2),
  ('sc_surya', 'sovereign_crown', 'guardian', 2),
  ('sc_krishna', 'sovereign_crown', 'trickster', 5),
  ('sc_maya', 'sovereign_crown', 'trickster', 3),
  ('sc_narada', 'sovereign_crown', 'trickster', 2),
  ('sc_rahu', 'sovereign_crown', 'trickster', 3),
  ('sc_ketu', 'sovereign_crown', 'trickster', 2),
  ('wa_horus', 'wildlands_ascendants', 'warrior', 4),
  ('wa_sekhmet', 'wildlands_ascendants', 'warrior', 4),
  ('wa_set', 'wildlands_ascendants', 'warrior', 4),
  ('wa_montu', 'wildlands_ascendants', 'warrior', 3),
  ('wa_sobek', 'wildlands_ascendants', 'warrior', 3),
  ('wa_anhur', 'wildlands_ascendants', 'warrior', 2),
  ('wa_khnum', 'wildlands_ascendants', 'warrior', 2),
  ('wa_osiris', 'wildlands_ascendants', 'guardian', 5),
  ('wa_isis', 'wildlands_ascendants', 'guardian', 5),
  ('wa_hathor', 'wildlands_ascendants', 'guardian', 3),
  ('wa_thoth', 'wildlands_ascendants', 'guardian', 4),
  ('wa_ra', 'wildlands_ascendants', 'guardian', 5),
  ('wa_anubis', 'wildlands_ascendants', 'guardian', 3),
  ('wa_neith', 'wildlands_ascendants', 'guardian', 2),
  ('wa_apep', 'wildlands_ascendants', 'trickster', 5),
  ('wa_bes', 'wildlands_ascendants', 'trickster', 1),
  ('wa_sekhmet_shadow', 'wildlands_ascendants', 'trickster', 2),
  ('wa_neit_shadow', 'wildlands_ascendants', 'trickster', 2),
  ('wa_taweret', 'wildlands_ascendants', 'trickster', 1),
  ('wa_khepri', 'wildlands_ascendants', 'trickster', 2),
  -- Veiled Current expansion (45/150)
  ('vc_kappa', 'veiled_current', 'trickster', 1),
  ('vc_yukionna', 'veiled_current', 'trickster', 1),
  ('vc_nurarihyon', 'veiled_current', 'trickster', 2),
  ('vc_rokurokubi', 'veiled_current', 'trickster', 1),
  ('vc_akaname', 'veiled_current', 'trickster', 1),
  ('vc_konakijiji', 'veiled_current', 'guardian', 1),
  ('vc_zashikiwarashi', 'veiled_current', 'guardian', 1),
  ('vc_karasutengu', 'veiled_current', 'warrior', 1),
  ('vc_amenouzume', 'veiled_current', 'trickster', 2),
  ('vc_okuninushi', 'veiled_current', 'guardian', 2),
  ('vc_sarutahiko', 'veiled_current', 'warrior', 2),
  ('vc_konohanasakuya', 'veiled_current', 'guardian', 2),
  ('vc_toyotamahime', 'veiled_current', 'guardian', 2),
  ('vc_komainu', 'veiled_current', 'guardian', 3),
  ('vc_tenjin', 'veiled_current', 'guardian', 3),
  ('vc_kishijoten', 'veiled_current', 'guardian', 3),
  ('vc_shouki', 'veiled_current', 'warrior', 3),
  ('vc_konpira', 'veiled_current', 'warrior', 3),
  ('vc_sukunabikona', 'veiled_current', 'guardian', 4),
  ('vc_omoikane', 'veiled_current', 'guardian', 4),
  ('vc_futsunushi', 'veiled_current', 'warrior', 4),
  ('vc_takeminakata', 'veiled_current', 'warrior', 4),
  ('vc_amenominakanushi', 'veiled_current', 'guardian', 5),
  ('vc_takamimusubi', 'veiled_current', 'guardian', 5),
  ('vc_kamimusubi', 'veiled_current', 'trickster', 5),
  -- Sovereign Crown expansion (45/150)
  ('sc_vayu', 'sovereign_crown', 'warrior', 1),
  ('sc_chandra', 'sovereign_crown', 'guardian', 1),
  ('sc_kubera', 'sovereign_crown', 'guardian', 1),
  ('sc_yama', 'sovereign_crown', 'guardian', 1),
  ('sc_nirrti', 'sovereign_crown', 'trickster', 1),
  ('sc_pushan', 'sovereign_crown', 'guardian', 1),
  ('sc_ushas', 'sovereign_crown', 'trickster', 1),
  ('sc_ashvins', 'sovereign_crown', 'warrior', 1),
  ('sc_narasimha', 'sovereign_crown', 'warrior', 2),
  ('sc_vamana', 'sovereign_crown', 'trickster', 2),
  ('sc_parashurama', 'sovereign_crown', 'warrior', 2),
  ('sc_matsya', 'sovereign_crown', 'guardian', 2),
  ('sc_kurma', 'sovereign_crown', 'guardian', 2),
  ('sc_chinnamasta', 'sovereign_crown', 'trickster', 3),
  ('sc_bhairavi', 'sovereign_crown', 'warrior', 3),
  ('sc_tripurasundari', 'sovereign_crown', 'guardian', 3),
  ('sc_bagalamukhi', 'sovereign_crown', 'trickster', 3),
  ('sc_dhumavati', 'sovereign_crown', 'trickster', 3),
  ('sc_ishana', 'sovereign_crown', 'warrior', 4),
  ('sc_dhanvantari', 'sovereign_crown', 'guardian', 4),
  ('sc_kamadeva', 'sovereign_crown', 'trickster', 4),
  ('sc_vishwakarma', 'sovereign_crown', 'guardian', 4),
  ('sc_adishakti', 'sovereign_crown', 'guardian', 5),
  ('sc_mahavishnu', 'sovereign_crown', 'guardian', 5),
  ('sc_kalabhairava', 'sovereign_crown', 'warrior', 5),
  -- Wildlands Ascendants expansion (45/150)
  ('wa_ammit', 'wildlands_ascendants', 'trickster', 1),
  ('wa_serqet', 'wildlands_ascendants', 'guardian', 1),
  ('wa_wadjet', 'wildlands_ascendants', 'guardian', 1),
  ('wa_qebehsenuef', 'wildlands_ascendants', 'guardian', 1),
  ('wa_hapy', 'wildlands_ascendants', 'guardian', 1),
  ('wa_imsety', 'wildlands_ascendants', 'guardian', 1),
  ('wa_duamutef', 'wildlands_ascendants', 'warrior', 1),
  ('wa_maahes', 'wildlands_ascendants', 'warrior', 1),
  ('wa_nefertem', 'wildlands_ascendants', 'guardian', 2),
  ('wa_khonsu', 'wildlands_ascendants', 'warrior', 2),
  ('wa_shu', 'wildlands_ascendants', 'guardian', 2),
  ('wa_tefnut', 'wildlands_ascendants', 'guardian', 2),
  ('wa_min', 'wildlands_ascendants', 'warrior', 2),
  ('wa_nut', 'wildlands_ascendants', 'guardian', 3),
  ('wa_geb', 'wildlands_ascendants', 'guardian', 3),
  ('wa_atum', 'wildlands_ascendants', 'warrior', 3),
  ('wa_heka', 'wildlands_ascendants', 'trickster', 3),
  ('wa_mehetweret', 'wildlands_ascendants', 'guardian', 3),
  ('wa_ptah', 'wildlands_ascendants', 'guardian', 4),
  ('wa_amunra', 'wildlands_ascendants', 'warrior', 4),
  ('wa_sopdu', 'wildlands_ascendants', 'warrior', 4),
  ('wa_satet', 'wildlands_ascendants', 'trickster', 4),
  ('wa_nun', 'wildlands_ascendants', 'guardian', 5),
  ('wa_naunet', 'wildlands_ascendants', 'guardian', 5),
  ('wa_kek', 'wildlands_ascendants', 'trickster', 5),
  -- Veiled Current expansion batch 2 (70/150)
  ('vc_nuppeppo', 'veiled_current', 'guardian', 1),
  ('vc_hitotsumekozo', 'veiled_current', 'trickster', 1),
  ('vc_gashadokuro', 'veiled_current', 'warrior', 1),
  ('vc_tsuchigumo', 'veiled_current', 'trickster', 1),
  ('vc_nukekubi', 'veiled_current', 'trickster', 1),
  ('vc_ukemochi', 'veiled_current', 'guardian', 2),
  ('vc_toyouke', 'veiled_current', 'guardian', 2),
  ('vc_wakahirume', 'veiled_current', 'trickster', 2),
  ('vc_hiruko', 'veiled_current', 'trickster', 2),
  ('vc_kuraokami', 'veiled_current', 'guardian', 2),
  ('vc_daikokuten', 'veiled_current', 'guardian', 3),
  ('vc_fukurokuju', 'veiled_current', 'guardian', 3),
  ('vc_jurojin', 'veiled_current', 'guardian', 3),
  ('vc_hotei', 'veiled_current', 'trickster', 3),
  ('vc_kanayamahiko', 'veiled_current', 'warrior', 3),
  ('vc_ohoyamatsumi', 'veiled_current', 'guardian', 4),
  ('vc_kukunochi', 'veiled_current', 'guardian', 4),
  ('vc_kayanohime', 'veiled_current', 'guardian', 4),
  ('vc_shinatsuhiko', 'veiled_current', 'warrior', 4),
  ('vc_hayaakitsuhime', 'veiled_current', 'trickster', 4),
  ('vc_umashiashikabihikoji', 'veiled_current', 'guardian', 5),
  ('vc_amenotokotachi', 'veiled_current', 'guardian', 5),
  ('vc_kuninotokotachi', 'veiled_current', 'guardian', 5),
  ('vc_toyokumonu', 'veiled_current', 'trickster', 5),
  ('vc_omodaru', 'veiled_current', 'warrior', 5),
  -- Sovereign Crown expansion batch 2 (70/150)
  ('sc_aditi', 'sovereign_crown', 'guardian', 1),
  ('sc_diti', 'sovereign_crown', 'trickster', 1),
  ('sc_mitra', 'sovereign_crown', 'guardian', 1),
  ('sc_aryaman', 'sovereign_crown', 'warrior', 1),
  ('sc_bhaga', 'sovereign_crown', 'trickster', 1),
  ('sc_rama', 'sovereign_crown', 'warrior', 2),
  ('sc_buddha', 'sovereign_crown', 'guardian', 2),
  ('sc_kalki', 'sovereign_crown', 'warrior', 2),
  ('sc_balarama', 'sovereign_crown', 'warrior', 2),
  ('sc_mohini', 'sovereign_crown', 'trickster', 2),
  ('sc_kamala', 'sovereign_crown', 'guardian', 3),
  ('sc_matangi', 'sovereign_crown', 'trickster', 3),
  ('sc_bhuvaneshwari', 'sovereign_crown', 'guardian', 3),
  ('sc_tara', 'sovereign_crown', 'trickster', 3),
  ('sc_annapurna', 'sovereign_crown', 'guardian', 3),
  ('sc_aiyanar', 'sovereign_crown', 'warrior', 4),
  ('sc_ayyappan', 'sovereign_crown', 'guardian', 4),
  ('sc_khandoba', 'sovereign_crown', 'warrior', 4),
  ('sc_vetala', 'sovereign_crown', 'trickster', 4),
  ('sc_bhumidevi', 'sovereign_crown', 'guardian', 4),
  ('sc_hiranyagarbha', 'sovereign_crown', 'guardian', 5),
  ('sc_prajapati', 'sovereign_crown', 'guardian', 5),
  ('sc_purusha', 'sovereign_crown', 'guardian', 5),
  ('sc_akshara', 'sovereign_crown', 'trickster', 5),
  ('sc_daksha', 'sovereign_crown', 'warrior', 5),
  -- Wildlands Ascendants expansion batch 2 (70/150)
  ('wa_nehebkau', 'wildlands_ascendants', 'guardian', 1),
  ('wa_aker', 'wildlands_ascendants', 'guardian', 1),
  ('wa_tutu', 'wildlands_ascendants', 'guardian', 1),
  ('wa_shesmu', 'wildlands_ascendants', 'trickster', 1),
  ('wa_reshep', 'wildlands_ascendants', 'warrior', 1),
  ('wa_wepwawet', 'wildlands_ascendants', 'warrior', 2),
  ('wa_mafdet', 'wildlands_ascendants', 'warrior', 2),
  ('wa_pakhet', 'wildlands_ascendants', 'trickster', 2),
  ('wa_renenutet', 'wildlands_ascendants', 'guardian', 2),
  ('wa_heqet', 'wildlands_ascendants', 'guardian', 2),
  ('wa_mut', 'wildlands_ascendants', 'guardian', 3),
  ('wa_hapi', 'wildlands_ascendants', 'guardian', 3),
  ('wa_sopdet', 'wildlands_ascendants', 'trickster', 3),
  ('wa_mertseger', 'wildlands_ascendants', 'guardian', 3),
  ('wa_wosret', 'wildlands_ascendants', 'warrior', 3),
  ('wa_sobekra', 'wildlands_ascendants', 'warrior', 4),
  ('wa_banebdjedet', 'wildlands_ascendants', 'guardian', 4),
  ('wa_medjed', 'wildlands_ascendants', 'trickster', 4),
  ('wa_wadjwer', 'wildlands_ascendants', 'guardian', 4),
  ('wa_khentiamentiu', 'wildlands_ascendants', 'guardian', 4),
  ('wa_heh', 'wildlands_ascendants', 'guardian', 5),
  ('wa_hauhet', 'wildlands_ascendants', 'guardian', 5),
  ('wa_amaunet', 'wildlands_ascendants', 'trickster', 5),
  ('wa_tatenen', 'wildlands_ascendants', 'guardian', 5),
  ('wa_iusaas', 'wildlands_ascendants', 'trickster', 5),
  -- Veiled Current expansion batch 3 (95/150)
  ('vc_ittanmomen', 'veiled_current', 'trickster', 1),
  ('vc_bakedanuki', 'veiled_current', 'trickster', 1),
  ('vc_wanyudo', 'veiled_current', 'warrior', 1),
  ('vc_nopperabo', 'veiled_current', 'trickster', 1),
  ('vc_ushioni', 'veiled_current', 'warrior', 1),
  ('vc_funadama', 'veiled_current', 'guardian', 2),
  ('vc_dosojin', 'veiled_current', 'guardian', 2),
  ('vc_kanayako', 'veiled_current', 'warrior', 2),
  ('vc_suijin', 'veiled_current', 'guardian', 2),
  ('vc_yamanokami', 'veiled_current', 'trickster', 2),
  ('vc_agyo', 'veiled_current', 'warrior', 3),
  ('vc_ungyo', 'veiled_current', 'guardian', 3),
  ('vc_suwa', 'veiled_current', 'guardian', 3),
  ('vc_kumano', 'veiled_current', 'guardian', 3),
  ('vc_atago', 'veiled_current', 'warrior', 3),
  ('vc_otoshi', 'veiled_current', 'guardian', 4),
  ('vc_yashimajinumi', 'veiled_current', 'warrior', 4),
  ('vc_watatsumi', 'veiled_current', 'guardian', 4),
  ('vc_sumiyoshi', 'veiled_current', 'guardian', 4),
  ('vc_hoderi', 'veiled_current', 'trickster', 4),
  ('vc_uhijini', 'veiled_current', 'guardian', 5),
  ('vc_suhijini', 'veiled_current', 'guardian', 5),
  ('vc_tsunoguhi', 'veiled_current', 'trickster', 5),
  ('vc_ikuguhi', 'veiled_current', 'trickster', 5),
  ('vc_ayakashikone', 'veiled_current', 'guardian', 5),
  -- Sovereign Crown expansion batch 3 (95/150)
  ('sc_soma', 'sovereign_crown', 'trickster', 1),
  ('sc_tvashtar', 'sovereign_crown', 'guardian', 1),
  ('sc_vishvedevas', 'sovereign_crown', 'guardian', 1),
  ('sc_apas', 'sovereign_crown', 'guardian', 1),
  ('sc_dyaus', 'sovereign_crown', 'warrior', 1),
  ('sc_vyasa', 'sovereign_crown', 'guardian', 2),
  ('sc_agastya', 'sovereign_crown', 'guardian', 2),
  ('sc_markandeya', 'sovereign_crown', 'guardian', 2),
  ('sc_vishvamitra', 'sovereign_crown', 'warrior', 2),
  ('sc_durvasa', 'sovereign_crown', 'trickster', 2),
  ('sc_gauri', 'sovereign_crown', 'guardian', 3),
  ('sc_mahagauri', 'sovereign_crown', 'guardian', 3),
  ('sc_ambika', 'sovereign_crown', 'guardian', 3),
  ('sc_kanyakumari', 'sovereign_crown', 'trickster', 3),
  ('sc_chamundi', 'sovereign_crown', 'trickster', 3),
  ('sc_chitrasena', 'sovereign_crown', 'trickster', 4),
  ('sc_manibhadra', 'sovereign_crown', 'guardian', 4),
  ('sc_garuda', 'sovereign_crown', 'warrior', 4),
  ('sc_virupaksha', 'sovereign_crown', 'guardian', 4),
  ('sc_hayagriva', 'sovereign_crown', 'guardian', 4),
  ('sc_sadashiva', 'sovereign_crown', 'guardian', 5),
  ('sc_pralaya', 'sovereign_crown', 'trickster', 5),
  ('sc_srishti', 'sovereign_crown', 'guardian', 5),
  ('sc_kalachakra', 'sovereign_crown', 'trickster', 5),
  ('sc_pranava', 'sovereign_crown', 'guardian', 5),
  -- Wildlands Ascendants expansion batch 3 (95/150)
  ('wa_farstrider', 'wildlands_ascendants', 'warrior', 1),
  ('wa_fireembracer', 'wildlands_ascendants', 'trickster', 1),
  ('wa_bonebreaker', 'wildlands_ascendants', 'warrior', 1),
  ('wa_shadoweater', 'wildlands_ascendants', 'trickster', 1),
  ('wa_bloodwalker', 'wildlands_ascendants', 'warrior', 1),
  ('wa_bata', 'wildlands_ascendants', 'warrior', 2),
  ('wa_sed', 'wildlands_ascendants', 'guardian', 2),
  ('wa_iat', 'wildlands_ascendants', 'guardian', 2),
  ('wa_nekhbet', 'wildlands_ascendants', 'guardian', 2),
  ('wa_sokar', 'wildlands_ascendants', 'guardian', 2),
  ('wa_anuket', 'wildlands_ascendants', 'trickster', 3),
  ('wa_iabet', 'wildlands_ascendants', 'guardian', 3),
  ('wa_imet', 'wildlands_ascendants', 'trickster', 3),
  ('wa_mehit', 'wildlands_ascendants', 'warrior', 3),
  ('wa_wenet', 'wildlands_ascendants', 'trickster', 3),
  ('wa_rahorakhty', 'wildlands_ascendants', 'warrior', 4),
  ('wa_atumkhepri', 'wildlands_ascendants', 'guardian', 4),
  ('wa_raatum', 'wildlands_ascendants', 'guardian', 4),
  ('wa_horemakhet', 'wildlands_ascendants', 'warrior', 4),
  ('wa_atumserpent', 'wildlands_ascendants', 'trickster', 4),
  ('wa_kauket', 'wildlands_ascendants', 'guardian', 5),
  ('wa_niu', 'wildlands_ascendants', 'trickster', 5),
  ('wa_benben', 'wildlands_ascendants', 'guardian', 5),
  ('wa_islandofflame', 'wildlands_ascendants', 'guardian', 5),
  ('wa_zeptepi', 'wildlands_ascendants', 'trickster', 5),
  -- Veiled Current expansion batch 4 (120/150)
  ('vc_mujina', 'veiled_current', 'trickster', 1),
  ('vc_hyakume', 'veiled_current', 'guardian', 1),
  ('vc_tsurubeotoshi', 'veiled_current', 'warrior', 1),
  ('vc_amefurikozo', 'veiled_current', 'trickster', 1),
  ('vc_kasaobake', 'veiled_current', 'trickster', 1),
  ('vc_kamadogami', 'veiled_current', 'guardian', 2),
  ('vc_idogami', 'veiled_current', 'guardian', 2),
  ('vc_kawayagami', 'veiled_current', 'trickster', 2),
  ('vc_toshigami', 'veiled_current', 'guardian', 2),
  ('vc_hashiragami', 'veiled_current', 'warrior', 2),
  ('vc_sannogongen', 'veiled_current', 'guardian', 3),
  ('vc_kifunemyojin', 'veiled_current', 'guardian', 3),
  ('vc_munakatasanjojin', 'veiled_current', 'trickster', 3),
  ('vc_kasugadaimyojin', 'veiled_current', 'warrior', 3),
  ('vc_haguro', 'veiled_current', 'warrior', 3),
  ('vc_yamatotakeru', 'veiled_current', 'warrior', 4),
  ('vc_jimmu', 'veiled_current', 'guardian', 4),
  ('vc_kushinadahime', 'veiled_current', 'guardian', 4),
  ('vc_tamayoribime', 'veiled_current', 'trickster', 4),
  ('vc_oomononushi', 'veiled_current', 'guardian', 4),
  ('vc_otonoji', 'veiled_current', 'guardian', 5),
  ('vc_otonobe', 'veiled_current', 'guardian', 5),
  ('vc_amenomihashira', 'veiled_current', 'guardian', 5),
  ('vc_amanoiwato', 'veiled_current', 'trickster', 5),
  ('vc_amenonuboko', 'veiled_current', 'warrior', 5),
  -- Sovereign Crown expansion batch 4 (120/150)
  ('sc_ratri', 'sovereign_crown', 'guardian', 1),
  ('sc_prithvi', 'sovereign_crown', 'guardian', 1),
  ('sc_vac', 'sovereign_crown', 'guardian', 1),
  ('sc_aranyani', 'sovereign_crown', 'trickster', 1),
  ('sc_sinivali', 'sovereign_crown', 'trickster', 1),
  ('sc_bhrigu', 'sovereign_crown', 'warrior', 2),
  ('sc_atri', 'sovereign_crown', 'guardian', 2),
  ('sc_kashyapa', 'sovereign_crown', 'guardian', 2),
  ('sc_gautama', 'sovereign_crown', 'guardian', 2),
  ('sc_bharadvaja', 'sovereign_crown', 'warrior', 2),
  ('sc_meenakshi', 'sovereign_crown', 'warrior', 3),
  ('sc_vaishnodevi', 'sovereign_crown', 'guardian', 3),
  ('sc_mahalakshmi', 'sovereign_crown', 'guardian', 3),
  ('sc_yellamma', 'sovereign_crown', 'trickster', 3),
  ('sc_santoshimata', 'sovereign_crown', 'guardian', 3),
  ('sc_vibhishana', 'sovereign_crown', 'guardian', 4),
  ('sc_sugriva', 'sovereign_crown', 'warrior', 4),
  ('sc_jambavan', 'sovereign_crown', 'guardian', 4),
  ('sc_airavata', 'sovereign_crown', 'guardian', 4),
  ('sc_uchchaishrava', 'sovereign_crown', 'trickster', 4),
  ('sc_narayana', 'sovereign_crown', 'guardian', 5),
  ('sc_dakshinamurti', 'sovereign_crown', 'guardian', 5),
  ('sc_hamsa', 'sovereign_crown', 'trickster', 5),
  ('sc_ardhanarishvara', 'sovereign_crown', 'guardian', 5),
  ('sc_trimurti', 'sovereign_crown', 'warrior', 5),
  -- Wildlands Ascendants expansion batch 4 (120/150)
  ('wa_mahaf', 'wildlands_ascendants', 'guardian', 1),
  ('wa_aqen', 'wildlands_ascendants', 'warrior', 1),
  ('wa_hrafhaf', 'wildlands_ascendants', 'trickster', 1),
  ('wa_babi', 'wildlands_ascendants', 'warrior', 1),
  ('wa_qebui', 'wildlands_ascendants', 'guardian', 1),
  ('wa_ash', 'wildlands_ascendants', 'warrior', 2),
  ('wa_dedun', 'wildlands_ascendants', 'guardian', 2),
  ('wa_tjenenet', 'wildlands_ascendants', 'guardian', 2),
  ('wa_hemen', 'wildlands_ascendants', 'warrior', 2),
  ('wa_ha', 'wildlands_ascendants', 'trickster', 2),
  ('wa_meskhetiu', 'wildlands_ascendants', 'warrior', 3),
  ('wa_sah', 'wildlands_ascendants', 'guardian', 3),
  ('wa_decans', 'wildlands_ascendants', 'trickster', 3),
  ('wa_mesektet', 'wildlands_ascendants', 'guardian', 3),
  ('wa_shesmetet', 'wildlands_ascendants', 'warrior', 3),
  ('wa_khonsuthoth', 'wildlands_ascendants', 'guardian', 4),
  ('wa_iahdjehuty', 'wildlands_ascendants', 'trickster', 4),
  ('wa_ramin', 'wildlands_ascendants', 'warrior', 4),
  ('wa_amunmin', 'wildlands_ascendants', 'warrior', 4),
  ('wa_khnumra', 'wildlands_ascendants', 'guardian', 4),
  ('wa_amun', 'wildlands_ascendants', 'guardian', 5),
  ('wa_ptahnun', 'wildlands_ascendants', 'warrior', 5),
  ('wa_theogdoad', 'wildlands_ascendants', 'guardian', 5),
  ('wa_hehu', 'wildlands_ascendants', 'trickster', 5),
  ('wa_zepneter', 'wildlands_ascendants', 'trickster', 5),

  -- Veiled Current expansion batch 5 (150/150)
  ('vc_kamaitachi', 'veiled_current', 'warrior', 1),
  ('vc_nekomata', 'veiled_current', 'trickster', 1),
  ('vc_inugami', 'veiled_current', 'warrior', 1),
  ('vc_mokumokuren', 'veiled_current', 'guardian', 1),
  ('vc_abumiguchi', 'veiled_current', 'trickster', 1),
  ('vc_betobetosan', 'veiled_current', 'trickster', 1),
  ('vc_hatanokami', 'veiled_current', 'guardian', 2),
  ('vc_funaosa', 'veiled_current', 'guardian', 2),
  ('vc_saohime', 'veiled_current', 'trickster', 2),
  ('vc_tataragami', 'veiled_current', 'warrior', 2),
  ('vc_michishirube', 'veiled_current', 'guardian', 2),
  ('vc_umayagami', 'veiled_current', 'guardian', 2),
  ('vc_gionkami', 'veiled_current', 'guardian', 3),
  ('vc_aoimatsuri', 'veiled_current', 'guardian', 3),
  ('vc_jidaimatsuri', 'veiled_current', 'trickster', 3),
  ('vc_danjiri', 'veiled_current', 'warrior', 3),
  ('vc_mikoshi', 'veiled_current', 'guardian', 3),
  ('vc_nebuta', 'veiled_current', 'trickster', 3),
  ('vc_abenoseimei', 'veiled_current', 'trickster', 4),
  ('vc_tamuramaro', 'veiled_current', 'warrior', 4),
  ('vc_raiko', 'veiled_current', 'warrior', 4),
  ('vc_tawaratoda', 'veiled_current', 'warrior', 4),
  ('vc_jingu', 'veiled_current', 'guardian', 4),
  ('vc_shotoku', 'veiled_current', 'guardian', 4),
  ('vc_kuninosazuchi', 'veiled_current', 'guardian', 5),
  ('vc_tsunokui', 'veiled_current', 'warrior', 5),
  ('vc_ikukui', 'veiled_current', 'guardian', 5),
  ('vc_amenosagiri', 'veiled_current', 'trickster', 5),
  ('vc_kuninosagiri', 'veiled_current', 'trickster', 5),

  -- Sovereign Crown expansion batch 5 (150/150)
  ('sc_vata', 'sovereign_crown', 'trickster', 1),
  ('sc_parjanya', 'sovereign_crown', 'guardian', 1),
  ('sc_savitr', 'sovereign_crown', 'warrior', 1),
  ('sc_trita', 'sovereign_crown', 'warrior', 1),
  ('sc_brihaspati', 'sovereign_crown', 'guardian', 1),
  ('sc_chayadevi', 'sovereign_crown', 'trickster', 1),
  ('sc_parashara', 'sovereign_crown', 'guardian', 2),
  ('sc_jamadagni', 'sovereign_crown', 'warrior', 2),
  ('sc_pulastya', 'sovereign_crown', 'trickster', 2),
  ('sc_garga', 'sovereign_crown', 'guardian', 2),
  ('sc_chyavana', 'sovereign_crown', 'trickster', 2),
  ('sc_lomasha', 'sovereign_crown', 'guardian', 2),
  ('sc_kamakhya', 'sovereign_crown', 'guardian', 3),
  ('sc_renuka', 'sovereign_crown', 'guardian', 3),
  ('sc_mariamman', 'sovereign_crown', 'trickster', 3),
  ('sc_sitala', 'sovereign_crown', 'guardian', 3),
  ('sc_bhadrakali', 'sovereign_crown', 'warrior', 3),
  ('sc_vindhyavasini', 'sovereign_crown', 'trickster', 3),
  ('sc_mahishasura', 'sovereign_crown', 'warrior', 4),
  ('sc_raktabija', 'sovereign_crown', 'trickster', 4),
  ('sc_hiranyaksha', 'sovereign_crown', 'warrior', 4),
  ('sc_hiranyakashipu', 'sovereign_crown', 'guardian', 4),
  ('sc_mayasura', 'sovereign_crown', 'trickster', 4),
  ('sc_nala', 'sovereign_crown', 'guardian', 4),
  ('sc_brahman', 'sovereign_crown', 'guardian', 5),
  ('sc_atman', 'sovereign_crown', 'guardian', 5),
  ('sc_lila', 'sovereign_crown', 'trickster', 5),
  ('sc_avidya', 'sovereign_crown', 'trickster', 5),
  ('sc_moksha', 'sovereign_crown', 'guardian', 5),
  ('sc_satchitananda', 'sovereign_crown', 'warrior', 5),

  -- Wildlands Ascendants expansion batch 5 (150/150)
  ('wa_wedjat', 'wildlands_ascendants', 'guardian', 1),
  ('wa_tit', 'wildlands_ascendants', 'guardian', 1),
  ('wa_djed', 'wildlands_ascendants', 'guardian', 1),
  ('wa_sebau', 'wildlands_ascendants', 'trickster', 1),
  ('wa_hemhemti', 'wildlands_ascendants', 'warrior', 1),
  ('wa_nehaher', 'wildlands_ascendants', 'trickster', 1),
  ('wa_sekhem', 'wildlands_ascendants', 'warrior', 2),
  ('wa_khentyirty', 'wildlands_ascendants', 'guardian', 2),
  ('wa_khentekhtai', 'wildlands_ascendants', 'warrior', 2),
  ('wa_heryshaf', 'wildlands_ascendants', 'guardian', 2),
  ('wa_nemty', 'wildlands_ascendants', 'trickster', 2),
  ('wa_andjety', 'wildlands_ascendants', 'guardian', 2),
  ('wa_tayet', 'wildlands_ascendants', 'guardian', 3),
  ('wa_imiut', 'wildlands_ascendants', 'guardian', 3),
  ('wa_qebehut', 'wildlands_ascendants', 'trickster', 3),
  ('wa_henu', 'wildlands_ascendants', 'warrior', 3),
  ('wa_seshat', 'wildlands_ascendants', 'guardian', 3),
  ('wa_nehemtawy', 'wildlands_ascendants', 'guardian', 3),
  ('wa_amenhotep', 'wildlands_ascendants', 'guardian', 4),
  ('wa_imhotep', 'wildlands_ascendants', 'guardian', 4),
  ('wa_ahmosenefertari', 'wildlands_ascendants', 'guardian', 4),
  ('wa_senusret', 'wildlands_ascendants', 'warrior', 4),
  ('wa_amenirdis', 'wildlands_ascendants', 'trickster', 4),
  ('wa_djoser', 'wildlands_ascendants', 'guardian', 4),
  ('wa_iunu', 'wildlands_ascendants', 'guardian', 5),
  ('wa_mnevis', 'wildlands_ascendants', 'warrior', 5),
  ('wa_weretkekau', 'wildlands_ascendants', 'trickster', 5),
  ('wa_akhet', 'wildlands_ascendants', 'guardian', 5),
  ('wa_pesedjet', 'wildlands_ascendants', 'warrior', 5),
  ('wa_benu', 'wildlands_ascendants', 'trickster', 5)
on conflict (blueprint_id) do nothing;
