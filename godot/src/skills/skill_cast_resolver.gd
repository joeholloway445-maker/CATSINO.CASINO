class_name SkillCastResolver
extends RefCounted
## Shared skill cast pipeline — one place for windup, telegraph, VFX,
## damage math, element riders, and hit juice. LayerWorld / Arena / PVXC /
## TrialArena used to each invent a slightly different instant-cast loop;
## hosts now call resolve() (sync, for smokes) or resolve_async() (windup).

const WINDUP_DAMAGE := 0.22
const WINDUP_ULT := 0.38
const WINDUP_UTILITY := 0.12

## Host opts (all optional except what the kind needs):
##   base_attack: int          — weapon/stat floor for damage kinds
##   targets: Array            — Node3Ds with take_hit (or Callable filter)
##   on_hit: Callable(node, dmg, elem) — extra host reaction per land
##   on_self_shield: Callable(amount) — host applies shield pool
##   on_self_mobility: Callable(distance) — host moves caster
##   on_self_buff: Callable(power) — host buffs attack briefly
##   on_build / on_sentry / on_summon / on_transform / on_bastion / on_control
##   skip_vfx: bool
##   skip_windup: bool         — force sync even in resolve_async
##   telegraph: bool           — default true for damage shapes

static func windup_for(sk: Dictionary) -> float:
	if int(sk.get("ult_cost", 0)) > 0:
		return WINDUP_ULT
	match str(sk.get("kind", "damage")):
		"shield", "buff", "mobility":
			return WINDUP_UTILITY
		_:
			return WINDUP_DAMAGE * clampf(float(sk.get("power", 1.0)) / 2.0 + 0.5, 0.6, 1.4)

static func element_color(elem: String) -> Color:
	var e: Dictionary = SkillData.element(elem)
	if e.is_empty():
		return Color.TRANSPARENT
	return e.get("color", Color.WHITE) as Color

static func compute_damage(sk: Dictionary, base_attack: int) -> int:
	var power := float(sk.get("power", 1.0))
	var dmg := int(float(base_attack) * power)
	var elem := str(sk.get("element", ""))
	if elem == "" and SkillManager != null and SkillManager.has_method("element_of_skill"):
		elem = str(SkillManager.element_of_skill(str(sk.get("id", ""))))
	if elem == "energy":
		dmg = int(dmg * 1.15)
	if SkillManager != null and SkillManager.has_method("wagering_edge_relief"):
		dmg = int(dmg * (1.0 + SkillManager.wagering_edge_relief()))
	if str(sk.get("kind", "")) == "chance":
		# Gambler's spread — house still edges long-run.
		dmg = int(dmg * (2.0 if randf() < 0.35 else 0.6))
	return maxi(dmg, 1)

static func play_cast_vfx(host: Node3D, caster: Node3D, sk: Dictionary) -> void:
	if host == null or caster == null or not is_instance_valid(host) or not is_instance_valid(caster):
		return
	var at: Vector3 = caster.global_position
	var shape: String = str(sk.get("shape", "single"))
	var radius: float = float(sk.get("radius", 3.0))
	var elem := str(sk.get("element", ""))
	if elem == "" and SkillManager != null and SkillManager.has_method("element_of_skill"):
		elem = str(SkillManager.element_of_skill(str(sk.get("id", ""))))
	var tint := element_color(elem)
	var cast_bp := {}
	if BlueprintManager != null and BlueprintManager.has_method("equipped_for"):
		cast_bp = BlueprintManager.equipped_for("skill", str(sk.get("id", "")))
	if not cast_bp.is_empty():
		SkillVFX.blueprint_cast(host, at, cast_bp)
	else:
		SkillVFX.cast_flash(host, at)
		if tint.a > 0.0:
			SkillVFX.aoe_ring(host, at, 1.2, tint)
	if int(sk.get("ult_cost", 0)) > 0:
		SkillVFX.ultimate_burst(host, at, maxf(radius, 6.0))
	elif shape == "aoe":
		SkillVFX.aoe_ring(host, at, radius, tint if tint.a > 0.0 else Color.TRANSPARENT)
	elif shape == "line":
		SkillVFX.line_beam(host, at, -caster.global_transform.basis.z, radius)
		if tint.a > 0.0:
			SkillVFX.aoe_ring(host, at + (-caster.global_transform.basis.z) * (radius * 0.5), 0.8, tint)

static func play_telegraph(host: Node3D, caster: Node3D, sk: Dictionary) -> void:
	if host == null or caster == null:
		return
	var shape: String = str(sk.get("shape", "single"))
	var radius: float = float(sk.get("radius", 3.0))
	var elem := str(sk.get("element", ""))
	var tint := element_color(elem)
	if tint.a <= 0.0:
		tint = Color(1.0, 0.85, 0.35, 0.85)
	tint.a = 0.55
	match shape:
		"aoe", "single":
			SkillVFX.cast_telegraph(host, caster.global_position, maxf(radius, 2.5), tint, windup_for(sk))
		"line":
			SkillVFX.cast_telegraph_line(host, caster.global_position,
				-caster.global_transform.basis.z, radius, tint, windup_for(sk))
		_:
			SkillVFX.cast_telegraph(host, caster.global_position, 2.0, tint, windup_for(sk))

## Immediate resolve — smokes + hosts that already did their own windup.
static func resolve(host: Node3D, caster: Node3D, sk: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var out := {
		"hits": 0, "damage": 0, "kind": str(sk.get("kind", "damage")),
		"skill_id": str(sk.get("id", "")), "element": str(sk.get("element", "")),
		"self_only": false,
	}
	if host == null or caster == null or not is_instance_valid(caster):
		return out
	var elem := str(sk.get("element", ""))
	if elem == "" and SkillManager != null and SkillManager.has_method("element_of_skill"):
		elem = str(SkillManager.element_of_skill(str(sk.get("id", ""))))
		out["element"] = elem
	if not bool(opts.get("skip_vfx", false)):
		play_cast_vfx(host, caster, sk)

	var kind: String = str(sk.get("kind", "damage"))
	var power: float = float(sk.get("power", 1.0))
	match kind:
		"shield":
			var amount := int(30 * power)
			if opts.get("on_self_shield") is Callable:
				(opts.on_self_shield as Callable).call(amount)
			elif not bool(opts.get("skip_vfx", false)):
				SkillVFX.shield_bubble(host, caster, 6.0)
			out["self_only"] = true
			out["shield"] = amount
			return out
		"buff":
			if opts.get("on_self_buff") is Callable:
				(opts.on_self_buff as Callable).call(power)
			out["self_only"] = true
			return out
		"mobility":
			var dist := 6.0 + 6.0 * power
			if opts.get("on_self_mobility") is Callable:
				(opts.on_self_mobility as Callable).call(dist)
			else:
				caster.global_position += -caster.global_transform.basis.z * dist
			out["self_only"] = true
			return out
		"build":
			if opts.get("on_build") is Callable:
				(opts.on_build as Callable).call(power)
			out["self_only"] = true
			return out
		"sentry":
			if opts.get("on_sentry") is Callable:
				(opts.on_sentry as Callable).call(power)
			out["self_only"] = true
			return out
		"summon":
			if opts.get("on_summon") is Callable:
				(opts.on_summon as Callable).call(power)
			out["self_only"] = true
			return out
		"transform":
			if opts.get("on_transform") is Callable:
				(opts.on_transform as Callable).call(power, int(sk.get("ult_cost", 0)) > 0)
			out["self_only"] = true
			return out
		"bastion":
			if opts.get("on_bastion") is Callable:
				(opts.on_bastion as Callable).call(power)
			out["self_only"] = true
			return out
		"control":
			if opts.get("on_control") is Callable:
				(opts.on_control as Callable).call(sk, power)
			# Fall through to hit targets too when a target list is provided.
		_:
			pass

	var base_attack := int(opts.get("base_attack", 12))
	var dmg := compute_damage(sk, base_attack)
	out["damage"] = dmg
	var radius: float = float(sk.get("radius", 3.0))
	var reach := maxf(radius, 4.0)
	var shape: String = str(sk.get("shape", "single"))
	var targets: Array = opts.get("targets", [])
	var hits := 0
	for t in targets:
		if t == null or not is_instance_valid(t):
			continue
		if not (t is Node3D):
			continue
		var n := t as Node3D
		if not _in_shape(caster, n, shape, reach):
			continue
		var has_hit := n.has_method("take_hit")
		if not has_hit and not (opts.get("on_hit") is Callable):
			continue
		if has_hit:
			n.take_hit(dmg)
		if not bool(opts.get("skip_vfx", false)):
			SkillVFX.hit_spark(host, n.global_position)
			if elem != "":
				SkillVFX.element_hit(host, n.global_position, elem)
		_apply_element_rider(host, caster, elem, n, dmg)
		hits += 1
		if opts.get("on_hit") is Callable:
			(opts.on_hit as Callable).call(n, dmg, elem)
		if SkillManager != null:
			SkillManager.gain_ultimate(4.0)
			if str(sk.get("id", "")) != "":
				SkillManager.add_skill_xp(str(sk.get("id", "")), 8)
	out["hits"] = hits
	return out

## Windup + telegraph, then resolve. `host` must be in the scene tree.
static func resolve_async(host: Node, caster: Node3D, sk: Dictionary, opts: Dictionary = {}) -> Dictionary:
	if host == null or host.get_tree() == null:
		return resolve(host as Node3D, caster, sk, opts)
	var skip := bool(opts.get("skip_windup", false))
	var kind := str(sk.get("kind", "damage"))
	var wants_telegraph := bool(opts.get("telegraph", kind in ["damage", "chance", "control"]))
	if not skip and wants_telegraph and host is Node3D and caster != null:
		play_telegraph(host as Node3D, caster, sk)
	var wait := 0.0 if skip else windup_for(sk)
	if wait > 0.0:
		await host.get_tree().create_timer(wait).timeout
	if caster == null or not is_instance_valid(caster):
		return {"hits": 0, "damage": 0, "kind": kind, "skill_id": str(sk.get("id", "")), "cancelled": true}
	return resolve(host as Node3D, caster, sk, opts)

static func _in_shape(caster: Node3D, target: Node3D, shape: String, reach: float) -> bool:
	var delta: Vector3 = target.global_position - caster.global_position
	delta.y = 0.0
	var dist := delta.length()
	match shape:
		"line":
			if dist > reach or dist < 0.15:
				return false
			var fwd := -caster.global_transform.basis.z
			fwd.y = 0.0
			if fwd.length() < 0.01:
				return dist <= reach
			fwd = fwd.normalized()
			var dir := delta.normalized()
			return dir.dot(fwd) >= 0.55
		"self":
			return false
		_:
			return dist <= reach

static func _apply_element_rider(host: Node3D, caster: Node3D, elem: String, target: Node3D, dmg: int) -> void:
	if elem == "" or not is_instance_valid(target):
		return
	match elem:
		"entropy":
			if host.get_tree() == null:
				return
			var tid := target.get_instance_id()
			host.get_tree().create_timer(0.95).timeout.connect(func():
				var n := instance_from_id(tid)
				if n != null and is_instance_valid(n) and n.has_method("take_hit"):
					n.take_hit(maxi(1, dmg / 3))
					if n is Node3D:
						SkillVFX.hit_spark(host, (n as Node3D).global_position)
						SkillVFX.element_hit(host, (n as Node3D).global_position, "entropy"))
		"quantum":
			if randf() < 0.2 and target.has_method("take_hit"):
				target.take_hit(dmg)
				SkillVFX.hit_spark(host, target.global_position)
				SkillVFX.element_hit(host, target.global_position, "quantum")
		"gravity":
			var pull: Vector3 = caster.global_position - target.global_position
			pull.y = 0.0
			if pull.length() > 0.2:
				target.global_position += pull.normalized() * mini(3.0, pull.length() * 0.4)
		"psyche":
			target.rotation.y += randf_range(-1.2, 1.2)
		"matter":
			# Hosts that track shield should listen via on_hit; soft local cue.
			SkillVFX.aoe_ring(host, caster.global_position, 1.4, element_color("matter"))
		_:
			pass
