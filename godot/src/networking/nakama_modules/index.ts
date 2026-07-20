// Single Nakama entrypoint. registerRpc/registerMatch MUST appear
// directly inside InitModule — Nakama AST-walks only that body.

import { rpcClaimAchievement, rpcGetAchievements } from "./achievement_rpc";
import { rpcAddBattlePassXP, rpcClaimBattlePassTier } from "./battlepass_rpc";
import { playBlackjack } from "./blackjack_rpc";
import { rpcGetActiveDistricts, rpcGetChatHistory, rpcSendSystemMessage } from "./chat_rpc";
import { rpcCombatAction } from "./combat_rpc";
import { evolveCompanion, feedCompanion } from "./companion_evolve_rpc";
import { rpcEquipRoster, rpcGetMyCompanions, rpcUnlockCompanion } from "./companion_rpc";
import { rpcDailyBonus, rpcEarnCoins, rpcGetWallet, rpcSpendCoins } from "./economy_rpc";
import { rpcGetActiveEvents, rpcGetFactionScores, rpcSubmitFactionScore } from "./event_rpc";
import { drawFortune } from "./fortune_rpc";
import { rpcAddFriend, rpcGetFriends, rpcRemoveFriend } from "./friend_rpc";
import { summonCompanion } from "./gacha_rpc";
import { rpcCreateGuild, rpcGetGuild, rpcInviteToGuild, rpcJoinGuild, rpcLeaveGuild } from "./guild_rpc";
import { rpcHideoutClaim, rpcHideoutContestWin, rpcHideoutGet, rpcHideoutSetBanner, rpcHideoutUpsertSite, register_hideout_rpc } from "./hideout_rpc";
import { playHoldem } from "./holdem_rpc";
import { getInventory, grantItem, useItem } from "./inventory_rpc";
import { layerMatchInit, layerMatchJoin, layerMatchJoinAttempt, layerMatchLeave, layerMatchLoop, layerMatchSignal, layerMatchTerminate, rpcFindOrCreateLayerMatch, register_layer_presence } from "./layer_presence";
import { rpcGetLeaderboard, rpcResetWeeklyLeaderboard, rpcSubmitScore } from "./leaderboard_rpc";
import { catsinoMatchInit, catsinoMatchJoin, catsinoMatchJoinAttempt, catsinoMatchLeave, catsinoMatchLoop, catsinoMatchSignal, catsinoMatchTerminate, rpcFindMatch } from "./matchmaking";
import { mobaMatchInit, mobaMatchJoin, mobaMatchJoinAttempt, mobaMatchLeave, mobaMatchLoop, mobaMatchSignal, mobaMatchTerminate, rpcFindMobaMatch, register_moba_match } from "./moba_match";
import { playPoker } from "./poker_rpc";
import { getProfile, updateProfile } from "./profile_rpc";
import { submitPuzzleScore } from "./puzzle_rpc";
import { rpcGetQuests, rpcQuestAction } from "./quest_rpc";
import { rpcStartRace } from "./race_rpc";
import { rpcBuyScratchCard } from "./scratch_rpc";
import { rpcGetShopInventory, rpcGetWorldShop, rpcShopPurchase } from "./shop_rpc";
import { rpcSpinSlots } from "./slots_rpc";
import { rpcPredictMatch } from "./sports_rpc";
import { rpcGetStoryTallies, rpcStoryVote } from "./story_vote_rpc";
import { rpcCreateTournament, rpcGetActiveTournaments, rpcJoinTournament } from "./tournament_rpc";
import { claimDailyBonus } from "./wallet_rpc";
import { rpcClaimWorldBossSpawn, rpcGetWorldBossState, rpcNoteZoneBossKill, rpcReportWorldBossKill } from "./world_boss_rpc";
import { register_init_rpc } from "./init_rpc";
import { register_score_rpc } from "./score_rpc";

function InitModule(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    logger.info("=== CATSINO.CASINO Nakama Server Starting ===");

    register_init_rpc(ctx, logger, nk, initializer);
    register_score_rpc(ctx, logger, nk, initializer);
    register_moba_match(ctx, logger, nk, initializer);
    register_layer_presence(ctx, logger, nk, initializer);
    register_hideout_rpc(ctx, logger, nk, initializer);

    // RPCs — string literal id + top-level named function (Nakama AST requirement)
    initializer.registerRpc("claim_achievement", rpcClaimAchievement);
    initializer.registerRpc("get_achievements", rpcGetAchievements);
    initializer.registerRpc("add_battlepass_xp", rpcAddBattlePassXP);
    initializer.registerRpc("claim_battlepass_tier", rpcClaimBattlePassTier);
    initializer.registerRpc("play_blackjack", playBlackjack);
    initializer.registerRpc("get_chat_history", rpcGetChatHistory);
    initializer.registerRpc("send_system_message", rpcSendSystemMessage);
    initializer.registerRpc("get_active_districts", rpcGetActiveDistricts);
    initializer.registerRpc("combat_action", rpcCombatAction);
    initializer.registerRpc("feed_companion", feedCompanion);
    initializer.registerRpc("evolve_companion", evolveCompanion);
    initializer.registerRpc("unlock_companion", rpcUnlockCompanion);
    initializer.registerRpc("equip_roster", rpcEquipRoster);
    initializer.registerRpc("get_my_companions", rpcGetMyCompanions);
    initializer.registerRpc("earn_coins", rpcEarnCoins);
    initializer.registerRpc("spend_coins", rpcSpendCoins);
    initializer.registerRpc("get_wallet", rpcGetWallet);
    initializer.registerRpc("daily_bonus", rpcDailyBonus);
    initializer.registerRpc("get_active_events", rpcGetActiveEvents);
    initializer.registerRpc("submit_faction_score", rpcSubmitFactionScore);
    initializer.registerRpc("get_faction_scores", rpcGetFactionScores);
    initializer.registerRpc("draw_fortune", drawFortune);
    initializer.registerRpc("add_friend", rpcAddFriend);
    initializer.registerRpc("remove_friend", rpcRemoveFriend);
    initializer.registerRpc("get_friends", rpcGetFriends);
    initializer.registerRpc("summon_companion", summonCompanion);
    initializer.registerRpc("create_guild", rpcCreateGuild);
    initializer.registerRpc("join_guild", rpcJoinGuild);
    initializer.registerRpc("leave_guild", rpcLeaveGuild);
    initializer.registerRpc("get_guild", rpcGetGuild);
    initializer.registerRpc("invite_to_guild", rpcInviteToGuild);
    initializer.registerRpc("hideout_upsert_site", rpcHideoutUpsertSite);
    initializer.registerRpc("hideout_get", rpcHideoutGet);
    initializer.registerRpc("hideout_claim", rpcHideoutClaim);
    initializer.registerRpc("hideout_contest_win", rpcHideoutContestWin);
    initializer.registerRpc("hideout_set_banner", rpcHideoutSetBanner);
    initializer.registerRpc("play_holdem", playHoldem);
    initializer.registerRpc("get_inventory", getInventory);
    initializer.registerRpc("use_item", useItem);
    initializer.registerRpc("grant_item", grantItem);
    initializer.registerRpc("find_or_create_layer_match", rpcFindOrCreateLayerMatch);
    initializer.registerRpc("submit_score", rpcSubmitScore);
    initializer.registerRpc("get_leaderboard", rpcGetLeaderboard);
    initializer.registerRpc("reset_weekly_leaderboard", rpcResetWeeklyLeaderboard);
    initializer.registerRpc("find_match", rpcFindMatch);
    initializer.registerRpc("find_moba_match", rpcFindMobaMatch);
    initializer.registerRpc("play_poker", playPoker);
    initializer.registerRpc("get_profile", getProfile);
    initializer.registerRpc("update_profile", updateProfile);
    initializer.registerRpc("submit_puzzle_score", submitPuzzleScore);
    initializer.registerRpc("quest_action", rpcQuestAction);
    initializer.registerRpc("get_quests", rpcGetQuests);
    initializer.registerRpc("start_race", rpcStartRace);
    initializer.registerRpc("buy_scratch_card", rpcBuyScratchCard);
    initializer.registerRpc("shop_purchase", rpcShopPurchase);
    initializer.registerRpc("get_shop_inventory", rpcGetShopInventory);
    initializer.registerRpc("get_world_shop", rpcGetWorldShop);
    initializer.registerRpc("spin_slots", rpcSpinSlots);
    initializer.registerRpc("predict_match", rpcPredictMatch);
    initializer.registerRpc("story_vote", rpcStoryVote);
    initializer.registerRpc("get_story_tallies", rpcGetStoryTallies);
    initializer.registerRpc("create_tournament", rpcCreateTournament);
    initializer.registerRpc("join_tournament", rpcJoinTournament);
    initializer.registerRpc("get_active_tournaments", rpcGetActiveTournaments);
    initializer.registerRpc("get_tournaments", rpcGetActiveTournaments);
    initializer.registerRpc("claim_daily_bonus", claimDailyBonus);
    initializer.registerRpc("get_world_boss_state", rpcGetWorldBossState);
    initializer.registerRpc("claim_world_boss_spawn", rpcClaimWorldBossSpawn);
    initializer.registerRpc("report_world_boss_kill", rpcReportWorldBossKill);
    initializer.registerRpc("note_zone_boss_kill", rpcNoteZoneBossKill);

    // Match handlers — Nakama 3.21 requires matchSignal on every registerMatch.
    initializer.registerMatch("layer_presence", { matchInit: layerMatchInit, matchJoinAttempt: layerMatchJoinAttempt, matchJoin: layerMatchJoin, matchLeave: layerMatchLeave, matchLoop: layerMatchLoop, matchTerminate: layerMatchTerminate, matchSignal: layerMatchSignal, });
    initializer.registerMatch("catsino_match", { matchInit: catsinoMatchInit, matchJoinAttempt: catsinoMatchJoinAttempt, matchJoin: catsinoMatchJoin, matchLeave: catsinoMatchLeave, matchLoop: catsinoMatchLoop, matchTerminate: catsinoMatchTerminate, matchSignal: catsinoMatchSignal, });
    initializer.registerMatch("moba_match", { matchInit: mobaMatchInit, matchJoinAttempt: mobaMatchJoinAttempt, matchJoin: mobaMatchJoin, matchLeave: mobaMatchLeave, matchLoop: mobaMatchLoop, matchTerminate: mobaMatchTerminate, matchSignal: mobaMatchSignal, });

    logger.info("All 70 RPCs + 3 matches registered. Server ready.");
}

// Nakama looks up this exact global name at module load time.
!InitModule && InitModule;
