function fillGameplayFile() {
  var root = DriveApp.getFoldersByName("Periliminal").next();
  var coreFolder = root.getFoldersByName("core").next();

  // Create or overwrite gameplay.py
  var gameplayFile;
  var files = coreFolder.getFilesByName("gameplay.py");
  if (files.hasNext()) {
    gameplayFile = files.next();
  } else {
    gameplayFile = coreFolder.createFile("gameplay.py", "");
  }

  var gameplayContent = `
# GAMEPLAY SYSTEMS

# Skill Tree Structure
skill_trees = {
    "light_frames": {
        "skills_per_tree": 5,
        "level_caps": [1,2,3,4,5],
        "morph_unlock": 5
    },
    "heavy_frames": {
        "skill_trees": 3,
        "level_caps": [1,2,3,4,5],
        "morph_unlock": 5
    }
}

# Resource Pools
resource_pools = {
    "mana": "Magic/Ability resource",
    "stamina": "Physical resource",
    "energy": "Procless/Hybrid resource"
}

# Resource rules
# Even a stamina build can use magicka/heals and vice versa.
def get_resource_pool(build_type):
    pools = ["mana", "stamina", "energy"]
    if build_type == "stamina":
        return {"primary": "stamina", "secondary": ["mana", "energy"]}
    elif build_type == "mana":
        return {"primary": "mana", "secondary": ["stamina", "energy"]}
    else:
        return {"primary": "energy", "secondary": ["mana", "stamina"]}

# Cooldowns & Scaling
def calculate_cooldown(base_cd, skill_power):
    """
    base_cd: base cooldown seconds
    skill_power: affects cooldown reduction
    """
    # Higher skill power = higher cooldown
    return base_cd * (1 + skill_power / 100)

# Coin & Loot Drop Formula
loot_types = ["coins", "tokens", "fragments", "charge_nodes", "renown"]
def drop_loot(player_level, boss_level):
    # Simplified logic: coins mostly from bosses or casino
    # Tokens, fragments, charge_nodes, renown from NPCs
    return {"coins": 0.1, "tokens": 0.4, "fragments":0.3, "charge_nodes":0.1, "renown":0.1}

# PvP Rules
def pvp_eligibility(player_level):
    if player_level < 10:
        return False  # Cannot join PvP
    elif player_level < 50:
        return "low_level_campaign"
    else:
        return "high_level_campaign"

# Ultimates
ultimate_unlock_level = 15

# Dungeon Difficulty
dungeon_tiers = ["common", "uncommon", "rare", "epic", "legendary", "mythic"]

# Respawn Rules
def respawn(player, party_status):
    if party_status == "all_dead":
        return "spawn_point"
    elif party_status == "alive_teammates":
        return "resurrected_by_team"

# Guilds
guild_rules = {
    "leveling": "collective XP, everyone contributes",
    "alliances": "cross-faction allowed",
    "war_declaration": ">=3 members attack same base triggers war"
}

# XP Formula Example
def calculate_xp(base_xp, modifiers):
    xp = base_xp
    for mod in modifiers:
        xp += base_xp * mod
    return xp

# Territory scaling (example)
zone_scaling = {
    "zone1": 1.0,
    "zone2": 0.8,
    "zone3": 0.6,
    "zone4": 0.3
}

# Heavy Ultimates → Suppression State
heavy_ultimate_suppression = {"min_seconds":30, "max_seconds":60}

`;

  gameplayFile.setContent(gameplayContent);
  Logger.log("Gameplay file created/updated successfully!");
}