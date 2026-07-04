function createPeriliminalAI() {
  var realmsFolderName = "realms";
  var realms = ["Periliminal", "Liminal", "Subliminal", "Superliminal"];
  var aiFolders = ["doors", "companions", "mounts", "teams", "pets", "environmentNodes"];
  var aiFiles = ["__init__.py", "behaviors.py", "spawn.py", "interactions.py", "config.json"];

  var parentFolders = DriveApp.getFoldersByName(realmsFolderName);
  if (!parentFolders.hasNext()) {
    Logger.log("Error: 'realms' folder does not exist. Please create it first.");
    return;
  }
  var realmsFolder = parentFolders.next();

  realms.forEach(function(realmName) {
    var realmFolders = realmsFolder.getFoldersByName(realmName);
    if (!realmFolders.hasNext()) {
      Logger.log("Error: Realm folder '" + realmName + "' does not exist. Skipping...");
      return;
    }
    var realmFolder = realmFolders.next();

    aiFolders.forEach(function(aiFolderName) {
      var folder;
      var existing = realmFolder.getFoldersByName(aiFolderName);
      if (!existing.hasNext()) {
        folder = realmFolder.createFolder(aiFolderName);
      } else {
        folder = existing.next();
      }

      // Create starter files for AI logic
      aiFiles.forEach(function(fileName) {
        var existingFiles = folder.getFilesByName(fileName);
        if (!existingFiles.hasNext()) {
          folder.createFile(fileName, "", MimeType.PLAIN_TEXT);
        }
      });
    });
  });
}