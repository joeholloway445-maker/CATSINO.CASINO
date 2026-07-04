function createPeriliminalRealms() {
  var realmsFolderName = "realms";
  var realms = [
    {
      name: "Periliminal",
      description: "The rarest realm, for shadow battles, trials, and deep PvP/PvE interactions. High-risk, high-reward."
    },
    {
      name: "Liminal",
      description: "Intermediate reality, where players awaken from dreams, transition between layers, and experience flexible challenges."
    },
    {
      name: "Subliminal",
      description: "A creative realm where players can fully express themselves, build, craft, and manipulate the world freely."
    },
    {
      name: "Superliminal",
      description: "The base layer of reality, the core realm where standard gameplay and quest tutorials occur."
    }
  ];

  var parentFolders = DriveApp.getFoldersByName(realmsFolderName);
  if (!parentFolders.hasNext()) {
    Logger.log("Error: 'realms' folder does not exist. Please create it first.");
    return;
  }
  var realmsFolder = parentFolders.next();

  realms.forEach(function(realm) {
    var existing = realmsFolder.getFoldersByName(realm.name);
    var realmFolder;
    if (!existing.hasNext()) {
      realmFolder = realmsFolder.createFolder(realm.name);
    } else {
      realmFolder = existing.next();
    }

    // Create a description file
    var descFiles = realmFolder.getFilesByName("description.txt");
    if (!descFiles.hasNext()) {
      realmFolder.createFile("description.txt", realm.description, MimeType.PLAIN_TEXT);
    }
  });
}