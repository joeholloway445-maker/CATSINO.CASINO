/**
 * Champion Ascension, Crowns, Leaderboards, and Guilds
 * Periliminal.Space – Replit Version
 * Author: Your Team
 */

// =======================
// CONFIGURATION
// =======================

const CHAMPION_LEVEL_MIN = 50;
const CHAMPION_LEVEL_MAX = 1600;
const PROVISIONAL_PVP_HOURS = 4;
const LEADERBOARD_UPDATE_INTERVAL = 15;

const CROWN_TYPES = [
  "PvP_Under50", "PvP_Over50",
  "Crafter", "Explorer", "WorldCreator",
  "WeaponMaster", "ArmorMaster", "HiddenSpecial"
];

// =======================
// DATA STRUCTURES
// =======================

let players = {};       // PlayerID -> Player Object
let guilds = {};        // GuildID -> Guild Object
let crowns = {};        // CrownType -> PlayerID
let leaderboards = {};  // CrownType -> [{playerID, points}]

// Initialize leaderboards and crowns
CROWN_TYPES.forEach(type => {
  leaderboards[type] = [];
  crowns[type] = null;
});

// Player structure
function createPlayer(playerID, username, guildID=null) {
  return {
    id: playerID,
    name: username,
    guildID: guildID,
    level: 1,
    championLevel: 0,
    factionRank: 0,
    controlStat: 0,
    crownsHeld: [],
    provisionalStatus: false,
    tripleCrown: false,
    godTierEligible: false,
    points: {},       // Points per leaderboard
    auraEffects: [],
    title: null       // Normal, Champion, Ascendant, Former Ascendant, God
  };
}

// Guild structure
function createGuild(guildID, guildName) {
  return {
    id: guildID,
    name: guildName,
    members: [],       // PlayerIDs
    guildCrowns: [],   // Crowns held collectively
    guildLeaderboardPoints: {} // Sum of member points per leaderboard type
  };
}

// =======================
// LEADERBOARD & CROWN FUNCTIONS
// =======================

function updateLeaderboard(playerID, crownType, points) {
  if (!leaderboards[crownType]) leaderboards[crownType] = [];
  let entry = leaderboards[crownType].find(e => e.playerID === playerID);
  if (entry) {
    entry.points = points;
  } else {
    leaderboards[crownType].push({ playerID: playerID, points: points });
  }
  leaderboards[crownType].sort((a, b) => b.points - a.points);

  const topPlayer = leaderboards[crownType][0];
  crowns[crownType] = topPlayer.playerID;

  // Update guild points
  const player = players[playerID];
  if (player.guildID) {
    const guild = guilds[player.guildID];
    guild.guildLeaderboardPoints[crownType] = guild.guildLeaderboardPoints[crownType] || 0;
    guild.guildLeaderboardPoints[crownType] += points;
    if (!guild.guildCrowns.includes(crownType)) guild.guildCrowns.push(crownType);
  }
}

function checkTripleCrown(playerID) {
  let count = 0;
  CROWN_TYPES.forEach(type => {
    if (crowns[type] === playerID) count++;
  });
  return count >= 3;
}

// =======================
// CHAMPION ASCENSION
// =======================

function canOptInChampion(player) {
  return player.level >= CHAMPION_LEVEL_MIN;
}

function startChampionTrial(player) {
  if (!canOptInChampion(player)) return false;
  player.provisionalStatus = true;
  player.trialStartTime = new Date();
  player.provisionalPvPHours = 0;
  return true;
}

function updateProvisionalPvP(player, hours) {
  if (!player.provisionalStatus) return;
  player.provisionalPvPHours += hours;
  if (player.provisionalPvPHours >= PROVISIONAL_PVP_HOURS) {
    finalizeChampion(player);
  }
}

function finalizeChampion(player) {
  player.provisionalStatus = false;
  player.championLevel = 1;
  player.title = "Champion";
  player.auraEffects.push("ChampionAura");
  player.tripleCrown = checkTripleCrown(player.id);
  if (player.tripleCrown) player.godTierEligible = true;
}

// =======================
// GOD TIER ASCENSION
// =======================

function attemptGodAscension(player) {
  if (!player.godTierEligible || player.championLevel < 160) return false;
  if (player.crownsHeld.length < 1) return false;
  player.title = "God";
  player.auraEffects.push("GodAura");
  return true;
}

function demoteChampion(player) {
  if (player.title === "Champion" || player.title === "Ascendant") {
    player.title = "Former " + player.title;
    player.auraEffects = [];
  }
}

// =======================
// PERIODIC UPDATE
// =======================

function updateAllLeaderboards() {
  CROWN_TYPES.forEach(type => {
    const top = leaderboards[type][0];
    if (top) crowns[type] = top.playerID;
  });
}

// =======================
// SAMPLE USAGE
// =======================

// Create guilds
guilds["g1"] = createGuild("g1", "Sunfire Clan");
guilds["g2"] = createGuild("g2", "Nightveil Syndicate");

// Create players
players["p1"] = createPlayer("p1", "Alice", "g1");
players["p2"] = createPlayer("p2", "Bob", "g2");

// Add members to guilds
guilds["g1"].members.push("p1");
guilds["g2"].members.push("p2");

// Update points and leaderboards
updateLeaderboard("p1", "PvP_Under50", 150);
updateLeaderboard("p2", "PvP_Under50", 200);

// Start champion trial
startChampionTrial(players["p2"]);
updateProvisionalPvP(players["p2"], 4); // completes provisional

attemptGodAscension(players["p2"]); // fails (not triple crown yet)