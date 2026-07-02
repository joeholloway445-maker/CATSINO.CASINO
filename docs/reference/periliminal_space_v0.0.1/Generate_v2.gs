function generatePeriliminalStructure() {
  const rootName = "PERILIMINAL";
  
  const structure = {
    "CoreStats": ["core_stats.gs"],
    "Gameplay": ["gameplay.gs", "crowd_control.gs", "champion_ascension.gs", "faction_buffs.gs"],
    "Races": ["races.gs"],
    "Frames": ["frames.gs"],
    "MorphologicalRigs": ["rigs.gs"],
    "AI": ["npc_behaviors.gs", "companions.gs", "mounts.gs", "pets.gs", "doors.gs"],
    "Leaderboards": ["leaderboard_main.gs", "leaderboard_hidden.gs", "leaderboard_updates.gs"],
    "Guilds": ["guild_management.gs", "guild_ranks.gs"],
    "Factions": ["factions.gs"],
    "Realms": ["PERILIMINAL/periliminal_world.gs", "LIMINAL/liminal_world.gs", "SUBLIMINAL/subliminal_world.gs", "SUPERLIMINAL/superliminal_world.gs"],
    "Assets": ["RacePrompts/race_prompts.gs", "FramePrompts/frame_prompts.gs", "RigPrompts/rig_prompts.gs"],
    "Config": ["config.gs"],
    "Systems": ["systems_core.gs", "systems_combat.gs", "systems_automation.gs"],
    "Index": ["index_replit.gs", "index_unreal.gs"]
  };
  
  const rootFolder = getOrCreateFolder(rootName);
  
  for (let folderName in structure) {
    const files = structure[folderName];
    
    if (folderName === "Realms" || folderName === "Assets") {
      // Special handling for nested folders
      files.forEach(filePath => {
        const pathParts = filePath.split("/");
        const subFolderName = pathParts[0];
        const fileName = pathParts[1];
        const subFolder = getOrCreateFolder(subFolderName, rootFolder);
        createOrUpdateFile(fileName, subFolder);
      });
    } else {
      const folder = getOrCreateFolder(folderName, rootFolder);
      files.forEach(fileName => createOrUpdateFile(fileName, folder));
    }
  }
  
  Logger.log("PERILIMINAL structure created/updated successfully.");
}

/**
 * Get or create a folder by name under optional parent
 */
function getOrCreateFolder(name, parent) {
  let folder;
  if (parent) {
    const folders = parent.getFoldersByName(name);
    folder = folders.hasNext() ? folders.next() : parent.createFolder(name);
  } else {
    const folders = DriveApp.getFoldersByName(name);
    folder = folders.hasNext() ? folders.next() : DriveApp.createFolder(name);
  }
  return folder;
}

/**
 * Create or update a file with a header comment
 */
function createOrUpdateFile(name, folder) {
  const files = folder.getFilesByName(name);
  if (files.hasNext()) {
    Logger.log("File already exists, skipping: " + name);
  } else {
    const file = folder.createFile(name, "// TODO: Implement " + name, MimeType.GOOGLE_APPS_SCRIPT);
    Logger.log("Created file: " + name);
  }
}