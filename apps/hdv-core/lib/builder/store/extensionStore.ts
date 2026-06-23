import { create } from 'zustand';
import { extensions as mockExtensions, type Extension } from '@/lib/builder/data/extensions';

interface ExtensionState {
  extensions: Extension[];
  install: (id: string) => void;
  uninstall: (id: string) => void;
  toggleEnabled: (id: string) => void;
}

export const useExtensionStore = create<ExtensionState>((set) => ({
  extensions: mockExtensions,
  install: (id) => set((s) => ({
    extensions: s.extensions.map((e) => e.id === id ? { ...e, installed: true, enabled: true } : e)
  })),
  uninstall: (id) => set((s) => ({
    extensions: s.extensions.map((e) => e.id === id ? { ...e, installed: false, enabled: false } : e)
  })),
  toggleEnabled: (id) => set((s) => ({
    extensions: s.extensions.map((e) => e.id === id && e.installed ? { ...e, enabled: !e.enabled } : e)
  })),
}));
