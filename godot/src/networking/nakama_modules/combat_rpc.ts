// Server-authoritative RPS-style combat (Light > Heavy > Tech > Light)
// Damage = attacker.pow * type_mult - defender.res * 0.5

interface CombatPayload {
    action?: "start" | "move";
    opponent_id?: string;
    move?: string; // "light" | "heavy" | "tech"
    game_state?: CombatState;
    bet?: number;
    frame_id?: string;
}

interface CombatState {
    round: number;
    player_hp: number;
    opponent_hp: number;
    player_pow: number;
    player_res: number;
    opponent_pow: number;
    opponent_res: number;
    opponent_id: string;
    bet: number;
    log: string[];
}

const TYPE_MULT: Record<string, Record<string, number>> = {
    "light": { "light": 1.0, "heavy": 1.5, "tech": 0.5 },
    "heavy": { "light": 0.5, "heavy": 1.0, "tech": 1.5 },
    "tech":  { "light": 1.5, "heavy": 0.5, "tech": 1.0 },
};

const AI_MOVES = ["light", "heavy", "tech"];

const FRAME_COMBAT: Record<string, { pow: number; res: number; hp: number }> = {
    "bastion":  { pow: 110, res: 120, hp: 300 },
    "tremor":   { pow: 118, res: 108, hp: 280 },
    "behemoth": { pow: 105, res: 125, hp: 320 },
    "surge":    { pow: 120, res: 80,  hp: 250 },
    "viper":    { pow: 108, res: 75,  hp: 220 },
    "bolt":     { pow: 104, res: 65,  hp: 200 },
    "phantom":  { pow: 88,  res: 88,  hp: 240 },
};

function aiPickMove(nk: nkruntime.Nakama): string {
    return AI_MOVES[Math.floor(nk.mathRandom() * 3)];
}

function calcDamage(atk_pow: number, def_res: number, mult: number): number {
    return Math.max(1, Math.floor(atk_pow * mult - def_res * 0.5));
}

const rpcCombatAction: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: CombatPayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    if (data.action === "start") {
        const { bet = 0, frame_id = "phantom", opponent_id = "npc_arena_guard" } = data;

        if (bet > 0) {
            try {
                nk.walletUpdate(ctx.userId, { coins: -bet }, { reason: `combat_entry` });
            } catch { throw new Error("Insufficient coins"); }
        }

        const pStats = FRAME_COMBAT[frame_id] ?? { pow: 90, res: 90, hp: 250 };
        const oppStats = FRAME_COMBAT["tremor"];

        const state: CombatState = {
            round: 1,
            player_hp: pStats.hp,
            opponent_hp: oppStats.hp,
            player_pow: pStats.pow,
            player_res: pStats.res,
            opponent_pow: oppStats.pow,
            opponent_res: oppStats.res,
            opponent_id,
            bet,
            log: [],
        };
        return JSON.stringify({ success: true, state, status: "active" });
    }

    // move action
    const { move, game_state } = data;
    if (!move || !game_state) throw new Error("move and game_state required");
    if (!TYPE_MULT[move]) throw new Error("Invalid move: " + move);

    const s = game_state;
    const ai_move = aiPickMove(nk);

    const playerDmg = calcDamage(s.player_pow, s.opponent_res, TYPE_MULT[move][ai_move]);
    const aiDmg     = calcDamage(s.opponent_pow, s.player_res, TYPE_MULT[ai_move][move]);

    s.opponent_hp -= playerDmg;
    s.player_hp   -= aiDmg;
    s.log.push(`Round ${s.round}: You used ${move}, opponent used ${ai_move}. You dealt ${playerDmg}, took ${aiDmg}.`);
    s.round++;

    if (s.player_hp <= 0 || s.opponent_hp <= 0) {
        const won = s.opponent_hp <= 0 && s.player_hp > 0;
        if (won && s.bet > 0) {
            nk.walletUpdate(ctx.userId, { coins: s.bet * 2 }, { reason: "combat_win" });
        }
        logger.info("rpcCombatAction: %s %s (bet=%d)", ctx.userId, won ? "won" : "lost", s.bet);
        return JSON.stringify({ success: true, state: s, status: won ? "player_win" : "opponent_win" });
    }

    return JSON.stringify({ success: true, state: s, status: "active", ai_move });
};

export function register_combat_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("combat_action", rpcCombatAction);
    logger.info("combat_rpc module initialized");
}
