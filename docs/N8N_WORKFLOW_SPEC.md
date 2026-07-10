# n8n Workflow: Batch Asset Generation & Organization

## Workflow Overview

This workflow automates visual asset generation via Perchance.org and organizes outputs into the Godot project structure.

## Prerequisites

- n8n instance (self-hosted or n8n.cloud)
- Perchance.org account with configured generator
- GitHub integration (to commit generated assets)
- Webhook access to trigger workflow

## Workflow Architecture

```
┌─────────────────────────────────────────────────────────┐
│ TRIGGER: Manual or Scheduled (daily at 2 AM)            │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Read Entity Database                                     │
│ - Load entity_dex_data.gd or JSON export                │
│ - Extract: id, name, category, faction                  │
│ - Output: Array[EntityData]                             │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Filter Ungenerated Entities                             │
│ - Query GitHub /godot/assets/entities/ for existing     │
│ - Build exclusion list                                  │
│ - Output: Array[EntityData] (new only)                  │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Generate Perchance Prompts                              │
│ - Template: "A {stage} {name} of {category}..."         │
│ - Inject faction color preferences                      │
│ - Output: Array[PromptData]                             │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Batch Split (Chunk into 20)                             │
│ - Perchance rate-limits at ~20/batch                    │
│ - Create N batches                                      │
│ - Output: Array[Array[PromptData]]                      │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
        ┌──────────────┐
        │ LOOP: Per Batch
        └──────┬───────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Queue to Perchance Generator                            │
│ - POST to Perchance API (or manual UI queue)            │
│ - Collect job IDs                                       │
│ - Log to progress file: .n8n/perchance_jobs.json        │
│ - Output: Array[JobID]                                  │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Poll Status Loop (60s interval)                         │
│ - Check each job status via Perchance API               │
│ - Break when all complete or timeout (24h)              │
│ - Output: Array[CompletedJob]                           │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Download Generated Images                               │
│ - Download from Perchance per job                       │
│ - Rename: {EntityName}_stage{N}.png                     │
│ - Temporary storage: /tmp/entities/                      │
│ - Output: Array[LocalFilePath]                          │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Organize into Godot Structure                           │
│ - Create directories: godot/assets/entities/{faction}   │
│ - Move files: /tmp → godot/assets/entities/{F}/{C}/     │
│ - Output: FileTree                                      │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Generate Asset Manifest                                 │
│ - Build JSON: asset_manifest.json                       │
│ - Include: paths, hashes, metadata                      │
│ - Save to: godot/assets/entity_manifest.json            │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Commit to GitHub                                        │
│ - git add godot/assets/entities/                        │
│ - git add godot/assets/entity_manifest.json             │
│ - git commit -m "chore(assets): batch entity gen #{N}"  │
│ - git push origin assets/batch-{N}                      │
│ - Output: CommitHash                                    │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│ Send Status Notification                                │
│ - To: #dev-assets Discord channel                       │
│ - Content: batch size, generated count, commit link     │
└─────────────────────────────────────────────────────────┘
```

---

## Node Specifications

### 1. Trigger Node

**Type**: Manual Trigger + Cron

```
Cron: 0 2 * * * (daily 2 AM)
Manual: Webhook endpoint for manual kicks
Payload: { "batch_size": 20 }
```

### 2. Read Entity Database

**Type**: HTTP Request OR File Read

**Option A: HTTP (if entity_dex_data is exposed via API)**
```
URL: https://api.periliminal.space/entities
Method: GET
Output: JSON array
```

**Option B: File Read (from repo)**
```
Path: godot/src/companion/entity_dex_data.gd
Parse: Extract LINES array, convert to JSON
Transform: Add auto-incrementing IDs, normalize keys
```

### 3. Filter Ungenerated

**Type**: Code Node (JavaScript)

```javascript
// Input: entities array
// Check what already exists in godot/assets/entities/

const fs = require('fs');
const path = require('path');

const existing = new Set();
const assetsDir = 'godot/assets/entities';

// Walk existing assets
function walkDir(dir) {
  fs.readdirSync(dir).forEach(file => {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      walkDir(fullPath);
    } else if (file.endsWith('.png')) {
      const name = file.split('_stage')[0];
      existing.add(name);
    }
  });
}

if (fs.existsSync(assetsDir)) {
  walkDir(assetsDir);
}

// Filter
return {
  entities: $input.all()[0].entities.filter(e => !existing.has(e.name)),
  existingCount: existing.size
};
```

### 4. Generate Perchance Prompts

**Type**: Template Node

```
Template per entity:
"A Stage 2 {entity.name} of the {entity.category} category, bearing the {entity.faction} aesthetic. 
{entity.lore}. 
Illustration style: high fantasy character design, 4K quality, concept art. Award-winning digital painting."

Output: Array of prompt + entity metadata
```

### 5. Batch Split

**Type**: Code Node (JavaScript)

```javascript
const prompts = $input.all()[0];
const batchSize = $input.first().json.batch_size || 20;

const batches = [];
for (let i = 0; i < prompts.length; i += batchSize) {
  batches.push(prompts.slice(i, i + batchSize));
}

return { batches, totalBatches: batches.length };
```

### 6. Loop Over Batches

**Type**: Loop Node

```
Items to loop: batches array
Parallel: false (sequential, respects API rate limits)
Max iterations: 50
```

### 7. Queue to Perchance

**Type**: HTTP Request (inside loop)

```
URL: https://perchance.org/api/jobs (hypothetical)
Method: POST
Body: 
{
  "generator_id": "{YOUR_GENERATOR_ID}",
  "prompts": $loop.item.map(p => p.prompt),
  "count": $loop.item.length
}

Output: { jobIds: [...], estimatedTime: 300 }
```

**Alternative (Manual)**: 
- If Perchance API unavailable, use UI automation via RPA tool (UiPath, Selenium)
- Or create manual tracking sheet (slower but feasible)

### 8. Poll Status Loop

**Type**: Loop Node (inside parent loop)

```
Items: jobIds array
Condition: until all jobs are "complete" or timeout
Interval: 60s between polls
Max iterations: 1440 (24 hours)

Endpoint: GET https://perchance.org/api/jobs/{jobId}/status
```

### 9. Download Images

**Type**: HTTP Request (in loop for each completed job)

```
URL: {job.downloadUrl}
Method: GET
Save to: /tmp/entities/{entity.name}_stage{entity.stage}.png
```

### 10. Organize into Godot

**Type**: Code Node (Node.js with fs)

```javascript
const fs = require('fs-extra');
const path = require('path');

const downloadDir = '/tmp/entities';
const baseDir = 'godot/assets/entities';

const entities = $input.all()[0];

entities.forEach(entity => {
  const faction = entity.faction || 'Factionless';
  const category = entity.category;
  
  const targetDir = path.join(baseDir, faction, category);
  fs.ensureDirSync(targetDir);
  
  const srcFile = path.join(downloadDir, `${entity.name}_stage${entity.stage}.png`);
  const dstFile = path.join(targetDir, `${entity.name}_stage${entity.stage}.png`);
  
  fs.copySync(srcFile, dstFile);
});

return { organized: entities.length, baseDir };
```

### 11. Generate Manifest

**Type**: Code Node (JavaScript)

```javascript
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const entities = $input.all()[0];
const manifest = {
  generated_at: new Date().toISOString(),
  total_entities: entities.length,
  by_faction: {},
  by_category: {},
  assets: []
};

entities.forEach(entity => {
  const faction = entity.faction || 'Factionless';
  const category = entity.category;
  const filePath = `godot/assets/entities/${faction}/${category}/${entity.name}_stage${entity.stage}.png`;
  
  // Count by faction
  manifest.by_faction[faction] = (manifest.by_faction[faction] || 0) + 1;
  
  // Count by category
  manifest.by_category[category] = (manifest.by_category[category] || 0) + 1;
  
  // Add asset entry
  if (fs.existsSync(filePath)) {
    const fileContent = fs.readFileSync(filePath);
    const hash = crypto.createHash('sha256').update(fileContent).digest('hex');
    
    manifest.assets.push({
      entity_id: entity.id,
      name: entity.name,
      category: entity.category,
      faction: faction,
      stage: entity.stage || 2,
      image_path: filePath,
      hash: hash,
      generated: true
    });
  }
});

fs.writeFileSync('godot/assets/entity_manifest.json', JSON.stringify(manifest, null, 2));
return manifest;
```

### 12. Commit to GitHub

**Type**: Code Node (Node.js with child_process)

```javascript
const { execSync } = require('child_process');

const batchNum = new Date().getTime();
const branchName = `assets/batch-${batchNum}`;

try {
  execSync(`cd godot && git checkout -b ${branchName}`);
  execSync(`git add assets/entities/ assets/entity_manifest.json`);
  execSync(`git commit -m "chore(assets): batch entity generation #${batchNum}"`);
  execSync(`git push origin ${branchName}`);
  
  return {
    success: true,
    branch: branchName,
    timestamp: new Date().toISOString()
  };
} catch (error) {
  return {
    success: false,
    error: error.message
  };
}
```

### 13. Discord Notification

**Type**: HTTP Request (Discord Webhook)

```
URL: https://discord.com/api/webhooks/{YOUR_WEBHOOK_ID}/{YOUR_WEBHOOK_TOKEN}
Method: POST
Body:
{
  "content": "✅ Asset batch complete!",
  "embeds": [{
    "title": "Generated {count} entity visuals",
    "fields": [
      { "name": "Batch", "value": "#{batchNum}", "inline": true },
      { "name": "Factions", "value": "object.keys(manifest.by_faction).join(', ')", "inline": true },
      { "name": "Branch", "value": "{branch}", "inline": false },
      { "name": "Commit", "value": "{commitHash}", "inline": false }
    ]
  }]
}
```

---

## Deployment Checklist

- [ ] Create n8n account (self-hosted or cloud)
- [ ] Create Perchance generator and save generator ID
- [ ] Get Discord webhook URL
- [ ] Configure GitHub credentials in n8n
- [ ] Deploy workflow (test with 1 entity first)
- [ ] Set cron to daily 2 AM
- [ ] Monitor first run for errors
- [ ] Adjust prompts/settings based on results

---

## Estimated Costs

**Perchance**: Free (community tier) or $5-20/month (faster generation)
**n8n**: Free (self-hosted) or $20+/month (cloud)
**GitHub**: Free (public repo)
**Total**: $0-40/month

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Perchance API rate limit | Reduce batch size to 10, increase poll interval to 120s |
| Timeouts | Increase timeout to 48h (Perchance queues can be slow) |
| Network errors | Add retry logic: 3 attempts with exponential backoff |
| Disk space | Delete /tmp/entities after commit succeeds |
| GitHub conflicts | Rebase before push: `git rebase origin/main` |

