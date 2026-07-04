function createPeriliminalStructure() {
  var rootFolder = DriveApp.createFolder("Periliminal");

  // Top-Level Files
  var topFiles = ["index.py", "README.md", "config.py"];
  topFiles.forEach(function(name){
    rootFolder.createFile(name, "# " + name + " placeholder\n");
  });

  // Core folder
  var core = rootFolder.createFolder("core");
  var coreFiles = ["stats.py","cooldowns.py","champion_ascension.py","factions.py"];
  coreFiles.forEach(f => core.createFile(f, "# " + f + " placeholder\n"));

  // Systems folder
  var systems = rootFolder.createFolder("systems");
  var systemFiles = ["crowd_control.py","crafting.py","economy.py","housing.py","memorials.py"];
  systemFiles.forEach(f => systems.createFile(f,"# " + f + " placeholder\n"));

  // Realms folder
  var realms = rootFolder.createFolder("realms");
  var realmFiles = ["periliminal.py","subliminal.py","liminal.py","superliminal.py"];
  realmFiles.forEach(f => realms.createFile(f,"# " + f + " placeholder\n"));

  Logger.log("Master folder and subfolders created!");
}