extends Node
## Autoloaded as "PvxcManager". The PVXC — an Ark-Survival-style PvXC pit
## INSIDE the casino (hyperliminal layer). Everything about it serves two
## loops at once:
##
##  REVENGE LOOP (players): dying registers your killer in the revenge
##  ledger. Killing your registered killer pays a revenge bonus and clears
##  the grudge — which usually creates a new grudge pointed the other way.
##
##  HOUSE RECOVERY (the casino): the house takes the entry stake up front,
##  a cut of every death (the rest goes to the killer), and an extraction
##  fee on the way out. Big winners walking the floor eventually walk in
##  here — that's the design.
##
##  MULTIPLIERS: all reward rates x6 inside the zone; x12 in the permanent
##  RED CORE at the center, where the risk never turns off.
##
##  LAYER ROTATION (15 min): PvE = house-cat skins vs wildlife; PvP =
##  race/frame/mod identity forms so fighters meet as themselves. Global
##  clock via combat_phase / phase_changed.
##
##  Later: a "light" spectator/gamble-on-it version outside the zone
##  (possible web-app spinoff) — bet on runs without entering. Hooks:
##  run_started/run_ended/kill_recorded are the events that version needs.

signal run_started(stake: int)
signal run_ended(extracted: bool, loot: int)
signal kill_recorded(killer: String, victim: String, revenge: bool)
## Global combat layer for everyone in the pit. PvE = house-cat skins vs
## wildlife; PvP = race/frame/mod identity forms, player-vs-player.
signal phase_changed(phase: String)

const ZONE_MULT := 6.0        # reward multiplier anywhere in the PVXC
const RED_CORE_MULT := 12.0   # the permanently red center
const HOUSE_DEATH_CUT := 0.4  # house's share of a victim's carried loot
const EXTRACT_FEE := 0.10     # house fee on successful extraction
const MIN_STAKE := 100        # chips
## Server-wide PvE ↔ PvP rotation (seconds). Same clock for every run.
const PHASE_DURATION := 900.0

## Radii in world units (the zone scene mirrors these).
const ZONE_RADIUS := 120.0
const RED_CORE_RADIUS := 30.0

var in_run := false
var stake := 0
var carried_loot := 0
## victim -> killer: who you're owed revenge on.
var revenge_ledger: Dictionary = {}
## Lifetime house recovery (chips) — the casino's ledger.
var house_take := 0
## "pve" (cats vs wildlife) or "pvp" (identity forms, fight each other).
var combat_phase := "pve"
var _phase_elapsed := 0.0

## Multiplier at a world position inside the zone scene (center = origin).
func mult_at(pos: Vector3) -> float:
	var d := Vector2(pos.x, pos.z).length()
	if d <= RED_CORE_RADIUS:
		return RED_CORE_MULT
	if d <= ZONE_RADIUS:
		return ZONE_MULT
	return 1.0

func in_red_core(pos: Vector3) -> bool:
	return Vector2(pos.x, pos.z).length() <= RED_CORE_RADIUS

## Entry: stake chips. The house takes them immediately — you're buying a
## chance at 6x-12x, not making a deposit.
func enter(stake_chips: int) -> bool:
	if in_run:
		return false
	stake_chips = maxi(stake_chips, MIN_STAKE)
	if not await EconomyManager.spend_currency("chips", stake_chips, "pvxc_stake"):
		NotificationUI.notify_error("The PVXC wants %d chips up front. The house doesn't do credit." % stake_chips)
		return false
	house_take += stake_chips
	in_run = true
	stake = stake_chips
	carried_loot = 0
	run_started.emit(stake_chips)
	NotificationUI.notify_info("🔴 You're in the PVXC. Everything pays 6x. The red core pays 12x. Everyone here knows it.")
	return true

## Loot pickup while inside — base value multiplied by position.
func collect(base_value: int, pos: Vector3) -> void:
	if not in_run:
		return
	carried_loot += int(base_value * mult_at(pos))

## You killed someone: their carried loot splits house/you, and if they
## were YOUR registered killer, the revenge bonus doubles your share and
## clears the grudge.
func record_kill(victim_id: String, victim_loot: int, pos: Vector3) -> void:
	if not in_run:
		return
	var house_cut := int(victim_loot * HOUSE_DEATH_CUT)
	var share := victim_loot - house_cut
	var revenge: bool = revenge_ledger.get("local_player", "") == victim_id
	if revenge:
		share *= 2
		revenge_ledger.erase("local_player")
		NotificationUI.notify_win("⚔️ REVENGE. Double share. The grudge is settled — for you.")
	house_take += house_cut
	carried_loot += int(share * (mult_at(pos) / ZONE_MULT)) # position scales the kill too
	revenge_ledger[victim_id] = "local_player" # now THEY owe YOU one
	CrownManager.add_score("Top PvP Kills", "local_player", 1, PlayerProfile.faction)
	kill_recorded.emit("local_player", victim_id, revenge)

## You died: everything carried is seized — house cut first, killer gets
## the rest — and the killer goes into your revenge ledger.
func record_death(killer_id: String) -> void:
	if not in_run:
		return
	house_take += int(carried_loot * HOUSE_DEATH_CUT)
	revenge_ledger["local_player"] = killer_id
	in_run = false
	var lost := carried_loot
	carried_loot = 0
	stake = 0
	run_ended.emit(false, 0)
	NotificationUI.notify_error("💀 %s took everything (%d). The PVXC remembers. So should you." % [killer_id, lost])

## Walked out through an extraction gate: house skims the fee, the rest
## banks as chips (it's the casino's pit — it pays in the casino's money).
func extract() -> void:
	if not in_run:
		return
	var fee := int(carried_loot * EXTRACT_FEE)
	house_take += fee
	var banked := carried_loot - fee
	if banked > 0:
		await EconomyManager.earn_currency("chips", banked, "pvxc_extraction")
	in_run = false
	carried_loot = 0
	run_ended.emit(true, banked)
	NotificationUI.notify_win("🎰 Extracted with %d chips (house kept %d). Walk away. Or don't." % [banked, fee])

func my_target() -> String:
	return revenge_ledger.get("local_player", "")

func is_pvp_phase() -> bool:
	return combat_phase == "pvp"

func phase_seconds_left() -> float:
	return maxf(PHASE_DURATION - _phase_elapsed, 0.0)

func phase_label() -> String:
	if combat_phase == "pvp":
		return "PvP — fight as yourself"
	return "PvE — house cats vs the pit"

## PVXC time is provisional-PvP time: every second in a run feeds the
## Champion trial clock (CrownManager wants hours). The 15-minute layer
## flip runs whenever anyone is inside so the floor stays synchronized.
func _process(delta: float) -> void:
	_advance_phase(delta)
	if in_run:
		CrownManager.log_provisional_pvp("local_player", delta / 3600.0)

func _advance_phase(delta: float) -> void:
	_phase_elapsed += delta
	if _phase_elapsed < PHASE_DURATION:
		return
	_phase_elapsed = 0.0
	combat_phase = "pvp" if combat_phase == "pve" else "pve"
	phase_changed.emit(combat_phase)
	if combat_phase == "pvp":
		NotificationUI.notify_info("🔴 PVXC flips — PvP. Shed the house cat. Fight as yourself.")
	else:
		NotificationUI.notify_info("🐱 PVXC flips — PvE. House skins on. The wildlife hunts again.")
