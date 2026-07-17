class_name GameVariants
# 200+ game variant definitions across all GameFactory types

const SLOTS_VARIANTS: Array[Dictionary] = [
	{id="slots_classic", name="Classic Purr", theme="classic", reels=3, paylines=1, min_bet=10, jackpot_mult=50},
	{id="slots_mega", name="Mega Paw", theme="mega", reels=5, paylines=25, min_bet=25, jackpot_mult=100},
	{id="slots_void", name="Void Reels", theme="void", reels=3, paylines=5, min_bet=10, jackpot_mult=75},
	{id="slots_crown", name="Crown Reels", theme="crown", reels=5, paylines=20, min_bet=50, jackpot_mult=200},
	{id="slots_neon", name="Neon Alley Slots", theme="neon", reels=3, paylines=9, min_bet=10, jackpot_mult=50},
	{id="slots_jungle", name="Cat Forest Spins", theme="jungle", reels=5, paylines=30, min_bet=25, jackpot_mult=150},
	{id="slots_cosmic", name="Cosmic Claw", theme="cosmic", reels=5, paylines=50, min_bet=100, jackpot_mult=500},
	{id="slots_retro", name="Retro Cats", theme="retro", reels=3, paylines=3, min_bet=5, jackpot_mult=25},
	{id="slots_aqua", name="Aqua Spins", theme="aqua", reels=4, paylines=15, min_bet=20, jackpot_mult=80},
	{id="slots_fire", name="Ember Reels", theme="fire", reels=3, paylines=5, min_bet=15, jackpot_mult=60},
	{id="slots_ice", name="Glacial Spins", theme="ice", reels=5, paylines=25, min_bet=30, jackpot_mult=120},
	{id="slots_storm", name="Storm Chasers", theme="storm", reels=3, paylines=9, min_bet=10, jackpot_mult=45},
	{id="slots_shadow", name="Shadow Reels", theme="shadow", reels=4, paylines=16, min_bet=20, jackpot_mult=90},
	{id="slots_quantum", name="Quantum Spins", theme="quantum", reels=5, paylines=243, min_bet=50, jackpot_mult=300},
	{id="slots_lunar", name="Lunar Fortune", theme="lunar", reels=3, paylines=5, min_bet=10, jackpot_mult=40},
	{id="slots_radiant", name="Radiant Reels", theme="radiant", reels=5, paylines=30, min_bet=25, jackpot_mult=100},
	{id="slots_obsidian", name="Obsidian Spins", theme="obsidian", reels=4, paylines=20, min_bet=40, jackpot_mult=200},
	{id="slots_bloom", name="Bloom Bonus", theme="bloom", reels=3, paylines=5, min_bet=10, jackpot_mult=35},
	{id="slots_photon", name="Photon Rush", theme="photon", reels=5, paylines=40, min_bet=30, jackpot_mult=180},
	{id="slots_prism", name="Prism Pay", theme="prism", reels=5, paylines=25, min_bet=20, jackpot_mult=110},
]

const RACING_VARIANTS: Array[Dictionary] = [
	{id="race_sprint", name="Neon Sprint", laps=1, track="neon_alley", ai_count=5, prize_mult=2},
	{id="race_circuit", name="Paws Vegas Circuit", laps=3, track="paw_vegas", ai_count=7, prize_mult=5},
	{id="race_endurance", name="Forest Endurance", laps=10, track="cat_forest", ai_count=3, prize_mult=15},
	{id="race_drag", name="Alley Drag", laps=1, track="drag_strip", ai_count=1, prize_mult=2},
	{id="race_coliseum", name="Coliseum Grand Prix", laps=5, track="coliseum_ring", ai_count=11, prize_mult=20},
	{id="race_midnight", name="Midnight Run", laps=2, track="neon_alley_night", ai_count=5, prize_mult=8},
	{id="race_off_road", name="Wild Offroad", laps=3, track="cat_forest_dirt", ai_count=5, prize_mult=12},
	{id="race_time_trial", name="Time Trial", laps=1, track="paw_vegas", ai_count=0, prize_mult=3},
	{id="race_reverse", name="Reverse Circuit", laps=3, track="neon_alley_rev", ai_count=5, prize_mult=10},
	{id="race_obstacle", name="Obstacle Course", laps=2, track="obstacle_track", ai_count=5, prize_mult=18},
	{id="race_faction_cup", name="Faction Cup", laps=3, track="faction_arena", ai_count=3, prize_mult=25},
	{id="race_arcade_blitz", name="Arcade Blitz", laps=1, track="arcade_galaxy", ai_count=7, prize_mult=6},
	{id="race_coastal", name="Coastal Speedway", laps=5, track="coastal", ai_count=9, prize_mult=22},
	{id="race_underground", name="Underground Circuit", laps=3, track="underground", ai_count=7, prize_mult=30},
	{id="race_championship", name="Championship Series", laps=5, track="championship", ai_count=15, prize_mult=50},
]

const CARD_VARIANTS: Array[Dictionary] = [
	{id="card_blackjack", name="Black Cat 21", type="blackjack", decks=1, min_bet=10, natural_mult=2.5},
	{id="card_blackjack_double", name="Double Deck 21", type="blackjack", decks=2, min_bet=25, natural_mult=2.5},
	{id="card_poker_jacks", name="Jacks or Better", type="poker", variant="jacks", min_bet=10, royal_mult=250},
	{id="card_poker_deuces", name="Deuces Wild", type="poker", variant="deuces", min_bet=10, royal_mult=200},
	{id="card_holdem", name="9 Lives Hold'Em", type="holdem", streets=4, min_bet=10, max_raise=3},
	{id="card_holdem_omaha", name="Omaha Hi-Lo", type="omaha", hole_cards=4, min_bet=25, max_raise=4},
	{id="card_baccarat", name="Cat Baccarat", type="baccarat", min_bet=10, player_mult=2.0},
	{id="card_war", name="Cat War", type="war", min_bet=5, war_mult=3.0},
	{id="card_three_card", name="Three Paw Poker", type="three_card", min_bet=10, pair_plus=true},
	{id="card_caribbean", name="Caribbean Claw", type="caribbean_stud", min_bet=10, progressive=true},
	{id="card_let_it_ride", name="Let It Ride", type="let_it_ride", min_bet=10, bonus=true},
	{id="card_pai_gow", name="Pai Gow Cats", type="pai_gow", min_bet=25, banker_option=true},
	{id="card_high_low", name="Higher or Lower", type="high_low", min_bet=5, streak_bonus=true},
	{id="card_snap", name="Cat Snap", type="snap", min_bet=5, speed_bonus=true},
	{id="card_pyramid", name="Pyramid Solitaire", type="solitaire", min_bet=10, clear_bonus=100},
]

const SPORTS_VARIANTS: Array[Dictionary] = [
	{id="sports_sprint_100m", name="100m Sprint", sport="athletics", cat_count=8, bet_type="winner"},
	{id="sports_boxing", name="Cat Boxing", sport="combat", cat_count=2, bet_type="winner"},
	{id="sports_swimming", name="Aqua Race", sport="swimming", cat_count=6, bet_type="winner"},
	{id="sports_gymnastics", name="Acro Cats", sport="gymnastics", cat_count=4, bet_type="score"},
	{id="sports_hurdles", name="Paw Hurdles", sport="hurdles", cat_count=8, bet_type="winner"},
	{id="sports_high_jump", name="High Jump Cats", sport="high_jump", cat_count=4, bet_type="score"},
	{id="sports_discus", name="Discus Claw", sport="discus", cat_count=4, bet_type="distance"},
	{id="sports_relay", name="Relay Race", sport="relay", cat_count=16, bet_type="team"},
	{id="sports_triathlon", name="Cat Triathlon", sport="triathlon", cat_count=8, bet_type="time"},
	{id="sports_decathlon", name="Cat Decathlon", sport="decathlon", cat_count=4, bet_type="score"},
]

const PUZZLE_VARIANTS: Array[Dictionary] = [
	{id="puzzle_match3", name="Match-3 Paws", type="match3", grid=8, moves=30, min_bet=10},
	{id="puzzle_sudoku", name="Cat Sudoku", type="sudoku", difficulty=2, time_limit=300, min_bet=10},
	{id="puzzle_sliding", name="Sliding Paws", type="sliding", size=4, min_bet=10},
	{id="puzzle_maze", name="Cat Maze", type="maze", size=15, time_limit=120, min_bet=15},
	{id="puzzle_memory", name="Memory Cats", type="memory", pairs=8, min_bet=10},
	{id="puzzle_word", name="Cat Words", type="word", letters=6, bonus_words=true, min_bet=10},
	{id="puzzle_jigsaw", name="Paw Jigsaw", type="jigsaw", pieces=25, time_limit=180, min_bet=15},
	{id="puzzle_pipe", name="Pipe Paws", type="pipes", grid=8, flow_target=80, min_bet=10},
	{id="puzzle_nonogram", name="Cat Nonogram", type="nonogram", size=10, min_bet=20},
	{id="puzzle_tetris", name="Tet-Cats", type="tetris", speed=1, min_bet=10},
]

const ARCADE_VARIANTS: Array[Dictionary] = [
	{id="arc_coin_pusher", name="Coin Pusher", type="coin_pusher", grid_x=10, grid_y=8, min_bet=5},
	{id="arc_coin_flip", name="Coin Flip", type="coin_flip", sides=2, streak_bonus=true, min_bet=5},
	{id="arc_higher_lower", name="Higher or Lower", type="higher_lower", rounds=10, min_bet=10},
	{id="arc_scratch_cat", name="Catnip Scratch", type="scratch", grid=3, match_target=3, min_bet=10},
	{id="arc_wheel", name="Lucky Cat Wheel", type="wheel", segments=8, jackpot_segment=1, min_bet=10},
	{id="arc_dart", name="Cat Darts", type="darts", throws=3, bullseye_mult=10, min_bet=10},
	{id="arc_ball_drop", name="Plinko Paws", type="plinko", pegs=9, multipliers=[1,2,3,5,10], min_bet=10},
	{id="arc_whack", name="Whack-A-Cat", type="whack", targets=9, time_limit=30, min_bet=10},
	{id="arc_claw", name="Claw Machine", type="claw", prizes=["companion", "gem", "coins"], min_bet=25},
	{id="arc_slots_mini", name="Mini Slots", type="slots_mini", reels=2, symbols=4, min_bet=5},
	{id="arc_bingo", name="Cat Bingo", type="bingo", cards=1, balls=75, min_bet=10},
	{id="arc_keno", name="Keno Paws", type="keno", picks=10, pool=80, min_bet=10},
	{id="arc_roulette", name="Cat Roulette", type="roulette", pockets=37, min_bet=5},
	{id="arc_craps", name="Cat Craps", type="craps", dice=2, min_bet=10},
	{id="arc_pachinko", name="Cat Pachinko", type="pachinko", pins=50, buckets=10, min_bet=15},
]

static func get_all_variants() -> Dictionary:
	return {
		"slots": SLOTS_VARIANTS,
		"racing": RACING_VARIANTS,
		"cards": CARD_VARIANTS,
		"sports": SPORTS_VARIANTS,
		"puzzle": PUZZLE_VARIANTS,
		"arcade": ARCADE_VARIANTS,
	}

static func get_variant(type: String, id: String) -> Dictionary:
	var all = get_all_variants()
	if type not in all:
		return {}
	var variants: Array = all[type]
	for v in variants:
		if v.get("id", "") == id:
			return v.duplicate()
	return {}

static func count_all() -> int:
	var total = 0
	for arr in get_all_variants().values():
		total += arr.size()
	return total
