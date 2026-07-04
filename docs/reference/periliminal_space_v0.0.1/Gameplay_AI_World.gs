function createGameplayAIWorld() {
  var root = DriveApp.getFoldersByName("Periliminal").next();
var rootFolder = DriveApp.createFolder("Periliminal");
var url = "31.97.98.79:5678/webhook/generate-asset";

var payload = { "model_link": "robbyant/lingbot-world-base-cam" };

var options = { "method": "post", "contentType": "application/json", "payload": JSON.stringify(payload) };

UrlFetchApp.fetch(url, options);
  // Gameplay
  var gameplay = root.createFolder("gameplay");
  var gameplayFiles = ["skills.py","leveling.py","ultimates.py","PvP.py","dungeon_tiers.py"];
  gameplayFiles.forEach(f => gameplay.createFile(f,"# " + f + " placeholder\n"));

  // AI
  var ai = root.createFolder("AI");
  var aiFiles = ["NPC_behavior.py","enemy_scaling.py","companion_system.py"];
  aiFiles.forEach(f => ai.createFile(f,"# " + f + " placeholder\n"));

  // World
  var world = root.createFolder("world");
  var worldFiles = ["zones.py","environment_effects.py","territory.py","map_clock.py"];
  worldFiles.forEach(f => world.createFile(f,"# " + f + " placeholder\n"));

  // Multiplayer
  var multi = root.createFolder("multiplayer");
  var multiFiles = ["guilds.py","alliances.py","war_declarations.py","raid_system.py"];
  multiFiles.forEach(f => multi.createFile(f,"# " + f + " placeholder\n"));

  // Data
  var data = root.createFolder("data");
  var dataFiles = ["coins_tokens_fragments.py","renown.py","item_charges.py"];
  dataFiles.forEach(f => data.createFile(f,"# " + f + " placeholder\n"));

  Logger.log("Gameplay, AI, World, Multiplayer, Data folders/files created!");
}