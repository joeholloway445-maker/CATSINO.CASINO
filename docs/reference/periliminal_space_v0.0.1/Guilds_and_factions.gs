// guilds_and_factions.gs
// PERILIMINAL: Guilds & Factions System
// Handles creation, management, and interactions of player guilds and factions.

///////////////////////////////
// GUILD DEFINITIONS
///////////////////////////////

const Guilds = {}; // { guildID: {name, leader, members[], rankStructure{}, treasury, factionAffiliation, perks{}, achievements[] } }

/**
 * Create a new guild
 * @param {string} guildID - Unique identifier
 * @param {string} guildName - Name of the guild
 * @param {string} leaderID - Player ID of guild leader
 * @param {string} factionID - Optional faction affiliation
 */
function createGuild(guildID, guildName, leaderID, factionID = null) {
  if (Guilds[guildID]) {
    Logger.log(`Guild ${guildName} already exists.`);
    return;
  }
  
  Guilds[guildID] = {
    name: guildName,
    leader: leaderID,
    members: [leaderID],
    rankStructure: { "Leader": 100, "Officer": 75, "Member": 50, "Initiate": 25 },
    treasury: 0,
    factionAffiliation: factionID,
    perks: {
      auraEffect: true,
      minorPassiveBonus: true,
      playstyleModifiers: {}
    },
    achievements: []
  };
  Logger.log(`Guild ${guildName} created successfully.`);
}

/**
 * Add member to guild
 */
function addGuildMember(guildID, playerID, rank = "Initiate") {
  const guild = Guilds[guildID];
  if (!guild) {
    Logger.log(`Guild ${guildID} does not exist.`);
    return;
  }
  if (!guild.members.includes(playerID)) {
    guild.members.push(playerID);
    Logger.log(`Player ${playerID} added to guild ${guild.name} as ${rank}.`);
  }
}

/**
 * Promote member
 */
function promoteGuildMember(guildID, playerID, newRank) {
  const guild = Guilds[guildID];
  if (!guild || !guild.members.includes(playerID)) return;
  guild.rankStructure[playerID] = newRank;
  Logger.log(`Player ${playerID} promoted to ${newRank} in ${guild.name}.`);
}

/**
 * Guild treasury management
 */
function depositToGuild(guildID, amount) {
  const guild = Guilds[guildID];
  if (!guild) return;
  guild.treasury += amount;
  Logger.log(`Deposited ${amount} to guild ${guild.name}.`);
}

function withdrawFromGuild(guildID, amount) {
  const guild = Guilds[guildID];
  if (!guild || guild.treasury < amount) return;
  guild.treasury -= amount;
  Logger.log(`Withdrew ${amount} from guild ${guild.name}.`);
}

///////////////////////////////
// FACTION DEFINITIONS
///////////////////////////////

const Factions = {}; // { factionID: {name, leader, members[], crownsHeld, leaderboard, perks{}, auraEffects{}, achievements[]} }

/**
 * Create a faction
 */
function createFaction(factionID, factionName, leaderID) {
  if (Factions[factionID]) {
    Logger.log(`Faction ${factionName} already exists.`);
    return;
  }

  Factions[factionID] = {
    name: factionName,
    leader: leaderID,
    members: [leaderID],
    crownsHeld: [],
    leaderboard: [],
    perks: {
      territoryBonus: 0.1, // +10% territory efficiency
      influenceBoost: 0.05, // +5% NPC/AI influence
      stackingBuffs: {}
    },
    auraEffects: true,
    achievements: []
  };
  Logger.log(`Faction ${factionName} created successfully.`);
}

/**
 * Add member to faction
 */
function addFactionMember(factionID, playerID) {
  const faction = Factions[factionID];
  if (!faction) return;
  if (!faction.members.includes(playerID)) faction.members.push(playerID);
  Logger.log(`Player ${playerID} added to faction ${faction.name}.`);
}

/**
 * Crown & leaderboard management
 */
function assignCrown(factionID, crownID) {
  const faction = Factions[factionID];
  if (!faction) return;
  if (!faction.crownsHeld.includes(crownID)) faction.crownsHeld.push(crownID);
  Logger.log(`Crown ${crownID} assigned to faction ${faction.name}.`);
}

function updateLeaderboard(factionID, leaderboardArray) {
  const faction = Factions[factionID];
  if (!faction) return;
  faction.leaderboard = leaderboardArray; // [{playerID, score}, ...]
  Logger.log(`Faction ${faction.name} leaderboard updated.`);
}

/**
 * Apply faction perks globally
 */
function applyFactionPerks(playerID, factionID) {
  const faction = Factions[factionID];
  if (!faction || !faction.members.includes(playerID)) return;
  // Apply aura, bonuses, etc.
  Logger.log(`Applied perks of faction ${faction.name} to player ${playerID}.`);
}