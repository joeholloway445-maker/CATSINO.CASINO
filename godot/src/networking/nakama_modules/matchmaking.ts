// matchmaking.ts
// Nakama server-side runtime module — match creation and lifecycle for CATSINO.CASINO
// Implements a state-machine match: LOBBY → PLAYING → RESULTS

// ─── Constants ────────────────────────────────────────────────────────────────
const MAX_PLAYERS = 8;
const LOBBY_WAIT_SEC = 30;       // seconds to wait in lobby before force-starting
const RESULTS_DISPLAY_SEC = 10;  // seconds to display results before terminating
const TICK_RATE = 5;             // match loop ticks per second

// ─── Match state machine ──────────────────────────────────────────────────────
const enum MatchPhase {
  LOBBY = 0,
  PLAYING = 1,
  RESULTS = 2,
}

// ─── Op-codes for match messages ──────────────────────────────────────────────
const OpCode = {
  PHASE_CHANGE: 1,
  PLAYER_JOINED: 2,
  PLAYER_LEFT: 3,
  GAME_ACTION: 4,
  RESULT_UPDATE: 5,
  MATCH_METADATA: 6,
} as const;

// ─── Match state ─────────────────────────────────────────────────────────────
interface MatchState {
  phase: MatchPhase;
  players: Record<string, PlayerState>;
  game_type: string;
  tick: number;
  lobby_start_tick: number;
  playing_start_tick: number;
  results_start_tick: number;
  results: Record<string, PlayerResult>;
}

interface PlayerState {
  user_id: string;
  display_name: string;
  presence: nkruntime.Presence;
  ready: boolean;
  score: number;
}

interface PlayerResult {
  user_id: string;
  score: number;
  rank: number;
  coins_won: number;
}

// ─── RPC: Find or create match ───────────────────────────────────────────────
export function rpcFindMatch(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
): string {
  let game_type = "slots";
  try {
    const data = JSON.parse(payload);
    game_type = data.game_type ?? "slots";
  } catch (_) {
    // use default
  }

  // Search for an existing LOBBY-phase match with space
  const matches = nk.matchList(10, true, `${game_type}`, undefined, MAX_PLAYERS - 1, "*");

  if (matches.length > 0) {
    const match = matches[0];
    logger.info("FindMatch: user=%s joining existing match=%s", ctx.userId, match.matchId);
    return JSON.stringify({ ok: true, match_id: match.matchId, created: false });
  }

  // Create new match
  const match_id = nk.matchCreate("catsino_match", { game_type });
  logger.info("FindMatch: user=%s created new match=%s game_type=%s", ctx.userId, match_id, game_type);
  return JSON.stringify({ ok: true, match_id, created: true });
};

// ─── Match handlers ───────────────────────────────────────────────────────────
export function catsinoMatchInit(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  params: Record<string, string>
): { state: MatchState; tickRate: number; label: string } {
  const state: MatchState = {
    phase: MatchPhase.LOBBY,
    players: {},
    game_type: params["game_type"] ?? "slots",
    tick: 0,
    lobby_start_tick: 0,
    playing_start_tick: 0,
    results_start_tick: 0,
    results: {},
  };

  logger.info("matchInit: game_type=%s", state.game_type);

  return {
    state,
    tickRate: TICK_RATE,
    label: state.game_type,
  };
};

export function catsinoMatchJoinAttempt(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: MatchState,
  presence: nkruntime.Presence,
  metadata: Record<string, string>
): { state: MatchState; accept: boolean; rejectMessage?: string } {
  // Reject if match is in RESULTS phase
  if (state.phase === MatchPhase.RESULTS) {
    return { state, accept: false, rejectMessage: "Match already finished" };
  }

  // Reject if at capacity
  const playerCount = Object.keys(state.players).length;
  if (playerCount >= MAX_PLAYERS) {
    return { state, accept: false, rejectMessage: "Match is full" };
  }

  return { state, accept: true };
};

export function catsinoMatchJoin(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: MatchState,
  presences: nkruntime.Presence[]
): { state: MatchState } | null {
  for (const presence of presences) {
    const account = nk.accountGetId(presence.userId);
    state.players[presence.userId] = {
      user_id: presence.userId,
      display_name: account.user.displayName ?? presence.username,
      presence,
      ready: false,
      score: 0,
    };

    logger.info("matchJoin: user=%s joined match tick=%d", presence.userId, tick);

    // Notify all existing players
    dispatcher.broadcastMessage(
      OpCode.PLAYER_JOINED,
      JSON.stringify({ user_id: presence.userId, display_name: account.user.displayName }),
      null,
      null,
      true
    );

    // Send current match state to the joining player
    dispatcher.broadcastMessage(
      OpCode.MATCH_METADATA,
      JSON.stringify({
        phase: state.phase,
        game_type: state.game_type,
        player_count: Object.keys(state.players).length,
        max_players: MAX_PLAYERS,
      }),
      [presence],
      null,
      true
    );
  }

  // Auto-start if full
  if (Object.keys(state.players).length >= MAX_PLAYERS && state.phase === MatchPhase.LOBBY) {
    state = _startPlaying(state, tick, dispatcher);
  }

  return { state };
};

export function catsinoMatchLeave(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: MatchState,
  presences: nkruntime.Presence[]
): { state: MatchState } | null {
  for (const presence of presences) {
    delete state.players[presence.userId];
    logger.info("matchLeave: user=%s left tick=%d", presence.userId, tick);

    dispatcher.broadcastMessage(
      OpCode.PLAYER_LEFT,
      JSON.stringify({ user_id: presence.userId }),
      null,
      null,
      true
    );
  }

  // If everyone left during lobby or playing, terminate
  if (Object.keys(state.players).length === 0) {
    return null;
  }

  return { state };
};

export function catsinoMatchLoop(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: MatchState,
  messages: nkruntime.MatchMessage[]
): { state: MatchState } | null {
  state.tick = tick;

  // Process incoming messages
  for (const msg of messages) {
    if (msg.opCode === OpCode.GAME_ACTION) {
      _handleGameAction(state, msg, dispatcher, nk, logger);
    }
  }

  // Phase transitions
  if (state.phase === MatchPhase.LOBBY) {
    const elapsed_sec = (tick - state.lobby_start_tick) / TICK_RATE;
    const player_count = Object.keys(state.players).length;

    // Start if enough time has passed and at least 1 player
    if (elapsed_sec >= LOBBY_WAIT_SEC && player_count > 0) {
      state = _startPlaying(state, tick, dispatcher);
    }
  } else if (state.phase === MatchPhase.PLAYING) {
    // Game loop logic — in a real game this drives round timers, etc.
    // For slots: all actions are individual, so just track score updates
    // (handled in _handleGameAction)

    // Check if game is over (e.g., after 3 minutes of play)
    const elapsed_sec = (tick - state.playing_start_tick) / TICK_RATE;
    if (elapsed_sec >= 180) {
      state = _startResults(state, tick, dispatcher, nk, ctx);
    }
  } else if (state.phase === MatchPhase.RESULTS) {
    const elapsed_sec = (tick - state.results_start_tick) / TICK_RATE;
    if (elapsed_sec >= RESULTS_DISPLAY_SEC) {
      logger.info("matchLoop: match complete, terminating tick=%d", tick);
      return null; // Terminate match
    }
  }

  return { state };
};

export function catsinoMatchTerminate(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher,
  tick: number,
  state: MatchState,
  graceSeconds: number
): { state: MatchState } | null {
  logger.info("matchTerminate: gracePeriod=%d tick=%d", graceSeconds, tick);
  dispatcher.broadcastMessage(
    OpCode.PHASE_CHANGE,
    JSON.stringify({ phase: "TERMINATED" }),
    null,
    null,
    false
  );
  return { state };
};

/** Required by Nakama 3.21+ registerMatch — no-op passthrough for external signals. */
export function catsinoMatchSignal(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _dispatcher: nkruntime.MatchDispatcher,
  _tick: number,
  state: MatchState,
  _data: string
): { state: MatchState } {
  return { state };
};

// ─── Internal helpers ─────────────────────────────────────────────────────────
function _startPlaying(
  state: MatchState,
  tick: number,
  dispatcher: nkruntime.MatchDispatcher
): MatchState {
  state.phase = MatchPhase.PLAYING;
  state.playing_start_tick = tick;
  dispatcher.broadcastMessage(
    OpCode.PHASE_CHANGE,
    JSON.stringify({ phase: "PLAYING" }),
    null,
    null,
    true
  );
  return state;
}

function _startResults(
  state: MatchState,
  tick: number,
  dispatcher: nkruntime.MatchDispatcher,
  nk: nkruntime.Nakama,
  ctx: nkruntime.Context
): MatchState {
  state.phase = MatchPhase.RESULTS;
  state.results_start_tick = tick;

  // Rank players by score
  const sorted = Object.values(state.players).sort((a, b) => b.score - a.score);
  for (let i = 0; i < sorted.length; i++) {
    const player = sorted[i];
    const rank = i + 1;
    const coins_won = rank === 1 ? 1000 : rank === 2 ? 500 : rank === 3 ? 250 : 0;

    state.results[player.user_id] = {
      user_id: player.user_id,
      score: player.score,
      rank,
      coins_won,
    };

    // Credit winnings
    if (coins_won > 0) {
      const changeset: Record<string, number> = { coins: coins_won };
      nk.walletUpdate(player.user_id, changeset, { reason: "match_result", rank }, true);
    }
  }

  dispatcher.broadcastMessage(
    OpCode.PHASE_CHANGE,
    JSON.stringify({ phase: "RESULTS", results: state.results }),
    null,
    null,
    true
  );

  return state;
}

function _handleGameAction(
  state: MatchState,
  msg: nkruntime.MatchMessage,
  dispatcher: nkruntime.MatchDispatcher,
  nk: nkruntime.Nakama,
  logger: nkruntime.Logger
): void {
  if (state.phase !== MatchPhase.PLAYING) return;

  let action: Record<string, unknown>;
  try {
    action = JSON.parse(nk.binaryToString(msg.data));
  } catch (_) {
    return;
  }

  const player = state.players[msg.sender.userId];
  if (!player) return;

  // Action: score update from a local game outcome
  if (action["type"] === "score_update") {
    const delta = Number(action["delta"] ?? 0);
    player.score += delta;

    dispatcher.broadcastMessage(
      OpCode.RESULT_UPDATE,
      JSON.stringify({ user_id: msg.sender.userId, score: player.score }),
      null,
      null,
      true
    );
  }
}

// ─── Module initializer ───────────────────────────────────────────────────────
export function register_matchmaking(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {

  logger.info("matchmaking module loaded — match: catsino_match, rpc: find_match");
}

// @ts-ignore
