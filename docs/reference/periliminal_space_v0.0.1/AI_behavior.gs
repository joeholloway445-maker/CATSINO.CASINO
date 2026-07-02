function populatePeriliminalAI() {
  var realmsFolderName = "realms";
  var realms = ["Periliminal", "Liminal", "Subliminal", "Superliminal"];
  var aiFolders = ["doors", "companions", "mounts", "teams", "pets", "environmentNodes"];
  
  // Templates for each AI type
  var aiTemplates = {
    "doors": {
      "__init__.py": "# Door AI initialization\nclass Door:\n    def __init__(self, id, state='closed'):\n        self.id = id\n        self.state = state",
      "behaviors.py": "# Door behavior logic\n# Example: auto-close, access check, trigger events",
      "spawn.py": "# Door spawn positions and rules\n# Map locations, quest gating, realm transitions",
      "interactions.py": "# Player interactions with doors\n# Open, lock, key requirements, event triggers",
      "config.json": "{\n  \"autoCloseTime\": 5,\n  \"requiresKey\": true\n}"
    },
    "companions": {
      "__init__.py": "# Companion AI initialization\nclass Companion:\n    def __init__(self, name, type='NPC'):\n        self.name = name\n        self.type = type",
      "behaviors.py": "# Companion AI behavior logic\n# Follows, assists, fights, buffs, heals",
      "spawn.py": "# Companion spawn rules\n# Tied to quest, player level, or realm events",
      "interactions.py": "# Player interaction with companions\n# Talk, command, dismiss, upgrade",
      "config.json": "{\n  \"aggressionLevel\": 5,\n  \"loyalty\": 100\n}"
    },
    "mounts": {
      "__init__.py": "# Mount AI init\nclass Mount:\n    def __init__(self, species, speed=1.0):\n        self.species = species\n        self.speed = speed",
      "behaviors.py": "# Mount AI behavior\n# Movement patterns, auto-follow, stamina drain",
      "spawn.py": "# Mount spawn points\n# Realm-specific locations, rare spawns",
      "interactions.py": "# Mount interaction\n# Ride, dismount, upgrade, feed",
      "config.json": "{\n  \"maxSpeed\": 10,\n  \"staminaDrain\": 1.0\n}"
    },
    "teams": {
      "__init__.py": "# Team AI initialization\nclass Team:\n    def __init__(self, id, members=[]):\n        self.id = id\n        self.members = members",
      "behaviors.py": "# Team AI logic\n# Coordination, strategy, buffs, auto-assign roles",
      "spawn.py": "# Team spawn logic\n# Quest groups, raid setups, dynamic events",
      "interactions.py": "# Player interactions\n# Join, leave, command, formation control",
      "config.json": "{\n  \"maxMembers\": 5,\n  \"aggression\": 3\n}"
    },
    "pets": {
      "__init__.py": "# Pet AI init\nclass Pet:\n    def __init__(self, name, type='companion'):\n        self.name = name\n        self.type = type",
      "behaviors.py": "# Pet AI behavior\n# Assist, fetch, guard, evolve",
      "spawn.py": "# Pet spawn rules\n# Player ownership, quest reward, realm-specific",
      "interactions.py": "# Player interactions with pets\n# Feed, summon, dismiss, train",
      "config.json": "{\n  \"happiness\": 100,\n  \"energy\": 100\n}"
    },
    "environmentNodes": {
      "__init__.py": "# Environmental Node init\nclass EnvNode:\n    def __init__(self, type, effect=None):\n        self.type = type\n        self.effect = effect",
      "behaviors.py": "# Environmental AI behavior\n# Hazards, triggers, buffs, environmental effects",
      "spawn.py": "# Spawn rules\n# Realm-specific events, randomization, quest triggers",
      "interactions.py": "# Player/environment interactions\n# Trigger, avoid, disable, harvest",
      "config.json": "{\n  \"active\": true,\n  \"effectStrength\": 1.0\n}"
    }
  };

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

      var files = aiTemplates[aiName];
      for (var fileName in files) {
        var existing = folder.getFilesByName(fileName);
        if (!existing.hasNext()) {
          folder.createFile(fileName, files[fileName], MimeType.PLAIN_TEXT);
        }
      }
    });
  });
}