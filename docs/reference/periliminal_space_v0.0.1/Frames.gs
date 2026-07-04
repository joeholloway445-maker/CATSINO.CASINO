function fillFramesFiles() {
  var root = DriveApp.getFoldersByName("Periliminal").next();
  var morph = root.getFoldersByName("morphology").next();
  var framesFolder = morph.getFoldersByName("frames").next();

  var framesData = {
    "skirmisher.py": `# Skirmisher
# Type: Light Frame
# Exclusive Stat: Precision (Movement crit scaling)
# Focus: Duel combat, mobility burst
# Description: Light agile combat armor, sleek vanguard style, kinetic energy effects.
# AI Prompt: Light agile combat armor, sleek vanguard style, kinetic energy effects, small shield and blade, action-ready stance
`,
    "strider.py": `# Strider
# Type: Light Frame
# Exclusive Stat: Velocity (Dash cooldown compresses with sustained motion)
# Focus: Speed scaling
# Description: Agile scout frame, enhanced legs, forward-leaning motion.
# AI Prompt: Agile scout frame, light armor, enhanced legs and mobility systems, forward-leaning motion pose, dynamic background
`,
    "skybound.py": `# Skybound
# Type: Light Frame
# Exclusive Stat: Lift (Jump cooldown reduces with airtime)
# Focus: Air dominance
# Description: Winged or jet-assisted light frame, vertical lift systems.
# AI Prompt: Winged or jet-assisted light frame, vertical lift systems, dynamic airborne pose, wind trails and sky background
`,
    "flicker.py": `# Flicker
# Type: Light Frame
# Exclusive Stat: Phase Charge (Blink chain multiplier)
# Focus: Short-range teleport combat
# Description: Light teleporting frame, fragmented visual trails, agile posture.
# AI Prompt: Light teleporting frame, fragmented visual trails, afterimage effect, agile posture, mystical neon background
`,
    "marshal.py": `# Marshal
# Type: Light Frame
# Exclusive Stat: Command (NPC efficiency)
# Focus: Tactical AI leadership
# Description: Light command frame, emblematic armor, battlefield backdrop.
# AI Prompt: Light command frame, emblematic armor, tactical holographic displays, leadership pose, battlefield backdrop
`,
    "bloom.py": `# Bloom
# Type: Light Frame
# Exclusive Stat: Mutation Rate (Resistance shifts)
# Focus: Adaptive combat
# Description: Light symbiotic frame, natural growth integrated with armor.
# AI Prompt: Light symbiotic frame, natural growth integrated with armor, floral tendrils, elegant pose, forested background
`,
    "rewind.py": `# Rewind
# Type: Light Frame
# Exclusive Stat: Temporal Thread (Undo window)
# Focus: Micro time control
# Description: Light temporal frame, hourglass motifs, floating time fragments.
# AI Prompt: Light temporal frame, hourglass motifs, floating time fragments, soft glowing energy trails, sci-fi mystic pose
`,
    "conduit.py": `# Conduit
# Type: Light Frame
# Exclusive Stat: Flux (Cooldown compression)
# Focus: Energy cycling
# Description: Light energy frame, flowing electric arcs along limbs.
# AI Prompt: Light energy frame, flowing electric arcs along limbs, dynamic casting pose, sci-fi tech environment
`,
    "shade.py": `# Shade
# Type: Light Frame
# Exclusive Stat: Obscurity (Stealth → crit scaling)
# Focus: Assassination
# Description: Light stealth frame, shadowy material, crouched ambush pose.
# AI Prompt: Light stealth frame, shadowy material, sleek silhouette, crouched or poised for ambush, dark urban/fantasy background
`,
    "fabricator.py": `# Fabricator
# Type: Light Frame
# Exclusive Stat: Assembly (Build speed multiplier)
# Focus: Deployables & traps
# Description: Light construct frame, deployable tool limbs, mechanical components.
# AI Prompt: Light construct frame, deployable tool limbs, mechanical components, workshop or battlefield background, ready-to-build stance
`,
    "bastion.py": `# Bastion
# Type: Heavy Frame
# Exclusive Stat: Fortitude (Damage reduction while stationary)
# Focus: Area defense
# Description: Heavy fortified armor, tower-like silhouette, defensive stance.
# AI Prompt: Heavy fortified armor, reinforced plating, tower-like silhouette, defensive stance, siege-ready aesthetic
`,
    "juggernaut.py": `# Juggernaut
# Type: Heavy Frame
# Exclusive Stat: Impact (Momentum → AoE)
# Focus: Charge devastation
# Description: Massive armored frame, momentum-based design.
# AI Prompt: Massive armored frame, mechanical heavy plates, momentum-based design, charge-ready stance, destructible terrain hints
`,
    "gravemind.py": `# Gravemind
# Type: Heavy Frame
# Exclusive Stat: Gravity (CC strength scaling)
# Focus: Pull, slam, anti-air
# Description: Heavy frame manipulating gravity, magnetic orbs, dark environment.
# AI Prompt: Heavy frame manipulating gravity, magnetic orbs and energy fields, grounded yet imposing stance, dark environment
`,
    "riftbreaker.py": `# Riftbreaker
# Type: Heavy Frame
# Exclusive Stat: Spatial Integrity (Portal durability)
# Focus: Map distortion
# Description: Heavy portal-manipulating frame, dimensional cracks.
# AI Prompt: Heavy portal-manipulating frame, dimensional cracks around body, imposing stance, cosmic rift energy
`,
    "sovereign.py": `# Sovereign
# Type: Heavy Frame
# Exclusive Stat: Dominion (Territory yield)
# Focus: Zone ownership
# Description: Heavy ruler frame, ornate armor, commanding stance.
# AI Prompt: Heavy ruler frame, ornate reinforced armor, territorial symbols, seated or commanding stance, epic fortress background
`,
    "worldroot.py": `# Worldroot
# Type: Heavy Frame
# Exclusive Stat: Spread (Terrain conversion rate)
# Focus: Environmental takeover
# Description: Heavy symbiotic frame, roots spread into environment.
# AI Prompt: Heavy symbiotic frame, massive plant/terrain integration, grounded stance, roots spreading into environment, earthy style
`,
    "epoch.py": `# Epoch
# Type: Heavy Frame
# Exclusive Stat: Chrono Weight (Time dilation)
# Focus: Macro time control
# Description: Heavy time-manipulating frame, clockwork structures integrated.
# AI Prompt: Heavy time-manipulating frame, clockwork structures integrated with armor, gravitational distortions around body
`,
    "overlord.py": `# Overlord
# Type: Heavy Frame
# Exclusive Stat: Overheat (Cataclysm multiplier)
# Focus: Energy detonation
# Description: Heavy energy frame, concentrated power core.
# AI Prompt: Heavy energy frame, concentrated power core, large-scale destructive aura, imposing stance, glowing environment
`,
    "obscura.py": `# Obscura
# Type: Heavy Frame
# Exclusive Stat: Veil Density (Area concealment)
# Focus: Mass stealth control
# Description: Heavy stealth/veil frame, cloak-like armor.
# AI Prompt: Heavy stealth/veil frame, cloak-like armor, area concealment energy fields, static stance, dark mystical environment
`,
    "architect.py": `# Architect
# Type: Heavy Frame
# Exclusive Stat: Infrastructure (Structure durability)
# Focus: Fortress building
# Description: Heavy build frame, structural plating, fortress motif.
# AI Prompt: Heavy build frame, massive structural plating, environmental integration, fortress motif, construction-ready stance
`
  };

  for (var fileName in framesData) {
    var file = framesFolder.getFilesByName(fileName).next();
    file.setContent(framesData[fileName]);
  }

  Logger.log("All 20 frame files are fully populated!");
}