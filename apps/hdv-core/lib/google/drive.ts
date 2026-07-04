const DRIVE_API = 'https://www.googleapis.com/drive/v3'

export interface DriveFile {
  id: string
  name: string
  mimeType: string
  createdTime: string
  modifiedTime: string
  viewedByMeTime?: string
  size?: string
}

export interface ClutterGroup {
  name: string
  mimeType: string
  files: DriveFile[]
}

const FOLDER_MIME = 'application/vnd.google-apps.folder'
const SCRIPT_MIME = 'application/vnd.google-apps.script'

async function driveFetch(path: string, token: string, init?: RequestInit) {
  const res = await fetch(`${DRIVE_API}${path}`, {
    ...init,
    headers: {
      ...init?.headers,
      Authorization: `Bearer ${token}`,
    },
  })
  if (!res.ok) {
    const body = await res.text()
    throw new Error(`Drive API error ${res.status}: ${body}`)
  }
  return res.json()
}

/** Fetches every non-trashed file/folder the user owns, paging through results. */
export async function listAllFiles(
  token: string,
  onProgress?: (count: number) => void,
): Promise<DriveFile[]> {
  const files: DriveFile[] = []
  let pageToken: string | undefined

  do {
    const params = new URLSearchParams({
      pageSize: '1000',
      fields: 'nextPageToken, files(id, name, mimeType, createdTime, modifiedTime, viewedByMeTime, size)',
      q: "trashed = false and 'me' in owners",
    })
    if (pageToken) params.set('pageToken', pageToken)

    const data = await driveFetch(`/files?${params.toString()}`, token)
    files.push(...(data.files ?? []))
    pageToken = data.nextPageToken
    onProgress?.(files.length)
  } while (pageToken)

  return files
}

export async function trashFile(token: string, fileId: string) {
  await driveFetch(`/files/${fileId}`, token, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ trashed: true }),
  })
}

export async function renameFile(token: string, fileId: string, name: string) {
  await driveFetch(`/files/${fileId}`, token, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name }),
  })
}

/**
 * Groups files/folders that share an exact name and type. Repeated names
 * (e.g. a folder recreated every few hours by a stale Apps Script trigger)
 * surface here as a group with many entries.
 */
export function findClutterGroups(files: DriveFile[], minCount = 3): ClutterGroup[] {
  const groups = new Map<string, DriveFile[]>()

  for (const f of files) {
    const key = `${f.name}::${f.mimeType}`
    const arr = groups.get(key)
    if (arr) arr.push(f)
    else groups.set(key, [f])
  }

  const result: ClutterGroup[] = []
  for (const [key, arr] of groups) {
    if (arr.length < minCount) continue
    const [name, mimeType] = key.split('::')
    arr.sort((a, b) => new Date(a.createdTime).getTime() - new Date(b.createdTime).getTime())
    result.push({ name, mimeType, files: arr })
  }

  result.sort((a, b) => b.files.length - a.files.length)
  return result
}

/** Non-folder files at or above the given size, largest first. */
export function findLargeFiles(files: DriveFile[], minSizeBytes: number): DriveFile[] {
  return files
    .filter((f) => f.mimeType !== FOLDER_MIME && Number(f.size ?? 0) >= minSizeBytes)
    .sort((a, b) => Number(b.size ?? 0) - Number(a.size ?? 0))
}

/** Files not modified or opened in over `staleDays`, oldest activity first. */
export function findStaleFiles(files: DriveFile[], staleDays: number): DriveFile[] {
  const cutoff = Date.now() - staleDays * 24 * 60 * 60 * 1000
  return files
    .filter((f) => {
      const lastActive = Math.max(
        new Date(f.modifiedTime).getTime(),
        f.viewedByMeTime ? new Date(f.viewedByMeTime).getTime() : 0,
      )
      return lastActive < cutoff
    })
    .sort((a, b) => new Date(a.modifiedTime).getTime() - new Date(b.modifiedTime).getTime())
}

/**
 * Apps Script projects owned by the user. Any of these can hold a
 * time-driven trigger that keeps regenerating files/folders in the
 * background — surfaced here as candidates for a V2 trigger audit.
 */
export function findAutomationSources(files: DriveFile[]): DriveFile[] {
  return files
    .filter((f) => f.mimeType === SCRIPT_MIME)
    .sort((a, b) => new Date(b.modifiedTime).getTime() - new Date(a.modifiedTime).getTime())
}

export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  return `${(bytes / 1024 ** i).toFixed(1)} ${units[i]}`
}
