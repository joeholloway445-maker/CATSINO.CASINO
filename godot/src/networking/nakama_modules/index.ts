// Single Nakama entrypoint — imports every module's register_* function and
// calls it from the ONE InitModule Nakama's JS runtime actually invokes.
// Each *_rpc.ts file used to declare its own top-level `InitModule`, which
// silently overwrote all the others when bundled — only the last-loaded file's
// RPCs were ever registered. This file is the fix: it is the single source of truth.

import { register_achievement_rpc } from "./achievement_rpc";
import { register_battlepass_rpc } from "./battlepass_rpc";
import { register_blackjack_rpc } from "./blackjack_rpc";
import { register_chat_rpc } from "./chat_rpc";
import { register_combat_rpc } from "./combat_rpc";
import { register_companion_evolve_rpc } from "./companion_evolve_rpc";
import { register_companion_rpc } from "./companion_rpc";
import { register_economy_rpc } from "./economy_rpc";
import { register_event_rpc } from "./event_rpc";
import { register_fortune_rpc } from "./fortune_rpc";
import { register_friend_rpc } from "./friend_rpc";
import { register_gacha_rpc } from "./gacha_rpc";
import { register_guild_rpc } from "./guild_rpc";
import { register_holdem_rpc } from "./holdem_rpc";
import { register_init_rpc } from "./init_rpc";
import { register_inventory_rpc } from "./inventory_rpc";
import { register_leaderboard_rpc } from "./leaderboard_rpc";
import { register_matchmaking } from "./matchmaking";
import { register_moba_match } from "./moba_match";
import { register_poker_rpc } from "./poker_rpc";
import { register_profile_rpc } from "./profile_rpc";
import { register_puzzle_rpc } from "./puzzle_rpc";
import { register_quest_rpc } from "./quest_rpc";
import { register_race_rpc } from "./race_rpc";
import { register_score_rpc } from "./score_rpc";
import { register_scratch_rpc } from "./scratch_rpc";
import { register_shop_rpc } from "./shop_rpc";
import { register_slots_rpc } from "./slots_rpc";
import { register_sports_rpc } from "./sports_rpc";
import { register_story_vote_rpc } from "./story_vote_rpc";
import { register_tournament_rpc } from "./tournament_rpc";
import { register_wallet_rpc } from "./wallet_rpc";

function InitModule(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    logger.info("=== CATSINO.CASINO Nakama Server Starting ===");

    register_init_rpc(ctx, logger, nk, initializer);          // leaderboards
    register_slots_rpc(ctx, logger, nk, initializer);
    register_blackjack_rpc(ctx, logger, nk, initializer);
    register_poker_rpc(ctx, logger, nk, initializer);
    register_holdem_rpc(ctx, logger, nk, initializer);
    register_fortune_rpc(ctx, logger, nk, initializer);
    register_scratch_rpc(ctx, logger, nk, initializer);
    register_sports_rpc(ctx, logger, nk, initializer);
    register_combat_rpc(ctx, logger, nk, initializer);
    register_race_rpc(ctx, logger, nk, initializer);
    register_puzzle_rpc(ctx, logger, nk, initializer);
    register_gacha_rpc(ctx, logger, nk, initializer);
    register_shop_rpc(ctx, logger, nk, initializer);
    register_quest_rpc(ctx, logger, nk, initializer);
    register_achievement_rpc(ctx, logger, nk, initializer);
    register_battlepass_rpc(ctx, logger, nk, initializer);
    register_event_rpc(ctx, logger, nk, initializer);
    register_leaderboard_rpc(ctx, logger, nk, initializer);
    register_score_rpc(ctx, logger, nk, initializer);
    register_profile_rpc(ctx, logger, nk, initializer);
    register_wallet_rpc(ctx, logger, nk, initializer);
    register_friend_rpc(ctx, logger, nk, initializer);
    register_guild_rpc(ctx, logger, nk, initializer);
    register_tournament_rpc(ctx, logger, nk, initializer);
    register_chat_rpc(ctx, logger, nk, initializer);
    register_companion_rpc(ctx, logger, nk, initializer);
    register_companion_evolve_rpc(ctx, logger, nk, initializer);
    register_economy_rpc(ctx, logger, nk, initializer);
    register_matchmaking(ctx, logger, nk, initializer);
    register_moba_match(ctx, logger, nk, initializer);
    register_inventory_rpc(ctx, logger, nk, initializer);
    register_story_vote_rpc(ctx, logger, nk, initializer);

    logger.info("All 31 RPC modules registered. Server ready.");
}

// Nakama's JS runtime looks up this exact global name at module load time.
!InitModule && InitModule;
