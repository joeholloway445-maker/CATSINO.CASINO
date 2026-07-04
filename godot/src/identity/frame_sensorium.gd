class_name FrameSensorium
## Frames don't just carry stats — they ARE your senses. Each of the 20
## frames defines the light your client renders and the sound your world
## makes: key light color, exposure, fog, a musical mode, tempo, and timbre.
## Race chooses what surfaces are made of; frame chooses how they're lit and
## what they sound like. At Champion ascension a SECOND frame is chosen and
## the two sensoria blend — 20 base soundscapes become 400 duets.

const SENSORIA: Dictionary = {
	# Light frames
	"veil":    {light=Color(0.75, 0.7, 1.0),  energy=0.85, fog=0.15, mode="lydian",     tempo=64,  timbre="breath", desc="Violet hush; the world sounds like it's holding its breath."},
	"zephyr":  {light=Color(0.7, 0.9, 1.0),   energy=1.0,  fog=0.05, mode="ionian",     tempo=96,  timbre="flute",  desc="Clear windward light; airy whistling harmonics."},
	"viper":   {light=Color(0.6, 1.0, 0.6),   energy=1.05, fog=0.0,  mode="phrygian",   tempo=132, timbre="pluck",  desc="Venom-green edge light; short striking plucks."},
	"phantom": {light=Color(0.8, 0.8, 0.95),  energy=0.7,  fog=0.35, mode="aeolian",    tempo=58,  timbre="pad",    desc="Half-there light; sounds arrive a beat after their sources."},
	"crimson": {light=Color(1.0, 0.45, 0.4),  energy=1.15, fog=0.05, mode="dorian",     tempo=120, timbre="brass",  desc="War-red wash; distant horns under everything."},
	"glacial": {light=Color(0.75, 0.9, 1.0),  energy=0.95, fog=0.1,  mode="ionian",     tempo=72,  timbre="bell",   desc="Ice-white clarity; crystalline bell tones."},
	"bolt":    {light=Color(1.0, 1.0, 0.85),  energy=1.3,  fog=0.0,  mode="mixolydian", tempo=160, timbre="saw",    desc="Overexposed white-hot light; everything staccato."},
	"soul":    {light=Color(1.0, 0.85, 0.95), energy=0.9,  fog=0.2,  mode="lydian",     tempo=80,  timbre="choir",  desc="Warm rose glow; faint choir bound to your companions."},
	"cinder":  {light=Color(1.0, 0.6, 0.3),   energy=1.05, fog=0.15, mode="dorian",     tempo=104, timbre="crackle",desc="Ember light from below; soft fire-crackle percussion."},
	"flux":    {light=Color(0.85, 0.85, 0.85),energy=1.0,  fog=0.1,  mode="chromatic",  tempo=100, timbre="glass",  desc="Light that re-decides its color; harmonies that never resolve."},
	# Heavy frames
	"bastion": {light=Color(0.8, 0.8, 0.7),   energy=0.9,  fog=0.05, mode="ionian",     tempo=60,  timbre="drum",   desc="Fortress amber; deep slow drums like a heartbeat in stone."},
	"tremor":  {light=Color(0.9, 0.75, 0.5),  energy=1.0,  fog=0.1,  mode="phrygian",   tempo=88,  timbre="sub",    desc="Dust-brown light; sub-bass that arrives through the floor."},
	"behemoth":{light=Color(0.7, 0.7, 0.75),  energy=0.85, fog=0.1,  mode="aeolian",    tempo=48,  timbre="drone",  desc="Granite grey; one endless patient drone."},
	"bulwark": {light=Color(0.75, 0.8, 0.9),  energy=0.95, fog=0.05, mode="dorian",     tempo=76,  timbre="horn",   desc="Shield-blue steadiness; a horn line that never breaks rank."},
	"ignis":   {light=Color(1.0, 0.5, 0.2),   energy=1.2,  fog=0.2,  mode="phrygian",   tempo=112, timbre="roar",   desc="Furnace orange; low continuous burn under all audio."},
	"glaci":   {light=Color(0.7, 0.85, 1.0),  energy=0.9,  fog=0.15, mode="lydian",     tempo=66,  timbre="chime",  desc="Permafrost blue; chimes with long frozen decay."},
	"surge":   {light=Color(1.0, 0.95, 0.5),  energy=1.1,  fog=0.0,  mode="mixolydian", tempo=140, timbre="pulse",  desc="Capacitor yellow; three quiet beats, then one loud one."},
	"siege":   {light=Color(0.85, 0.7, 0.6),  energy=1.05, fog=0.1,  mode="dorian",     tempo=92,  timbre="anvil",  desc="Rampart bronze; rhythmic metal-on-metal strikes."},
	"blight":  {light=Color(0.7, 0.85, 0.5),  energy=0.8,  fog=0.4,  mode="locrian",    tempo=70,  timbre="hiss",   desc="Sickly green haze; sounds decay faster than they should."},
	"ossian":  {light=Color(0.9, 0.88, 0.8),  energy=0.85, fog=0.08, mode="aeolian",    tempo=54,  timbre="bone",   desc="Old ivory light; hollow woodblock knocks like ancient joints."},
}

static func of(frame_id: String) -> Dictionary:
	return SENSORIA.get(frame_id, SENSORIA["flux"])

## Dual-frame blend, used after Champion ascension. The base frame keeps
## 60% authority (it's still who you are); the ascension frame colors it.
static func blend(base_id: String, ascended_id: String) -> Dictionary:
	if ascended_id == "" or ascended_id == base_id:
		return of(base_id)
	var a := of(base_id)
	var b := of(ascended_id)
	return {
		light = a.light.lerp(b.light, 0.4),
		energy = lerpf(a.energy, b.energy, 0.4),
		fog = lerpf(a.fog, b.fog, 0.4),
		mode = a.mode, # melody keeps the base mode...
		tempo = int(lerpf(a.tempo, b.tempo, 0.4)),
		timbre = "%s+%s" % [a.timbre, b.timbre], # ...but plays both voices
		desc = "%s Under it now: %s" % [a.desc, b.desc.to_lower()],
	}
