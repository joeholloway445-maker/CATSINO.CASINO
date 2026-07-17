// Hideout online parity (Gate 8) — authoritative claim / contest / site sync.
// Storage is global (SYSTEM_USER) so all clients share the same territory map.
// Token spend stays on the client (EconomyManager); the server owns ownership
// + exclusion radius so two guilds cannot both hold overlapping sites.

const SYSTEM_USER = "00000000-0000-0000-0000-000000000000";
const COLLECTION = "hideouts";
const MIN_DISTANCE = 220.0;
const CLAIM_COST_TOKENS = 500;
const CONQUEST_REWARD_TOKENS = 40;

interface HideoutSite {
    site_id: string;
    realm: string;
    hub: string;
    pos: number[]; // [x, z]
    owner: string;
    banner: boolean;
    defenders: string[];
    claimed_by?: string;
    claimed_at?: number;
    updated_at?: number;
}

interface UpsertPayload {
    site_id?: string;
    realm?: string;
    hub?: string;
    pos?: number[] | { x?: number; z?: number };
}

interface ClaimPayload {
    site_id?: string;
    guild?: string;
}

interface ContestPayload {
    site_id?: string;
    attacker_guild?: string;
}

interface BannerPayload {
    site_id?: string;
    banner?: boolean;
}

interface GetPayload {
    site_id?: string;
    realm?: string;
}

function _fail(error: string, extra: Record<string, unknown> = {}): string {
    return JSON.stringify({ success: false, ok: false, error, ...extra });
}

function _ok(extra: Record<string, unknown> = {}): string {
    return JSON.stringify({ success: true, ok: true, ...extra });
}

function _readSite(nk: nkruntime.Nakama, siteId: string): HideoutSite | null {
    try {
        const stored = nk.storageRead([{
            collection: COLLECTION,
            key: siteId,
            userId: SYSTEM_USER
        }]);
        if (stored.length > 0 && stored[0].value) {
            return stored[0].value as unknown as HideoutSite;
        }
    } catch (_e) { /* miss */ }
    return null;
}

function _writeSite(nk: nkruntime.Nakama, site: HideoutSite): void {
    nk.storageWrite([{
        collection: COLLECTION,
        key: site.site_id,
        userId: SYSTEM_USER,
        value: site as unknown as {[key: string]: unknown},
        permissionRead: 2,
        permissionWrite: 0
    }]);
}

function _listSites(nk: nkruntime.Nakama, logger: nkruntime.Logger, realm?: string): HideoutSite[] {
    const out: HideoutSite[] = [];
    try {
        let cursor: string | undefined = undefined;
        do {
            const page = nk.storageList(SYSTEM_USER, COLLECTION, 100, cursor);
            for (const obj of page.objects ?? []) {
                const site = obj.value as unknown as HideoutSite;
                if (!site || !site.site_id) continue;
                if (realm && String(site.realm || "") !== realm) continue;
                out.push(site);
            }
            cursor = page.cursor;
        } while (cursor);
    } catch (e) {
        logger.warn("hideout_list: soft-fail: %v", e);
    }
    return out;
}

function _normalizePos(raw: UpsertPayload["pos"]): number[] {
    if (Array.isArray(raw) && raw.length >= 2) {
        return [Number(raw[0]) || 0, Number(raw[1]) || 0];
    }
    if (raw && typeof raw === "object") {
        const o = raw as { x?: number; z?: number };
        return [Number(o.x) || 0, Number(o.z) || 0];
    }
    return [0, 0];
}

function _canClaim(
    sites: HideoutSite[],
    site: HideoutSite,
    guild: string
): { ok: boolean; reason: string } {
    const owner = String(site.owner || "");
    if (owner !== "") {
        return {
            ok: false,
            reason: `${owner} holds this ground. Defeat their defenders to take it.`
        };
    }
    const myPos = [Number(site.pos?.[0]) || 0, Number(site.pos?.[1]) || 0];
    for (const other of sites) {
        if (other.site_id === site.site_id) continue;
        const oOwner = String(other.owner || "");
        if (oOwner === "" || oOwner === guild) continue;
        if (String(other.realm || "") !== String(site.realm || "")) continue;
        const oPos = [Number(other.pos?.[0]) || 0, Number(other.pos?.[1]) || 0];
        const dx = myPos[0] - oPos[0];
        const dz = myPos[1] - oPos[1];
        if (Math.sqrt(dx * dx + dz * dz) < MIN_DISTANCE) {
            return {
                ok: false,
                reason: `Too close to ${oOwner} territory — no two guilds build within the same distance. Take theirs instead.`
            };
        }
    }
    return { ok: true, reason: "" };
}

export function rpcHideoutUpsertSite(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    if (!ctx.userId) return _fail("Not authenticated");

    let data: UpsertPayload;
    try {
        data = JSON.parse(payload || "{}");
    } catch (_e) {
        return _fail("Invalid JSON payload");
    }

    const siteId = String(data.site_id || "").trim();
    if (!siteId) return _fail("site_id required");

    const prior = _readSite(nk, siteId);
    const pos = _normalizePos(data.pos);
    const site: HideoutSite = {
        site_id: siteId,
        realm: String(data.realm || prior?.realm || "supraliminal"),
        hub: String(data.hub || prior?.hub || ""),
        pos,
        owner: prior?.owner || "",
        banner: prior?.banner !== undefined ? Boolean(prior.banner) : true,
        defenders: Array.isArray(prior?.defenders) ? prior!.defenders : [],
        claimed_by: prior?.claimed_by,
        claimed_at: prior?.claimed_at,
        updated_at: Date.now()
    };

    try {
        _writeSite(nk, site);
    } catch (e) {
        logger.error("hideout_upsert_site failed for %s: %v", siteId, e);
        return _fail("Failed to upsert hideout site");
    }

    logger.info("hideout_upsert_site: %s realm=%s by %s", siteId, site.realm, ctx.userId);
    return _ok({ site, claim_cost_tokens: CLAIM_COST_TOKENS });
};

export function rpcHideoutGet(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: GetPayload = {};
    try {
        data = JSON.parse(payload || "{}");
    } catch (_e) { /* empty */ }

    const siteId = String(data.site_id || "").trim();
    if (siteId) {
        const site = _readSite(nk, siteId);
        if (!site) return _fail("Unknown site", { site_id: siteId });
        return _ok({ site });
    }

    const realm = String(data.realm || "").trim();
    const sites = _listSites(nk, logger, realm || undefined);
    return _ok({ sites, count: sites.length });
};

export function rpcHideoutClaim(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    if (!ctx.userId) return _fail("Not authenticated");

    let data: ClaimPayload;
    try {
        data = JSON.parse(payload || "{}");
    } catch (_e) {
        return _fail("Invalid JSON payload");
    }

    const siteId = String(data.site_id || "").trim();
    const guild = String(data.guild || "").trim();
    if (!siteId) return _fail("site_id required");
    if (!guild) return _fail("guild required");

    let site = _readSite(nk, siteId);
    if (!site) {
        // Allow claim-after-upsert race: create a stub so smoke / early clients work.
        site = {
            site_id: siteId,
            realm: "supraliminal",
            hub: "",
            pos: [0, 0],
            owner: "",
            banner: true,
            defenders: [],
            updated_at: Date.now()
        };
    }

    const all = _listSites(nk, logger);
    // Ensure the target site is in the exclusion scan set.
    if (!all.find((s) => s.site_id === siteId)) {
        all.push(site);
    }
    const check = _canClaim(all, site, guild);
    if (!check.ok) {
        return _fail(check.reason, { reason: "blocked", site });
    }

    site.owner = guild;
    site.claimed_by = ctx.userId;
    site.claimed_at = Date.now();
    site.updated_at = Date.now();
    try {
        _writeSite(nk, site);
    } catch (e) {
        logger.error("hideout_claim write failed for %s: %v", siteId, e);
        return _fail("Failed to claim hideout");
    }

    logger.info("hideout_claim: %s → %s by %s", siteId, guild, ctx.userId);
    return _ok({
        site,
        claimed: true,
        claim_cost_tokens: CLAIM_COST_TOKENS,
        message: `${guild} claims this hideout.`
    });
};

export function rpcHideoutContestWin(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    if (!ctx.userId) return _fail("Not authenticated");

    let data: ContestPayload;
    try {
        data = JSON.parse(payload || "{}");
    } catch (_e) {
        return _fail("Invalid JSON payload");
    }

    const siteId = String(data.site_id || "").trim();
    const attacker = String(data.attacker_guild || "").trim();
    if (!siteId) return _fail("site_id required");
    if (!attacker) return _fail("attacker_guild required");

    const site = _readSite(nk, siteId);
    if (!site) return _fail("Unknown site", { site_id: siteId });

    const holder = String(site.owner || "");
    if (holder === "" || holder === attacker) {
        return _fail("Nothing to contest", { reason: "noop", site });
    }

    const priorOwner = holder;
    site.defenders = [];
    site.owner = attacker;
    site.claimed_by = ctx.userId;
    site.claimed_at = Date.now();
    site.updated_at = Date.now();
    try {
        _writeSite(nk, site);
    } catch (e) {
        logger.error("hideout_contest_win write failed for %s: %v", siteId, e);
        return _fail("Failed to resolve contest");
    }

    logger.info("hideout_contest_win: %s %s → %s by %s", siteId, priorOwner, attacker, ctx.userId);
    return _ok({
        site,
        contested: true,
        prior_owner: priorOwner,
        conquest_reward_tokens: CONQUEST_REWARD_TOKENS,
        message: `${attacker} clears the garrison and takes the hideout from ${priorOwner}!`
    });
};

export function rpcHideoutSetBanner(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    if (!ctx.userId) return _fail("Not authenticated");

    let data: BannerPayload;
    try {
        data = JSON.parse(payload || "{}");
    } catch (_e) {
        return _fail("Invalid JSON payload");
    }

    const siteId = String(data.site_id || "").trim();
    if (!siteId) return _fail("site_id required");
    if (typeof data.banner !== "boolean") return _fail("banner bool required");

    const site = _readSite(nk, siteId);
    if (!site) return _fail("Unknown site", { site_id: siteId });

    site.banner = data.banner;
    site.updated_at = Date.now();
    try {
        _writeSite(nk, site);
    } catch (e) {
        logger.error("hideout_set_banner write failed for %s: %v", siteId, e);
        return _fail("Failed to set banner");
    }

    logger.info("hideout_set_banner: %s banner=%s by %s", siteId, site.banner, ctx.userId);
    return _ok({ site });
};

export function register_hideout_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {




    logger.info("hideout_rpc module initialized");
}
