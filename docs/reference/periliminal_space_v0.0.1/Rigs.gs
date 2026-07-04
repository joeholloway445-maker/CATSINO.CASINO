function fillMorphRigsFiles() {
  var root = DriveApp.getFoldersByName("Periliminal").next();
  var morph = root.getFoldersByName("morphology").next();
  var rigsFolder = morph.getFoldersByName("rigs").next();

  var rigsData = {
    "heavy_siege.py": `# Heavy Siege
# Bonus: +Stability
# Drawback: -Momentum
# Description: Massive skeletal frame, reinforced plating, slow but stable, industrial fantasy aesthetic
# AI Prompt: Massive skeletal frame, reinforced plating, slow but stable, industrial fantasy aesthetic
`,
    "swiftburner.py": `# Swiftburner
# Bonus: +Acceleration
# Drawback: -Control
# Description: Light skeletal frame, elongated legs, agile posture, kinetic energy trails, fast-motion effect
# AI Prompt: Light skeletal frame, elongated legs, agile posture, kinetic energy trails, fast-motion effect
`,
    "multi_limbed.py": `# Multi-Limbed
# Bonus: +Aux Action Slot
# Drawback: -Energy Stability
# Description: Humanoid with multiple functional limbs, balanced mechanics, complex action-ready pose
# AI Prompt: Humanoid with multiple functional limbs, balanced mechanics, complex action-ready pose
`,
    "towering.py": `# Towering
# Bonus: +Intimidation Radius
# Drawback: -Evasion
# Description: Extremely tall skeletal frame, intimidating proportions, vertical emphasis, epic fantasy setting
# AI Prompt: Extremely tall skeletal frame, intimidating proportions, vertical emphasis, epic fantasy setting
`,
    "compact.py": `# Compact
# Bonus: +Evasion
# Drawback: -AoE Reach
# Description: Short, dense skeletal frame, high agility, crouched action stance, futuristic environment
# AI Prompt: Short, dense skeletal frame, high agility, crouched action stance, futuristic environment
`,
    "elastic.py": `# Elastic
# Bonus: +Melee Range
# Drawback: -Mitigation
# Description: Flexible elongated skeletal frame, stretching limbs, exaggerated motion pose, dynamic style
# AI Prompt: Flexible elongated skeletal frame, stretching limbs, exaggerated motion pose, dynamic style
`,
    "floating_core.py": `# Floating Core
# Bonus: +Vertical Mastery
# Drawback: -Traction
# Description: Levitation-based frame, suspended central core, floating posture, mystical sci-fi lighting
# AI Prompt: Levitation-based frame, suspended central core, floating posture, mystical sci-fi lighting
`,
    "split_form.py": `# Split Form
# Bonus: +Decoy
# Drawback: -Focus Regen
# Description: Skeletal frame divided into dual-body segments, mirrored action pose, energy separation effects
# AI Prompt: Skeletal frame divided into dual-body segments, mirrored action pose, energy separation effects
`,
    "inverted_spine.py": `# Inverted Spine
# Bonus: +Backstab Damage
# Drawback: -Front Defense
# Description: Unusual upside-down spine skeletal structure, back-heavy action stance, dark fantasy setting
# AI Prompt: Unusual upside-down spine skeletal structure, back-heavy action stance, dark fantasy setting
`,
    "modular.py": `# Modular
# Bonus: +Item Slot
# Drawback: -Vitality Regen
# Description: Interchangeable skeletal parts, mechanical modular design, tool-equipped posture, workshop background
# AI Prompt: Interchangeable skeletal parts, mechanical modular design, tool-equipped posture, workshop background
`,
    "armored.py": `# Armored
# Bonus: +Mitigation
# Drawback: -Momentum
# Description: Heavily plated skeletal frame, tank-like proportions, battle-ready stance, dark industrial environment
# AI Prompt: Heavily plated skeletal frame, tank-like proportions, battle-ready stance, dark industrial environment
`,
    "lithe.py": `# Lithe
# Bonus: +Dodge Window
# Drawback: -Stability
# Description: Slim skeletal frame, high dodge emphasis, dynamic motion blur, agile pose
# AI Prompt: Slim skeletal frame, high dodge emphasis, dynamic motion blur, agile pose
`,
    "tendril.py": `# Tendril
# Bonus: +CC Duration
# Drawback: -Burst Damage
# Description: Skeletal frame with organic tendrils extending from body, CC-focused stance, shadowy environment
# AI Prompt: Skeletal frame with organic tendrils extending from body, CC-focused stance, shadowy environment
`,
    "rooted.py": `# Rooted
# Bonus: +Control Strength
# Drawback: No Dash
# Description: Lower body anchored, strong grounded posture, skeletal roots extending, earthy setting
# AI Prompt: Lower body anchored, strong grounded posture, skeletal roots extending, earthy setting
`,
    "hover_strider.py": `# Hover Strider
# Bonus: No Fall Damage
# Drawback: -Stamina Regen
# Description: Floating skeletal frame, aerodynamic form, hovering pose, sci-fi sky background
# AI Prompt: Floating skeletal frame, aerodynamic form, hovering pose, sci-fi sky background
`,
    "centroid.py": `# Centroid
# Bonus: +5% All Stats
# Drawback: None
# Description: Balanced skeletal frame, neutral proportions, symmetric action pose, bright neutral environment
# AI Prompt: Balanced skeletal frame, neutral proportions, symmetric action pose, bright neutral environment
`,
    "shardform.py": `# Shardform
# Bonus: +Reflect
# Drawback: Shatter Risk
# Description: Crystalline skeletal frame, reflective shards protruding, angular pose, high fantasy lighting
# AI Prompt: Crystalline skeletal frame, reflective shards protruding, angular pose, high fantasy lighting
`,
    "quadruped.py": `# Quadruped
# Bonus: +Sprint Speed
# Drawback: No Dual-Wield
# Description: Four-legged skeletal frame, low center of gravity, sprinting pose, rugged terrain environment
# AI Prompt: Four-legged skeletal frame, low center of gravity, sprinting pose, rugged terrain environment
`,
    "serpentine.py": `# Serpentine
# Bonus: +Immobilize Resist
# Drawback: -Jump Height
# Description: Long, flexible skeletal frame, snake-like movement, coiled action stance, mystical background
# AI Prompt: Long, flexible skeletal frame, snake-like movement, coiled action stance, mystical background
`,
    "colossus.py": `# Colossus
# Bonus: +Control
# Drawback: -Momentum
# Description: Gigantic skeletal frame, towering proportions, slow imposing pose, epic battle environment
# AI Prompt: Gigantic skeletal frame, towering proportions, slow imposing pose, epic battle environment
`
  };

  for (var fileName in rigsData) {
    var file = rigsFolder.getFilesByName(fileName).next();
    file.setContent(rigsData[fileName]);
  }

  Logger.log("All 20 Morphological Rig files are fully populated!");
}