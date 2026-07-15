class_name CityAmbience
extends Node
## The mega-city's sound bed. A district declares layers (city_traffic,
## city_crowd, neon_hum, machine_hum) with per-layer dB in CityData; this
## node plays each layer looped. Real audio drops in via AssetLibrary sound
## slots (assets/audio/<slot>.ogg); with none installed it synthesizes a
## looping bed per layer type so the city is never silent. Sits under the
## MusicManager track and the per-build SensoriumAmbience.
##
## add_child(CityAmbience.new()) then call setup(district_type).

const MIX_RATE := 22050
const LOOP_SECONDS := 4.0

func setup(district_type: String) -> void:
	var d := CityData.district(district_type)
	var layers: Dictionary = d.get("sounds", {})
	for slot in layers:
		var player := AudioStreamPlayer.new()
		player.bus = "Ambient" if AudioServer.get_bus_index("Ambient") != -1 else "Master"
		player.volume_db = float(layers[slot])
		var real := AssetLibrary.sound(slot, true)
		player.stream = real if real != null else _synth_bed(slot)
		add_child(player)
		player.play()

## Procedural looping bed per layer archetype — a 4s 16-bit mono WAV.
func _synth_bed(slot: String) -> AudioStreamWAV:
	var frames := int(MIX_RATE * LOOP_SECONDS)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(slot)
	var brown := 0.0
	var phase := 0.0
	for i in frames:
		var t := float(i) / MIX_RATE
		var s := 0.0
		match slot:
			"city_traffic":
				# low-passed brown noise rumble + slow swell
				brown = clampf(brown + rng.randf_range(-0.02, 0.02), -1.0, 1.0)
				s = brown * 0.5 * (0.7 + 0.3 * sin(t * 0.6))
			"city_crowd":
				# band-limited murmur: noise gated by a slow tremolo
				s = rng.randf_range(-1.0, 1.0) * 0.18 * (0.5 + 0.5 * sin(t * 3.1))
			"neon_hum":
				# 120 Hz buzz + 3rd harmonic + flicker
				phase += 120.0 / MIX_RATE
				var flick := 1.0 if rng.randf() > 0.002 else 0.3
				s = (sin(phase * TAU) * 0.4 + sin(phase * TAU * 3.0) * 0.15) * 0.3 * flick
			"machine_hum":
				# 60 Hz drone + occasional clank
				phase += 60.0 / MIX_RATE
				s = sin(phase * TAU) * 0.35 + sin(phase * TAU * 2.0) * 0.12
				if rng.randf() < 0.0006:
					s += rng.randf_range(-0.6, 0.6)
			_:
				s = rng.randf_range(-1.0, 1.0) * 0.1
		# Taper the very start/end so the loop seam doesn't click.
		s *= clampf(t / 0.05, 0.0, 1.0) * clampf((LOOP_SECONDS - t) / 0.05, 0.0, 1.0)
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	return wav
