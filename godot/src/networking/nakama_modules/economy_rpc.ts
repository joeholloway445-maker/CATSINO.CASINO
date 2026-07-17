// economy_rpc.ts
// Nakama server-side runtime module — Cat Coins economy (server-authoritative)
// Deploy to Nakama's TypeScript runtime directory.

// ─── Type shims for Nakama runtime ───────────────────────────────────────────
declare const nk: nkruntime.Nakama;
declare const logger: nkruntime.Logger;

// ─── Constants ────────────────────────────────────────────────────────────────
const COLLECTION_ECONOMY = "economy";
const KEY_DAILY_BONUS = "daily_bonus";
const CURRENCY_COINS = "coins";
const CURRENCY_GEMS = "gems";

const DAILY_BONUS_COOLDOWN_SEC = 20 * 60 * 60; // 20 hours
const DAILY_BONUS_BASE = 500;
const DAILY_BONUS_PER_STREAK = 100;
const DAILY_BONUS_MAX_STREAK = 30;

// ─── Payload / response helpers ───────────────────────────────────────────────
interface EarnCoinsPayload {
  amount: number;
  reason: string;
}

interface SpendCoinsPayload {
  amount: number;
  reason: string;
}

interface DailyBonusState {
  last_claim_sec: number;
  streak: number;
}

interface WalletResponse {
  coins: number;
  gems: number;
}

function parsePayload<T>(payload: string): T {
  try {
    return JSON.parse(payload) as T;
  } catch (e) {
    throw new Error("Invalid JSON payload: " + e);
  }
}

function jsonResponse(obj: object): string {
  return JSON.stringify(obj);
}

function getWalletBalances(
  ctx: nkruntime.Context,
  nk: nkruntime.Nakama
): WalletResponse {
  const account = nk.accountGetId(ctx.userId);
  const wallet = account.wallet as Record<string, number>;
  return {
    coins: wallet[CURRENCY_COINS] ?? 0,
    gems: wallet[CURRENCY_GEMS] ?? 0,
  };
}

// ─── RPC: Earn Coins ──────────────────────────────────────────────────────────
// Called when the server wants to credit coins (e.g., match reward, event payout).
// Clients SHOULD NOT call this directly — use server-to-server or Nakama hooks.
function rpcEarnCoins(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
): string {
  if (!ctx.userId) {
    throw new Error("No user context");
  }

  const data = parsePayload<EarnCoinsPayload>(payload);
  if (!data.amount || data.amount <= 0) {
    throw new Error("amount must be a positive integer");
  }
  if (data.amount > 100_000) {
    throw new Error("amount exceeds single-transaction maximum");
  }

  const changeset: Record<string, number> = {};
  changeset[CURRENCY_COINS] = Math.floor(data.amount);

  const metadata = {
    reason: data.reason ?? "earn",
    ts: Date.now(),
  };

  nk.walletUpdate(ctx.userId, changeset, metadata, true);

  logger.info("EarnCoins: user=%s amount=%d reason=%s", ctx.userId, data.amount, data.reason);

  const balances = getWalletBalances(ctx, nk);
  return jsonResponse({ ok: true, coins: balances.coins, gems: balances.gems });
};

// ─── RPC: Spend Coins ─────────────────────────────────────────────────────────
// Validates balance before deducting. Returns error if insufficient funds.
function rpcSpendCoins(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
): string {
  if (!ctx.userId) {
    throw new Error("No user context");
  }

  const data = parsePayload<SpendCoinsPayload>(payload);
  if (!data.amount || data.amount <= 0) {
    throw new Error("amount must be a positive integer");
  }

  const balances = getWalletBalances(ctx, nk);
  if (balances.coins < data.amount) {
    return jsonResponse({
      ok: false,
      error: "insufficient_coins",
      coins: balances.coins,
      gems: balances.gems,
    });
  }

  const changeset: Record<string, number> = {};
  changeset[CURRENCY_COINS] = -Math.floor(data.amount);

  const metadata = {
    reason: data.reason ?? "spend",
    ts: Date.now(),
  };

  nk.walletUpdate(ctx.userId, changeset, metadata, true);

  logger.info("SpendCoins: user=%s amount=%d reason=%s", ctx.userId, data.amount, data.reason);

  const newBalances = getWalletBalances(ctx, nk);
  return jsonResponse({ ok: true, coins: newBalances.coins, gems: newBalances.gems });
};

// ─── RPC: Get Wallet ──────────────────────────────────────────────────────────
function rpcGetWallet(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  _payload: string
): string {
  if (!ctx.userId) {
    throw new Error("No user context");
  }

  const balances = getWalletBalances(ctx, nk);
  logger.debug("GetWallet: user=%s coins=%d gems=%d", ctx.userId, balances.coins, balances.gems);

  // Also return recent ledger entries (last 10)
  const ledger = nk.walletLedgerList(ctx.userId, 10);
  const history = ledger.items.map((entry) => ({
    id: entry.id,
    changeset: entry.changeset,
    metadata: entry.metadata,
    create_time: entry.createTime,
  }));

  return jsonResponse({
    ok: true,
    success: true,
    coins: balances.coins,
    gems: balances.gems,
    cat_coins: balances.coins, // alias for legacy HUD readers
    balances: {
      coins: balances.coins,
      gems: balances.gems,
      cat_coins: balances.coins,
    },
    history,
  });
};

// ─── RPC: Daily Bonus ────────────────────────────────────────────────────────
// 20-hour cooldown with streak tracking.
// Grants DAILY_BONUS_BASE + streak * DAILY_BONUS_PER_STREAK coins.
function rpcDailyBonus(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  _payload: string
): string {
  if (!ctx.userId) {
    throw new Error("No user context");
  }

  const nowSec = Math.floor(Date.now() / 1000);

  // Read current streak state from storage
  let state: DailyBonusState = { last_claim_sec: 0, streak: 0 };
  const records = nk.storageRead([
    {
      collection: COLLECTION_ECONOMY,
      key: KEY_DAILY_BONUS,
      userId: ctx.userId,
    },
  ]);

  if (records.length > 0 && records[0].value) {
    state = records[0].value as DailyBonusState;
  }

  // Cooldown check
  const elapsed = nowSec - (state.last_claim_sec ?? 0);
  if (elapsed < DAILY_BONUS_COOLDOWN_SEC) {
    const remaining = DAILY_BONUS_COOLDOWN_SEC - elapsed;
    return jsonResponse({
      ok: false,
      error: "cooldown",
      cooldown_remaining_sec: remaining,
    });
  }

  // Streak logic: if within 48h window, extend streak; otherwise reset
  const streak_window_sec = 48 * 60 * 60;
  let new_streak: number;
  if (elapsed <= streak_window_sec) {
    new_streak = Math.min((state.streak ?? 0) + 1, DAILY_BONUS_MAX_STREAK);
  } else {
    new_streak = 1; // streak broken
  }

  const bonus_amount = DAILY_BONUS_BASE + (new_streak - 1) * DAILY_BONUS_PER_STREAK;

  // Credit coins
  const changeset: Record<string, number> = {};
  changeset[CURRENCY_COINS] = bonus_amount;
  nk.walletUpdate(ctx.userId, changeset, { reason: "daily_bonus", streak: new_streak }, true);

  // Persist updated streak state
  const newState: DailyBonusState = {
    last_claim_sec: nowSec,
    streak: new_streak,
  };

  nk.storageWrite([
    {
      collection: COLLECTION_ECONOMY,
      key: KEY_DAILY_BONUS,
      userId: ctx.userId,
      value: newState,
      permissionRead: 1,
      permissionWrite: 0, // server-only write
    },
  ]);

  logger.info(
    "DailyBonus: user=%s streak=%d bonus=%d",
    ctx.userId,
    new_streak,
    bonus_amount
  );

  const balances = getWalletBalances(ctx, nk);
  return jsonResponse({
    ok: true,
    bonus_amount,
    streak: new_streak,
    coins: balances.coins,
    gems: balances.gems,
  });
};

// ─── Module initializer ───────────────────────────────────────────────────────
// Nakama TypeScript runtime requires a default export that registers RPCs.
export function register_economy_rpc(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  initializer.registerRpc("earn_coins", rpcEarnCoins);
  initializer.registerRpc("spend_coins", rpcSpendCoins);
  initializer.registerRpc("get_wallet", rpcGetWallet);
  initializer.registerRpc("daily_bonus", rpcDailyBonus);

  logger.info("economy_rpc module loaded — RPCs: earn_coins, spend_coins, get_wallet, daily_bonus");
}

// @ts-ignore — Nakama runtime picks this up automatically
