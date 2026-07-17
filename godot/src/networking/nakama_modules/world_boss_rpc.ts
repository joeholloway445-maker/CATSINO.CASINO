// world_boss_rpc.ts — Gate 8 shared Metroplex Titan cadence.
// Clients poll get_world_boss_state; first online client due to spawn
// claims via claim_world_boss_spawn; kills report via report_world_boss_kill.
// Zone kills can accelerate the next window (note_zone_boss_kill).

const SYSTEM_USER = "00000000-0000-0000-0000-000000000000";
const COLLECTION = "world_boss";
const KEY = "schedule";
const DEFAULT_INTERVAL_SEC = 20 * 60;
const MAX_LIFETIME_SEC = 8 * 60;

interface ActiveBoss {
  boss_id: string;
  spawned_at: number; // unix sec
  line_id: string;
  faction: string;
  category: string;
  stage: number;
  x: number;
  y: number;
  z: number;
}

interface Schedule {
  next_spawn_unix: number;
  interval_sec: number;
  active: ActiveBoss | null;
  zone_kills: Record<string, number>;
}

function _nowSec(): number {
  return Math.floor(Date.now() / 1000);
}

function _defaultSchedule(): Schedule {
  return {
    next_spawn_unix: _nowSec() + 90,
    interval_sec: DEFAULT_INTERVAL_SEC,
    active: null,
    zone_kills: {},
  };
}

function _read(nk: nkruntime.Nakama): Schedule {
  try {
    const stored = nk.storageRead([{
      collection: COLLECTION,
      key: KEY,
      userId: SYSTEM_USER,
    }]);
    if (stored.length > 0 && stored[0].value) {
      const v = stored[0].value as unknown as Schedule;
      return {
        next_spawn_unix: Number(v.next_spawn_unix) || _nowSec() + 90,
        interval_sec: Number(v.interval_sec) || DEFAULT_INTERVAL_SEC,
        active: v.active || null,
        zone_kills: (v.zone_kills && typeof v.zone_kills === "object") ? v.zone_kills : {},
      };
    }
  } catch (_e) { /* first boot */ }
  return _defaultSchedule();
}

function _write(nk: nkruntime.Nakama, schedule: Schedule): void {
  nk.storageWrite([{
    collection: COLLECTION,
    key: KEY,
    userId: SYSTEM_USER,
    value: schedule as unknown as {[key: string]: unknown},
    permissionRead: 2,
    permissionWrite: 0,
  }]);
}

function _expireStale(schedule: Schedule): Schedule {
  if (schedule.active) {
    const age = _nowSec() - Number(schedule.active.spawned_at || 0);
    if (age >= MAX_LIFETIME_SEC) {
      schedule.active = null;
      schedule.next_spawn_unix = _nowSec() + schedule.interval_sec;
    }
  }
  return schedule;
}

export function rpcGetWorldBossState(_ctx, logger, nk, _payload) {
  let schedule = _expireStale(_read(nk));
  try {
    _write(nk, schedule);
  } catch (e) {
    logger.warn("get_world_boss_state write failed: %v", e);
  }
  return JSON.stringify({
    ok: true,
    success: true,
    next_spawn_unix: schedule.next_spawn_unix,
    interval_sec: schedule.interval_sec,
    active: schedule.active,
    seconds_until_spawn: Math.max(0, schedule.next_spawn_unix - _nowSec()),
  });
};

export function rpcClaimWorldBossSpawn(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    return JSON.stringify({ ok: false, success: false, error: "Not authenticated" });
  }
  let body: Record<string, unknown> = {};
  try {
    body = JSON.parse(payload || "{}");
  } catch (_e) { /* empty */ }

  let schedule = _expireStale(_read(nk));
  if (schedule.active) {
    return JSON.stringify({
      ok: true,
      success: true,
      claimed: false,
      reason: "already_active",
      active: schedule.active,
      next_spawn_unix: schedule.next_spawn_unix,
    });
  }
  if (_nowSec() < schedule.next_spawn_unix) {
    return JSON.stringify({
      ok: true,
      success: true,
      claimed: false,
      reason: "not_due",
      next_spawn_unix: schedule.next_spawn_unix,
      seconds_until_spawn: schedule.next_spawn_unix - _nowSec(),
    });
  }

  const boss_id = String(body["boss_id"] || `world_${_nowSec()}`);
  const active: ActiveBoss = {
    boss_id,
    spawned_at: _nowSec(),
    line_id: String(body["line_id"] || "world_boss"),
    faction: String(body["faction"] || "Factionless"),
    category: String(body["category"] || "Gravity"),
    stage: Math.max(3, Number(body["stage"]) || 4),
    x: Number(body["x"]) || 0,
    y: Number(body["y"]) || 0,
    z: Number(body["z"]) || 0,
  };
  schedule.active = active;
  schedule.next_spawn_unix = _nowSec() + schedule.interval_sec;
  try {
    _write(nk, schedule);
  } catch (e) {
    logger.error("claim_world_boss_spawn write failed: %v", e);
    return JSON.stringify({ ok: false, success: false, error: "storage_write_failed" });
  }
  logger.info("world boss claimed by %s id=%s", ctx.userId, boss_id);
  return JSON.stringify({
    ok: true,
    success: true,
    claimed: true,
    active,
    next_spawn_unix: schedule.next_spawn_unix,
  });
};

export function rpcReportWorldBossKill(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    return JSON.stringify({ ok: false, success: false, error: "Not authenticated" });
  }
  let body: Record<string, unknown> = {};
  try {
    body = JSON.parse(payload || "{}");
  } catch (_e) { /* empty */ }
  const boss_id = String(body["boss_id"] || "");
  let schedule = _expireStale(_read(nk));
  if (schedule.active && boss_id && schedule.active.boss_id !== boss_id) {
    return JSON.stringify({
      ok: true,
      success: true,
      cleared: false,
      reason: "mismatch",
      active: schedule.active,
    });
  }
  schedule.active = null;
  schedule.next_spawn_unix = _nowSec() + schedule.interval_sec;
  try {
    _write(nk, schedule);
  } catch (e) {
    logger.error("report_world_boss_kill write failed: %v", e);
    return JSON.stringify({ ok: false, success: false, error: "storage_write_failed" });
  }
  logger.info("world boss killed by %s id=%s", ctx.userId, boss_id || "?");
  return JSON.stringify({
    ok: true,
    success: true,
    cleared: true,
    next_spawn_unix: schedule.next_spawn_unix,
  });
};

export function rpcNoteZoneBossKill(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    return JSON.stringify({ ok: false, success: false, error: "Not authenticated" });
  }
  let hub_id = "unknown";
  try {
    const body = JSON.parse(payload || "{}");
    hub_id = String(body["hub_id"] || "unknown");
  } catch (_e) { /* default */ }
  let schedule = _expireStale(_read(nk));
  schedule.zone_kills[hub_id] = Number(schedule.zone_kills[hub_id] || 0) + 1;
  if (schedule.zone_kills[hub_id] >= 2 && !schedule.active) {
    schedule.next_spawn_unix = Math.min(schedule.next_spawn_unix, _nowSec() + 30);
  }
  try {
    _write(nk, schedule);
  } catch (e) {
    logger.warn("note_zone_boss_kill write failed: %v", e);
  }
  return JSON.stringify({
    ok: true,
    success: true,
    hub_id,
    zone_kills: schedule.zone_kills[hub_id],
    next_spawn_unix: schedule.next_spawn_unix,
  });
};

export function register_world_boss_rpc(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {



  logger.info("world_boss_rpc module loaded");
}
