class_name MorphRigData
## The 20 morphological rig MODS, ported verbatim from the Periliminal.Space
## Apps Script source (docs/reference/periliminal_space_v0.0.1/Rigs.gs).
## A mod is your body plan: a bonus, a drawback, and a silhouette. The
## ai_prompt field is the canonical art-generation prompt for each rig,
## used by the UGC/asset pipeline when generating rig visuals.

const RIGS: Array[Dictionary] = [
	{id="heavy_siege", name="Heavy Siege", bonus="+Stability", drawback="-Momentum", desc="Massive skeletal frame, reinforced plating, slow but stable, industrial fantasy aesthetic", ai_prompt="Massive skeletal frame, reinforced plating, slow but stable, industrial fantasy aesthetic"},
	{id="swiftburner", name="Swiftburner", bonus="+Acceleration", drawback="-Control", desc="Light skeletal frame, elongated legs, agile posture, kinetic energy trails, fast-motion effect", ai_prompt="Light skeletal frame, elongated legs, agile posture, kinetic energy trails, fast-motion effect"},
	{id="multi_limbed", name="Multi-Limbed", bonus="+Aux Action Slot", drawback="-Energy Stability", desc="Humanoid with multiple functional limbs, balanced mechanics, complex action-ready pose", ai_prompt="Humanoid with multiple functional limbs, balanced mechanics, complex action-ready pose"},
	{id="towering", name="Towering", bonus="+Intimidation Radius", drawback="-Evasion", desc="Extremely tall skeletal frame, intimidating proportions, vertical emphasis, epic fantasy setting", ai_prompt="Extremely tall skeletal frame, intimidating proportions, vertical emphasis, epic fantasy setting"},
	{id="compact", name="Compact", bonus="+Evasion", drawback="-AoE Reach", desc="Short, dense skeletal frame, high agility, crouched action stance, futuristic environment", ai_prompt="Short, dense skeletal frame, high agility, crouched action stance, futuristic environment"},
	{id="elastic", name="Elastic", bonus="+Melee Range", drawback="-Mitigation", desc="Flexible elongated skeletal frame, stretching limbs, exaggerated motion pose, dynamic style", ai_prompt="Flexible elongated skeletal frame, stretching limbs, exaggerated motion pose, dynamic style"},
	{id="floating_core", name="Floating Core", bonus="+Vertical Mastery", drawback="-Traction", desc="Levitation-based frame, suspended central core, floating posture, mystical sci-fi lighting", ai_prompt="Levitation-based frame, suspended central core, floating posture, mystical sci-fi lighting"},
	{id="split_form", name="Split Form", bonus="+Decoy", drawback="-Focus Regen", desc="Skeletal frame divided into dual-body segments, mirrored action pose, energy separation effects", ai_prompt="Skeletal frame divided into dual-body segments, mirrored action pose, energy separation effects"},
	{id="inverted_spine", name="Inverted Spine", bonus="+Backstab Damage", drawback="-Front Defense", desc="Unusual upside-down spine skeletal structure, back-heavy action stance, dark fantasy setting", ai_prompt="Unusual upside-down spine skeletal structure, back-heavy action stance, dark fantasy setting"},
	{id="modular", name="Modular", bonus="+Item Slot", drawback="-Vitality Regen", desc="Interchangeable skeletal parts, mechanical modular design, tool-equipped posture, workshop background", ai_prompt="Interchangeable skeletal parts, mechanical modular design, tool-equipped posture, workshop background"},
	{id="armored", name="Armored", bonus="+Mitigation", drawback="-Momentum", desc="Heavily plated skeletal frame, tank-like proportions, battle-ready stance, dark industrial environment", ai_prompt="Heavily plated skeletal frame, tank-like proportions, battle-ready stance, dark industrial environment"},
	{id="lithe", name="Lithe", bonus="+Dodge Window", drawback="-Stability", desc="Slim skeletal frame, high dodge emphasis, dynamic motion blur, agile pose", ai_prompt="Slim skeletal frame, high dodge emphasis, dynamic motion blur, agile pose"},
	{id="tendril", name="Tendril", bonus="+CC Duration", drawback="-Burst Damage", desc="Skeletal frame with organic tendrils extending from body, CC-focused stance, shadowy environment", ai_prompt="Skeletal frame with organic tendrils extending from body, CC-focused stance, shadowy environment"},
	{id="rooted", name="Rooted", bonus="+Control Strength", drawback="No Dash", desc="Lower body anchored, strong grounded posture, skeletal roots extending, earthy setting", ai_prompt="Lower body anchored, strong grounded posture, skeletal roots extending, earthy setting"},
	{id="hover_strider", name="Hover Strider", bonus="No Fall Damage", drawback="-Stamina Regen", desc="Floating skeletal frame, aerodynamic form, hovering pose, sci-fi sky background", ai_prompt="Floating skeletal frame, aerodynamic form, hovering pose, sci-fi sky background"},
	{id="centroid", name="Centroid", bonus="+5% All Stats", drawback="None", desc="Balanced skeletal frame, neutral proportions, symmetric action pose, bright neutral environment", ai_prompt="Balanced skeletal frame, neutral proportions, symmetric action pose, bright neutral environment"},
	{id="shardform", name="Shardform", bonus="+Reflect", drawback="Shatter Risk", desc="Crystalline skeletal frame, reflective shards protruding, angular pose, high fantasy lighting", ai_prompt="Crystalline skeletal frame, reflective shards protruding, angular pose, high fantasy lighting"},
	{id="quadruped", name="Quadruped", bonus="+Sprint Speed", drawback="No Dual-Wield", desc="Four-legged skeletal frame, low center of gravity, sprinting pose, rugged terrain environment", ai_prompt="Four-legged skeletal frame, low center of gravity, sprinting pose, rugged terrain environment"},
	{id="serpentine", name="Serpentine", bonus="+Immobilize Resist", drawback="-Jump Height", desc="Long, flexible skeletal frame, snake-like movement, coiled action stance, mystical background", ai_prompt="Long, flexible skeletal frame, snake-like movement, coiled action stance, mystical background"},
	{id="colossus", name="Colossus", bonus="+Control", drawback="-Momentum", desc="Gigantic skeletal frame, towering proportions, slow imposing pose, epic battle environment", ai_prompt="Gigantic skeletal frame, towering proportions, slow imposing pose, epic battle environment"},
]

static func by_id(rig_id: String) -> Dictionary:
	for r in RIGS:
		if r.id == rig_id: return r
	return {}
