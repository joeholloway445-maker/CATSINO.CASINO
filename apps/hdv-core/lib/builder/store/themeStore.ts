import { create } from 'zustand';

export type Theme = 'dark' | 'light' | 'solarized' | 'monokai' | 'github';

interface ThemeState {
  theme: Theme;
  setTheme: (t: Theme) => void;
}

const THEME_CLASS_MAP: Record<Theme, string> = {
  dark: '',
  light: 'vs-light',
  solarized: 'vs-solarized-dark',
  monokai: 'vs-monokai',
  github: 'vs-github',
};

export const useThemeStore = create<ThemeState>((set) => ({
  theme: 'dark',
  setTheme: (t) => {
    const root = document.documentElement;
    Object.values(THEME_CLASS_MAP).forEach((cls) => {
      if (cls) root.classList.remove(cls);
    });
    if (THEME_CLASS_MAP[t]) {
      root.classList.add(THEME_CLASS_MAP[t]);
    }
    set({ theme: t });
  },
}));
