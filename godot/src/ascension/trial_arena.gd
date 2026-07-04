extends Node3D
## The Ascension Trial arena — a sealed twilight ring. Reads
## AscensionTrial.round_rules() and runs waves (round 1) or the shadow
## duel (rounds 2-3). The shadow is Knoll wearing your build: its stats
## come from YOUR stats plus Hope's learned combat profile — it punishes
## the habits you actually have.

const ARENA_R := 40.0
const WAVES := 3
const WAVE_SIZE := 4

var _player: ThirdPersonController
var _creatures: Array[PvxcCreature] = []
var _shadow: PvxcCreature = null
var _player_hp := 100
var _shield := 0
var _attack_damage := 20
var _wave := 0
var _hud: Label

func _ready() -> void:
	var rules := AscensionTrial.round_rules()
	if rules.is_empty():
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/ascension.tscn")
		return
	_build_arena()
	_player = ThirdPersonController.new()
	add_child(_player)
	_player.global_position = Vector3(0, 2, ARENA_R * 0.6)
	var stats := CharacterCreatorLogic.build_starting_stats(
		PlayerProfile.selected_race_id, PlayerProfile.faction, PlayerProfile.selected_frame)
	_attack_damage = 16 + int(stats.pow) / 2 + PlayerProfile.level

	var hotbar := HotbarUI.new()
	hotbar.cast_requested.connect(_on_cast)
	add_child(hotbar)
	add_child(SensoriumAmbience.new())
	MusicManager.play_context("pvxc") # silence + your hum; the trial is private

	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(10, 10)
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)
	NotificationUI.notify_info(rules.desc)

	if rules.mode == "waves":
		_next_wave()
	else:
		_spawn_shadow(rules.shadow_frame)

func _build_arena() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.03, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.35, 0.55)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var floor_mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = ARENA_R
	cyl.bottom_radius = ARENA_R
	cyl.height = 1.0
	floor_mi.mesh = cyl
	floor_mi.position.y = -0.5
	floor_mi.material_override = IdentityLens.world_material(Color(0.18, 0.15, 0.28))
	add_child(floor_mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = ARENA_R
	shape.height = 1.0
	cs.shape = shape
	cs.position.y = -0.5
	body.add_child(cs)
	add_child(body)

	var lamp := OmniLight3D.new()
	lamp.light_color = IdentityLens.sensorium().light
	lamp.omni_range = ARENA_R * 2.0
	lamp.light_energy = 2.0
	lamp.position.y = 14.0
	add_child(lamp)

func _next_wave() -> void:
	_wave += 1
	if _wave > WAVES:
		AscensionTrial.win_round()
		return
	NotificationUI.notify_info("Wave %d / %d" % [_wave, WAVES])
	var roster := CompanionRegistry.get_all()
	for i in range(WAVE_SIZE):
		var a := TAU * i / WAVE_SIZE
		var c := PvxcCreature.new()
		c.position = Vector3(cos(a), 0, sin(a)) * (ARENA_R * 0.7)
		add_child(c)
		c.setup(roster[randi() % roster.size()], _player)
		c.bit_player.connect(_on_bitten)
		c.died.connect(func(cr):
			_creatures.erase(cr)
			if _creatures.is_empty():
				_next_wave())
		_creatures.append(c)

## The shadow: Knoll in your silhouette, biased by Hope's read on you.
func _spawn_shadow(shadow_frame: String) -> void:
	var stats := CharacterCreatorLogic.build_starting_stats(
		PlayerProfile.selected_race_id, PlayerProfile.faction, shadow_frame)
	var bias: Dictionary = Hope.combat_profile()
	var shadow_entity := {
		"id": "knoll", "name": "Knoll (you)",
		"faction": PlayerProfile.faction, "rarity": 5,
		"pow": int(stats.pow) * 2 + int(bias.get("aggression", 0.5) * 30.0),
		"res": int(stats.res) * 2 + int(bias.get("caution", 0.5) * 30.0),
		"spd": int(stats.spd) * 2,
	}
	_shadow = PvxcCreature.new()
	_shadow.position = Vector3(0, 0, -ARENA_R * 0.6)
	add_child(_shadow)
	_shadow.setup(shadow_entity, _player)
	_shadow.bit_player.connect(_on_bitten)
	_shadow.died.connect(func(_c): AscensionTrial.win_round())
	_creatures.append(_shadow)
	SkillVFX.ultimate_burst(self, _shadow.position, 5.0)
	NotificationUI.notify_info("👤 Knoll steps out of your shadow. It has been taking notes.")

func _on_bitten(damage: int) -> void:
	SkillManager.gain_ultimate(3.0)
	if _shield > 0:
		var ab := mini(_shield, damage)
		_shield -= ab
		damage -= ab
	_player_hp -= damage
	if _player_hp <= 0:
		AscensionTrial.lose(AscensionTrial.current_round)

func _on_cast(sk: Dictionary) -> void:
	SkillVFX.cast_flash(self, _player.global_position)
	var radius: float = maxf(float(sk.get("radius", 3.0)), 4.0)
	var power: float = float(sk.get("power", 1.0))
	match sk.get("kind", "damage"):
		"shield":
			_shield = maxi(_shield, int(30 * power))
			SkillVFX.shield_bubble(self, _player)
		"mobility":
			_player.global_position += -_player.global_transform.basis.z * (6.0 + 6.0 * power)
		_:
			var dmg := int(_attack_damage * power)
			SkillVFX.aoe_ring(self, _player.global_position, radius)
			for c in _creatures.duplicate():
				if is_instance_valid(c) and c.dist_to(_player.global_position) < radius:
					c.take_hit(dmg)
					SkillVFX.hit_spark(self, c.global_position)
					SkillManager.gain_ultimate(6.0)

func _process(_d: float) -> void:
	if _hud == null:
		return
	var line := "ROUND %d   HP %d" % [AscensionTrial.current_round, maxi(_player_hp, 0)]
	if _shield > 0:
		line += "  SHIELD %d" % _shield
	if AscensionTrial.round_rules().get("mode", "") == "waves":
		line += "   Wave %d/%d" % [_wave, WAVES]
	else:
		line += "   - beat yourself."
	_hud.text = line
