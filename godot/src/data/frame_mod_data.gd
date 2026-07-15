class_name FrameModData
# Hyperliminal sensorium frames + legacy stat mods.
# OmniDex identity frames are the separate 20-entry Periliminal set in
# OmniDexRegistry.FRAMES (skirmisher…architect). Do NOT add shop cosmetics
# here — that was the typo that inflated the frame count to 24.

const FRAMES: Array[Dictionary] = [
	# Light Frames (index 0-9)
	{id="veil", name="Veil Frame", type="light", stat_bonus={spd=15, sty=10}, desc="Gossamer-thin, near-invisible in motion", lore="Constructed from Nyx-silk, the Veil Frame bends light around its wearer.", unlock_pow=0},
	{id="zephyr", name="Zephyr Frame", type="light", stat_bonus={spd=12, lck=8}, desc="Wind-adapted, reduces drag to zero", lore="The Zephyr was engineered by Aqua artisans who studied how air moves through water.", unlock_pow=0},
	{id="viper", name="Viper Frame", type="light", stat_bonus={spd=10, pow=8, sty=5}, desc="Strike-optimized for rapid offense", lore="Named for the viper-cats of Cat Forest. Attacks twice as often but defends less.", unlock_pow=100},
	{id="phantom", name="Phantom Frame", type="light", stat_bonus={spd=8, lck=12, sty=8}, desc="Ethereal construction, hard to target", lore="The Phantom Frame partially dematerializes on impact, reducing hit damage.", unlock_pow=200},
	{id="crimson", name="Crimson Frame", type="light", stat_bonus={spd=10, pow=12, sty=6}, desc="Battle-red chassis, POW-forward design", lore="War frames from the old empire, repurposed for Paw Vegas combat circuits.", unlock_pow=300},
	{id="glacial", name="Glacial Frame", type="light", stat_bonus={spd=6, res=10, sty=12}, desc="Ice-tempered, stable at speed", lore="Cooled to sub-zero during construction. Prevents overheating in intense races.", unlock_pow=300},
	{id="bolt", name="Bolt Frame", type="light", stat_bonus={spd=20, pow=4}, desc="Maximum velocity configuration", lore="The fastest light frame ever made. Sacrifices everything for speed.", unlock_pow=500},
	{id="soul", name="Soul Frame", type="light", stat_bonus={lck=15, sty=15}, desc="Resonates with companion bond energy", lore="Amplifies the spiritual connection between cat and companion.", unlock_pow=500},
	{id="cinder", name="Cinder Frame", type="light", stat_bonus={spd=8, pow=10, lck=6}, desc="Ember-forged, runs hot", lore="Built in the forges beneath Cat Coliseum. Still warm from creation.", unlock_pow=400},
	{id="flux", name="Flux Frame", type="light", stat_bonus={spd=10, lck=10, sty=10}, desc="Quantum-stable, adaptable", lore="The Flux Frame adapts its properties based on the combat situation.", unlock_pow=750},
	# Heavy Frames (index 10-19)
	{id="bastion", name="Bastion Frame", type="heavy", stat_bonus={res=20, pow=10}, desc="Impenetrable fortress configuration", lore="A Bastion-frame cat has never been moved in combat. Not once.", unlock_pow=0},
	{id="tremor", name="Tremor Frame", type="heavy", stat_bonus={pow=18, res=8}, desc="Earth-shaking strike frame", lore="Each step sends shockwaves. Combat trainers measure Tremor pilots by the cracks they leave.", unlock_pow=100},
	{id="behemoth", name="Behemoth Frame", type="heavy", stat_bonus={res=25, pow=5}, desc="Maximum endurance build", lore="The Behemoth doesn't dodge. It doesn't need to.", unlock_pow=200},
	{id="bulwark", name="Bulwark Frame", type="heavy", stat_bonus={res=15, pow=12, sty=5}, desc="Defensive anchor with offensive capability", lore="Team-optimized. A Bulwark at the front means the team survives.", unlock_pow=300},
	{id="ignis", name="Ignis Frame", type="heavy", stat_bonus={pow=16, res=10, sty=4}, desc="Fire-core engine, burn damage", lore="The Ignis burns. Everything it touches. Consistently.", unlock_pow=400},
	{id="glaci", name="Glaci Frame", type="heavy", stat_bonus={res=20, sty=10}, desc="Permafrost armor, cold resistance", lore="Nothing penetrates Glaci-grade armor. Not heat, not steel, not time.", unlock_pow=400},
	{id="surge", name="Surge Frame", type="heavy", stat_bonus={pow=20, lck=5}, desc="Power-burst configuration", lore="Stores kinetic energy for three turns. The fourth turn is devastating.", unlock_pow=500},
	{id="siege", name="Siege Frame", type="heavy", stat_bonus={pow=14, res=16}, desc="Balanced heavy-assault build", lore="Siege-frame cats are deployed when the objective must be destroyed.", unlock_pow=600},
	{id="blight", name="Blight Frame", type="heavy", stat_bonus={pow=12, res=12, lck=-5, sty=8}, desc="Toxic warfare chassis", lore="Effective. Also slightly cursed. The LCK penalty is considered acceptable.", unlock_pow=700},
	{id="ossian", name="Ossian Frame", type="heavy", stat_bonus={res=30, pow=8}, desc="Bone-reinforced maximum defense", lore="Oldest heavy frame design in the archive. Still the hardest to crack.", unlock_pow=1000},
]

const MODS: Array[Dictionary] = [
	{id="overclock", name="Overclock", stat_bonus={spd=10, pow=5, res=-5}, category="offensive", desc="Push all systems past rated limits", lore="Voided warranty. Absolutely worth it."},
	{id="shield_matrix", name="Shield Matrix", stat_bonus={res=15, spd=-5}, category="defensive", desc="Energy barrier absorbs first 20 damage", lore="SovereignCrown tech, licensed to the public. Slightly."},
	{id="reflex_booster", name="Reflex Booster", stat_bonus={spd=8, lck=5}, category="utility", desc="Reaction time enhancement", lore="Implanted at the base of the tail. Tingles during combat."},
	{id="void_capacitor", name="Void Capacitor", stat_bonus={lck=12, sty=8}, category="utility", desc="Draws power from void energy", lore="Slightly dangerous. Worth the +12 LCK."},
	{id="combat_ai", name="Combat AI", stat_bonus={pow=8, lck=6}, category="offensive", desc="Tactical AI co-pilot for combat decisions", lore="Doesn't take over. Just suggests. Loudly. Until you listen."},
	{id="thermal_vent", name="Thermal Vent", stat_bonus={pow=6, res=8, spd=4}, category="defensive", desc="Heat dissipation prevents overload", lore="Keeps the frame cool under fire. Both metaphorically and literally."},
	{id="momentum_coil", name="Momentum Coil", stat_bonus={spd=15, pow=8, res=-8}, category="offensive", desc="Converts speed to strike force", lore="The faster you go, the harder you hit. Also the harder you crash."},
	{id="stealth_cloak", name="Stealth Cloak", stat_bonus={sty=15, lck=8, pow=-5}, category="utility", desc="Partial optical camouflage", lore="Makes you harder to target. Also very stylish."},
	{id="luck_amplifier", name="Luck Amplifier", stat_bonus={lck=20, pow=-5, res=-5}, category="utility", desc="Pure probability manipulation", lore="Statistically impossible outcomes become merely very unlikely."},
	{id="power_core_mk2", name="Power Core MK2", stat_bonus={pow=15, res=5}, category="offensive", desc="Upgraded power generation system", lore="Standard issue for SovereignCrown elite. Available for the right price."},
	{id="nano_repair", name="Nano Repair", stat_bonus={res=12, sty=5}, category="defensive", desc="Self-repairing nanobots during combat", lore="Fixes damage between hits. Not during hits. Yet."},
	{id="faction_amplifier", name="Faction Amplifier", stat_bonus={}, category="faction", desc="Triples faction synergy bonus", lore="Resonates with faction energy. Choose your faction wisely before installing."},
	{id="companion_link", name="Companion Link", stat_bonus={lck=8, sty=8}, category="companion", desc="Deepens companion bond, +5% faction synergy", lore="The bond between cat and companion, made material."},
	{id="turbo_injector", name="Turbo Injector", stat_bonus={spd=20, pow=3, res=-10}, category="offensive", desc="Maximum speed burst system", lore="Warning: not intended for sustained use. Very much used for sustained use."},
	{id="quantum_lens", name="Quantum Lens", stat_bonus={lck=10, pow=6, spd=4}, category="utility", desc="Observes probability to find optimal paths", lore="Schrödinger insisted this was impossible. He lost a bet."},
	{id="adaptive_armor", name="Adaptive Armor", stat_bonus={res=10, sty=10}, category="defensive", desc="Self-adapts to damage type received", lore="After the first hit, it knows how to stop the second."},
	{id="overdrive_pulse", name="Overdrive Pulse", stat_bonus={pow=18, res=-8, spd=5}, category="offensive", desc="Maximum power output pulse", lore="Three seconds of absolute maximum power. Used carefully. Never carefully."},
	{id="ghost_protocol", name="Ghost Protocol", stat_bonus={sty=20, lck=10, spd=6}, category="utility", desc="Full stealth system with ghost imaging", lore="In ghost mode, you're not there. You're really not there."},
	{id="berserker_chip", name="Berserker Chip", stat_bonus={pow=22, lck=-10, res=-8}, category="offensive", desc="Removes all combat limiters", lore="All limiters removed. Irreversible. Extremely effective."},
	{id="harmony_crystal", name="Harmony Crystal", stat_bonus={pow=5, res=5, spd=5, lck=5, sty=5}, category="balanced", desc="Perfectly balanced mod, +5 to all stats", lore="Cut from the Harmony Stone deep in Cat Forest. Extremely rare."},
]

static func get_frame(frame_id: String) -> Dictionary:
	for f in FRAMES:
		if f.id == frame_id: return f.duplicate()
	return {}

static func get_mod(mod_id: String) -> Dictionary:
	for m in MODS:
		if m.id == mod_id: return m.duplicate()
	return {}

static func apply_frame_stats(frame_id: String, base_stats: Dictionary) -> Dictionary:
	var frame = get_frame(frame_id)
	if frame.is_empty(): return base_stats
	var result = base_stats.duplicate()
	for stat in frame.get("stat_bonus", {}).keys():
		result[stat] = result.get(stat, 0) + frame["stat_bonus"][stat]
	return result

static func apply_mod_stats(mod_id: String, base_stats: Dictionary) -> Dictionary:
	var mod = get_mod(mod_id)
	if mod.is_empty(): return base_stats
	var result = base_stats.duplicate()
	for stat in mod.get("stat_bonus", {}).keys():
		result[stat] = result.get(stat, 0) + mod["stat_bonus"][stat]
	return result

static func get_all_frames_by_type(frame_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for f in FRAMES:
		if f.get("type", "") == frame_type:
			result.append(f.duplicate())
	return result
