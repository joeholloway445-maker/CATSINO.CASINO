import { create } from 'zustand';

export type SidebarView = 'explorer' | 'search' | 'scm' | 'run' | 'extensions';

interface SidebarState {
  activeView: SidebarView;
  isVisible: boolean;
  width: number;
  setView: (view: SidebarView) => void;
  toggle: () => void;
  show: () => void;
  setWidth: (width: number) => void;
}

export const useSidebarStore = create<SidebarState>((set, get) => ({
  activeView: 'explorer',
  isVisible: true,
  width: 260,

  setView: (view) => {
    if (!get().isVisible) {
      set({ activeView: view, isVisible: true });
    } else if (get().activeView === view) {
      set({ isVisible: false });
    } else {
      set({ activeView: view });
    }
  },

  toggle: () => set((s) => ({ isVisible: !s.isVisible })),
  show: () => set({ isVisible: true }),
  setWidth: (width) => set({ width: Math.max(170, Math.min(600, width)) }),
}));
