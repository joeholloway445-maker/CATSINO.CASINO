import type { SpaceZone } from '@/types/character'

export const TILE_SIZE = 32
export const MAP_SIZE = 100

export interface TileData {
  zone: SpaceZone
  hasEntity: boolean
  entityFaction?: 'veiled_current' | 'sovereign_crown' | 'wildlands_ascendants'
  explored: boolean
  passable: boolean
}

const ZONE_COLORS: Record<SpaceZone, { fill: number; border: number; fog: number }> = {
  supraliminal: { fill: 0x0d1b2a, border: 0x1e3a5f, fog: 0x040d14 },
  liminal:      { fill: 0x1a1030, border: 0x3b2068, fog: 0x0a0818 },
  periliminal:  { fill: 0x1a0505, border: 0x5c1a1a, fog: 0x0a0202 },
  subliminal:   { fill: 0x051a05, border: 0x1a5c1a, fog: 0x020a02 },
  hyperliminal: { fill: 0x1a1505, border: 0x5c4c05, fog: 0x0a0d02 },
}

export { ZONE_COLORS }

export function generateMap(): TileData[][] {
  const map: TileData[][] = []
  const cx = MAP_SIZE / 2
  const cy = MAP_SIZE / 2

  for (let y = 0; y < MAP_SIZE; y++) {
    map[y] = []
    for (let x = 0; x < MAP_SIZE; x++) {
      const dx = x - cx
      const dy = y - cy
      const dist = Math.sqrt(dx * dx + dy * dy)

      // Simple noise using sin/cos
      const n = (Math.sin(x * 0.31 + y * 0.71) + Math.cos(x * 0.53 - y * 0.47)) * 0.5
      const adjusted = (dist / (MAP_SIZE * 0.4)) + n * 0.15

      let zone: SpaceZone
      if (adjusted < 0.25) {
        zone = 'supraliminal'
      } else if (adjusted < 0.55) {
        zone = 'liminal'
      } else if (adjusted < 0.85) {
        zone = 'periliminal'
      } else {
        zone = 'periliminal'
      }

      // Subliminal pockets — rare safe zones in supraliminal
      if (zone === 'supraliminal' && Math.sin(x * 2.3 + y * 1.7) > 0.9) {
        zone = 'subliminal'
      }

      // Hyperliminal pockets — ultra rare in outer ring
      if (zone === 'periliminal' && Math.cos(x * 3.1 + y * 2.9) > 0.97) {
        zone = 'hyperliminal'
      }

      // Entity spawns — 3% chance, not in subliminal/hyperliminal
      const spawnChance = zone === 'supraliminal' ? 0.025 : zone === 'liminal' ? 0.04 : 0.06
      const hasEntity = Math.random() < spawnChance && zone !== 'subliminal'

      const factions: Array<'veiled_current' | 'sovereign_crown' | 'wildlands_ascendants'> = [
        'veiled_current', 'sovereign_crown', 'wildlands_ascendants'
      ]
      const entityFaction = hasEntity ? factions[Math.floor(Math.random() * 3)] : undefined

      // Starting area is explored
      const nearStart = dist < 6

      map[y][x] = {
        zone,
        hasEntity,
        entityFaction,
        explored: nearStart,
        passable: true,
      }
    }
  }

  return map
}
