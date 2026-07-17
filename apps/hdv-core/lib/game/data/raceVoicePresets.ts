// Per-race voice "accent" presets for the Capture step's voice recorder.
// Each race gets a distinct pitch/bass/treble combo derived from its texture
// flavor (lib/game/data/races.ts) so builds sound recognizably different from
// each other — a Deepborne growls, a Lumenari sounds bright and airy, etc.
//
// These are defaults, not a cage: StepCapture applies a race's preset as a
// starting point, and the pitch/bass/treble sliders stay fully live after
// that, so a player who'd rather just talk as themselves can drag right back
// to 0/0/0 (or anywhere else) at any time.

export interface RaceVoicePreset {
  /** Matches Race['texture']['type'] in races.ts */
  textureType: string
  /** Short in-world name for the accent, shown in the UI */
  accent: string
  pitch: number   // semitones, -12..12
  bass: number    // dB, -15..15
  treble: number  // dB, -15..15
}

export const RACE_VOICE_PRESETS: RaceVoicePreset[] = [
  { textureType: 'radiant', accent: 'Radiant Chorus', pitch: 3, bass: -4, treble: 6 },
  { textureType: 'mutated', accent: 'Undercity Rasp', pitch: -2, bass: 3, treble: -3 },
  { textureType: 'abyssal', accent: 'Trench Growl', pitch: -8, bass: 10, treble: -6 },
  { textureType: 'spectral', accent: 'Spectral Hymn', pitch: 5, bass: -6, treble: 4 },
  { textureType: 'phasic', accent: 'Phase Flicker', pitch: 2, bass: -2, treble: 5 },
  { textureType: 'temporal', accent: 'Clockwork Cadence', pitch: 0, bass: 1, treble: 2 },
  { textureType: 'voidlike', accent: 'Void Monotone', pitch: -4, bass: -3, treble: -4 },
  { textureType: 'symbiotic', accent: 'Bramble Warmth', pitch: -1, bass: 2, treble: -2 },
  { textureType: 'digital', accent: 'Signal Echo', pitch: 4, bass: -5, treble: 8 },
  { textureType: 'biotech', accent: 'Chassis Hum', pitch: -3, bass: 4, treble: -1 },
  { textureType: 'dimensional', accent: 'Rift Warble', pitch: 1, bass: 3, treble: 3 },
  { textureType: 'amphibious', accent: 'Bog Croak', pitch: -6, bass: 5, treble: -5 },
  { textureType: 'solar', accent: 'Solar Flare', pitch: 6, bass: -3, treble: 5 },
  { textureType: 'crystalline', accent: 'Frost Chime', pitch: 3, bass: -4, treble: 9 },
  { textureType: 'electric', accent: 'Arc Crackle', pitch: 2, bass: -1, treble: 7 },
  { textureType: 'morphic', accent: 'Morphic Murmur', pitch: -1, bass: 1, treble: -3 },
  { textureType: 'regal', accent: 'Regal Baritone', pitch: -5, bass: 6, treble: -2 },
  { textureType: 'decayed', accent: 'Withered Rasp', pitch: -7, bass: 2, treble: -7 },
  { textureType: 'crystal', accent: 'Prism Clarity', pitch: 4, bass: -5, treble: 8 },
  { textureType: 'celestial', accent: 'Celestial Drift', pitch: 3, bass: -2, treble: 4 },
]

const BY_TEXTURE_TYPE = new Map(RACE_VOICE_PRESETS.map((p) => [p.textureType, p]))

export function getRaceVoicePreset(textureType: string | undefined | null): RaceVoicePreset | undefined {
  if (!textureType) return undefined
  return BY_TEXTURE_TYPE.get(textureType)
}
