'use client'

// Local persistence for player-captured media (portrait photo, voice line)
// from the character Capture step. Keyed by character slot number.
//
// This is deliberately client-only, mirroring lib/builder/utils/persistence.ts:
// no backend table/bucket exists for avatars yet, so captures live in
// IndexedDB (via idb) rather than bloating localStorage or requiring a schema
// change. If/when a real avatar column + storage bucket is added, swapping
// this module's implementation is the only change needed — callers just
// want a Blob back for a given slot.

import { openDB, type DBSchema } from 'idb'
import { useEffect, useState } from 'react'

interface PeriHumanMediaDB extends DBSchema {
  portraits: { key: number; value: Blob }
  voiceClips: { key: number; value: Blob }
}

const DB_NAME = 'perihuman-media-db'
const DB_VERSION = 1

function hasIndexedDB() {
  return typeof indexedDB !== 'undefined'
}

async function getDB() {
  return openDB<PeriHumanMediaDB>(DB_NAME, DB_VERSION, {
    upgrade(db) {
      if (!db.objectStoreNames.contains('portraits')) db.createObjectStore('portraits')
      if (!db.objectStoreNames.contains('voiceClips')) db.createObjectStore('voiceClips')
    },
  })
}

export async function savePortrait(slot: number, blob: Blob): Promise<void> {
  if (!hasIndexedDB()) return
  const db = await getDB()
  await db.put('portraits', blob, slot)
}

export async function loadPortrait(slot: number): Promise<Blob | undefined> {
  if (!hasIndexedDB()) return undefined
  const db = await getDB()
  return db.get('portraits', slot)
}

export async function saveVoiceClip(slot: number, blob: Blob): Promise<void> {
  if (!hasIndexedDB()) return
  const db = await getDB()
  await db.put('voiceClips', blob, slot)
}

export async function loadVoiceClip(slot: number): Promise<Blob | undefined> {
  if (!hasIndexedDB()) return undefined
  const db = await getDB()
  return db.get('voiceClips', slot)
}

/** Object-URL for a slot's saved portrait, or null while loading/absent.
 *  Revokes the URL on unmount / slot change. */
export function usePortraitUrl(slot: number | null): string | null {
  const [url, setUrl] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    let objectUrl: string | null = null
    Promise.resolve(slot === null ? undefined : loadPortrait(slot)).then((blob) => {
      if (cancelled) return
      if (!blob) { setUrl(null); return }
      objectUrl = URL.createObjectURL(blob)
      setUrl(objectUrl)
    })
    return () => {
      cancelled = true
      if (objectUrl) URL.revokeObjectURL(objectUrl)
    }
  }, [slot])

  return url
}
