// Selfie → PeriHuman avatar portrait. The "Gemini avatar" ask, done the same
// way the rest of the streaming stack works: entirely in the browser, over a
// canvas's ImageData, no external image-gen API or key required. Pixel math
// follows the same style as lib/personamatrix/filters/engine.ts.

export type AvatarStyle = "portrait" | "toon" | "neon";

export const AVATAR_STYLES: { id: AvatarStyle; label: string; hint: string }[] = [
  { id: "portrait", label: "Portrait", hint: "cleaned up, true to the photo" },
  { id: "toon", label: "Toon", hint: "posterized + inked edges" },
  { id: "neon", label: "Neon", hint: "glowing edge-trace on black" },
];

const PORTRAIT_SIZE = 512;

/** Snapshot the current frame of a playing <video> into a square data URL. */
export function capturePhoto(video: HTMLVideoElement, mirror = true): string {
  const canvas = document.createElement("canvas");
  canvas.width = PORTRAIT_SIZE;
  canvas.height = PORTRAIT_SIZE;
  const ctx = canvas.getContext("2d")!;
  const vw = video.videoWidth || PORTRAIT_SIZE;
  const vh = video.videoHeight || PORTRAIT_SIZE;
  // center-crop the video to a square so the portrait isn't stretched
  const side = Math.min(vw, vh);
  const sx = (vw - side) / 2;
  const sy = (vh - side) / 2;
  ctx.save();
  if (mirror) {
    ctx.translate(PORTRAIT_SIZE, 0);
    ctx.scale(-1, 1);
  }
  ctx.drawImage(video, sx, sy, side, side, 0, 0, PORTRAIT_SIZE, PORTRAIT_SIZE);
  ctx.restore();
  return canvas.toDataURL("image/png");
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = src;
  });
}

function posterize(d: ImageData, levels: number) {
  const step = 255 / (levels - 1);
  for (let i = 0; i < d.data.length; i += 4) {
    d.data[i] = Math.round(Math.round(d.data[i] / step) * step);
    d.data[i + 1] = Math.round(Math.round(d.data[i + 1] / step) * step);
    d.data[i + 2] = Math.round(Math.round(d.data[i + 2] / step) * step);
  }
}

function boostSaturation(d: ImageData, amount: number) {
  for (let i = 0; i < d.data.length; i += 4) {
    const r = d.data[i], g = d.data[i + 1], b = d.data[i + 2];
    const lum = r * 0.3 + g * 0.59 + b * 0.11;
    d.data[i] = clamp(lum + (r - lum) * amount);
    d.data[i + 1] = clamp(lum + (g - lum) * amount);
    d.data[i + 2] = clamp(lum + (b - lum) * amount);
  }
}

/** Sobel edge magnitude, written into a separate luminance buffer so the
 *  caller can either ink over the source (toon) or trace it on black (neon). */
function edgeMap(src: ImageData, W: number, H: number): Float32Array {
  const gray = new Float32Array(W * H);
  for (let i = 0, p = 0; i < src.data.length; i += 4, p++) {
    gray[p] = src.data[i] * 0.3 + src.data[i + 1] * 0.59 + src.data[i + 2] * 0.11;
  }
  const out = new Float32Array(W * H);
  for (let y = 1; y < H - 1; y++) {
    for (let x = 1; x < W - 1; x++) {
      const i = y * W + x;
      const gx =
        -gray[i - W - 1] + gray[i - W + 1] -
        2 * gray[i - 1] + 2 * gray[i + 1] -
        gray[i + W - 1] + gray[i + W + 1];
      const gy =
        -gray[i - W - 1] - 2 * gray[i - W] - gray[i - W + 1] +
        gray[i + W - 1] + 2 * gray[i + W] + gray[i + W + 1];
      out[i] = Math.sqrt(gx * gx + gy * gy);
    }
  }
  return out;
}

function clamp(v: number) {
  return v < 0 ? 0 : v > 255 ? 255 : v;
}

/**
 * Stylize a captured photo into a PeriHuman avatar. Returns a new data URL —
 * the source image is untouched so a player can flip between styles.
 */
export async function stylizeAvatar(sourceDataUrl: string, style: AvatarStyle): Promise<string> {
  const img = await loadImage(sourceDataUrl);
  const W = img.naturalWidth || PORTRAIT_SIZE;
  const H = img.naturalHeight || PORTRAIT_SIZE;
  const canvas = document.createElement("canvas");
  canvas.width = W;
  canvas.height = H;
  const ctx = canvas.getContext("2d")!;
  ctx.drawImage(img, 0, 0, W, H);

  if (style === "portrait") {
    const d = ctx.getImageData(0, 0, W, H);
    boostSaturation(d, 1.12);
    ctx.putImageData(d, 0, 0);
    // subtle accent vignette so every portrait reads as "this game", not a raw selfie
    const grd = ctx.createRadialGradient(W / 2, H / 2, W * 0.3, W / 2, H / 2, W * 0.62);
    grd.addColorStop(0, "rgba(0,0,0,0)");
    grd.addColorStop(1, "rgba(20,10,30,0.35)");
    ctx.fillStyle = grd;
    ctx.fillRect(0, 0, W, H);
    return canvas.toDataURL("image/png");
  }

  const d = ctx.getImageData(0, 0, W, H);
  const edges = edgeMap(d, W, H);

  if (style === "toon") {
    posterize(d, 5);
    boostSaturation(d, 1.35);
    for (let p = 0; p < edges.length; p++) {
      if (edges[p] > 90) {
        const i = p * 4;
        d.data[i] = d.data[i + 1] = d.data[i + 2] = 12;
      }
    }
    ctx.putImageData(d, 0, 0);
    return canvas.toDataURL("image/png");
  }

  // "neon" — glowing edge trace on black, matches the game's purple/green accent palette
  const out = ctx.createImageData(W, H);
  for (let p = 0; p < edges.length; p++) {
    const i = p * 4;
    const e = Math.min(1, edges[p] / 260);
    out.data[i] = 8 + e * 193; // toward accent purple/green
    out.data[i + 1] = 8 + e * 255;
    out.data[i + 2] = 12 + e * 245 * 0.6;
    out.data[i + 3] = 255;
  }
  ctx.putImageData(out, 0, 0);
  return canvas.toDataURL("image/png");
}

export function dataUrlToBlob(dataUrl: string): Blob {
  const [header, b64] = dataUrl.split(",");
  const mime = header.match(/data:(.*);base64/)?.[1] ?? "image/png";
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return new Blob([bytes], { type: mime });
}
