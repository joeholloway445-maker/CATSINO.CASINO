function linkAINodesToGameplay() {
  var realmsFolderName = "realms";
  var realms = ["Periliminal", "Liminal", "Subliminal", "Superliminal"];
  var aiFolders = ["doors", "companions", "mounts", "teams", "pets", "environmentNodes"];

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

    aiFolders.forEach(function(aiName) {
      var aiFolder = realmFolder.getFoldersByName(aiName);
      var folder;
      if (!aiFolder.hasNext()) {
        folder = realmFolder.createFolder(aiName);
      } else {
        folder = aiFolder.next();
      }

      // Gameplay logic scaffolds
      var files = {
        "questBindings.py": "# Links " + aiName + " to quests\n# Example: trigger quest stage, rewards, AI behavior modification\n",
        "eventBindings.py": "# Links " + aiName + " to events\n# Example: world events, time-based triggers, AI aggression changes\n",
        "mechanicsBindings.py": "# Links " + aiName + " to gameplay mechanics\n# Include taming, building, breeding, befriending, discovering\n",
        "notes.txt": "Instructions: Customize AI spawn rules, behaviors, and interactions for the realm.\n- Taming: Define requirements, skill checks, consumables\n- Creating: Crafting or summoning\n- Breeding: Compatible entities, gestation, inheritance\n- Befriending: Faction or affinity logic\n- Finding: Rare spawns, exploration triggers\n- Environmental AI: Hazards, buffs, events"
      };

      for (var fileName in files) {
        var existing = folder.getFilesByName(fileName);
        if (!existing.hasNext()) {
          folder.createFile(fileName, files[fileName], MimeType.PLAIN_TEXT);
        }
      }
    });
  });
}