// Real-time canvas filter engine — TypeScript port of filters/engine.py's
// CPU filters, the same pixel math proven in public/dream-deck.html.
//
// The original Python ran these through OpenCV for pyvirtualcam → OBS. In the
// browser we run them over a 2D canvas's ImageData so the Dream studio surface
// (components/studio/DreamStudio.tsx) shows the exact same filter stack the
// desktop app produces. Chains mirror config/filters.json 1:1.

export type ChainName = "scarecrow_proceedings" | "squid_round" | "full_breakdown";

export interface ChainDef {
  keys: string[];
  label: string;
  hint: string;
}

export const CHAINS: Record<ChainName, ChainDef> = {
  scarecrow_proceedings: {
    keys: ["fear_toxin", "scarecrow_warp", "vhs_glitch"],
    label: "SCARECROW PROCEEDINGS",
    hint: "fear_toxin → scarecrow_warp → vhs_glitch",
  },
  squid_round: {
    keys: ["squid_game_overlay", "chromatic_aberration"],
    label: "SQUID ROUND",
    hint: "squid_game_overlay → chromatic_aberration",
  },
  full_breakdown: {
    keys: ["mirror_fragment", "entity_static", "pixel_sort"],
    label: "FULL BREAKDOWN",
    hint: "mirror_fragment → entity_static → pixel_sort",
  },
};

export const CHAIN_ORDER: ChainName[] = ["scarecrow_proceedings", "squid_round", "full_breakdown"];
const ACCENT = [201, 71, 245];

type PixelFilter = (d: ImageData, t: number, W: number, H: number) => void;
type CtxFilter = (g: CanvasRenderingContext2D, t: number, W: number, H: number) => void;

const fx_scarecrow_warp: PixelFilter = (d, t, W, H, intensity = 0.55) => {
  const src = new Uint8ClampedArray(d.data);
  const amp = intensity * 14;
  for (let y = 0; y < H; y++) {
    const sh = Math.round(Math.sin(y * 0.03 + t * 0.08) * amp);
    for (let x = 0; x < W; x++) {
      let sx = x + sh;
      if (sx < 0) sx = 0;
      if (sx >= W) sx = W - 1;
      const di = (y * W + x) * 4, si = (y * W + sx) * 4;
      d.data[di] = src[si]; d.data[di + 1] = src[si + 1]; d.data[di + 2] = src[si + 2];
    }
  }
};

const fx_chromatic: PixelFilter = (d, _t, W, _H, shift = 7) => {
  const src = new Uint8ClampedArray(d.data);
  const s = Math.round(shift);
  for (let i = 0; i < d.data.length; i += 4) {
    const px = (i / 4) % W;
    const rIdx = i - (px > s ? s * 4 : 0), bIdx = i + (px < W - s ? s * 4 : 0);
    d.data[i] = src[rIdx]; d.data[i + 2] = src[bIdx + 2];
  }
};

const fx_fear_toxin: PixelFilter = (d, t, W, H, intensity = 0.6) => {
  const breath = 0.5 + 0.5 * Math.sin(t * 0.05);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const i = (y * W + x) * 4;
    const dx = (x - W / 2) / (W / 2), dy = (y - H / 2) / (H / 2);
    const vig = Math.max(0, 1 - (dx * dx + dy * dy) * (0.6 + breath * intensity));
    d.data[i] *= 0.7 + 0.3 * vig; d.data[i + 1] *= vig;
    d.data[i + 2] = Math.min(255, d.data[i + 2] * (1.1 + intensity * breath));
  }
};

const fx_vhs: PixelFilter = (d, _t, W, H) => {
  for (let y = 0; y < H; y += 2) for (let x = 0; x < W; x++) {
    const i = (y * W + x) * 4; d.data[i] *= 0.82; d.data[i + 1] *= 0.82; d.data[i + 2] *= 0.82;
  }
  if (Math.random() < 0.22) {
    const ty = Math.floor(Math.random() * H), th = 4 + Math.random() * 16, off = (Math.random() - 0.5) * 60 | 0;
    const src = new Uint8ClampedArray(d.data);
    for (let y = ty; y < Math.min(H, ty + th); y++) for (let x = 0; x < W; x++) {
      let sx = x + off; if (sx < 0) sx += W; if (sx >= W) sx -= W;
      const di = (y * W + x) * 4, si = (y * W + sx) * 4;
      d.data[di] = src[si]; d.data[di + 1] = src[si + 1]; d.data[di + 2] = src[si + 2];
    }
  }
};

const fx_entity_static: PixelFilter = (d, _t, _W, _H, intensity = 0.5) => {
  for (let i = 0; i < d.data.length; i += 4) {
    if (Math.random() < intensity * 0.12) {
      const n = Math.random() * 255; d.data[i] = n; d.data[i + 1] = n; d.data[i + 2] = n;
    }
  }
};

const fx_mirror: PixelFilter = (d, _t, W, H) => {
  const src = new Uint8ClampedArray(d.data);
  for (let y = 0; y < H; y++) for (let x = 0; x < W / 2; x++) {
    const i = (y * W + (W - 1 - x)) * 4, si = (y * W + x) * 4;
    d.data[i] = src[si]; d.data[i + 1] = src[si + 1]; d.data[i + 2] = src[si + 2];
  }
};

const fx_pixel_sort: PixelFilter = (d, _t, W, H, thr = 180) => {
  for (let y = 0; y < H; y++) {
    let x = 0;
    while (x < W) {
      const i = (y * W + x) * 4;
      const lum = d.data[i] * 0.3 + d.data[i + 1] * 0.59 + d.data[i + 2] * 0.11;
      if (lum > thr) {
        let end = x;
        while (end < W) {
          const j = (y * W + end) * 4;
          if (d.data[j] * 0.3 + d.data[j + 1] * 0.59 + d.data[j + 2] * 0.11 <= thr) break;
          end++;
        }
        const r = d.data[i], g = d.data[i + 1], b = d.data[i + 2];
        for (let k = x; k < end; k++) { const j = (y * W + k) * 4; d.data[j] = r; d.data[j + 1] = g; d.data[j + 2] = b; }
        x = end;
      } else x++;
    }
  }
};

const fx_squid_overlay: CtxFilter = (g, t, W, H) => {
  const remaining = 456 - (Math.floor(t / 12) % 456);
  g.save(); g.font = "bold 26px monospace"; g.textAlign = "right";
  g.fillStyle = "rgba(8,7,12,.6)"; g.fillRect(W - 220, 16, 204, 54);
  g.strokeStyle = `rgb(${ACCENT})`; g.strokeRect(W - 220, 16, 204, 54);
  g.fillStyle = "#fff"; g.fillText("PLAYERS", W - 30, 40);
  g.fillStyle = `rgb(${ACCENT})`; g.fillText(String(remaining).padStart(3, "0"), W - 30, 64);
  const frac = (t % 720) / 720; g.fillStyle = `rgb(${ACCENT})`; g.fillRect(16, 16, (W - 440) * (1 - frac), 6);
  if (Math.floor(t) % 180 < 6) { g.fillStyle = "rgba(255,255,255,.12)"; g.fillRect(0, 0, W, H); }
  g.restore();
};

const PIXEL_FILTERS: Record<string, PixelFilter> = {
  scarecrow_warp: fx_scarecrow_warp, chromatic_aberration: fx_chromatic,
  fear_toxin: fx_fear_toxin, vhs_glitch: fx_vhs, entity_static: fx_entity_static,
  mirror_fragment: fx_mirror, pixel_sort: fx_pixel_sort,
};
const CTX_FILTERS: Record<string, CtxFilter> = { squid_game_overlay: fx_squid_overlay };

/**
 * Apply a named filter chain to a 2D context in place. `t` is the frame
 * counter (drives all time-based animation). Pixel filters run first over a
 * single getImageData/putImageData pass; context filters (HUD overlays) draw
 * on top. Pass null/unknown chain to leave the frame untouched.
 */
export function applyChain(
  ctx: CanvasRenderingContext2D,
  chainName: ChainName | null,
  t: number,
  W: number,
  H: number,
) {
  if (!chainName) return;
  const chain = CHAINS[chainName];
  if (!chain) return;
  const needsPixels = chain.keys.some((k) => PIXEL_FILTERS[k]);
  if (needsPixels) {
    const img = ctx.getImageData(0, 0, W, H);
    for (const k of chain.keys) PIXEL_FILTERS[k]?.(img, t, W, H);
    ctx.putImageData(img, 0, 0);
  }
  for (const k of chain.keys) CTX_FILTERS[k]?.(ctx, t, W, H);
}

/** Mirror of core/persona.py's filter_director thresholds. */
export function directorPick(energy: number): ChainName {
  if (energy > 0.8) return "full_breakdown";
  if (energy > 0.5) return "scarecrow_proceedings";
  return "squid_round";
}
