function generateAISpawnAndEventSystem() {
  var realmsFolderName = "realms";
  var realms = ["Periliminal", "Liminal", "Subliminal", "Superliminal"];
  var aiTypes = ["doors", "companions", "mounts", "teams", "pets", "environmentNodes"];
  
  var parentFolders = DriveApp.getFoldersByName(realmsFolderName);
  if (!parentFolders.hasNext()) {
    Logger.log("Error: 'realms' folder does not exist. Create it first.");
    return;
  }
  var realmsFolder = parentFolders.next();
  
  realms.forEach(function(realmName) {
    var realmFolders = realmsFolder.getFoldersByName(realmName);
    if (!realmFolders.hasNext()) {
      Logger.log("Error: Realm folder '" + realmName + "' not found. Skipping...");
      return;
    }
    var realmFolder = realmFolders.next();

    aiTypes.forEach(function(aiName) {
      var aiFolder = realmFolder.getFoldersByName(aiName);
      var folder;
      if (!aiFolder.hasNext()) {
        folder = realmFolder.createFolder(aiName);
      } else {
        folder = aiFolder.next();
      }

      var spawnFileName = "spawnAndEvents.py";
      var existing = folder.getFilesByName(spawnFileName);
      if (existing.hasNext()) {
        folder.getFilesByName(spawnFileName).next().setTrashed(true);
      }

      var content = `
# AI Spawn & Event System for ${aiName} in ${realmName}
# ---------------------------------------
# Each AI node can have conditional spawns and event ties
# Auto-generated scaffold; fill in specifics later

ai_spawn_config = [
  {
    "name": "${aiName}_common",
    "spawn_chance": 0.6,  # 60% chance to appear per cycle
    "locations": ["zone1", "zone2"],  # Replace with coordinates or areas
    "level_range": [1, 50],
    "faction_requirements": null,
    "time_restrictions": null,
    "events_triggered": ["event1", "event2"],
    "quest_bindings": ["quest_alpha", "quest_beta"],
    "special_conditions": ["tameable", "discoverable"]
  },
  {
    "name": "${aiName}_rare",
    "spawn_chance": 0.1,
    "locations": ["hidden_zone1", "hidden_zone2"],
    "level_range": [20, 100],
    "faction_requirements": ["guildA", "guildB"],
    "time_restrictions": ["night_cycle"],
    "events_triggered": ["event_rare"],
    "quest_bindings": ["quest_gamma"],
    "special_conditions": ["tameable", "breeding", "hidden"]
  }
]

# Example function: determine if AI should spawn
def should_spawn(ai_node, player_level, faction=None, current_time=None):
    # Check level range
    if not (ai_node["level_range"][0] <= player_level <= ai_node["level_range"][1]):
        return False
    # Check faction requirement
    if ai_node["faction_requirements"] and faction not in ai_node["faction_requirements"]:
        return False
    # Check time restrictions
    if ai_node["time_restrictions"] and current_time not in ai_node["time_restrictions"]:
        return False
    # Chance roll
    import random
    return random.random() <= ai_node["spawn_chance"]

# Hook spawn nodes into world events or quest triggers in your main game loop
# Example:
# for ai_node in ai_spawn_config:
#     if should_spawn(ai_node, player.level, player.faction, game.time):
#         spawn_ai(ai_node)
`;

      folder.createFile(spawnFileName, content, MimeType.PLAIN_TEXT);
    });
  });
}