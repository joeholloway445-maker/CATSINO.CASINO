import { create } from 'zustand';

export interface EditorTab {
  id: string;
  name: string;
  path: string;
  content: string;
  language: string;
  isDirty: boolean;
  isActive: boolean;
}

export interface EditorSplit {
  id: string;
  tabIds: string[];
  activeTabId: string | null;
}

interface EditorState {
  tabs: EditorTab[];
  activeTabId: string | null;
  splits: EditorSplit[];
  activeSplitIndex: number;
  openFile: (path: string, name: string, content: string, language: string) => void;
  closeTab: (tabId: string) => void;
  setActiveTab: (tabId: string) => void;
  updateTabContent: (tabId: string, content: string) => void;
  markClean: (tabId: string) => void;
  markDirty: (tabId: string) => void;
  newUntitled: () => string;
  splitEditor: () => void;
  closeSplit: (splitId: string) => void;
  getActiveTab: () => EditorTab | undefined;
  getTabByPath: (path: string) => EditorTab | undefined;
}

let untitledCounter = 1;

export const useEditorStore = create<EditorState>((set, get) => ({
  tabs: [],
  activeTabId: null,
  splits: [{ id: 'split-0', tabIds: [], activeTabId: null }],
  activeSplitIndex: 0,

  openFile: (path, name, content, language) => {
    const existing = get().tabs.find((t) => t.path === path);
    if (existing) {
      set({ activeTabId: existing.id });
      const splitIdx = get().activeSplitIndex;
      const splits = [...get().splits];
      if (!splits[splitIdx].tabIds.includes(existing.id)) {
        splits[splitIdx].tabIds.push(existing.id);
      }
      splits[splitIdx].activeTabId = existing.id;
      set({ splits });
      return;
    }

    const newTab: EditorTab = {
      id: `tab-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      name,
      path,
      content,
      language,
      isDirty: false,
      isActive: true,
    };

    const splitIdx = get().activeSplitIndex;
    const splits = [...get().splits];
    splits[splitIdx].tabIds.push(newTab.id);
    splits[splitIdx].activeTabId = newTab.id;

    set({
      tabs: [...get().tabs.map((t) => ({ ...t, isActive: false })), newTab],
      activeTabId: newTab.id,
      splits,
    });
  },

  closeTab: (tabId) => {
    const state = get();
    const newTabs = state.tabs.filter((t) => t.id !== tabId);
    const splits = state.splits.map((s) => ({
      ...s,
      tabIds: s.tabIds.filter((id) => id !== tabId),
      activeTabId: s.activeTabId === tabId
        ? s.tabIds.filter((id) => id !== tabId).at(-1) ?? null
        : s.activeTabId,
    }));

    let newActiveId = state.activeTabId;
    if (state.activeTabId === tabId) {
      newActiveId = newTabs.at(-1)?.id ?? null;
    }

    set({ tabs: newTabs, activeTabId: newActiveId, splits });
  },

  setActiveTab: (tabId) => {
    const splits = [...get().splits];
    const splitIdx = get().activeSplitIndex;
    splits[splitIdx].activeTabId = tabId;
    set({
      activeTabId: tabId,
      tabs: get().tabs.map((t) => ({ ...t, isActive: t.id === tabId })),
      splits,
    });
  },

  updateTabContent: (tabId, content) => {
    set({
      tabs: get().tabs.map((t) =>
        t.id === tabId ? { ...t, content, isDirty: true } : t
      ),
    });
  },

  markClean: (tabId) => {
    set({
      tabs: get().tabs.map((t) =>
        t.id === tabId ? { ...t, isDirty: false } : t
      ),
    });
  },

  markDirty: (tabId) => {
    set({
      tabs: get().tabs.map((t) =>
        t.id === tabId ? { ...t, isDirty: true } : t
      ),
    });
  },

  newUntitled: () => {
    const id = `tab-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    const name = `Untitled-${untitledCounter++}`;
    const newTab: EditorTab = {
      id,
      name,
      path: name,
      content: '',
      language: 'plaintext',
      isDirty: false,
      isActive: true,
    };
    const splitIdx = get().activeSplitIndex;
    const splits = [...get().splits];
    splits[splitIdx].tabIds.push(id);
    splits[splitIdx].activeTabId = id;
    set({
      tabs: [...get().tabs.map((t) => ({ ...t, isActive: false })), newTab],
      activeTabId: id,
      splits,
    });
    return id;
  },

  splitEditor: () => {
    const state = get();
    if (state.splits.length >= 3) return;
    const newSplit: EditorSplit = {
      id: `split-${state.splits.length}`,
      tabIds: [],
      activeTabId: null,
    };
    set({
      splits: [...state.splits, newSplit],
      activeSplitIndex: state.splits.length,
    });
  },

  closeSplit: (splitId) => {
    const state = get();
    if (state.splits.length <= 1) return;
    const idx = state.splits.findIndex((s) => s.id === splitId);
    if (idx === -1) return;
    const splits = state.splits.filter((s) => s.id !== splitId);
    set({
      splits,
      activeSplitIndex: Math.min(state.activeSplitIndex, splits.length - 1),
    });
  },

  getActiveTab: () => {
    return get().tabs.find((t) => t.id === get().activeTabId);
  },

  getTabByPath: (path) => {
    return get().tabs.find((t) => t.path === path);
  },
}));
