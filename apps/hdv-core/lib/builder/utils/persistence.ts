import { openDB, type DBSchema } from 'idb';
import type { EditorTab } from '@/lib/builder/store/editorStore';
import type { FileNode } from '@/lib/builder/store/fileSystemStore';

interface VSCodeDB extends DBSchema {
  files: {
    key: string;
    value: { path: string; content: string; language: string; updatedAt: number };
  };
  tabs: {
    key: string;
    value: EditorTab;
  };
  settings: {
    key: string;
    value: unknown;
  };
  extensions: {
    key: string;
    value: { id: string; installed: boolean; name: string };
  };
  git: {
    key: string;
    value: { branch: string; commits: unknown[]; staged: string[]; changes: string[] };
  };
  terminal: {
    key: string;
    value: { history: string[]; cwd: string };
  };
  filesystem: {
    key: string;
    value: FileNode[];
  };
}

const DB_NAME = 'vscode-web-db';
const DB_VERSION = 1;

async function getDB() {
  return openDB<VSCodeDB>(DB_NAME, DB_VERSION, {
    upgrade(db) {
      if (!db.objectStoreNames.contains('files')) db.createObjectStore('files', { keyPath: 'path' });
      if (!db.objectStoreNames.contains('tabs')) db.createObjectStore('tabs', { keyPath: 'id' });
      if (!db.objectStoreNames.contains('settings')) db.createObjectStore('settings');
      if (!db.objectStoreNames.contains('extensions')) db.createObjectStore('extensions', { keyPath: 'id' });
      if (!db.objectStoreNames.contains('git')) db.createObjectStore('git', { keyPath: 'branch' });
      if (!db.objectStoreNames.contains('terminal')) db.createObjectStore('terminal', { keyPath: 'cwd' });
      if (!db.objectStoreNames.contains('filesystem')) db.createObjectStore('filesystem');
    },
  });
}

/* ---------- files ---------- */
export async function saveFile(path: string, content: string, language: string): Promise<void> {
  const db = await getDB();
  await db.put('files', { path, content, language, updatedAt: Date.now() });
}

export async function loadFile(path: string): Promise<{ content: string; language: string } | undefined> {
  const db = await getDB();
  const result = await db.get('files', path);
  return result ? { content: result.content, language: result.language } : undefined;
}

/* ---------- tabs ---------- */
export async function saveTabs(tabs: EditorTab[]): Promise<void> {
  const db = await getDB();
  const tx = db.transaction('tabs', 'readwrite');
  await tx.store.clear();
  for (const tab of tabs) {
    await tx.store.put(tab);
  }
  await tx.done;
}

export async function loadTabs(): Promise<EditorTab[]> {
  const db = await getDB();
  return db.getAll('tabs');
}

/* ---------- settings ---------- */
export async function saveSettings(key: string, value: unknown): Promise<void> {
  const db = await getDB();
  await db.put('settings', value, key);
}

export async function loadSettings(key: string): Promise<unknown | undefined> {
  const db = await getDB();
  return db.get('settings', key);
}

/* ---------- extensions ---------- */
export async function saveExtensions(extensions: Array<{ id: string; installed: boolean; name: string }>): Promise<void> {
  const db = await getDB();
  const tx = db.transaction('extensions', 'readwrite');
  await tx.store.clear();
  for (const ext of extensions) {
    await tx.store.put(ext);
  }
  await tx.done;
}

export async function loadExtensions(): Promise<Array<{ id: string; installed: boolean; name: string }>> {
  const db = await getDB();
  return db.getAll('extensions');
}

/* ---------- git ---------- */
export async function saveGit(data: { branch: string; commits: unknown[]; staged: string[]; changes: string[] }): Promise<void> {
  const db = await getDB();
  await db.put('git', data);
}

export async function loadGit(): Promise<{ branch: string; commits: unknown[]; staged: string[]; changes: string[] } | undefined> {
  const db = await getDB();
  return db.get('git', 'main');
}

/* ---------- terminal ---------- */
export async function saveTerminal(cwd: string, history: string[]): Promise<void> {
  const db = await getDB();
  await db.put('terminal', { cwd, history });
}

export async function loadTerminal(): Promise<{ history: string[]; cwd: string } | undefined> {
  const db = await getDB();
  return db.get('terminal', '/');
}

/* ---------- filesystem ---------- */
export async function saveFileSystem(root: FileNode[]): Promise<void> {
  const db = await getDB();
  await db.put('filesystem', root, 'root');
}

export async function loadFileSystem(): Promise<FileNode[] | undefined> {
  const db = await getDB();
  return db.get('filesystem', 'root');
}
