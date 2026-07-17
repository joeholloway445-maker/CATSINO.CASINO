# n8n Entity Image Generation Automation

**Status**: Ready to Deploy  
**Estimated Runtime**: queue-length dependent for 600 stage-specific images  
**Cost**: $0 (Perchance free tier, n8n free tier)

---

## Architecture Overview

```
PostgreSQL/CSV Input
    ↓
n8n: Read Entity Database
    ↓
n8n: Generate Perchance Prompts
    ↓
n8n: Batch into chunks of 20
    ↓
n8n: Queue to Perchance Generator
    ↓
n8n: Poll Perchance (60s interval)
    ↓
n8n: Download Generated Images
    ↓
n8n: Organize into Godot Structure
    ↓
n8n: Generate Asset Manifest
    ↓
n8n: Commit to GitHub
    ↓
n8n: Notify on Discord
```

---

## Node-by-Node Setup

### **Node 1: Read Entity Database**
**Type**: HTTP Request or PostgreSQL

**If using CSV**:
```
URL: https://raw.githubusercontent.com/joeholloway445-maker/CATSINO.CASINO/main/data/entity_database.csv
Method: GET
Response Type: JSON
```

**Expected Output**:
```json
[
  {
    "entity_id": "SC-SURLING",
    "entity_name": "Surling",
    "faction": "SovereignCrown",
    "type": "light",
    "stage_1": "A small luminous orb of structured light",
    "stage_2": "A refined beacon of ordered radiance",
    "stage_3": "A perfect sun of calculated light"
  }
]
```

### **Node 2: Generate Perchance Prompts**
**Type**: Function (JavaScript)

```javascript
// Input: array of entities
// Output: array of prompt sets

const createPrompts = (entities) => {
  return entities.map(entity => {
    const factionTheme = {
      "SovereignCrown": "ordered, geometric, authoritarian, gold/silver",
      "VeiledCurrent": "mystical, ethereal, dreamlike, deep purple/midnight blue",
      "WildlandsAscendant": "primal, organic, savage, emerald/amber"
    }[entity.faction] || "neutral";

    const basePrompt = `A creature from Periliminal.Space game. Faction: ${entity.faction}. Element: ${entity.type}. Art style: semi-realistic anime, ${factionTheme}, game sprite asset 256x256px.`;

    return {
      entity_id: entity.entity_id,
      entity_name: entity.entity_name,
      faction: entity.faction,
      prompts: [
        {
          stage: 1,
          prompt: `${basePrompt} Stage 1 (Juvenile): ${entity.stage_1}. Vibrant colors, square composition.`,
          url_param: `${entity.entity_id}_stage1`
        },
        {
          stage: 2,
          prompt: `${basePrompt} Stage 2 (Evolved): ${entity.stage_2}. More defined features, rich colors.`,
          url_param: `${entity.entity_id}_stage2`
        },
        {
          stage: 3,
          prompt: `${basePrompt} Stage 3 (Apex): ${entity.stage_3}. Mature appearance, vibrant and striking.`,
          url_param: `${entity.entity_id}_stage3`
        }
      ]
    };
  });
};

return createPrompts($input.all());
```

### **Node 3: Flatten Prompts**
**Type**: Item Lists > Split In Batches

**Config**:
- Batch size: 20
- Output: Array of arrays (each sub-array = batch of 20 prompts)

### **Node 4: Loop Over Batches**
**Type**: Loop

**Loop over**: Each batch from Node 3

### **Node 5: Queue to Perchance (Inside Loop)**
**Type**: HTTP Request

**For each prompt in batch**:
```
URL: https://perchance.org/api/generate
Method: POST
Headers:
  Content-Type: application/json
Body: {
  "prompt": "{{$item().prompt}}",
  "model": "dreamshaper-8", // or latest Perchance model
  "count": 1,
  "seed": {{$item().seed || Math.random() * 1000000 | floor}}
}
```

**Response**: `{ "images": [{ "url": "...", "id": "..." }] }`

### **Node 6: Wait for Batch Completion**
**Type**: Delay

**Config**: 5 minutes (gives Perchance time to generate batch)

### **Node 7: Poll Perchance Status**
**Type**: Loop with Timeout

```javascript
// Keep polling until all images in batch are generated
// Poll every 60 seconds
// Timeout after 24 hours

const pollStatus = async (batch_id) => {
  let attempts = 0;
  const max_attempts = 1440; // 24 hours / 60s intervals
  
  while (attempts < max_attempts) {
    const response = await fetch(`https://perchance.org/api/status/${batch_id}`);
    const data = await response.json();
    
    if (data.status === "completed") {
      return data.images;
    }
    
    if (data.status === "failed") {
      throw new Error(`Batch ${batch_id} failed`);
    }
    
    attempts++;
    await new Promise(r => setTimeout(r, 60000)); // Wait 60s
  }
  
  throw new Error(`Batch ${batch_id} timeout`);
};

return pollStatus($item().batch_id);
```

### **Node 8: Download Images**
**Type**: HTTP Request (per image in completed batch)

```
Method: GET
URL: {{$item().image_url}}
Return Full Response: true
Write to File: /tmp/perchance_batch_{{batch_number}}_{{entity_id}}_stage{{stage}}.png
```

### **Node 9: Organize Into Godot Structure**
**Type**: Function (JavaScript)

```javascript
const fs = require('fs');
const path = require('path');

const organizeImages = (downloaded_images) => {
  const structure = {
    "assets/entities": {
      "sovereign_crown": {},
      "veiled_current": {},
      "wildlands_ascendant": {}
    }
  };

  downloaded_images.forEach(img => {
    const { entity_id, faction, stage } = img;
    const dir = structure.assets.entities[faction.toLowerCase()];
    const filename = `${entity_id}_stage${stage}.png`;
    
    // Move image to correct directory
    fs.renameSync(img.temp_path, path.join(process.env.GODOT_PATH, 'assets/entities', faction.toLowerCase(), filename));
    
    dir[filename] = {
      entity_id,
      stage,
      size: fs.statSync(filename).size
    };
  });

  return structure;
};

return organizeImages($input.all());
```

### **Node 10: Generate Asset Manifest**
**Type**: Function (JavaScript)

```javascript
const generateManifest = (organized_structure) => {
  const manifest = {
    version: "1.0.0",
    generated_at: new Date().toISOString(),
    total_images: 600,
    entities: {}
  };

  // For each entity, record the 3 stage images
  Object.entries(organized_structure).forEach(([faction, images]) => {
    Object.entries(images).forEach(([filename, metadata]) => {
      const entity_id = metadata.entity_id;
      
      if (!manifest.entities[entity_id]) {
        manifest.entities[entity_id] = {
          stages: {}
        };
      }
      
      manifest.entities[entity_id].stages[metadata.stage] = filename;
    });
  });

  return JSON.stringify(manifest, null, 2);
};

return generateManifest($input.all());
```

**Output**: `assets/entity_manifest.json`

### **Node 11: Commit to GitHub**
**Type**: HTTP Request

```
URL: https://api.github.com/repos/joeholloway445-maker/CATSINO.CASINO/contents/assets/entities
Method: PUT
Headers:
  Authorization: Bearer {{github_token}}
  Content-Type: application/json
Body: {
  "message": "feat: auto-generate 600 entity sprites via Perchance + n8n",
  "content": "{{base64_encode(all_images)}}",
  "branch": "claude/intelligent-fermi-yyigzo"
}
```

### **Node 12: Discord Notification**
**Type**: HTTP Request

```
URL: {{discord_webhook_url}}
Method: POST
Body: {
  "content": "✅ Entity image generation complete!",
  "embeds": [{
    "title": "Asset Pipeline Complete",
    "description": "600 entity sprites generated and committed",
    "fields": [
      { "name": "Entities", "value": "600", "inline": true },
      { "name": "Stages", "value": "3 per entity", "inline": true },
      { "name": "Commit", "value": "[View on GitHub](https://github.com/...)", "inline": false }
    ],
    "color": 65280
  }]
}
```

---

## Environment Variables Needed

```bash
# In n8n credentials
GITHUB_TOKEN=ghp_xxxxx
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/xxxxx
PERCHANCE_API_KEY=xxx (if applicable)
GODOT_PATH=/home/user/CATSINO.CASINO/godot
```

---

## Workflow Execution Checklist

- [ ] Set up n8n instance (self-hosted or n8n.cloud)
- [ ] Create GitHub personal access token (repo permissions)
- [ ] Create Discord webhook
- [ ] Load entity database CSV to public URL
- [ ] Configure all 12 nodes with credentials
- [ ] Test with 1 batch (20 images)
- [ ] If successful, run full batch (600 images)
- [ ] Monitor progress via Discord notifications
- [ ] Commit generated assets to repo
- [ ] Verify Godot can load asset manifest

---

## Fallback: Manual Perchance Workflow

**If n8n automation fails**, manual process (1 person, 8 hours):

1. Use `perchance_prompt_generator.gd` to export CSV of all 600 prompts
2. Visit https://perchance.org
3. Create batch job with prompt CSV
4. Generate all images (2-4 hours wait)
5. Download bulk zip file
6. Extract to `assets/entities/` folder
7. Run manifest generator script
8. Commit to GitHub

**Cost**: $0, **Time**: 8 hours

---

## Cost Breakdown

| Component | Cost | Hours |
|-----------|------|-------|
| Perchance (free tier) | $0 | - |
| n8n (free tier) | $0 | - |
| Automation setup | $0 | 10 |
| **Total** | **$0** | **~10** |

**Versus**: Hiring Fiverr artist = $500-2000, 2-4 weeks

---

## Post-Generation Polish (Optional)

Once images are generated, optional enhancement (4-8 hours):

1. **Upscale with Upscayl** (free): 2x image resolution
2. **Color correction**: Batch adjust saturation/contrast
3. **Add backgrounds**: Procedural layer-themed BG per entity
4. **Manual touch-up**: Fix any generation artifacts (20% of images need touch)

Total polish time: 4-8 hours  
Cost: $0 (all free tools)

---

## Next Steps

1. **This Week**: Deploy n8n workflow (10 hours my time)
2. **Next phase**: Generate 600 entity images
3. **Week 1**: Polish generated images (4 hours community effort)
4. **Week 2**: Integrate into Godot character selection UI

**Result**: Full 600-entity authored pool visible once all mixed-stage renders are completed
