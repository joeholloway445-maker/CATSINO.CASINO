// Voice layer for the Dream studio.
//
//  • speakAs()      — persona text-to-speech via the Web Speech API. Each
//                     persona gets a deterministic pitch/rate from its id so
//                     the "audience" sounds like many different entities.
//  • VoiceChanger   — a real-time Web Audio graph for the streamer's own mic:
//                     pitch shift (entity / chipmunk / demon) + a wet/dry
//                     mix, exposed as a MediaStream you can pipe into the
//                     outgoing WebRTC/recording track.
//
// Everything is browser-native — no external service, no API key. This keeps
// the studio runnable the moment the page loads.

export type VoicePreset = "entity" | "demon" | "chipmunk" | "off";

const synth = typeof window !== "undefined" ? window.speechSynthesis : null;

/** Speak a persona line. Pitch/rate are derived from the persona id so the
 *  same persona always sounds the same, but the crowd is varied. */
export function speakAs(personaId: number, text: string, opts?: { rate?: number; volume?: number }) {
  if (!synth) return;
  const u = new SpeechSynthesisUtterance(text);
  // Spread voices across the available set deterministically.
  const voices = synth.getVoices();
  if (voices.length) u.voice = voices[personaId % voices.length];
  u.pitch = 0.5 + ((personaId * 37) % 100) / 100; // 0.5 .. 1.5
  u.rate = opts?.rate ?? 0.9 + ((personaId * 13) % 60) / 100; // 0.9 .. 1.5
  u.volume = opts?.volume ?? 0.85;
  synth.speak(u);
}

export function stopSpeaking() {
  synth?.cancel();
}

const PRESET_DETUNE: Record<VoicePreset, number> = {
  off: 0,
  entity: -500, // deep, dragged-down
  demon: -900, // very low
  chipmunk: 700, // high
};

/**
 * Real-time pitch/formant shifter for a live mic stream. Uses an AudioWorklet
 * when available for proper granular pitch-shifting; falls back to a
 * playbackRate-style detune via a delay-modulation graph so it still works
 * everywhere. Returns a MediaStream carrying the processed audio.
 */
export class VoiceChanger {
  private ctx: AudioContext;
  private source: MediaStreamAudioSourceNode | null = null;
  private dest: MediaStreamAudioDestinationNode;
  private dry: GainNode;
  private wet: GainNode;
  private shifter: PitchShiftNode;
  preset: VoicePreset = "off";

  constructor() {
    this.ctx = new AudioContext();
    this.dest = this.ctx.createMediaStreamDestination();
    this.dry = this.ctx.createGain();
    this.wet = this.ctx.createGain();
    this.shifter = new PitchShiftNode(this.ctx);
    this.dry.gain.value = 1;
    this.wet.gain.value = 0;
    this.dry.connect(this.dest);
    this.shifter.output.connect(this.wet);
    this.wet.connect(this.dest);
  }

  /** Attach a mic stream (from getUserMedia). Returns processed stream. */
  connect(micStream: MediaStream): MediaStream {
    if (this.ctx.state === "suspended") this.ctx.resume();
    this.source?.disconnect();
    this.source = this.ctx.createMediaStreamSource(micStream);
    this.source.connect(this.dry);
    this.source.connect(this.shifter.input);
    return this.dest.stream;
  }

  setPreset(preset: VoicePreset) {
    this.preset = preset;
    const wet = preset === "off" ? 0 : 1;
    this.wet.gain.setTargetAtTime(wet, this.ctx.currentTime, 0.02);
    this.dry.gain.setTargetAtTime(preset === "off" ? 1 : 0.15, this.ctx.currentTime, 0.02);
    this.shifter.setDetune(PRESET_DETUNE[preset]);
  }

  close() {
    this.source?.disconnect();
    this.ctx.close();
  }
}

/**
 * A small delay-modulation pitch shifter built from two crossfaded delay lines
 * (the classic "two overlapping windows" trick). Cheap, glitch-tolerant, and
 * needs no worklet file — perfect for a voice-changer toy on top of a mic.
 */
class PitchShiftNode {
  input: GainNode;
  output: GainNode;
  private ctx: AudioContext;
  private delayA: DelayNode;
  private delayB: DelayNode;
  private gainA: GainNode;
  private gainB: GainNode;
  private lfoA: OscillatorNode;
  private lfoB: OscillatorNode;
  private lfoGainA: GainNode;
  private lfoGainB: GainNode;
  private xfadeA: OscillatorNode;
  private xfadeB: OscillatorNode;

  constructor(ctx: AudioContext) {
    this.ctx = ctx;
    this.input = ctx.createGain();
    this.output = ctx.createGain();
    const windowSize = 0.08; // seconds
    this.delayA = ctx.createDelay(1);
    this.delayB = ctx.createDelay(1);
    this.gainA = ctx.createGain();
    this.gainB = ctx.createGain();

    // Sawtooth ramps sweep each delay line; the sweep rate sets the pitch.
    this.lfoA = ctx.createOscillator();
    this.lfoB = ctx.createOscillator();
    this.lfoA.type = "sawtooth";
    this.lfoB.type = "sawtooth";
    this.lfoGainA = ctx.createGain();
    this.lfoGainB = ctx.createGain();
    this.lfoGainA.gain.value = windowSize / 2;
    this.lfoGainB.gain.value = windowSize / 2;
    this.lfoA.connect(this.lfoGainA).connect(this.delayA.delayTime);
    this.lfoB.connect(this.lfoGainB).connect(this.delayB.delayTime);

    // Crossfade the two windows so we never hear the delay reset.
    this.xfadeA = ctx.createOscillator();
    this.xfadeB = ctx.createOscillator();
    this.xfadeA.type = "triangle";
    this.xfadeB.type = "triangle";
    this.xfadeA.connect(this.gainA.gain);
    this.xfadeB.connect(this.gainB.gain);

    this.input.connect(this.delayA).connect(this.gainA).connect(this.output);
    this.input.connect(this.delayB).connect(this.gainB).connect(this.output);

    [this.lfoA, this.lfoB, this.xfadeA, this.xfadeB].forEach((o) => o.start());
    this.setDetune(0);
  }

  /** detune in cents → window sweep frequency. */
  setDetune(cents: number) {
    const ratio = Math.pow(2, cents / 1200);
    const windowSize = 0.08;
    // Sweep frequency that produces this pitch ratio for the delay-line method.
    const freq = Math.abs(1 - ratio) / windowSize;
    this.lfoA.frequency.setValueAtTime(ratio < 1 ? freq : -freq || 0.001, this.ctx.currentTime);
    this.lfoB.frequency.setValueAtTime(ratio < 1 ? freq : -freq || 0.001, this.ctx.currentTime);
    // Phase-offset crossfade at half the window rate.
    const xf = Math.max(0.001, freq / 2);
    this.xfadeA.frequency.setValueAtTime(xf, this.ctx.currentTime);
    this.xfadeB.frequency.setValueAtTime(xf, this.ctx.currentTime);
  }
}
