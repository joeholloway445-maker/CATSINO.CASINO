import type { Faction } from '@/types/character'

export const FACTIONS: Record<string, Faction> = {
  veiled_current: {
    id: 'veiled_current',
    name: 'Veiled Current',
    origin: 'Japanese Pantheon',
    description:
      'Masters of the unseen flow — those who move like water and vanish like mist. The Veiled Current communes with the spirits of Japan to shape the currents of fate.',
    colorScheme: {
      primary: 0x3730a3,
      secondary: 0x6366f1,
      light: 0xa5b4fc,
      glow: '#6366f1',
      glowHex: 0x6366f1,
    },
    defeats: 'wildlands_ascendants',
    defeats_text: 'Flowing current extinguishes desert fire',
  },
  sovereign_crown: {
    id: 'sovereign_crown',
    name: 'Sovereign Crown',
    origin: 'Hindu Pantheon',
    description:
      'Wielders of divine authority — those who carry the weight of cosmos and cycle. The Sovereign Crown embodies creation, preservation, and destruction in eternal balance.',
    colorScheme: {
      primary: 0x92400e,
      secondary: 0xf59e0b,
      light: 0xfde68a,
      glow: '#f59e0b',
      glowHex: 0xf59e0b,
    },
    defeats: 'veiled_current',
    defeats_text: 'Sacred flame burns through mist and shadow',
  },
  wildlands_ascendants: {
    id: 'wildlands_ascendants',
    name: 'Wildlands Ascendants',
    origin: 'Egyptian Pantheon',
    description:
      'Children of the desert and the eternal Nile — those who know that death is not an ending but a passage. The Wildlands Ascendants command the forces of nature and the afterlife.',
    colorScheme: {
      primary: 0x065f46,
      secondary: 0x10b981,
      light: 0x6ee7b7,
      glow: '#10b981',
      glowHex: 0x10b981,
    },
    defeats: 'sovereign_crown',
    defeats_text: 'Ancient order outlasts divine cycle',
  },
}

export const FACTION_LIST = Object.values(FACTIONS)
