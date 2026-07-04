// ============================================
// Periliminal Realms & AI Node Setup Script
// Fully populated, ready to run on script.google.com
// ============================================

// Realms definitions
const realms = [
  {
    name: "Superliminal",
    description: "Base layer of reality, core gameplay, standard quests, tutorials, main events."
  },
  {
    name: "Liminal",
    description: "Waking/transition space, sandbox experimentation, personal exploration."
  },
  {
    name: "Subliminal",
    description: "Creative realm, total player freedom to build, craft, and invent, unrestricted construction."
  },
  {
    name: "Periliminal",
    description: "Rarest realm, combat-focused, shadow battles, elite trials, ultimate challenge zones."
  }
];

// AI Nodes with populated behaviors and interactions
const aiNodes = [
  {
    type: "Companions",
    behaviors: ["PassiveFollower", "AggressiveCombatSupport", "ResourceCollector", "QuestAssistant"],
    interactions: ["Tame", "Befriend", "Train", "AssignQuest", "Summon", "TradeItems"],
    spawnLogic: "Spawn near player starting zones, quest completions, or rare event triggers",
    eventHooks: "Companion quests, champion trials, faction events"
  },
  {
    type: "Mounts",
    behaviors: ["FastTravel", "CombatSupport", "ExplorationAid"],
    interactions: ["Ride", "Feed", "Train", "Breed", "UpgradeStats"],
    spawnLogic: "Available at stables, faction zones, or reward drops",
    eventHooks: "PvP races, exploration bonuses, world events"
  },
  {
    type: "Pets",
    behaviors: ["PassiveFollower", "CombatSupport", "EnvironmentalTrigger"],
    interactions: ["Tame", "Play", "Feed", "Breed", "Train", "Decorate"],
    spawnLogic: "Spawn in forests, caves, and player housing zones",
    eventHooks: "Companion synergy events, crafting buffs"
  },
  {
    type: "Teams",
    behaviors: ["SupportAI", "CombatSquad", "FollowerAI", "RaidAssist"],
    interactions: ["JoinTeam", "LeaveTeam", "AssistPlayer", "CoordinateCombat", "FollowLeader"],
    spawnLogic: "Spawn near group missions, guild halls, or PvP hotspots",
    eventHooks: "Guild missions, world events, faction wars"
  },
  {
    type: "Environment",
    behaviors: ["StaticObstacle", "DynamicHazard", "EventDrivenAI", "WeatherControl", "WorldEffect"],
    interactions: ["TriggerEvent", "Avoid", "SolvePuzzle", "ManipulateEnvironment"],
    spawnLogic: "Spawn based on world layer, biome, or player activity",
    eventHooks: "World quests, puzzles, hazard events, PvE challenges"
  }
];

// Subfolders for each realm
const realmSubfolders = ["AI_Nodes", "Quests", "Events", "Companions", "Mounts", "Pets", "Teams", "Environment"];

// Main function
function createPeriliminalRealmsPopulated() {
  const rootFolderName = "Periliminal_Realms";
  let rootFolder = DriveApp.getFoldersByName(rootFolderName).hasNext()
    ? DriveApp.getFoldersByName(rootFolderName).next()
    : DriveApp.createFolder(rootFolderName);

  realms.forEach(realm => {
    // Realm folder
    let realmFolder = rootFolder.getFoldersByName(realm.name).hasNext()
      ? rootFolder.getFoldersByName(realm.name).next()
      : rootFolder.createFolder(realm.name);

    // Description file
    if (!realmFolder.getFilesByName("Description.txt").hasNext()) {
      realmFolder.createFile("Description.txt", realm.description);
    }

    // Subfolders
    realmSubfolders.forEach(sub => {
      let subFolder = realmFolder.getFoldersByName(sub).hasNext()
        ? realmFolder.getFoldersByName(sub).next()
        : realmFolder.createFolder(sub);

      // Populate AI nodes if applicable
      if (sub === "AI_Nodes" || ["Companions", "Mounts", "Pets", "Teams", "Environment"].includes(sub)) {
        aiNodes.forEach(ai => {
          if (ai.type === sub.slice(0, -1) || sub === "AI_Nodes") {
            let aiFileName = `${ai.type}.txt`;
            if (!subFolder.getFilesByName(aiFileName).hasNext()) {
              let content = `
AI Type: ${ai.type}
Behaviors: ${ai.behaviors.join(", ")}
Interactions: ${ai.interactions.join(", ")}
Spawn Logic: ${ai.spawnLogic}
Quest/Event Hooks: ${ai.eventHooks}
Assigned Realm: ${realm.name}
`;
              subFolder.createFile(aiFileName, content.trim());
            }
          }
        });
      }
    });
  });

  Logger.log("Periliminal realms fully populated with AI nodes and events!");
}