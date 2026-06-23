import { create } from 'zustand';

export type PanelTab = 'terminal' | 'problems' | 'output' | 'debugConsole';

interface PanelState {
  activeTab: PanelTab;
  isVisible: boolean;
  height: number;
  setTab: (tab: PanelTab) => void;
  toggle: () => void;
  show: () => void;
  setHeight: (h: number) => void;
}

export const usePanelStore = create<PanelState>((set, get) => ({
  activeTab: 'terminal',
  isVisible: false,
  height: 200,

  setTab: (tab) => {
    if (!get().isVisible) {
      set({ activeTab: tab, isVisible: true });
    } else if (get().activeTab === tab) {
      set({ isVisible: false });
    } else {
      set({ activeTab: tab });
    }
  },

  toggle: () => set((s) => ({ isVisible: !s.isVisible })),
  show: () => set({ isVisible: true }),
  setHeight: (h) => set({ height: Math.max(100, Math.min(500, h)) }),
}));
