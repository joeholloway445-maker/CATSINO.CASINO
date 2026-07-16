/** Shared wallet helpers — all casino/economy RPCs use the `coins` currency. */

export const CURRENCY_COINS = "coins";
export const CURRENCY_GEMS = "gems";

export function spendCoins(
  nk: nkruntime.Nakama,
  userId: string,
  amount: number,
  reason: string
): void {
  if (amount <= 0) throw new Error("Invalid amount");
  try {
    nk.walletUpdate(userId, { [CURRENCY_COINS]: -Math.floor(amount) }, { reason }, true);
  } catch (_e) {
    throw new Error("Insufficient coins");
  }
}

export function payCoins(
  nk: nkruntime.Nakama,
  userId: string,
  amount: number,
  reason: string
): void {
  if (amount <= 0) return;
  nk.walletUpdate(userId, { [CURRENCY_COINS]: Math.floor(amount) }, { reason }, true);
}

export function cardDict(index: number): { index: number; value: number; suit: number } {
  return { index, value: index % 13, suit: Math.floor(index / 13) };
}

export function cardDicts(cards: number[]): Array<{ index: number; value: number; suit: number }> {
  return cards.map(cardDict);
}

export function normalizeHeld(data: { held?: boolean[]; held_indices?: number[] }): boolean[] {
  if (Array.isArray(data.held)) {
    const out = data.held.map(Boolean);
    while (out.length < 5) out.push(false);
    return out.slice(0, 5);
  }
  const flags = [false, false, false, false, false];
  for (const idx of data.held_indices ?? []) {
    const i = Math.floor(Number(idx));
    if (i >= 0 && i < 5) flags[i] = true;
  }
  return flags;
}

export function ok(extra: Record<string, unknown> = {}): string {
  return JSON.stringify({ success: true, ...extra });
}
