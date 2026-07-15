class_name NpcDialogueLibrary
## Lore-accurate dialogue for generated NPCs: one block per archetype × layer
## (5 × 6 = 30), written from docs/LORE_QUESTS_AND_NPCS.md. Every generated
## NPC of the same archetype in the same layer shares a block — individuality
## comes from name, face, disposition and WordOfMouth's per-NPC opening line,
## not from 1,000 hand-written scripts.
##
## Block ids follow the pipeline doc convention: "<archetype>_<layer>"
## (e.g. "barista_subliminal"). NPCManager registers these into
## WorldLoader.dialogues at boot so npc_dialogue_ui works unchanged.

const ARCHETYPES := ["barista", "archivist", "authority", "lover", "reflection"]
const LAYERS := ["subliminal", "liminal", "supraliminal", "hyperliminal", "extraliminal", "periliminal"]

## greeting line, then a deeper "lore" line, per archetype per layer.
const LINES := {
	"barista": {
		"subliminal": [
			"Oh — you again. Sorry. Long shift. It's always a long shift.",
			"You ever feel like the routine is... running you? Same cups, same faces. Something's wrong with it lately. Don't tell my manager I said that."
		],
		"liminal": [
			"Steam rises. Cup fills. Your order's ready. Steam rises. Cup fills.",
			"I hand you the cup. I always hand you the cup. If you take it, we start again. If you don't take it... nobody's ever not taken it."
		],
		"supraliminal": [
			"Your usual is already on the bar. You're four minutes later than your average.",
			"Consistency metrics are up this week. The Crown watches the metrics of every service worker in the city. It's fine. It's all fine. It's optimal, actually."
		],
		"hyperliminal": [
			"Coffee, chips, or both? I remember every order I've ever poured.",
			"I haven't slept since I started here. Don't need to. Between shifts there's the floor, and the floor always deals. Ask me anything — for the right tip."
		],
		"extraliminal": [
			"The blend changes with the banner. Depends who holds this ground today.",
			"I've served under three flags this month. Uniform one week, metaphors the next. You learn to read a territory by what they let you put in the cup."
		],
		"periliminal": [
			"I brewed what you're craving. You always crave it. Sit. Stay a while.",
			"One more cup won't hurt. That's true, isn't it? It's always been true before. Comfort, stimulation, meaning — I stock all three."
		],
	},
	"archivist": {
		"subliminal": [
			"People call it a hobby. Forty-one binders of things that don't add up is not a hobby.",
			"Missing time. Doors that weren't there. I write down every account, dates cross-referenced. They laugh at me, but nobody's ever found an error in my files."
		],
		"liminal": [
			"The library grew another wing last night. I catalogued it. I always catalogue it.",
			"I know where everything is. I can point you to any answer you want. I just can't walk to the exit. I've mapped it, you understand. I know exactly where it is."
		],
		"supraliminal": [
			"I can tell you exactly what I'm permitted to know.",
			"Notice the gaps in my records? Between file 300 and file 700 there is nothing. I did not lose those files. I was never given them. Draw your own conclusions — I'm not allowed to."
		],
		"hyperliminal": [
			"Every big win has a story. Some are even true. Buy me a chip and I'll tell one.",
			"I remember every legendary hand, every scandal the house buried. The house knows I know. That's why I'm still here — I'm cheaper to keep than to silence."
		],
		"extraliminal": [
			"Our records are the accurate ones. Whatever the other keepers told you — burn it.",
			"Every faction keeps its own history now. Same battle, three versions, three heroes. Control the record and you control what the war was FOR."
		],
		"periliminal": [
			"You left this memory here. No — you wouldn't remember. Shall I read it back to you?",
			"I keep everything you dropped: the words you swallowed, the day you pretended didn't happen. You filed them with me. I'm very good at my job."
		],
	},
	"authority": {
		"subliminal": [
			"Nothing to see out here. Go home. Forget about it. That's friendly advice.",
			"Some blocks I'd stay away from after dark. Not because of crime. Just — routine maintenance. The kind you don't want to watch. Go on home now."
		],
		"liminal": [
			"Rules of the hallway: don't run, don't look back, don't ask questions.",
			"I don't enforce the rules. The hallway does. I just sit at the desk so that someone can tell you the rules before it has to."
		],
		"supraliminal": [
			"The system works because everyone does their part. You look like someone who does their part.",
			"People call it control. I call it care at scale. Nobody goes hungry on my grid, and all it costs is everything being exactly where I put it."
		],
		"hyperliminal": [
			"House rules bend for the clever. They break for the greedy. Which are you?",
			"I keep the floor smooth. Card counters, loud drunks, sore winners — all handled quietly. Bend a rule with style and I might applaud. Cross the house and you were never here."
		],
		"extraliminal": [
			"This ground is claimed. State your allegiance or keep walking.",
			"Entities on the perimeter, banners on the towers. This is what order looks like out here — you hold it, or someone holds it over you."
		],
		"periliminal": [
			"Look at you. After everything, this is what you brought me?",
			"I only ever wanted you to do it RIGHT. Was that so much? Stand up straight. Try again. Disappoint me again."
		],
	},
	"lover": {
		"subliminal": [
			"Hey, you. You seem far away today. Or maybe that's me.",
			"Last night I dreamed we'd met before all this — different city, different you. You laughed more. Sorry. Weird thing to say out loud."
		],
		"liminal": [
			"You came back. You always come back. I can't leave, so... I'm glad.",
			"I'm less every time you see me. Don't argue, I can feel it. Just — stay until the light shifts, and don't remember me like this."
		],
		"supraliminal": [
			"I made reservations at the place you love. I always know the place you love.",
			"Have you noticed I've never once disagreed with you? I noticed. I tried to want something you don't want. I couldn't. Doesn't that scare you? It should scare me."
		],
		"hyperliminal": [
			"Bet you anything tonight ends well. Anything. That's the fun of it, isn't it?",
			"You can't tell if I'm playing you or falling for you. Neither can I, darling. That's the only game in this whole building with honest odds."
		],
		"extraliminal": [
			"It's not about the faction. Well. It's not ONLY about the faction. Walk with me?",
			"They told me to recruit you. I told them it was going well. It IS going well — just not the way I report it. We're both in trouble, aren't we."
		],
		"periliminal": [
			"I know you. That's the problem, isn't it? I actually know you.",
			"Here's what you're afraid of: not that I'll leave. That I'll stay, and see all of it, and stay anyway — and you won't believe me. Say it. Say that's not it."
		],
	},
	"reflection": {
		"subliminal": [
			"Don't stare. You'll notice the differences, and then you won't sleep.",
			"Check your own footage sometime. The pauses. The little errands you don't remember running. One of us is losing time, and I know which one I'd bet on."
		],
		"liminal": [
			"In here it's ME who's real, and YOU knocking on the glass. Want to trade?",
			"I made the other choice. Every mirror is the version where you turned left. Press your hand to the glass and I'll show you what it cost."
		],
		"supraliminal": [
			"I took the optimization. No more doubt. You could too — oh. But you're me. Awkward.",
			"They sanded off the hesitation, the second-guessing, the three a.m. spirals. I have your talent and none of your noise. Your life fits me better than it ever fit you."
		],
		"hyperliminal": [
			"I hit the jackpot the night you didn't. One choice. That's all we are — one choice apart.",
			"Penthouse comps, a name the pit bosses whisper. Or maybe I'm the one who lost it all and this suit is borrowed. You can't tell. That's the lesson, friend."
		],
		"extraliminal": [
			"You wear no banner? I wear ours. Same face, different flag. Strange, isn't it.",
			"I believed in something and it gave me an army. You stayed free and it gave you nothing to hold. Which of us do you pity? Careful — I'm asking myself the same thing."
		],
		"periliminal": [
			"Here I am. The worst of it. Fight me, run from me, or take my hand.",
			"I'm every night you didn't cope and every word you regret. You built me out of what you buried. Integration hurts less than another decade of pretending I'm not yours."
		],
	},
}

## Build one WorldLoader-format dialogue block for an archetype × layer pair.
static func build_dialogue(archetype: String, layer: String) -> Dictionary:
	var pair: Array = LINES.get(archetype, {}).get(layer, ["...", "..."])
	return {
		"dialogue_id": "%s_%s" % [archetype, layer],
		"start_node": "greeting",
		"nodes": [
			{
				"id": "greeting",
				"text": str(pair[0]),
				"options": [
					{"label": "Tell me more.", "next_node": "depth"},
					{"label": "Just passing through.", "next_node": "END", "action": "nothing"},
				],
			},
			{
				"id": "depth",
				"text": str(pair[1]),
				"options": [
					{"label": "...I'll remember that.", "next_node": "END", "action": "nothing"},
				],
			},
		],
	}

## The short opening line an NPC speaks in the world (also used as the
## legacy `greeting` field on generated NPC dicts).
static func greeting(archetype: String, layer: String) -> String:
	var pair: Array = LINES.get(archetype, {}).get(layer, ["..."])
	return str(pair[0])

## Register every block into WorldLoader.dialogues (existing hand-written
## dialogue always wins on id collision).
static func register_all() -> void:
	for arch in ARCHETYPES:
		for layer in LAYERS:
			var id := "%s_%s" % [arch, layer]
			if not WorldLoader.dialogues.has(id):
				WorldLoader.dialogues[id] = build_dialogue(arch, layer)
