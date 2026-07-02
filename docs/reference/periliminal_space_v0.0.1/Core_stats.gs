function fillCoreStatsFile() {
  var root = DriveApp.getFoldersByName("Periliminal").next();
  var coreFolder = root.getFoldersByName("core").next();

  // Create or overwrite core_stats.py
  var coreStatsFile;
  var files = coreFolder.getFilesByName("core_stats.py");
  if (files.hasNext()) {
    coreStatsFile = files.next();
  } else {
    coreStatsFile = coreFolder.createFile("core_stats.py", "");
  }

  var coreStatsContent = `
# CORE STAT SYSTEM

# Primary Stats
primary_stats = {
    "vitality": "Health Pool",
    "focus": "Ability Resource",
    "momentum": "Speed & Acceleration",
    "control": "CC Strength & Stability",
    "resonance": "Frame Affinity Growth",
    "influence": "NPC/AI Interaction Power"
}

# Secondary Stats / Systems
secondary_stats = {
    "cooldown_reduction": "Reduces skill cooldowns",
    "adaptation_rate": "Efficiency in new environments",
    "territory_efficiency": "Improves resource gain in zones",
    "vertical_mastery": "Affects jump, flight, vertical movement",
    "energy_stability": "Consistency of energy pool",
    "damage_mitigation": "Reduces incoming damage"
}

# Hard Stat Cap
HARD_CAP = 0.95  # 95% effective value
DIMINISHING_RETURNS = 0.7  # scaling slows beyond 70%

# Specialization Rules
specialization = {
    "primary_channels": 2,  # can fully specialize in 2 primary stats
    "secondary_channels": 1,  # can fully specialize in 1 secondary stat
    "over_specialization_penalty": 0.4  # scaling slows by 40% beyond specialization
}

# Example Functions
def calculate_effective_stat(base, bonus, is_primary=True):
    """
    Calculate stat with hard cap and diminishing returns.
    base: Base stat value
    bonus: Any added bonus
    is_primary: whether it's a primary stat
    """
    stat = base + bonus
    if stat > DIMINISHING_RETURNS:
        stat = DIMINISHING_RETURNS + (stat - DIMINISHING_RETURNS) * (1 - over_specialization_penalty(is_primary))
    if stat > HARD_CAP:
        stat = HARD_CAP
    return stat

def over_specialization_penalty(is_primary):
    return specialization["over_specialization_penalty"] if is_primary else 0
`;

  coreStatsFile.setContent(coreStatsContent);
  Logger.log("Core Stats file created/updated successfully!");
}