const crownsdata = [
  { id: 1, name: "Crown of Valor", category: "Visible", leaderboard: "Top PvP Kills", type: "visible",
    rewards: { aura: true, passiveBonus: "5% damage in PvP", playstyleBonus: "Faster attack recovery" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 2, name: "Crown of Wisdom", category: "Visible", leaderboard: "Top Quest Completions", type: "visible",
    rewards: { aura: true, passiveBonus: "5% XP gain", playstyleBonus: "Reduced cooldowns on abilities" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 3, name: "Crown of Shadows", category: "Visible", leaderboard: "Top Stealth Kills", type: "visible",
    rewards: { aura: true, passiveBonus: "5% critical chance in stealth", playstyleBonus: "Reduced detection range" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 4, name: "Crown of the Gladiator", category: "Visible", leaderboard: "Top Arena Victories", type: "visible",
    rewards: { aura: true, passiveBonus: "5% damage in arenas", playstyleBonus: "Faster attack recovery" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 5, name: "Crown of the Enchanter", category: "Visible", leaderboard: "Top Enchantments Applied", type: "visible",
    rewards: { aura: true, passiveBonus: "5% enchantment potency", playstyleBonus: "Reduced resource cost for enchantments" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 6, name: "Crown of the Shadow Slayer", category: "Visible", leaderboard: "Top Shadow Entity Kills", type: "visible",
    rewards: { aura: true, passiveBonus: "5% damage vs shadows", playstyleBonus: "Extended critical chance against shadow types" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 7, name: "Crown of the Pathfinder", category: "Visible", leaderboard: "Top Terrain Explored", type: "visible",
    rewards: { aura: true, passiveBonus: "5% movement speed", playstyleBonus: "Reduced stamina drain when exploring" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 8, name: "Crown of the Vanguard", category: "Visible", leaderboard: "Top Frontline Engagements", type: "visible",
    rewards: { aura: true, passiveBonus: "5% damage resistance", playstyleBonus: "Increased threat generation to draw enemies" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 9, name: "Crown of the Collector", category: "Visible", leaderboard: "Top Rare Items Gathered", type: "visible",
    rewards: { aura: true, passiveBonus: "5% item drop chance", playstyleBonus: "Increased luck on rare finds" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 10, name: "Crown of the Duelist", category: "Visible", leaderboard: "Top 1v1 Victories", type: "visible",
    rewards: { aura: true, passiveBonus: "5% attack speed in duels", playstyleBonus: "Reduced cooldowns on duel skills" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 11, name: "Crown of the Innovator", category: "Visible", leaderboard: "Top Game Mechanics Explored", type: "visible",
    rewards: { aura: true, passiveBonus: "5% efficiency with custom mechanics", playstyleBonus: "Access to advanced crafting options" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 12, name: "Crown of the Artisan of War", category: "Visible", leaderboard: "Top Weapon Crafts", type: "visible",
    rewards: { aura: true, passiveBonus: "5% weapon effectiveness", playstyleBonus: "Reduced crafting material cost" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 13, name: "Crown of the Arbiter", category: "Visible", leaderboard: "Top Judicial Decisions in Factions", type: "visible",
    rewards: { aura: true, passiveBonus: "5% faction influence", playstyleBonus: "Ability to resolve disputes faster" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 14, name: "Crown of the Scout", category: "Visible", leaderboard: "Top Recon Missions", type: "visible",
    rewards: { aura: true, passiveBonus: "5% detection range", playstyleBonus: "Faster stealth movement" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 15, name: "Crown of the Builder", category: "Visible", leaderboard: "Top Structures Built", type: "visible",
    rewards: { aura: true, passiveBonus: "5% building speed", playstyleBonus: "Reduced resource cost on structures" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 16, name: "Crown of the Scribe", category: "Visible", leaderboard: "Top Lore Contributions", type: "visible",
    rewards: { aura: true, passiveBonus: "5% knowledge gain", playstyleBonus: "Access to hidden lore recipes" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 17, name: "Crown of the Ranger", category: "Visible", leaderboard: "Top Wildlife Tames", type: "visible",
    rewards: { aura: true, passiveBonus: "5% taming success", playstyleBonus: "Reduced cooldown on pet commands" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 18, name: "Crown of the Strategist", category: "Visible", leaderboard: "Top Battle Plans Executed", type: "visible",
    rewards: { aura: true, passiveBonus: "5% efficiency in large-scale fights", playstyleBonus: "Reduced preparation time for events" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 19, name: "Crown of the Alchemist", category: "Visible", leaderboard: "Top Potions Brewed", type: "visible",
    rewards: { aura: true, passiveBonus: "5% potion potency", playstyleBonus: "Reduced ingredient use" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 20, name: "Crown of the Historian", category: "Visible", leaderboard: "Top Artifact Discoveries", type: "visible",
    rewards: { aura: true, passiveBonus: "5% artifact drop chance", playstyleBonus: "Increased analysis speed" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 21, name: "Crown of the Gladiator", category: "Visible", leaderboard: "Top Arena Victories", type: "visible",
    rewards: { aura: true, passiveBonus: "5% damage in arenas", playstyleBonus: "Faster attack recovery" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 22, name: "Crown of the Enchanter", category: "Visible", leaderboard: "Top Enchantments Applied", type: "visible",
    rewards: { aura: true, passiveBonus: "5% enchantment potency", playstyleBonus: "Reduced resource cost for enchantments" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 23, name: "Crown of the Shadow Slayer", category: "Visible", leaderboard: "Top Shadow Entity Kills", type: "visible",
    rewards: { aura: true, passiveBonus: "5% damage vs shadows", playstyleBonus: "Extended critical chance against shadow types" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 24, name: "Crown of the Pathfinder", category: "Visible", leaderboard: "Top Terrain Explored", type: "visible",
    rewards: { aura: true, passiveBonus: "5% movement speed", playstyleBonus: "Reduced stamina drain when exploring" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 25, name: "Crown of the Vanguard", category: "Visible", leaderboard: "Top Frontline Engagements", type: "visible",
    rewards: { aura: true, passiveBonus: "5% damage resistance", playstyleBonus: "Increased threat generation to draw enemies" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 26, name: "Crown of the Collector", category: "Visible", leaderboard: "Top Rare Items Gathered", type: "visible",
    rewards: { aura: true, passiveBonus: "5% item drop chance", playstyleBonus: "Increased luck on rare finds" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 27, name: "Crown of the Duelist", category: "Visible", leaderboard: "Top 1v1 Victories", type: "visible",
    rewards: { aura: true, passiveBonus: "5% attack speed in duels", playstyleBonus: "Reduced cooldowns on duel skills" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 28, name: "Crown of the Innovator", category: "Visible", leaderboard: "Top Game Mechanics Explored", type: "visible",
    rewards: { aura: true, passiveBonus: "5% efficiency with custom mechanics", playstyleBonus: "Access to advanced crafting options" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 29, name: "Crown of the Artisan of War", category: "Visible", leaderboard: "Top Weapon Crafts", type: "visible",
    rewards: { aura: true, passiveBonus: "5% weapon effectiveness", playstyleBonus: "Reduced crafting material cost" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 30, name: "Crown of the Arbiter", category: "Visible", leaderboard: "Top Judicial Decisions in Factions", type: "visible",
    rewards: { aura: true, passiveBonus: "5% faction influence", playstyleBonus: "Ability to resolve disputes faster" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  }
];const crownsContinuation = [
  { id: 31, name: "Crown of the Scout", category: "Visible", leaderboard: "Top Recon Missions", type: "visible",
    rewards: { aura: true, passiveBonus: "5% detection range", playstyleBonus: "Faster stealth movement" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 32, name: "Crown of the Builder", category: "Visible", leaderboard: "Top Structures Built", type: "visible",
    rewards: { aura: true, passiveBonus: "5% building speed", playstyleBonus: "Reduced resource cost on structures" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 33, name: "Crown of the Scribe", category: "Visible", leaderboard: "Top Lore Contributions", type: "visible",
    rewards: { aura: true, passiveBonus: "5% knowledge gain", playstyleBonus: "Access to hidden lore recipes" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 34, name: "Crown of the Ranger", category: "Visible", leaderboard: "Top Wildlife Tames", type: "visible",
    rewards: { aura: true, passiveBonus: "5% taming success", playstyleBonus: "Reduced cooldown on pet commands" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 35, name: "Crown of the Strategist", category: "Visible", leaderboard: "Top Battle Plans Executed", type: "visible",
    rewards: { aura: true, passiveBonus: "5% efficiency in large-scale fights", playstyleBonus: "Reduced preparation time for events" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 36, name: "Crown of the Alchemist", category: "Visible", leaderboard: "Top Potions Brewed", type: "visible",
    rewards: { aura: true, passiveBonus: "5% potion potency", playstyleBonus: "Reduced ingredient use" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 37, name: "Crown of the Historian", category: "Visible", leaderboard: "Top Artifact Discoveries", type: "visible",
    rewards: { aura: true, passiveBonus: "5% artifact drop chance", playstyleBonus: "Increased analysis speed" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 38, name: "Crown of the Duelist", category: "Visible", leaderboard: "Top 1v1 Victories", type: "visible",
    rewards: { aura: true, passiveBonus: "5% attack speed in duels", playstyleBonus: "Reduced cooldowns on duel skills" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 39, name: "Crown of the Innovator", category: "Visible", leaderboard: "Top Game Mechanics Explored", type: "visible",
    rewards: { aura: true, passiveBonus: "5% efficiency with custom mechanics", playstyleBonus: "Access to advanced crafting options" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 40, name: "Crown of the Artisan of War", category: "Visible", leaderboard: "Top Weapon Crafts", type: "visible",
    rewards: { aura: true, passiveBonus: "5% weapon effectiveness", playstyleBonus: "Reduced crafting material cost" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 41, name: "Crown of the Arbiter", category: "Visible", leaderboard: "Top Judicial Decisions in Factions", type: "visible",
    rewards: { aura: true, passiveBonus: "5% faction influence", playstyleBonus: "Ability to resolve disputes faster" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 42, name: "Crown of the Shadow Hunter", category: "Visible", leaderboard: "Top Dark Realm Kills", type: "visible",
    rewards: { aura: true, passiveBonus: "5% shadow damage", playstyleBonus: "Increased movement in shadow zones" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 43, name: "Crown of the Protector", category: "Visible", leaderboard: "Top Players Defended", type: "visible",
    rewards: { aura: true, passiveBonus: "5% ally protection effectiveness", playstyleBonus: "Reduced cooldowns on defensive skills" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 44, name: "Crown of the Explorer", category: "Visible", leaderboard: "Top Hidden Locations Discovered", type: "visible",
    rewards: { aura: true, passiveBonus: "5% movement speed", playstyleBonus: "Reveal hidden paths faster" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 45, name: "Crown of the Inventor", category: "Visible", leaderboard: "Top Devices Created", type: "visible",
    rewards: { aura: true, passiveBonus: "5% efficiency with gadgets", playstyleBonus: "Reduced cooldowns on mechanical devices" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 46, name: "Crown of the Beastmaster", category: "Visible", leaderboard: "Top Pets Controlled", type: "visible",
    rewards: { aura: true, passiveBonus: "5% pet damage", playstyleBonus: "Increased pet command range" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 47, name: "Crown of the Conqueror", category: "Visible", leaderboard: "Top Territory Captures", type: "visible",
    rewards: { aura: true, passiveBonus: "5% damage to forts", playstyleBonus: "Increased movement speed near objectives" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 48, name: "Crown of the Diplomat", category: "Visible", leaderboard: "Top Faction Alliances Formed", type: "visible",
    rewards: { aura: true, passiveBonus: "5% faction relations boost", playstyleBonus: "Reduced negotiation cooldowns" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 49, name: "Crown of the Librarian", category: "Visible", leaderboard: "Top Knowledge Collected", type: "visible",
    rewards: { aura: true, passiveBonus: "5% skill XP gain", playstyleBonus: "Reduced cooldown on research abilities" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  { id: 50, name: "Crown of the Mystic", category: "Visible", leaderboard: "Top Magical Achievements", type: "visible",
    rewards: { aura: true, passiveBonus: "5% magic damage", playstyleBonus: "Reduced mana costs" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: false } 
  },
  // Hidden crowns 51–60
  { id: 51, name: "Crown of the Forgotten", category: "Hidden", leaderboard: "Top Secret PvE Events", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% rare item drops", playstyleBonus: "Extra resource yields" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 52, name: "Crown of the Veil", category: "Hidden", leaderboard: "Top Hidden PvP Events", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% stealth efficiency", playstyleBonus: "Extended invisibility duration" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 53, name: "Crown of the Eclipse", category: "Hidden", leaderboard: "Top Shadow Realm Activities", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% damage vs rare bosses", playstyleBonus: "Reduced cooldowns in shadow zones" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 54, name: "Crown of the Revenant", category: "Hidden", leaderboard: "Top Resurrection Events", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% revival speed", playstyleBonus: "Reduced death penalties" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 55, name: "Crown of the Phantom", category: "Hidden", leaderboard: "Top Illusive Feats", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% dodge chance", playstyleBonus: "Reduced detection by AI" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 56, name: "Crown of the Obscured", category: "Hidden", leaderboard: "Top Hidden Crafting Feats", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% crafting efficiency", playstyleBonus: "Access to secret recipes" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 57, name: "Crown of the Ascendant", category: "Hidden", leaderboard: "Top Ascension Trials", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% all stats", playstyleBonus: "Reduced cooldowns on ascension skills" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 58, name: "Crown of the Eternal", category: "Hidden", leaderboard: "Top Endgame PvE Feats", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% damage to endgame bosses", playstyleBonus: "Reduced resource cost in epic events" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 59, name: "Crown of the Veiled God", category: "Hidden", leaderboard: "Top Secret World Manipulations", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% all rare interactions", playstyleBonus: "Extra event rewards" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  },
  { id: 60, name: "Crown of the Shadow King", category: "Hidden", leaderboard: "Top Hidden PvP Conquests", type: "hidden",
    rewards: { aura: true, passiveBonus: "5% damage in hidden arenas", playstyleBonus: "Extended invisibility and stealth" },
    requirements: { minChampionLevel: 1, crownRequired: false, factionRank: null, tokenRequired: true } 
  }
];
