'use client'

import { useCallback, useMemo, useState } from 'react'
import Script from 'next/script'
import {
  findAutomationSources,
  findClutterGroups,
  findLargeFiles,
  findStaleFiles,
  formatBytes,
  listAllFiles,
  renameFile,
  trashFile,
  type ClutterGroup,
  type DriveFile,
} from '@/lib/google/drive'

declare global {
  interface Window {
    google?: {
      accounts: {
        oauth2: {
          initTokenClient: (config: {
            client_id: string
            scope: string
            callback: (response: { access_token?: string; error?: string }) => void
          }) => { requestAccessToken: () => void }
        }
      }
    }
  }
}

const SCOPE = 'https://www.googleapis.com/auth/drive'

function formatDate(iso: string) {
  return new Date(iso).toLocaleString()
}

export default function DriveCleaner() {
  const [gsiReady, setGsiReady] = useState(false)
  const [token, setToken] = useState<string | null>(null)
  const [scanning, setScanning] = useState(false)
  const [scanned, setScanned] = useState(0)
  const [files, setFiles] = useState<DriveFile[] | null>(null)
  const [groups, setGroups] = useState<ClutterGroup[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busyGroup, setBusyGroup] = useState<string | null>(null)
  const [busyFile, setBusyFile] = useState<string | null>(null)
  const [trashedIds, setTrashedIds] = useState<Set<string>>(new Set())

  // Search
  const [searchTerm, setSearchTerm] = useState('')

  // Find & replace (bulk rename)
  const [findText, setFindText] = useState('')
  const [replaceText, setReplaceText] = useState('')
  const [renaming, setRenaming] = useState(false)
  const [renameDone, setRenameDone] = useState<Set<string>>(new Set())

  // AI triage
  const [explaining, setExplaining] = useState<string | null>(null)
  const [explanations, setExplanations] = useState<Record<string, string>>({})

  // Settings
  const [settingsOpen, setSettingsOpen] = useState(true)
  const [minDuplicates, setMinDuplicates] = useState(3)
  const [largeFileMb, setLargeFileMb] = useState(100)
  const [staleDays, setStaleDays] = useState(180)
  const [dryRun, setDryRun] = useState(true)
  const [enabledModules, setEnabledModules] = useState({
    duplicates: true,
    large: true,
    stale: true,
    automation: true,
  })

  const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID

  const connect = useCallback(() => {
    if (!window.google || !clientId) return
    setError(null)
    const client = window.google.accounts.oauth2.initTokenClient({
      client_id: clientId,
      scope: SCOPE,
      callback: (response) => {
        if (response.access_token) setToken(response.access_token)
        else setError('Google sign-in failed or was cancelled.')
      },
    })
    client.requestAccessToken()
  }, [clientId])

  const scan = useCallback(async () => {
    if (!token) return
    setScanning(true)
    setError(null)
    setFiles(null)
    setGroups(null)
    setScanned(0)
    setTrashedIds(new Set())
    setRenameDone(new Set())
    setExplanations({})
    setSearchTerm('')
    try {
      const fetched = await listAllFiles(token, setScanned)
      setFiles(fetched)
      setGroups(enabledModules.duplicates ? findClutterGroups(fetched, minDuplicates) : [])
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Scan failed.')
    } finally {
      setScanning(false)
    }
  }, [token, enabledModules.duplicates, minDuplicates])

  const cleanGroup = useCallback(async (group: ClutterGroup) => {
    if (!token) return
    const groupKey = `${group.name}::${group.mimeType}`
    setBusyGroup(groupKey)
    setError(null)
    try {
      // Keep the most recently created item, trash the rest.
      const toTrash = group.files.slice(0, -1)
      if (!dryRun) {
        for (const file of toTrash) {
          await trashFile(token, file.id)
        }
      }
      setTrashedIds((prev) => new Set([...prev, ...toTrash.map((f) => f.id)]))
      setGroups((prev) => prev?.filter((g) => `${g.name}::${g.mimeType}` !== groupKey) ?? null)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Cleanup failed.')
    } finally {
      setBusyGroup(null)
    }
  }, [token, dryRun])

  const trashSingleFile = useCallback(async (file: DriveFile) => {
    if (!token) return
    setBusyFile(file.id)
    setError(null)
    try {
      if (!dryRun) {
        await trashFile(token, file.id)
      }
      setTrashedIds((prev) => new Set([...prev, file.id]))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Trash failed.')
    } finally {
      setBusyFile(null)
    }
  }, [token, dryRun])

  const explainGroup = useCallback(async (group: ClutterGroup) => {
    const groupKey = `${group.name}::${group.mimeType}`
    setExplaining(groupKey)
    try {
      const oldest = group.files[0]
      const newest = group.files[group.files.length - 1]
      const res = await fetch('/api/cleaner/explain', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: group.name,
          mimeType: group.mimeType,
          count: group.files.length,
          firstCreated: formatDate(oldest.createdTime),
          mostRecentCreated: formatDate(newest.createdTime),
        }),
      })
      const data = await res.json()
      setExplanations((prev) => ({ ...prev, [groupKey]: data.explanation }))
    } catch {
      setExplanations((prev) => ({ ...prev, [groupKey]: 'AI triage failed — try again shortly.' }))
    } finally {
      setExplaining(null)
    }
  }, [])

  const largeFiles = useMemo(() => {
    if (!files || !enabledModules.large) return []
    return findLargeFiles(files, largeFileMb * 1024 * 1024).filter((f) => !trashedIds.has(f.id))
  }, [files, enabledModules.large, largeFileMb, trashedIds])

  const staleFiles = useMemo(() => {
    if (!files || !enabledModules.stale) return []
    return findStaleFiles(files, staleDays).filter((f) => !trashedIds.has(f.id))
  }, [files, enabledModules.stale, staleDays, trashedIds])

  const automationSources = useMemo(() => {
    if (!files || !enabledModules.automation) return []
    return findAutomationSources(files)
  }, [files, enabledModules.automation])

  const matchesSearch = useCallback(
    (name: string) => !searchTerm || name.toLowerCase().includes(searchTerm.toLowerCase()),
    [searchTerm],
  )

  const visibleGroups = useMemo(
    () => (groups ?? []).filter((g) => matchesSearch(g.name)),
    [groups, matchesSearch],
  )
  const visibleLargeFiles = useMemo(
    () => largeFiles.filter((f) => matchesSearch(f.name)),
    [largeFiles, matchesSearch],
  )
  const visibleStaleFiles = useMemo(
    () => staleFiles.filter((f) => matchesSearch(f.name)),
    [staleFiles, matchesSearch],
  )
  const visibleAutomationSources = useMemo(
    () => automationSources.filter((f) => matchesSearch(f.name)),
    [automationSources, matchesSearch],
  )

  const renameMatches = useMemo(() => {
    if (!files || !findText) return []
    return files
      .filter((f) => !trashedIds.has(f.id) && !renameDone.has(f.id) && f.name.includes(findText))
      .map((f) => ({ file: f, newName: f.name.split(findText).join(replaceText) }))
  }, [files, findText, replaceText, trashedIds, renameDone])

  const applyRename = useCallback(async () => {
    if (!token || renameMatches.length === 0) return
    setRenaming(true)
    setError(null)
    try {
      for (const { file, newName } of renameMatches) {
        if (!dryRun) {
          await renameFile(token, file.id, newName)
        }
      }
      const renamedIds = new Set(renameMatches.map((m) => m.file.id))
      setRenameDone((prev) => new Set([...prev, ...renamedIds]))
      if (!dryRun) {
        setFiles((prev) =>
          prev?.map((f) => {
            const match = renameMatches.find((m) => m.file.id === f.id)
            return match ? { ...f, name: match.newName } : f
          }) ?? null,
        )
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Rename failed.')
    } finally {
      setRenaming(false)
    }
  }, [token, renameMatches, dryRun])

  if (!clientId) {
    return (
      <div className="rounded-lg border border-amber-700 bg-[#1a1a2e]/50 p-4 font-mono text-sm text-amber-300">
        <p className="mb-2 font-bold">Setup needed</p>
        <p className="text-slate-400 leading-relaxed">
          Set <code className="text-amber-300">NEXT_PUBLIC_GOOGLE_CLIENT_ID</code> to an OAuth 2.0 Client ID
          from the{' '}
          <a
            className="underline hover:text-amber-200"
            href="https://console.cloud.google.com/apis/credentials"
            target="_blank"
            rel="noreferrer"
          >
            Google Cloud Console
          </a>
          . Enable the Drive API, add the <code className="text-amber-300">drive</code> scope, and add
          this app&apos;s URL as an authorized JavaScript origin.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <Script
        src="https://accounts.google.com/gsi/client"
        strategy="afterInteractive"
        onLoad={() => setGsiReady(true)}
      />

      {/* Settings & functions menu */}
      <div className="rounded-lg border border-purple-800 bg-[#1a1a2e]/50 p-4 font-mono text-sm">
        <button
          onClick={() => setSettingsOpen((v) => !v)}
          className="w-full flex items-center justify-between text-left text-purple-400 tracking-widest text-xs"
        >
          <span>⚙ SETTINGS &amp; FUNCTIONS</span>
          <span className="text-slate-500">{settingsOpen ? '−' : '+'}</span>
        </button>

        {settingsOpen && (
          <div className="mt-4 space-y-4">
            <label className="flex items-center justify-between gap-4 text-slate-300">
              <span>
                <span className="text-amber-300">Dry run</span> — preview only, never trash files
              </span>
              <input
                type="checkbox"
                checked={dryRun}
                onChange={(e) => setDryRun(e.target.checked)}
                className="accent-purple-500 w-4 h-4"
              />
            </label>

            <div className="border-t border-purple-900 pt-3 space-y-3">
              <div className="flex items-center justify-between gap-4 text-slate-300">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={enabledModules.duplicates}
                    onChange={(e) =>
                      setEnabledModules((m) => ({ ...m, duplicates: e.target.checked }))
                    }
                    className="accent-purple-500 w-4 h-4"
                  />
                  <span>Duplicate &amp; recurring item scanner</span>
                </label>
                <div className="flex items-center gap-2 text-slate-500">
                  <span>min copies</span>
                  <input
                    type="number"
                    min={2}
                    value={minDuplicates}
                    onChange={(e) => setMinDuplicates(Math.max(2, Number(e.target.value) || 2))}
                    className="w-16 bg-[#0f0f1a] border border-purple-900 rounded px-2 py-1 text-slate-200"
                  />
                </div>
              </div>

              <div className="flex items-center justify-between gap-4 text-slate-300">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={enabledModules.large}
                    onChange={(e) =>
                      setEnabledModules((m) => ({ ...m, large: e.target.checked }))
                    }
                    className="accent-purple-500 w-4 h-4"
                  />
                  <span>Large file finder</span>
                </label>
                <div className="flex items-center gap-2 text-slate-500">
                  <span>min size (MB)</span>
                  <input
                    type="number"
                    min={1}
                    value={largeFileMb}
                    onChange={(e) => setLargeFileMb(Math.max(1, Number(e.target.value) || 1))}
                    className="w-16 bg-[#0f0f1a] border border-purple-900 rounded px-2 py-1 text-slate-200"
                  />
                </div>
              </div>

              <div className="flex items-center justify-between gap-4 text-slate-300">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={enabledModules.stale}
                    onChange={(e) =>
                      setEnabledModules((m) => ({ ...m, stale: e.target.checked }))
                    }
                    className="accent-purple-500 w-4 h-4"
                  />
                  <span>Stale file finder</span>
                </label>
                <div className="flex items-center gap-2 text-slate-500">
                  <span>inactive days</span>
                  <input
                    type="number"
                    min={1}
                    value={staleDays}
                    onChange={(e) => setStaleDays(Math.max(1, Number(e.target.value) || 1))}
                    className="w-16 bg-[#0f0f1a] border border-purple-900 rounded px-2 py-1 text-slate-200"
                  />
                </div>
              </div>

              <div className="flex items-center justify-between gap-4 text-slate-300">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={enabledModules.automation}
                    onChange={(e) =>
                      setEnabledModules((m) => ({ ...m, automation: e.target.checked }))
                    }
                    className="accent-purple-500 w-4 h-4"
                  />
                  <span>Automation source finder (Apps Script projects)</span>
                </label>
              </div>
            </div>

            <div className="border-t border-purple-900 pt-3 text-slate-600 text-xs leading-relaxed">
              <p className="text-slate-500 font-bold mb-1">COMING SOON</p>
              <p>Full Apps Script trigger audit — detect &amp; disable runaway triggers (V2)</p>
              <p>AI chat history consolidation across apps (V3)</p>
              <p>Background activity tracker, desktop + mobile (V4)</p>
            </div>
          </div>
        )}
      </div>

      {!token && (
        <button
          onClick={connect}
          disabled={!gsiReady}
          className="px-6 py-3 bg-purple-700 hover:bg-purple-600 disabled:opacity-50 text-white font-mono text-sm tracking-widest rounded-lg border border-purple-500 transition-colors"
        >
          {gsiReady ? 'CONNECT GOOGLE DRIVE' : 'LOADING…'}
        </button>
      )}

      {token && !files && (
        <button
          onClick={scan}
          disabled={scanning}
          className="px-6 py-3 bg-purple-700 hover:bg-purple-600 disabled:opacity-50 text-white font-mono text-sm tracking-widest rounded-lg border border-purple-500 transition-colors"
        >
          {scanning ? `SCANNING… (${scanned} items)` : 'SCAN DRIVE'}
        </button>
      )}

      {error && (
        <div className="rounded-lg border border-red-700 bg-[#1a1a2e]/50 p-4 font-mono text-sm text-red-300">
          {error}
        </div>
      )}

      {files && (
        <div className="space-y-8">
          <div className="font-mono text-sm text-slate-400">
            Scanned {scanned} items.
            {dryRun && <span className="text-amber-400"> Dry run is ON — nothing will be trashed.</span>}
          </div>

          {/* Search */}
          <div>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search results by name…"
              className="w-full bg-[#0f0f1a] border border-purple-900 rounded-lg px-4 py-3 font-mono text-sm text-slate-200 placeholder:text-slate-600 focus:outline-none focus:border-purple-600"
            />
          </div>

          {/* Find & replace (bulk rename) */}
          <div className="rounded-lg border border-purple-800 bg-[#1a1a2e]/50 p-4 font-mono text-sm space-y-3">
            <div className="text-xs text-purple-400 tracking-widest">FIND &amp; REPLACE — BULK RENAME</div>
            <div className="flex flex-col sm:flex-row gap-2">
              <input
                type="text"
                value={findText}
                onChange={(e) => setFindText(e.target.value)}
                placeholder="Find in file name…"
                className="flex-1 bg-[#0f0f1a] border border-purple-900 rounded px-3 py-2 text-slate-200 placeholder:text-slate-600 focus:outline-none focus:border-purple-600"
              />
              <input
                type="text"
                value={replaceText}
                onChange={(e) => setReplaceText(e.target.value)}
                placeholder="Replace with…"
                className="flex-1 bg-[#0f0f1a] border border-purple-900 rounded px-3 py-2 text-slate-200 placeholder:text-slate-600 focus:outline-none focus:border-purple-600"
              />
              <button
                onClick={applyRename}
                disabled={renaming || renameMatches.length === 0}
                className="shrink-0 px-4 py-2 bg-purple-700 hover:bg-purple-600 disabled:opacity-50 text-white text-xs tracking-widest rounded-lg border border-purple-500 transition-colors"
              >
                {renaming
                  ? 'RENAMING…'
                  : `${dryRun ? 'PREVIEW' : 'APPLY'} (${renameMatches.length})`}
              </button>
            </div>
            {findText && (
              <div className="text-slate-500 text-xs space-y-1">
                {renameMatches.length === 0 ? (
                  <p>No files match &quot;{findText}&quot;.</p>
                ) : (
                  renameMatches.slice(0, 8).map(({ file, newName }) => (
                    <p key={file.id} className="truncate">
                      {file.name} <span className="text-purple-400">→</span> {newName}
                    </p>
                  ))
                )}
                {renameMatches.length > 8 && <p>…and {renameMatches.length - 8} more.</p>}
              </div>
            )}
          </div>

          {/* Duplicates */}
          {enabledModules.duplicates && (
            <div className="space-y-4">
              <div className="font-mono text-xs text-purple-400 tracking-widest">
                RECURRING ITEMS {visibleGroups.length > 0 && `(${visibleGroups.length})`}
              </div>
              {visibleGroups.length === 0 ? (
                <div className="font-mono text-sm text-slate-500">No recurring clutter found.</div>
              ) : (
                visibleGroups.map((group) => {
                  const groupKey = `${group.name}::${group.mimeType}`
                  const isFolder = group.mimeType === 'application/vnd.google-apps.folder'
                  const oldest = group.files[0]
                  const newest = group.files[group.files.length - 1]

                  return (
                    <div
                      key={groupKey}
                      className="rounded-lg border border-purple-800 bg-[#1a1a2e]/50 p-4 font-mono text-sm"
                    >
                      <div className="flex items-start justify-between gap-4">
                        <div>
                          <div className="text-slate-100 font-bold">
                            {group.name} <span className="text-slate-500">({isFolder ? 'folder' : 'file'})</span>
                          </div>
                          <div className="text-purple-400 mt-1">{group.files.length} copies</div>
                          <div className="text-slate-500 text-xs mt-2">
                            First created: {formatDate(oldest.createdTime)}
                            <br />
                            Most recent: {formatDate(newest.createdTime)}
                          </div>
                        </div>
                        <div className="flex flex-col gap-2 shrink-0">
                          <button
                            onClick={() => cleanGroup(group)}
                            disabled={busyGroup === groupKey}
                            className="px-4 py-2 bg-red-900/60 hover:bg-red-800/80 disabled:opacity-50 text-red-200 text-xs tracking-widest rounded-lg border border-red-700 transition-colors"
                          >
                            {busyGroup === groupKey
                              ? 'CLEANING…'
                              : `${dryRun ? 'PREVIEW' : 'TRASH'} ${group.files.length - 1}, KEEP NEWEST`}
                          </button>
                          <button
                            onClick={() => explainGroup(group)}
                            disabled={explaining === groupKey}
                            className="px-4 py-2 bg-[#1a1a2e] hover:bg-[#22223a] disabled:opacity-50 text-purple-300 text-xs tracking-widest rounded-lg border border-purple-800 transition-colors"
                          >
                            {explaining === groupKey ? 'THINKING…' : 'AI: WHY?'}
                          </button>
                        </div>
                      </div>
                      {explanations[groupKey] && (
                        <div className="mt-3 pt-3 border-t border-purple-900 text-slate-400 text-xs leading-relaxed">
                          {explanations[groupKey]}
                        </div>
                      )}
                    </div>
                  )
                })
              )}
            </div>
          )}

          {/* Large files */}
          {enabledModules.large && (
            <div className="space-y-4">
              <div className="font-mono text-xs text-purple-400 tracking-widest">
                LARGE FILES ≥ {largeFileMb} MB {visibleLargeFiles.length > 0 && `(${visibleLargeFiles.length})`}
              </div>
              {visibleLargeFiles.length === 0 ? (
                <div className="font-mono text-sm text-slate-500">No files at or above this size.</div>
              ) : (
                visibleLargeFiles.slice(0, 25).map((file) => (
                  <div
                    key={file.id}
                    className="rounded-lg border border-purple-800 bg-[#1a1a2e]/50 p-4 font-mono text-sm flex items-start justify-between gap-4"
                  >
                    <div>
                      <div className="text-slate-100 font-bold">{file.name}</div>
                      <div className="text-purple-400 mt-1">{formatBytes(Number(file.size ?? 0))}</div>
                      <div className="text-slate-500 text-xs mt-2">
                        Modified: {formatDate(file.modifiedTime)}
                      </div>
                    </div>
                    <button
                      onClick={() => trashSingleFile(file)}
                      disabled={busyFile === file.id}
                      className="shrink-0 px-4 py-2 bg-red-900/60 hover:bg-red-800/80 disabled:opacity-50 text-red-200 text-xs tracking-widest rounded-lg border border-red-700 transition-colors"
                    >
                      {busyFile === file.id ? '…' : dryRun ? 'PREVIEW TRASH' : 'TRASH'}
                    </button>
                  </div>
                ))
              )}
              {visibleLargeFiles.length > 25 && (
                <div className="font-mono text-xs text-slate-600">…and {visibleLargeFiles.length - 25} more.</div>
              )}
            </div>
          )}

          {/* Stale files */}
          {enabledModules.stale && (
            <div className="space-y-4">
              <div className="font-mono text-xs text-purple-400 tracking-widest">
                STALE FILES — INACTIVE {staleDays}+ DAYS {visibleStaleFiles.length > 0 && `(${visibleStaleFiles.length})`}
              </div>
              {visibleStaleFiles.length === 0 ? (
                <div className="font-mono text-sm text-slate-500">Nothing has been inactive that long.</div>
              ) : (
                visibleStaleFiles.slice(0, 25).map((file) => (
                  <div
                    key={file.id}
                    className="rounded-lg border border-purple-800 bg-[#1a1a2e]/50 p-4 font-mono text-sm flex items-start justify-between gap-4"
                  >
                    <div>
                      <div className="text-slate-100 font-bold">{file.name}</div>
                      <div className="text-slate-500 text-xs mt-2">
                        Last modified: {formatDate(file.modifiedTime)}
                        {file.viewedByMeTime && (
                          <>
                            <br />
                            Last viewed: {formatDate(file.viewedByMeTime)}
                          </>
                        )}
                      </div>
                    </div>
                    <button
                      onClick={() => trashSingleFile(file)}
                      disabled={busyFile === file.id}
                      className="shrink-0 px-4 py-2 bg-red-900/60 hover:bg-red-800/80 disabled:opacity-50 text-red-200 text-xs tracking-widest rounded-lg border border-red-700 transition-colors"
                    >
                      {busyFile === file.id ? '…' : dryRun ? 'PREVIEW TRASH' : 'TRASH'}
                    </button>
                  </div>
                ))
              )}
              {visibleStaleFiles.length > 25 && (
                <div className="font-mono text-xs text-slate-600">…and {visibleStaleFiles.length - 25} more.</div>
              )}
            </div>
          )}

          {/* Automation sources */}
          {enabledModules.automation && (
            <div className="space-y-4">
              <div className="font-mono text-xs text-purple-400 tracking-widest">
                AUTOMATION SOURCES — APPS SCRIPT PROJECTS {visibleAutomationSources.length > 0 && `(${visibleAutomationSources.length})`}
              </div>
              {visibleAutomationSources.length === 0 ? (
                <div className="font-mono text-sm text-slate-500">No Apps Script projects found.</div>
              ) : (
                <>
                  <div className="font-mono text-xs text-slate-500 leading-relaxed">
                    Any of these can hold a time-driven trigger that runs in the background even
                    when you&apos;re not using it. Open one in the script editor and check
                    Triggers (clock icon) to find and disable runaway automations.
                  </div>
                  {visibleAutomationSources.map((file) => (
                    <div
                      key={file.id}
                      className="rounded-lg border border-purple-800 bg-[#1a1a2e]/50 p-4 font-mono text-sm flex items-start justify-between gap-4"
                    >
                      <div>
                        <div className="text-slate-100 font-bold">{file.name}</div>
                        <div className="text-slate-500 text-xs mt-2">
                          Last modified: {formatDate(file.modifiedTime)}
                        </div>
                      </div>
                      <a
                        href={`https://script.google.com/d/${file.id}/edit`}
                        target="_blank"
                        rel="noreferrer"
                        className="shrink-0 px-4 py-2 bg-purple-700 hover:bg-purple-600 text-white text-xs tracking-widest rounded-lg border border-purple-500 transition-colors"
                      >
                        OPEN SCRIPT
                      </a>
                    </div>
                  ))}
                </>
              )}
            </div>
          )}

          <button
            onClick={scan}
            disabled={scanning}
            className="px-6 py-3 bg-[#1a1a2e] hover:bg-[#22223a] disabled:opacity-50 text-slate-300 font-mono text-sm tracking-widest rounded-lg border border-purple-800 transition-colors"
          >
            {scanning ? `SCANNING… (${scanned} items)` : 'RE-SCAN'}
          </button>
        </div>
      )}
    </div>
  )
}
