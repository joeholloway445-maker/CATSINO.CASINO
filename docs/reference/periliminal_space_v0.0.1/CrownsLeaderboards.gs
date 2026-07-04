// =====================================================
// Periliminal.Space – Mixed Leaderboards & Crown System
// =====================================================

// --- 50 Visible Leaderboards (Mixed PvP + PvE) ---
const visibleLeaderboards = {
  PvP_Kills_Under50: [],
  PvE_ExplorationSecrets: [],
  PvP_Kills_Over50: [],
  PvE_CraftingMastery: [],
  PvP_Duels_Wins: [],
  PvE_WeaponMastery: [],
  PvE_ArmorMastery: [],
  PvP_ArenaPoints: [],
  PvE_ResourceEfficiency: [],
  PvE_Alchemy: [],
  PvP_BountyHunter: [],
  PvE_FactionInfluence: [],
  PvP_RaidKills: [],
  PvE_TerritoryDefense: [],
  PvP_LeaderboardSurvival: [],
  PvE_QuestCompletion: [],
  PvP_MissionWins: [],
  PvE_PetTraining: [],
  PvP_DamageDealt: [],
  PvE_BuildingMastery: [],
  PvP_TeamCaptures: [],
  PvE_TrapEffectiveness: [],
  PvP_LeaderboardPvPTime: [],
  PvE_ExplorationSpeed: [],
  PvP_TopKillStreak: [],
  PvE_CraftingSpeed: [],
  PvP_PvPObjectiveControl: [],
  PvE_HarvestingEfficiency: [],
  PvP_CaptureTheFlag: [],
  PvE_MiningMastery: [],
  PvP_EliteDuelWins: [],
  PvE_WorldCreation: [],
  PvP_ArenaSurvival: [],
  PvE_SocialInfluence: [],
  PvP_DominationPoints: [],
  PvE_MissionsSuccessRate: [],
  PvP_SpecialEventKills: [],
  PvE_Enchanting: [],
  PvP_BossDefeats: [],
  PvE_TokenGathering: [],
  PvP_PvPContribution: [],
  PvE_Leadership: [],
  PvP_HighScorePvP: [],
  PvE_StealthMastery: [],
  PvP_PvPRankPoints: [],
  PvE_ArtifactCollection: [],
  PvP_TeamSupport: [],
  PvE_ResourceGathering: [],
  PvP_SoloPvP: [],
  PvE_CraftingQuality: [],
  PvP_BountyCompletion: []
};

// --- 10 Hidden Leaderboards (Mixed PvP + PvE) ---
const hiddenLeaderboards = {
  Hidden_PvP_Underworld: [],
  Hidden_PvE_AncientArtifacts: [],
  Hidden_PvP_ChampionKills: [],
  Hidden_PvE_SecretMissions: [],
  Hidden_PvP_ArenaElite: [],
  Hidden_PvE_MasterCrafter: [],
  Hidden_PvP_TopStrategist: [],
  Hidden_PvE_ExplorationMaster: [],
  Hidden_PvP_LegendaryStreak: [],
  Hidden_PvE_RareResourceCollector: []
};

// --- Crown & Triple Crown System (Same as Before) ---
class Crown {
  constructor(playerID, leaderboardID) {
    this.playerID = playerID;
    this.leaderboardID = leaderboardID;
    this.acquiredAt = new Date();
    this.tripleCrown = false;
  }
}
let crownHolders = [];

function checkTripleCrown(playerID) {
  const crowns = crownHolders.filter(c => c.playerID === playerID);
  return crowns.length >= 3;
}

function assignCrown(playerID, leaderboardID) {
  const newCrown = new Crown(playerID, leaderboardID);
  crownHolders.push(newCrown);
  const isTriple = checkTripleCrown(playerID);
  if (isTriple) {
    crownHolders.filter(c => c.playerID === playerID).forEach(c => c.tripleCrown = true);
  }
  return newCrown;
}

function removeCrown(playerID, leaderboardID) {
  crownHolders = crownHolders.filter(c => !(c.playerID === playerID && c.leaderboardID === leaderboardID));
  const crowns = crownHolders.filter(c => c.playerID === playerID);
  if (crowns.length < 3) crowns.forEach(c => c.tripleCrown = false);
}

function getPlayerCrowns(playerID) {
  return crownHolders.filter(c => c.playerID === playerID);
}

function addScoreToLeaderboard(leaderboardID, playerID, score) {
  if (visibleLeaderboards[leaderboardID]) {
    visibleLeaderboards[leaderboardID].push({ playerID, score });
    visibleLeaderboards[leaderboardID].sort((a, b) => b.score - a.score);
  } else if (hiddenLeaderboards[leaderboardID]) {
    hiddenLeaderboards[leaderboardID].push({ playerID, score });
    hiddenLeaderboards[leaderboardID].sort((a, b) => b.score - a.score);
  } else console.error(`Leaderboard ${leaderboardID} not found.`);
}