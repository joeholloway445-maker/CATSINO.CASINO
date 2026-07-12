/**
 * Master OmniDex registry — single source of truth for identity naming.
 *
 * Counts (invariant):
 *   20 races · 20 frames · 20 mods · entities by faction · companions by roster
 *
 * The previous typo that surfaced "24 frames" came from treating shop
 * cosmetics (chrome/neon/storm/wind, etc.) as identity frames. Those are
 * NOT part of this registry. Identity frames are exactly the 20 below.
 */
import { RACES } from './races'
import { FRAMES } from './frames'
import { PHYSICAL_MODS } from './physicalMods'
import { ALL_ENTITIES } from './entities'
import type { Race, Frame, PhysicalMod } from '@/types/character'
import type { Entity } from '@/types/entities'

export const OMNIDEX_FRAME_COUNT = 20
export const OMNIDEX_RACE_COUNT = 20
export const OMNIDEX_MOD_COUNT = 20

export const OMNIDEX_FRAME_IDS = [
  'skirmisher', 'strider', 'skybound', 'flicker', 'marshal',
  'bloom', 'rewind', 'conduit', 'shade', 'fabricator',
  'bastion', 'juggernaut', 'gravemind', 'riftbreaker', 'sovereign',
  'worldroot', 'epoch', 'overlord', 'obscura', 'architect',
] as const

export const OMNIDEX_RACE_IDS = [
  'lumenari', 'gutterkin', 'deepborne', 'ashen_choir', 'veilstriders',
  'chronarchs', 'nullborn', 'thorned', 'echoes', 'hollowed',
  'riftspawn', 'mirekin', 'sunspun', 'coldmarrow', 'pulseborn',
  'dreamflesh', 'crownless', 'rotweavers', 'glassborn', 'starfall',
] as const

export const OMNIDEX_MOD_IDS = [
  'heavy_siege', 'swiftburner', 'multi_limbed', 'towering', 'compact',
  'elastic', 'floating_core', 'split_form', 'inverted_spine', 'modular',
  'armored', 'lithe', 'tendril', 'rooted', 'hover_strider',
  'centroid', 'shardform', 'quadruped', 'serpentine', 'colossus',
] as const

export type OmniDexFrameId = (typeof OMNIDEX_FRAME_IDS)[number]
export type OmniDexRaceId = (typeof OMNIDEX_RACE_IDS)[number]
export type OmniDexModId = (typeof OMNIDEX_MOD_IDS)[number]

/** Cosmetic / shop skins — never counted as OmniDex identity frames. */
export const COSMETIC_FRAME_IDS = [
  'chrome_frame', 'neon_frame', 'gold_frame', 'shadow_frame', 'battle_frame',
  'storm', 'wind', 'basic', 'ghost', 'titan', 'royal', 'iron', 'void',
  'ember', 'atlas', 'silk', 'nova', 'frost', 'blaze', 'rock', 'prism',
  'colossus_cosmetic', 'mirage',
] as const

function assertCount<T>(label: string, items: readonly T[], expected: number): void {
  if (items.length !== expected) {
    throw new Error(`OmniDex ${label} must be exactly ${expected}, got ${items.length}`)
  }
}

assertCount('frames', FRAMES, OMNIDEX_FRAME_COUNT)
assertCount('races', RACES, OMNIDEX_RACE_COUNT)
assertCount('mods', PHYSICAL_MODS, OMNIDEX_MOD_COUNT)
assertCount('frame ids', OMNIDEX_FRAME_IDS, OMNIDEX_FRAME_COUNT)
assertCount('race ids', OMNIDEX_RACE_IDS, OMNIDEX_RACE_COUNT)
assertCount('mod ids', OMNIDEX_MOD_IDS, OMNIDEX_MOD_COUNT)

export interface OmniDexCompanionRef {
  id: string
  name: string
  faction: string
}

/** Lightweight companion index for OmniDex discovery UI (names only). */
export const OMNIDEX_COMPANION_FACTIONS = [
  'sovereign_crown',
  'wildlands_ascendant',
  'veiled_current',
  'factionless',
] as const

export function isOmniDexFrameId(id: string): id is OmniDexFrameId {
  return (OMNIDEX_FRAME_IDS as readonly string[]).includes(id)
}

export function isCosmeticFrameId(id: string): boolean {
  return (COSMETIC_FRAME_IDS as readonly string[]).includes(id)
}

export function frameName(id: string): string {
  return FRAMES.find((f) => f.id === id)?.name ?? id
}

export function raceName(id: string): string {
  return RACES.find((r) => r.id === id)?.name ?? id
}

export function modName(id: string): string {
  return PHYSICAL_MODS.find((m) => m.id === id)?.name ?? id
}

export function entityName(id: string): string {
  const e = ALL_ENTITIES.find((x) => x.id === id)
  return e ? `${e.name} — ${e.title}` : id
}

export function getOmniDexFrames(): Frame[] {
  return FRAMES
}

export function getOmniDexRaces(): Race[] {
  return RACES
}

export function getOmniDexMods(): PhysicalMod[] {
  return PHYSICAL_MODS
}

export function getOmniDexEntities(): Entity[] {
  return ALL_ENTITIES
}

export const OmniDexRegistry = {
  frameCount: OMNIDEX_FRAME_COUNT,
  raceCount: OMNIDEX_RACE_COUNT,
  modCount: OMNIDEX_MOD_COUNT,
  frameIds: OMNIDEX_FRAME_IDS,
  raceIds: OMNIDEX_RACE_IDS,
  modIds: OMNIDEX_MOD_IDS,
  frames: FRAMES,
  races: RACES,
  mods: PHYSICAL_MODS,
  entities: ALL_ENTITIES,
  frameName,
  raceName,
  modName,
  entityName,
  isOmniDexFrameId,
  isCosmeticFrameId,
} as const
