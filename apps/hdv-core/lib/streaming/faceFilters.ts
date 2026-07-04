// Face-tracking filters for the Dream studio.
//
// Loads MediaPipe's FaceLandmarker (468-point mesh) lazily from the CDN so it
// never bloats the app bundle and only downloads when a streamer actually
// turns the camera on. The landmarks drive *face-anchored* effects — glowing
// entity eyes, a scarecrow seam stitched across the mouth, a third eye — that
// track the real face, layered on top of the full-frame chain filters in
// lib/personamatrix/filters/engine.ts.
//
// Everything is dynamically imported and guarded, so a failed CDN load (or a
// browser without WebGL) degrades to "no face overlay" rather than breaking
// the stream.

export type FaceFilter = "none" | "entity_eyes" | "scarecrow_seam" | "third_eye";

const VISION_CDN = "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.22";

// Minimal structural types so we don't depend on the package at build time.
interface NormalizedLandmark { x: number; y: number; z: number }
export interface FaceLandmarkerResult { faceLandmarks: NormalizedLandmark[][] }
interface FaceLandmarkerLike {
  detectForVideo(video: HTMLVideoElement, ts: number): FaceLandmarkerResult;
  close(): void;
}

let landmarkerPromise: Promise<FaceLandmarkerLike | null> | null = null;

export function loadFaceLandmarker(): Promise<FaceLandmarkerLike | null> {
  if (landmarkerPromise) return landmarkerPromise;
  landmarkerPromise = (async () => {
    try {
      const vision = (await import(/* webpackIgnore: true */ `${VISION_CDN}/vision_bundle.mjs`)) as {
        FilesetResolver: { forVisionTasks(wasmPath: string): Promise<unknown> };
        FaceLandmarker: { createFromOptions(fileset: unknown, opts: Record<string, unknown>): Promise<FaceLandmarkerLike> };
      };
      const fileset = await vision.FilesetResolver.forVisionTasks(`${VISION_CDN}/wasm`);
      const landmarker = await vision.FaceLandmarker.createFromOptions(fileset, {
        baseOptions: {
          modelAssetPath:
            "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task",
          delegate: "GPU",
        },
        runningMode: "VIDEO",
        numFaces: 1,
      });
      return landmarker as FaceLandmarkerLike;
    } catch (err) {
      console.warn("FaceLandmarker failed to load — face filters disabled:", err);
      return null;
    }
  })();
  return landmarkerPromise;
}

// MediaPipe FaceMesh canonical indices we care about.
const LEFT_EYE_CENTER = 159;
const RIGHT_EYE_CENTER = 386;
const FOREHEAD = 10;
const MOUTH_LEFT = 61;
const MOUTH_RIGHT = 291;
const CHIN = 152;

function px(lm: NormalizedLandmark, W: number, H: number, mirror: boolean) {
  return { x: (mirror ? 1 - lm.x : lm.x) * W, y: lm.y * H };
}

/**
 * Draw the selected face-anchored overlay using the latest landmark result.
 * `t` is the frame counter (for pulsing). `mirror` matches the mirrored
 * webcam draw used by the studio. No-op when no face / filter "none".
 */
export function drawFaceFilter(
  g: CanvasRenderingContext2D,
  filter: FaceFilter,
  result: FaceLandmarkerResult | null,
  t: number,
  W: number,
  H: number,
  mirror: boolean,
) {
  if (filter === "none" || !result?.faceLandmarks?.length) return;
  const lm = result.faceLandmarks[0];
  const pulse = 0.6 + 0.4 * Math.sin(t * 0.12);

  if (filter === "entity_eyes") {
    for (const idx of [LEFT_EYE_CENTER, RIGHT_EYE_CENTER]) {
      const p = px(lm[idx], W, H, mirror);
      const r = 16 + 6 * pulse;
      const grd = g.createRadialGradient(p.x, p.y, 1, p.x, p.y, r * 2.2);
      grd.addColorStop(0, `rgba(201,71,245,${0.9 * pulse})`);
      grd.addColorStop(0.4, "rgba(57,255,20,0.5)");
      grd.addColorStop(1, "rgba(8,7,12,0)");
      g.fillStyle = grd;
      g.beginPath(); g.arc(p.x, p.y, r * 2.2, 0, Math.PI * 2); g.fill();
    }
    return;
  }

  if (filter === "third_eye") {
    const f = px(lm[FOREHEAD], W, H, mirror);
    const r = 18 + 8 * pulse;
    g.save();
    g.fillStyle = "#0a0810";
    g.beginPath(); g.ellipse(f.x, f.y - 10, r, r * 0.6, 0, 0, Math.PI * 2); g.fill();
    const grd = g.createRadialGradient(f.x, f.y - 10, 1, f.x, f.y - 10, r);
    grd.addColorStop(0, `rgba(57,255,20,${pulse})`);
    grd.addColorStop(1, "rgba(201,71,245,0.1)");
    g.fillStyle = grd;
    g.beginPath(); g.arc(f.x, f.y - 10, r * 0.55, 0, Math.PI * 2); g.fill();
    g.restore();
    return;
  }

  if (filter === "scarecrow_seam") {
    const a = px(lm[MOUTH_LEFT], W, H, mirror);
    const b = px(lm[MOUTH_RIGHT], W, H, mirror);
    const chin = px(lm[CHIN], W, H, mirror);
    g.save();
    g.strokeStyle = "rgba(20,16,24,0.9)";
    g.lineWidth = 4;
    // burlap seam across the mouth
    g.beginPath(); g.moveTo(a.x, a.y); g.lineTo(b.x, b.y); g.stroke();
    // stitches
    g.strokeStyle = `rgba(201,71,245,${0.7 + 0.3 * pulse})`;
    g.lineWidth = 2;
    const n = 7;
    for (let i = 0; i <= n; i++) {
      const x = a.x + ((b.x - a.x) * i) / n, y = a.y + ((b.y - a.y) * i) / n;
      g.beginPath(); g.moveTo(x, y - 8); g.lineTo(x, y + 8); g.stroke();
    }
    // seam down to the chin
    g.strokeStyle = "rgba(20,16,24,0.7)";
    g.lineWidth = 3;
    g.beginPath(); g.moveTo((a.x + b.x) / 2, (a.y + b.y) / 2); g.lineTo(chin.x, chin.y); g.stroke();
    g.restore();
  }
}
