// moba_match.ts — Authoritative Paws of the Ancients (5v5) Nakama match.
// Lobby fills humans + bots to 10, then server ticks structures/minions/heroes.

const MAX_PLAYERS = 10;
const TEAM_SIZE = 5;
const TICK_RATE = 5;
const LOBBY_WAIT_SEC = 20;
const COUNTDOWN_SEC = 3;
const WAVE_INTERVAL_SEC = 18;
const FOUNTAIN_RADIUS = 7.5;
const RECALL_SEC = 4;
const BASE_RESPAWN_SEC = 8;

const LANE_Z = [-14, 0, 14];

const Op = {
  READY: 1,
  INPUT: 2,
  BASIC_ATTACK: 4,
  SHOP_BUY: 5,
  SHOP_SELL: 6,
  RECALL_START: 7,
  RECALL_CANCEL: 8,
  SNAPSHOT: 101,
  EVENT: 107,
  PHASE: 108,
  MATCH_END: 109,
} as const;

const enum Phase { LOBBY = 0, COUNTDOWN = 1, PLAYING = 2, ENDED = 3 }

interface Vec { x: number; z: number }

interface NetPlayer {
  user_id: string;
  name: string;
  team: "ally" | "enemy";
  bot: boolean;
  presence?: nkruntime.Presence;
  ready: boolean;
  x: number; z: number;
  hp: number; max_hp: number;
  gold: number; xp: number; level: number; xp_next: number;
  damage: number; armor: number; attack_speed: number; tower_mult: number; attack_range: number;
  items: string[];
  alive: boolean;
  respawn_at: number;
  recall_left: number;
  kills: number; deaths: number; assists: number; cs: number;
  lane: number;
}

interface Structure {
  id: string; team: "ally" | "enemy"; kind: "tower" | "inhibitor" | "nexus";
  lane: number; x: number; z: number; hp: number; max_hp: number; armor: number; invuln: boolean;
}

interface Minion {
  id: string; team: "ally" | "enemy"; lane: number; kind: string;
  x: number; z: number; hp: number; max_hp: number; damage: number; speed: number; wp: number;
}

interface ShopItem { id: string; name: string; price: number; stats: Record<string, number>; consumable?: boolean }

interface MobaState {
  phase: Phase;
  tick: number;
  lobby_tick: number;
  countdown_tick: number;
  play_tick: number;
  wave: number;
  next_wave_tick: number;
  players: Record<string, NetPlayer>;
  structures: Structure[];
  minions: Minion[];
  next_minion_id: number;
  winner: "" | "ally" | "enemy";
}

const SHOP: ShopItem[] = [
  { id: "claw_edge", name: "Claw Edge", price: 100, stats: { damage: 8 } },
  { id: "razor_fang", name: "Razor Fang", price: 220, stats: { damage: 18 } },
  { id: "iron_collar", name: "Iron Collar", price: 120, stats: { armor: 5 } },
  { id: "obsidian_plate", name: "Obsidian Plate", price: 240, stats: { armor: 12, max_hp: 30 } },
  { id: "vitality_milk", name: "Vitality Milk", price: 90, stats: { max_hp: 40, heal: 40 } },
  { id: "swift_whiskers", name: "Swift Whiskers", price: 110, stats: { attack_speed: 0.25 } },
  { id: "tower_bane", name: "Tower Bane", price: 150, stats: { tower_mult: 0.2 } },
  { id: "heal_salve", name: "Heal Salve", price: 40, stats: { heal: 55 }, consumable: true },
];

function fountain(team: "ally" | "enemy"): Vec {
  return team === "ally" ? { x: -32, z: 0 } : { x: 32, z: 0 };
}

function makePlayer(user_id: string, name: string, team: "ally" | "enemy", bot: boolean, lane: number, presence?: nkruntime.Presence): NetPlayer {
  const f = fountain(team);
  return {
    user_id, name, team, bot, presence, ready: bot, lane,
    x: f.x + (team === "ally" ? 2 : -2), z: LANE_Z[lane] * 0.1,
    hp: 160, max_hp: 160, gold: 150, xp: 0, level: 1, xp_next: 100,
    damage: 14, armor: 2, attack_speed: 1, tower_mult: 0, attack_range: 3.2,
    items: [], alive: true, respawn_at: 0, recall_left: -1,
    kills: 0, deaths: 0, assists: 0, cs: 0,
  };
}

function buildStructures(): Structure[] {
  const out: Structure[] = [];
  for (let lane = 0; lane < 3; lane++) {
    const z = LANE_Z[lane];
    out.push({ id: `at_${lane}`, team: "ally", kind: "tower", lane, x: -16, z, hp: 240, max_hp: 240, armor: 5, invuln: false });
    out.push({ id: `et_${lane}`, team: "enemy", kind: "tower", lane, x: 16, z, hp: 240, max_hp: 240, armor: 5, invuln: false });
    out.push({ id: `ai_${lane}`, team: "ally", kind: "inhibitor", lane, x: -24, z, hp: 320, max_hp: 320, armor: 7, invuln: false });
    out.push({ id: `ei_${lane}`, team: "enemy", kind: "inhibitor", lane, x: 24, z, hp: 320, max_hp: 320, armor: 7, invuln: false });
  }
  out.push({ id: "an", team: "ally", kind: "nexus", lane: -1, x: -30, z: 0, hp: 520, max_hp: 520, armor: 10, invuln: true });
  out.push({ id: "en", team: "enemy", kind: "nexus", lane: -1, x: 30, z: 0, hp: 520, max_hp: 520, armor: 10, invuln: true });
  return out;
}

function refreshNexusLock(state: MobaState): void {
  const allyTowers = state.structures.filter(s => s.team === "ally" && s.kind === "tower" && s.hp > 0).length;
  const enemyTowers = state.structures.filter(s => s.team === "enemy" && s.kind === "tower" && s.hp > 0).length;
  for (const s of state.structures) {
    if (s.kind === "nexus") {
      s.invuln = s.team === "ally" ? allyTowers > 0 : enemyTowers > 0;
    }
  }
}

function assignTeam(state: MobaState): "ally" | "enemy" {
  let a = 0, e = 0;
  for (const p of Object.values(state.players)) {
    if (p.team === "ally") a++; else e++;
  }
  return a <= e ? "ally" : "enemy";
}

function fillBots(state: MobaState, logger: nkruntime.Logger): void {
  const names = ["Top Cat", "Mid Whisker", "Bot Pounce", "Jungle Yarn", "Support Purr", "Rival Ace", "Rival Blade", "Rival Shade", "Rival Bolt", "Rival Fang"];
  let i = 0;
  while (Object.keys(state.players).length < MAX_PLAYERS) {
    const team = assignTeam(state);
    const lane = Object.values(state.players).filter(p => p.team === team).length % 3;
    const id = `bot_${i}_${team}`;
    state.players[id] = makePlayer(id, names[i % names.length], team, true, lane);
    i++;
  }
  logger.info("moba: filled bots, roster=%d", Object.keys(state.players).length);
}

function broadcast(dispatcher: nkruntime.MatchDispatcher, op: number, payload: unknown): void {
  dispatcher.broadcastMessage(op, JSON.stringify(payload), null, null, true);
}

function snapshot(state: MobaState) {
  return {
    phase: state.phase,
    tick: state.tick,
    wave: state.wave,
    winner: state.winner,
    players: Object.values(state.players).map(p => ({
      id: p.user_id, name: p.name, team: p.team, bot: p.bot,
      x: +p.x.toFixed(2), z: +p.z.toFixed(2),
      hp: p.hp, max_hp: p.max_hp, gold: p.gold, level: p.level, xp: p.xp, xp_next: p.xp_next,
      damage: p.damage, armor: p.armor, attack_speed: p.attack_speed, tower_mult: p.tower_mult, attack_range: p.attack_range,
      items: p.items, alive: p.alive, respawn_at: p.respawn_at, recall_left: p.recall_left,
      kills: p.kills, deaths: p.deaths, assists: p.assists, cs: p.cs, lane: p.lane,
    })),
    structures: state.structures.map(s => ({
      id: s.id, team: s.team, kind: s.kind, lane: s.lane,
      x: s.x, z: s.z, hp: s.hp, max_hp: s.max_hp, invuln: s.invuln,
    })),
    minions: state.minions.map(m => ({
      id: m.id, team: m.team, lane: m.lane, kind: m.kind,
      x: +m.x.toFixed(2), z: +m.z.toFixed(2), hp: m.hp, max_hp: m.max_hp,
    })),
  };
}

function dist(ax: number, az: number, bx: number, bz: number): number {
  const dx = ax - bx, dz = az - bz;
  return Math.sqrt(dx * dx + dz * dz);
}

function applyItem(p: NetPlayer, item: ShopItem): void {
  const s = item.stats;
  if (s.damage) p.damage += s.damage;
  if (s.armor) p.armor += s.armor;
  if (s.max_hp) { p.max_hp += s.max_hp; }
  if (s.attack_speed) p.attack_speed += s.attack_speed;
  if (s.tower_mult) p.tower_mult += s.tower_mult;
  if (s.heal) p.hp = Math.min(p.max_hp, p.hp + s.heal);
}

function unapplyItem(p: NetPlayer, item: ShopItem): void {
  const s = item.stats;
  if (s.damage) p.damage = Math.max(1, p.damage - s.damage);
  if (s.armor) p.armor = Math.max(0, p.armor - s.armor);
  if (s.max_hp) { p.max_hp = Math.max(1, p.max_hp - s.max_hp); p.hp = Math.min(p.hp, p.max_hp); }
  if (s.attack_speed) p.attack_speed = Math.max(0.2, p.attack_speed - s.attack_speed);
  if (s.tower_mult) p.tower_mult = Math.max(0, p.tower_mult - s.tower_mult);
}

function addXp(p: NetPlayer, amount: number): void {
  p.xp += amount;
  while (p.xp >= p.xp_next) {
    p.xp -= p.xp_next;
    p.level += 1;
    p.xp_next = 100 + (p.level - 1) * 40;
    p.damage += 3;
    p.max_hp += 20;
    p.hp = Math.min(p.max_hp, p.hp + 20);
    p.armor += 1;
  }
}

function spawnWave(state: MobaState): void {
  state.wave += 1;
  const siege = state.wave % 3 === 0;
  for (let lane = 0; lane < 3; lane++) {
    const kinds = ["melee", "melee", "caster"];
    if (siege) kinds.push("siege");
    const enemyInhibDown = !state.structures.some(s => s.id === `ei_${lane}` && s.hp > 0);
    const allyInhibDown = !state.structures.some(s => s.id === `ai_${lane}` && s.hp > 0);
    if (enemyInhibDown) kinds.push("super");
    // ally supers when enemy destroyed our inhib? supers for the team that destroyed inhib — enemy gets supers in that lane when ally inhib down
    const allyKinds = ["melee", "melee", "caster"];
    if (siege) allyKinds.push("siege");
    if (allyInhibDown) allyKinds.push("super");
    for (let k = 0; k < kinds.length; k++) {
      state.minions.push(makeMinion(state, "enemy", lane, kinds[k], 26 + k * 1.3));
    }
    for (let k = 0; k < allyKinds.length; k++) {
      state.minions.push(makeMinion(state, "ally", lane, allyKinds[k], -26 - k * 1.3));
    }
  }
}

function makeMinion(state: MobaState, team: "ally" | "enemy", lane: number, kind: string, x: number): Minion {
  const z = LANE_Z[lane] + (Math.random() - 0.5);
  let hp = 80, damage = 10, speed = 3.5;
  if (kind === "caster") { hp = 55; damage = 14; speed = 3.3; }
  if (kind === "siege") { hp = 140; damage = 18; speed = 2.8; }
  if (kind === "super") { hp = 260; damage = 28; speed = 3.0; }
  state.next_minion_id += 1;
  return { id: `m${state.next_minion_id}`, team, lane, kind, x, z, hp, max_hp: hp, damage, speed, wp: team === "ally" ? 0 : 4 };
}

function waypoints(lane: number): Vec[] {
  const z = LANE_Z[lane];
  return [
    { x: -26, z }, { x: -12, z }, { x: 0, z }, { x: 12, z }, { x: 26, z },
  ];
}

function tickMinions(state: MobaState, dt: number): void {
  const alive = state.minions.filter(m => m.hp > 0);
  state.minions = alive;
  for (const m of alive) {
    const enemyUnits = [
      ...alive.filter(o => o.team !== m.team),
      ...Object.values(state.players).filter(p => p.alive && p.team !== m.team),
    ];
    let target: { x: number; z: number; hit: (d: number) => void } | null = null;
    let best = 8;
    for (const o of alive) {
      if (o.team === m.team) continue;
      const d = dist(m.x, m.z, o.x, o.z);
      if (d < best) {
        best = d;
        target = { x: o.x, z: o.z, hit: (dmg) => { o.hp -= Math.max(1, dmg); } };
      }
    }
    for (const s of state.structures) {
      if (s.team === m.team || s.hp <= 0) continue;
      if (s.kind === "inhibitor") {
        const towerAlive = state.structures.some(t => t.team === s.team && t.kind === "tower" && t.lane === s.lane && t.hp > 0);
        if (towerAlive) continue;
      }
      if (s.invuln) continue;
      const d = dist(m.x, m.z, s.x, s.z);
      if (d < best) {
        best = d;
        target = { x: s.x, z: s.z, hit: (dmg) => { s.hp -= Math.max(1, dmg - s.armor); } };
      }
    }
    for (const p of Object.values(state.players)) {
      if (!p.alive || p.team === m.team) continue;
      const d = dist(m.x, m.z, p.x, p.z);
      if (d < best) {
        best = d;
        target = { x: p.x, z: p.z, hit: (dmg) => { p.hp -= Math.max(1, dmg - p.armor); } };
      }
    }
    if (target && best <= 2.4) {
      target.hit(m.damage);
    } else if (target && best < 8) {
      const dx = target.x - m.x, dz = target.z - m.z;
      const len = Math.max(0.001, Math.sqrt(dx * dx + dz * dz));
      m.x += (dx / len) * m.speed * dt;
      m.z += (dz / len) * m.speed * dt;
    } else {
      const path = waypoints(m.lane);
      const idx = m.team === "ally" ? m.wp : (path.length - 1 - m.wp);
      const goal = path[Math.max(0, Math.min(path.length - 1, idx))];
      const dx = goal.x - m.x, dz = goal.z - m.z;
      const len = Math.sqrt(dx * dx + dz * dz);
      if (len < 1.2) m.wp = Math.min(m.wp + 1, path.length - 1);
      else {
        m.x += (dx / len) * m.speed * dt;
        m.z += (dz / len) * m.speed * dt;
      }
    }
  }
  // Cleanup dead minions + CS credit nearest enemy hero
  const dead = state.minions.filter(m => m.hp <= 0);
  state.minions = state.minions.filter(m => m.hp > 0);
  for (const m of dead) {
    let bestP: NetPlayer | null = null;
    let bestD = 12;
    for (const p of Object.values(state.players)) {
      if (!p.alive || p.team === m.team) continue;
      const d = dist(p.x, p.z, m.x, m.z);
      if (d < bestD) { bestD = d; bestP = p; }
    }
    if (bestP) {
      bestP.gold += m.kind === "siege" ? 40 : m.kind === "super" ? 55 : 20;
      bestP.cs += 1;
      addXp(bestP, 24);
    }
  }
  for (const s of state.structures) {
    if (s.hp < 0) s.hp = 0;
  }
}

function tickTowers(state: MobaState, dt: number): void {
  for (const s of state.structures) {
    if (s.hp <= 0 || s.kind === "inhibitor") continue;
    let best: NetPlayer | Minion | null = null;
    let bestD = 10;
    for (const m of state.minions) {
      if (m.team === s.team || m.hp <= 0) continue;
      const d = dist(s.x, s.z, m.x, m.z);
      if (d < bestD) { bestD = d; best = m; }
    }
    if (!best) {
      for (const p of Object.values(state.players)) {
        if (!p.alive || p.team === s.team) continue;
        const d = dist(s.x, s.z, p.x, p.z);
        if (d < bestD) { bestD = d; best = p; }
      }
    }
    if (!best || bestD > 10) continue;
    // Attack ~1Hz approximated every tick_rate bucket via random-ish cadence
    if (state.tick % TICK_RATE !== 0) continue;
    const dmg = s.kind === "nexus" ? 30 : 20;
    if ("user_id" in best) {
      const p = best as NetPlayer;
      p.hp -= Math.max(1, dmg - p.armor);
    } else {
      (best as Minion).hp -= dmg;
    }
  }
}

function tickBots(state: MobaState, dt: number): void {
  for (const p of Object.values(state.players)) {
    if (!p.bot || !p.alive) continue;
    // Push lane + attack nearest enemy
    const path = waypoints(p.lane);
    const goal = p.team === "ally" ? path[Math.min(4, Math.floor(state.wave / 2))] : path[Math.max(0, 4 - Math.floor(state.wave / 2))];
    let tx = goal.x, tz = goal.z;
    let target: { x: number; z: number; hit: () => void } | null = null;
    let best = 11;
    for (const m of state.minions) {
      if (m.team === p.team || m.hp <= 0) continue;
      const d = dist(p.x, p.z, m.x, m.z);
      if (d < best) {
        best = d; tx = m.x; tz = m.z;
        target = { x: m.x, z: m.z, hit: () => {
          m.hp -= Math.max(1, p.damage);
          if (m.hp <= 0) { p.gold += 20; p.cs += 1; addXp(p, 24); }
        }};
      }
    }
    for (const s of state.structures) {
      if (s.team === p.team || s.hp <= 0 || s.invuln) continue;
      if (s.kind === "inhibitor") {
        const towerAlive = state.structures.some(t => t.team === s.team && t.kind === "tower" && t.lane === s.lane && t.hp > 0);
        if (towerAlive) continue;
      }
      const d = dist(p.x, p.z, s.x, s.z);
      if (d < best) {
        best = d; tx = s.x; tz = s.z;
        target = { x: s.x, z: s.z, hit: () => {
          const dmg = Math.floor(p.damage * (1 + p.tower_mult));
          s.hp -= Math.max(1, dmg - s.armor);
        }};
      }
    }
    if (p.hp / p.max_hp < 0.35) {
      const f = fountain(p.team);
      tx = f.x; tz = f.z; target = null;
      p.hp = Math.min(p.max_hp, p.hp + 20 * dt);
    }
    const dx = tx - p.x, dz = tz - p.z;
    const len = Math.sqrt(dx * dx + dz * dz) || 1;
    if (target && best <= p.attack_range) {
      if (state.tick % Math.max(1, Math.floor(TICK_RATE / p.attack_speed)) === 0) target.hit();
    } else {
      p.x += (dx / len) * 4.2 * dt;
      p.z += (dz / len) * 4.2 * dt;
    }
  }
}

function tickPlayers(state: MobaState, dt: number): void {
  for (const p of Object.values(state.players)) {
    if (!p.alive) {
      if (state.tick >= p.respawn_at) {
        p.alive = true;
        p.hp = p.max_hp;
        const f = fountain(p.team);
        p.x = f.x; p.z = f.z;
      }
      continue;
    }
    // Fountain heal
    const f = fountain(p.team);
    if (dist(p.x, p.z, f.x, f.z) <= FOUNTAIN_RADIUS + 1.5) {
      p.hp = Math.min(p.max_hp, p.hp + 28 * dt);
    }
    // Passive gold
    p.gold += 1.6 * dt;
    // Recall
    if (p.recall_left >= 0) {
      p.recall_left -= dt;
      if (p.recall_left <= 0) {
        p.recall_left = -1;
        p.x = f.x; p.z = f.z;
      }
    }
    if (p.hp <= 0) {
      p.alive = false;
      p.deaths += 1;
      p.hp = 0;
      p.recall_left = -1;
      p.respawn_at = state.tick + Math.floor((BASE_RESPAWN_SEC + p.level * 1.5) * TICK_RATE);
    }
  }
}

function checkStructures(state: MobaState, dispatcher: nkruntime.MatchDispatcher): void {
  refreshNexusLock(state);
  for (const s of state.structures) {
    if (s.hp > 0) continue;
    // already processed if marked? use hp==0 once
  }
  const allyNexus = state.structures.find(s => s.id === "an");
  const enemyNexus = state.structures.find(s => s.id === "en");
  if (allyNexus && allyNexus.hp <= 0) {
    state.winner = "enemy";
    state.phase = Phase.ENDED;
    broadcast(dispatcher, Op.MATCH_END, { winner: "enemy", snapshot: snapshot(state) });
  } else if (enemyNexus && enemyNexus.hp <= 0) {
    state.winner = "ally";
    state.phase = Phase.ENDED;
    broadcast(dispatcher, Op.MATCH_END, { winner: "ally", snapshot: snapshot(state) });
  }
}

function handleMessage(state: MobaState, msg: nkruntime.MatchMessage, dispatcher: nkruntime.MatchDispatcher): void {
  const p = state.players[msg.sender.userId];
  if (!p || state.phase !== Phase.PLAYING) {
    if (msg.opCode === Op.READY && p) {
      p.ready = true;
    }
    return;
  }
  let data: any = {};
  try { data = JSON.parse(msg.data || "{}"); } catch { data = {}; }

  if (msg.opCode === Op.INPUT && p.alive) {
    if (typeof data.x === "number" && typeof data.z === "number") {
      // Clamp move delta — accept absolute pos with soft leash
      const nd = dist(p.x, p.z, data.x, data.z);
      if (nd <= 6) { p.x = data.x; p.z = data.z; }
      else {
        const dx = data.x - p.x, dz = data.z - p.z;
        const len = Math.sqrt(dx * dx + dz * dz) || 1;
        p.x += (dx / len) * 4.5 * (1 / TICK_RATE);
        p.z += (dz / len) * 4.5 * (1 / TICK_RATE);
      }
      if (p.recall_left >= 0 && nd > 0.6) p.recall_left = -1;
    }
  } else if (msg.opCode === Op.BASIC_ATTACK && p.alive) {
    const tid = String(data.target_id || "");
    let dmg = p.damage;
    const minion = state.minions.find(m => m.id === tid && m.team !== p.team);
    if (minion && dist(p.x, p.z, minion.x, minion.z) <= p.attack_range + 0.5) {
      minion.hp -= Math.max(1, dmg);
      if (minion.hp <= 0) { p.gold += 20; p.cs += 1; addXp(p, 24); }
      return;
    }
    const struct = state.structures.find(s => s.id === tid && s.team !== p.team && s.hp > 0);
    if (struct && !struct.invuln && dist(p.x, p.z, struct.x, struct.z) <= p.attack_range + 1) {
      if (struct.kind === "inhibitor") {
        const towerAlive = state.structures.some(t => t.team === struct.team && t.kind === "tower" && t.lane === struct.lane && t.hp > 0);
        if (towerAlive) return;
      }
      dmg = Math.floor(dmg * (1 + p.tower_mult));
      struct.hp -= Math.max(1, dmg - struct.armor);
      return;
    }
    const hero = state.players[tid];
    if (hero && hero.alive && hero.team !== p.team && dist(p.x, p.z, hero.x, hero.z) <= p.attack_range + 0.5) {
      hero.hp -= Math.max(1, dmg - hero.armor);
      if (hero.hp <= 0) {
        p.kills += 1; p.gold += 140; addXp(p, 90);
        broadcast(dispatcher, Op.EVENT, { type: "kill", killer: p.user_id, victim: hero.user_id });
      }
    }
  } else if (msg.opCode === Op.SHOP_BUY && p.alive) {
    const f = fountain(p.team);
    if (dist(p.x, p.z, f.x, f.z) > FOUNTAIN_RADIUS + 1.5) return;
    const item = SHOP.find(i => i.id === data.item_id);
    if (!item || p.gold < item.price) return;
    if (!item.consumable && p.items.length >= 6) return;
    p.gold -= item.price;
    applyItem(p, item);
    if (!item.consumable) p.items.push(item.id);
  } else if (msg.opCode === Op.SHOP_SELL && p.alive) {
    const slot = Number(data.slot);
    if (slot < 0 || slot >= p.items.length) return;
    const id = p.items[slot];
    const item = SHOP.find(i => i.id === id);
    if (!item) return;
    unapplyItem(p, item);
    p.items.splice(slot, 1);
    p.gold += Math.floor(item.price * 0.5);
  } else if (msg.opCode === Op.RECALL_START && p.alive) {
    const f = fountain(p.team);
    if (dist(p.x, p.z, f.x, f.z) <= FOUNTAIN_RADIUS + 1.5) return;
    p.recall_left = RECALL_SEC;
  } else if (msg.opCode === Op.RECALL_CANCEL) {
    p.recall_left = -1;
  } else if (msg.opCode === Op.READY) {
    p.ready = true;
  }
}

// ── RPC find_moba_match ──────────────────────────────────────────────────────
export function rpcFindMobaMatch(ctx, logger, nk, payload) {
  if (!ctx.userId) throw new Error("Not authenticated");
  const matches = nk.matchList(10, true, "moba", undefined, MAX_PLAYERS - 1, "*");
  if (matches.length > 0) {
    logger.info("find_moba_match: join %s", matches[0].matchId);
    return JSON.stringify({ ok: true, match_id: matches[0].matchId, created: false });
  }
  const match_id = nk.matchCreate("moba_match", { mode: "moba" });
  logger.info("find_moba_match: create %s", match_id);
  return JSON.stringify({ ok: true, match_id, created: true });
};

export function mobaMatchInit(_ctx, logger, _nk, _params) {
  const state: MobaState = {
    phase: Phase.LOBBY,
    tick: 0,
    lobby_tick: 0,
    countdown_tick: 0,
    play_tick: 0,
    wave: 0,
    next_wave_tick: 0,
    players: {},
    structures: buildStructures(),
    minions: [],
    next_minion_id: 0,
    winner: "",
  };
  logger.info("moba_match init");
  return { state, tickRate: TICK_RATE, label: "moba" };
};

export function mobaMatchJoinAttempt(_ctx, _logger, _nk, _d, _t, state, _p, _m) {
  const humans = Object.values(state.players).filter(p => !p.bot).length;
  return { state, accept: state.phase === Phase.LOBBY && humans < MAX_PLAYERS };
};

export function mobaMatchJoin(_ctx, logger, _nk, dispatcher, _tick, state, presences) {
  for (const presence of presences) {
    const team = assignTeam(state);
    const lane = Object.values(state.players).filter(p => p.team === team).length % 3;
    state.players[presence.userId] = makePlayer(
      presence.userId,
      presence.username || presence.userId.slice(0, 6),
      team, false, lane, presence
    );
    logger.info("moba join %s team=%s", presence.userId, team);
    broadcast(dispatcher, Op.EVENT, { type: "join", id: presence.userId, team });
  }
  broadcast(dispatcher, Op.PHASE, { phase: state.phase });
  broadcast(dispatcher, Op.SNAPSHOT, snapshot(state));
  return { state };
};

export function mobaMatchLeave(_ctx, logger, _nk, dispatcher, _tick, state, presences) {
  for (const presence of presences) {
    const p = state.players[presence.userId];
    if (p && !p.bot) {
      // Convert leaver to bot mid-match so the game continues.
      p.bot = true;
      p.name = (p.name || "Leaver") + " (bot)";
      p.presence = undefined;
      logger.info("moba leave→bot %s", presence.userId);
      broadcast(dispatcher, Op.EVENT, { type: "leave_bot", id: presence.userId });
    }
  }
  return { state };
};

export function mobaMatchLoop(_ctx, logger, _nk, dispatcher, tick, state, messages) {
  state.tick = tick;
  for (const msg of messages) handleMessage(state, msg, dispatcher);

  if (state.phase === Phase.LOBBY) {
    if (state.lobby_tick === 0) state.lobby_tick = tick;
    const humans = Object.values(state.players).filter(p => !p.bot).length;
    const waited = (tick - state.lobby_tick) / TICK_RATE;
    const allReady = humans > 0 && Object.values(state.players).filter(p => !p.bot).every(p => p.ready);
    if (humans > 0 && (waited >= LOBBY_WAIT_SEC || allReady || humans >= MAX_PLAYERS)) {
      fillBots(state, logger);
      state.phase = Phase.COUNTDOWN;
      state.countdown_tick = tick;
      broadcast(dispatcher, Op.PHASE, { phase: state.phase, countdown: COUNTDOWN_SEC });
      broadcast(dispatcher, Op.EVENT, { type: "countdown", seconds: COUNTDOWN_SEC });
    }
  } else if (state.phase === Phase.COUNTDOWN) {
    if ((tick - state.countdown_tick) / TICK_RATE >= COUNTDOWN_SEC) {
      state.phase = Phase.PLAYING;
      state.play_tick = tick;
      state.next_wave_tick = tick + WAVE_INTERVAL_SEC * TICK_RATE;
      spawnWave(state);
      broadcast(dispatcher, Op.PHASE, { phase: state.phase });
      broadcast(dispatcher, Op.EVENT, { type: "fight" });
      broadcast(dispatcher, Op.EVENT, { type: "wave", n: state.wave });
      broadcast(dispatcher, Op.SNAPSHOT, snapshot(state));
    }
  } else if (state.phase === Phase.PLAYING) {
    const dt = 1 / TICK_RATE;
    if (tick >= state.next_wave_tick) {
      state.next_wave_tick = tick + WAVE_INTERVAL_SEC * TICK_RATE;
      spawnWave(state);
      broadcast(dispatcher, Op.EVENT, { type: "wave", n: state.wave });
    }
    tickMinions(state, dt);
    tickTowers(state, dt);
    tickBots(state, dt);
    tickPlayers(state, dt);
    checkStructures(state, dispatcher);
    // Snapshot every tick
    broadcast(dispatcher, Op.SNAPSHOT, snapshot(state));
  }

  return { state };
};

export function mobaMatchTerminate(_ctx, logger, _nk, _d, _t, state, _grace) {
  logger.info("moba terminate winner=%s", state.winner);
  return { state };
};

/** Required by Nakama 3.21+ registerMatch — no-op passthrough for external signals. */
export function mobaMatchSignal(_ctx, _logger, _nk, _d, _t, state, _data) {
  return { state };
};

export function register_moba_match(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  logger.info("moba_match module loaded — rpc: find_moba_match, match: moba_match");
}
