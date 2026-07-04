function fillRacesFiles() {
  var root = DriveApp.getFoldersByName("Periliminal").next();
  var morph = root.getFoldersByName("morphology").next();
  var racesFolder = morph.getFoldersByName("races").next();

  var racesData = {
    "lumenari.py": `# Lumenari
# Origin Stats: Focus +15%, Energy Stability +10%, Momentum +5%
# Drawback: Focus −15% in darkness
# Passive: Radiant Pulse (small AoE burst at max Focus)
# Description: Futuristic humanoid glowing with solar energy, sleek armor, ambient light aura.
# AI Prompt: Futuristic humanoid glowing with solar energy, radiant skin, sleek armor, ambient light aura, high-tech solar accessories, epic fantasy style
`,
    "gutterkin.py": `# Gutterkin
# Origin Stats: Environmental Resistance +25%, Adaptation Rate +10%
# Drawback: Vitality Regen −10% in clean zones
# Passive: Hazard Conversion (hazards restore Focus)
# Description: Urban survivor humanoid, bio-urban mutation, toxic-stained clothing, gritty neon background.
# AI Prompt: Urban survivor humanoid, bio-urban mutation, toxic sludge stains, layered ragged clothing, neon urban background, gritty style
`,
    "deepborne.py": `# Deepborne
# Origin Stats: Vitality +20%, Control +15%
# Drawback: Momentum −10% on surface
# Passive: Pressure Pulse (knockback when struck)
# Description: Abyssal humanoid, deep-sea armor with luminescent patterns.
# AI Prompt: Abyssal humanoid, deep-sea inspired armor, dark luminescent patterns, glowing eyes, oceanic trench environment, moody lighting
`,
    "ashen_choir.py": `# Ashen Choir
# Origin Stats: Influence +20%, Resonance +15%
# Drawback: Incoming damage rises after ally death
# Passive: Sorrow Amplification (ally damage boost)
# Description: Ethereal, smoky translucent humanoid, floating in dark mist.
# AI Prompt: Ethereal spirit-like humanoid, smoky translucent form, emotional aura, choir-like spectral energy, floating in dark mist
`,
    "veilstriders.py": `# Veilstriders
# Origin Stats: Cooldown Reduction +15%, Momentum +10%
# Drawback: Minor random displacement under heavy damage
# Passive: 5% chance to ignore incoming hit
# Description: Phase-shifting humanoid, fragmented body, energy trails.
# AI Prompt: Phase-shifting humanoid, semi-transparent, fragmented body, streaks of energy trailing motion, futuristic mystical background
`,
    "chronarchs.py": `# Chronarchs
# Origin Stats: Cooldown Reduction +20%, Resonance +10%
# Drawback: Ability spam slows movement
# Passive: Micro-Rewind (correct small movement error)
# Description: Time-fractured humanoid with clockwork and floating temporal fragments.
# AI Prompt: Time-fractured human, clockwork elements, floating temporal fragments, glowing hourglass symbols, sci-fi fantasy style
`,
    "nullborn.py": `# Nullborn
# Origin Stats: Control +15%, Debuff Resistance +15%
# Drawback: Influence −10%
# Passive: Outcome Shift (minor RNG skew)
# Description: Alien humanoid outside normal physics, asymmetrical features, surreal style.
# AI Prompt: Alien humanoid outside normal physics, asymmetrical features, void-like shadows, abstract background, surreal sci-fi style
`,
    "thorned.py": `# Thorned
# Origin Stats: Vitality Regen +15%, Adaptation +20%
# Drawback: Fire Resistance −20%
# Passive: Regrowth Armor
# Description: Plant-symbiotic humanoid with vines and thorns, glowing pollen accents.
# AI Prompt: Plant-symbiotic humanoid, vines and thorns integrated into skin, glowing pollen accents, forest biome, fantasy style
`,
    "echoes.py": `# Echoes
# Origin Stats: Focus +20%, Cooldown Reduction +15%
# Drawback: EMP Vulnerability −15%
# Passive: Passive System Hack
# Description: Digital humanoid, holographic patterns, circuit-like glowing tattoos.
# AI Prompt: Digital humanoid, holographic patterns, circuit-like glowing tattoos, cyberpunk AI integration, glitch effects
`,
    "hollowed.py": `# Hollowed
# Origin Stats: Energy Stability +15%, Control +10%
# Drawback: Maintenance Drain (minor upkeep)
# Passive: Extra Item Slot
# Description: Biotech human, mechanical implants fused with flesh.
# AI Prompt: Biotech human, mechanical implants fused with flesh, modular appendages, cyber-organic armor, dark lab background
`,
    "riftspawn.py": `# Riftspawn
# Origin Stats: Momentum +15%, Vertical Mastery +15%
# Drawback: Spatial instability
# Passive: Minor Gravity Pull
# Description: Dimensional humanoid, gravity-defying posture, cosmic rift energy.
# AI Prompt: Dimensional humanoid, gravity-defying posture, warped limbs, cosmic rift energy, floating fragments, high fantasy
`,
    "mirekin.py": `# Mirekin
# Origin Stats: Environmental Resistance +20%, Vitality +15%
# Drawback: Momentum −10%
# Passive: Hive Awareness
# Description: Swamp humanoid, muddy textured skin, amphibious features.
# AI Prompt: Swamp humanoid, muddy textured skin, amphibious features, glowing fungi, wetland environment, fantasy horror
`,
    "sunspun.py": `# Sunspun
# Origin Stats: Focus Output +20%, Momentum +15%
# Drawback: Overheat risk
# Passive: Radiant Burst at max Focus
# Description: Solar-infused humanoid, golden energy streams, sun motif armor.
# AI Prompt: Solar-infused humanoid, golden energy streams, sun motif armor, glowing eyes, desert sky background
`,
    "coldmarrow.py": `# Coldmarrow
# Origin Stats: Damage Mitigation +25%, Control +10%
# Drawback: Momentum −15%
# Passive: Freeze Aura
# Description: Ice elemental humanoid, crystalline body, frost mist.
# AI Prompt: Ice elemental humanoid, crystalline body, frost mist, frozen spikes, snowstorm environment, epic fantasy style
`,
    "pulseborn.py": `# Pulseborn
# Origin Stats: Momentum +25%, Cooldown Reduction +20%
# Drawback: Nervous Overload (self-damage on overuse)
# Passive: Shock Dash AoE
# Description: Electrified humanoid, crackling energy flowing along body.
# AI Prompt: Electrified humanoid, crackling energy flowing over body, neon arcs, dynamic action pose, futuristic style
`,
    "dreamflesh.py": `# Dreamflesh
# Origin Stats: Adaptation +15%, Resonance +15%
# Drawback: Sleep cycle fluctuation
# Passive: Minor Morph Shift
# Description: Adaptive humanoid, soft glowing skin, subtle morphing features.
# AI Prompt: Adaptive humanoid, shapeshifting features, soft glowing skin, subtle morphing body parts, dreamlike environment
`,
    "crownless.py": `# Crownless
# Origin Stats: Influence +20%, Territory Efficiency +10%
# Drawback: Faction hostility events
# Passive: Authority Override
# Description: Political/faction humanoid, rugged appearance, emblematic robes.
# AI Prompt: Political/faction humanoid, noble but rugged appearance, emblematic robes, command aura, fantasy epic setting
`,
    "rotweavers.py": `# Rotweavers
# Origin Stats: Resource Gain +15%, Environmental Efficiency +15%
# Drawback: Influence −10%
# Passive: Decay Conversion Loot
# Description: Decay-infused humanoid, fungus and rot patterns, skeletal features.
# AI Prompt: Decay-infused humanoid, fungus and rot patterns, skeletal features, biohazard aesthetic, dark swamp background
`,
    "glassborn.py": `# Glassborn
# Origin Stats: Reflect Damage +20%, Control +10%
# Drawback: Shatter threshold vulnerability
# Passive: Mirror Shield
# Description: Crystalline humanoid, shard-like armor, prismatic lighting.
# AI Prompt: Crystalline humanoid, reflective surfaces, shard-like armor, prismatic lighting, futuristic fantasy style
`,
    "starfall.py": `# Starfall
# Origin Stats: Momentum +15%, Focus +15%
# Drawback: Meteor Reveal Burst
# Passive: Impact Entry (fall damage becomes AoE)
# Description: Celestial humanoid, cosmic energy trails, star-studded armor.
# AI Prompt: Celestial humanoid, cosmic energy trails, star-studded armor, falling meteor visual effects, dark void sky
`
  };

  for (var fileName in racesData) {
    var file = racesFolder.getFilesByName(fileName).next();
    file.setContent(racesData[fileName]);
  }

  Logger.log("All 20 race files are fully populated!");
}