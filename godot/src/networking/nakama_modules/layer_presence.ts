// layer_presence.ts — Gate 8 open-world presence.
// One long-lived Nakama match per reality layer. Clients broadcast
// positions (op 1); the server just keeps the room open and relays.

const TICK_RATE = 1;
const LABEL_PREFIX = "layer:";

interface LayerState {
  layer_id: string;
  tick: number;
  joins: number;
}

export function rpcFindOrCreateLayerMatch(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
): string {
  let layer_id = "liminal";
  try {
    const data = JSON.parse(payload || "{}");
    layer_id = String(data.layer_id ?? data.layer ?? "liminal");
  } catch (_) {
    // default
  }
  // Menus / apartment stay solo — refuse to create crowded rooms.
  if (layer_id === "hyperliminal" || layer_id === "subliminal") {
    return JSON.stringify({
      success: true,
      ok: true,
      match_id: "",
      layer_id,
      solo: true,
      created: false,
    });
  }

  const label = `${LABEL_PREFIX}${layer_id}`;
  const matches = nk.matchList(20, true, label, undefined, undefined, "*");
  if (matches.length > 0) {
    const match = matches[0];
    logger.info(
      "LayerPresence: user=%s join existing layer=%s match=%s",
      ctx.userId,
      layer_id,
      match.matchId
    );
    return JSON.stringify({
      success: true,
      ok: true,
      match_id: match.matchId,
      layer_id,
      created: false,
      size: match.size,
    });
  }

  const match_id = nk.matchCreate("layer_presence", { layer_id });
  logger.info(
    "LayerPresence: user=%s created layer=%s match=%s",
    ctx.userId,
    layer_id,
    match_id
  );
  return JSON.stringify({
    success: true,
    ok: true,
    match_id,
    layer_id,
    created: true,
    size: 0,
  });
};

export function layerMatchInit(
  _ctx,
  logger,
  _nk,
  params
) {
  const layer_id = String(params["layer_id"] ?? "liminal");
  logger.info("LayerPresence matchInit layer=%s", layer_id);
  return {
    state: { layer_id, tick: 0, joins: 0 },
    tickRate: TICK_RATE,
    label: `${LABEL_PREFIX}${layer_id}`,
  };
};

export function layerMatchJoinAttempt(
  _ctx,
  _logger,
  _nk,
  _dispatcher,
  _tick,
  state,
  _presence,
  _metadata
) {
  return { state, accept: true };
};

export function layerMatchJoin(
  _ctx,
  logger,
  _nk,
  _dispatcher,
  _tick,
  state,
  presences
) {
  state.joins += presences.length;
  for (const p of presences) {
    logger.info("LayerPresence join user=%s layer=%s", p.userId, state.layer_id);
  }
  return { state };
};

export function layerMatchLeave(
  _ctx,
  logger,
  _nk,
  _dispatcher,
  _tick,
  state,
  presences
) {
  for (const p of presences) {
    logger.info("LayerPresence leave user=%s layer=%s", p.userId, state.layer_id);
  }
  return { state };
};

export function layerMatchLoop(
  _ctx,
  _logger,
  _nk,
  dispatcher,
  _tick,
  state,
  messages
) {
  state.tick += 1;
  // Relay client position broadcasts to everyone else in the room.
  for (const msg of messages) {
    dispatcher.broadcastMessage(msg.opCode, msg.data, null, msg.sender, true);
  }
  return { state };
};

export function layerMatchTerminate(
  _ctx,
  _logger,
  _nk,
  _dispatcher,
  _tick,
  state,
  _grace
) {
  return { state };
};

export function layerMatchSignal(
  _ctx,
  _logger,
  _nk,
  _dispatcher,
  _tick,
  state,
  _data
) {
  return { state };
};

export function register_layer_presence(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  logger.info("layer_presence module loaded — rpc: find_or_create_layer_match, match: layer_presence");
}
