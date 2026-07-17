// layer_presence.ts — Gate 8 open-world presence.
// One Nakama match per reality layer (label = layer_id). Clients RPC
// join_layer_presence → real match UUID → join_match_async. Position
// broadcasts are relayed; counts land in storage for district HUD polls.

const TICK_RATE = 1;
const MAX_PRESENCES = 64;
const Op = {
  POSITION: 1,
  HELLO: 2,
} as const;

interface PresencePlayer {
  user_id: string;
  username: string;
  presence: nkruntime.Presence;
  x: number;
  y: number;
  z: number;
  profile: Record<string, unknown>;
}

interface LayerState {
  layer_id: string;
  players: Record<string, PresencePlayer>;
  tick: number;
}

const LAYER_TO_DISTRICT: Record<string, string> = {
  hyperliminal: "paw_vegas",
  liminal: "neon_alley",
  supraliminal: "cat_forest",
  extraliminal: "cat_coliseum",
  periliminal: "arcade_galaxy",
  // subliminal stays private — no district mapping
};

function writeLayerCounts(nk: nkruntime.Nakama, logger: nkruntime.Logger, layer_id: string, count: number): void {
  const systemUser = "00000000-0000-0000-0000-000000000000";
  let layers: Record<string, number> = {};
  try {
    const existing = nk.storageRead([{
      collection: "layer_presence",
      key: "active_counts",
      userId: systemUser,
    }]);
    if (existing.length > 0 && existing[0].value) {
      layers = existing[0].value as Record<string, number>;
    }
  } catch (e) {
    logger.warn("layer_presence: read layer counts failed: %v", e);
  }
  layers[layer_id] = count;
  try {
    nk.storageWrite([{
      collection: "layer_presence",
      key: "active_counts",
      userId: systemUser,
      value: layers,
      permissionRead: 2,
      permissionWrite: 0,
    }]);
  } catch (e) {
    logger.warn("layer_presence: write layer counts failed: %v", e);
  }

  const district = LAYER_TO_DISTRICT[layer_id];
  if (!district) {
    return;
  }
  let districts: Record<string, number> = {
    paw_vegas: 0,
    neon_alley: 0,
    cat_coliseum: 0,
    arcade_galaxy: 0,
    cat_forest: 0,
  };
  try {
    const existing = nk.storageRead([{
      collection: "districts",
      key: "active_counts",
      userId: systemUser,
    }]);
    if (existing.length > 0 && existing[0].value) {
      districts = { ...districts, ...(existing[0].value as Record<string, number>) };
    }
  } catch (e) {
    logger.warn("layer_presence: read district counts failed: %v", e);
  }
  districts[district] = count;
  try {
    nk.storageWrite([{
      collection: "districts",
      key: "active_counts",
      userId: systemUser,
      value: districts,
      permissionRead: 2,
      permissionWrite: 0,
    }]);
  } catch (e) {
    logger.warn("layer_presence: write district counts failed: %v", e);
  }
}

const rpcJoinLayerPresence: nkruntime.RpcFunction = function (ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("Not authenticated");
  }
  let layer_id = "liminal";
  try {
    const data = JSON.parse(payload || "{}");
    layer_id = String(data.layer_id || data.layer || "liminal");
  } catch (_) {
    // default
  }
  if (!layer_id || layer_id === "subliminal") {
    // Private apartment — no shared match.
    return JSON.stringify({ ok: true, match_id: "", private: true });
  }

  const label = `layer_${layer_id}`;
  const matches = nk.matchList(10, true, label, undefined, MAX_PRESENCES - 1, "*");
  if (matches.length > 0) {
    logger.info("join_layer_presence: user=%s join existing %s (%s)", ctx.userId, matches[0].matchId, label);
    return JSON.stringify({ ok: true, match_id: matches[0].matchId, created: false, layer_id });
  }
  const match_id = nk.matchCreate("layer_presence", { layer_id });
  logger.info("join_layer_presence: user=%s create %s (%s)", ctx.userId, match_id, label);
  return JSON.stringify({ ok: true, match_id, created: true, layer_id });
};

const rpcGetLayerPresenceCounts: nkruntime.RpcFunction = function (_ctx, logger, nk, _payload) {
  const systemUser = "00000000-0000-0000-0000-000000000000";
  try {
    const existing = nk.storageRead([{
      collection: "layer_presence",
      key: "active_counts",
      userId: systemUser,
    }]);
    const layers = existing.length > 0 ? existing[0].value : {};
    return JSON.stringify({ ok: true, layers });
  } catch (e) {
    logger.warn("get_layer_presence_counts failed: %v", e);
    return JSON.stringify({ ok: true, layers: {} });
  }
};

const matchInit: nkruntime.MatchInitFunction<LayerState> = function (_ctx, logger, _nk, params) {
  const layer_id = String(params["layer_id"] || "liminal");
  const state: LayerState = { layer_id, players: {}, tick: 0 };
  logger.info("layer_presence init layer=%s", layer_id);
  return { state, tickRate: TICK_RATE, label: `layer_${layer_id}` };
};

const matchJoinAttempt: nkruntime.MatchJoinAttemptFunction<LayerState> = function (
  _ctx, _logger, _nk, _dispatcher, _tick, state, _presence, _metadata
) {
  const n = Object.keys(state.players).length;
  return { state, accept: n < MAX_PRESENCES };
};

const matchJoin: nkruntime.MatchJoinFunction<LayerState> = function (
  _ctx, logger, nk, dispatcher, _tick, state, presences
) {
  for (const p of presences) {
    state.players[p.userId] = {
      user_id: p.userId,
      username: p.username || p.userId,
      presence: p,
      x: 0, y: 0, z: 0,
      profile: {},
    };
    dispatcher.broadcastMessage(Op.HELLO, JSON.stringify({
      id: p.username || p.userId,
      user_id: p.userId,
      layer_id: state.layer_id,
    }), null, null, true);
  }
  writeLayerCounts(nk, logger, state.layer_id, Object.keys(state.players).length);
  return { state };
};

const matchLeave: nkruntime.MatchLeaveFunction<LayerState> = function (
  _ctx, logger, nk, _dispatcher, _tick, state, presences
) {
  for (const p of presences) {
    delete state.players[p.userId];
  }
  writeLayerCounts(nk, logger, state.layer_id, Object.keys(state.players).length);
  return { state };
};

const matchLoop: nkruntime.MatchLoopFunction<LayerState> = function (
  _ctx, _logger, _nk, dispatcher, _tick, state, messages
) {
  state.tick += 1;
  for (const msg of messages) {
    if (msg.opCode !== Op.POSITION) {
      continue;
    }
    let data: Record<string, unknown> = {};
    try {
      data = JSON.parse(msg.data || "{}");
    } catch (_) {
      continue;
    }
    const uid = msg.sender.userId;
    const player = state.players[uid];
    if (!player) {
      continue;
    }
    const pos = data["pos"];
    if (Array.isArray(pos) && pos.length >= 3) {
      player.x = Number(pos[0]) || 0;
      player.y = Number(pos[1]) || 0;
      player.z = Number(pos[2]) || 0;
    }
    if (data["profile"] && typeof data["profile"] === "object") {
      player.profile = data["profile"] as Record<string, unknown>;
    }
    if (typeof data["id"] === "string" && data["id"]) {
      player.username = String(data["id"]);
    }
    // Relay to everyone else in the layer.
    dispatcher.broadcastMessage(Op.POSITION, JSON.stringify({
      id: player.username,
      user_id: uid,
      pos: [player.x, player.y, player.z],
      profile: player.profile,
    }), null, msg.sender, true);
  }
  return { state };
};

const matchTerminate: nkruntime.MatchTerminateFunction<LayerState> = function (
  _ctx, logger, nk, _dispatcher, _tick, state, _grace
) {
  writeLayerCounts(nk, logger, state.layer_id, 0);
  logger.info("layer_presence terminate layer=%s", state.layer_id);
  return { state };
};

export function register_layer_presence(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  initializer.registerRpc("join_layer_presence", rpcJoinLayerPresence);
  initializer.registerRpc("get_layer_presence_counts", rpcGetLayerPresenceCounts);
  initializer.registerMatch("layer_presence", {
    matchInit,
    matchJoinAttempt,
    matchJoin,
    matchLeave,
    matchLoop,
    matchTerminate,
  });
  logger.info("layer_presence module loaded — rpc: join_layer_presence, match: layer_presence");
}
