import { create } from 'zustand';

interface ProblemsCount {
  warnings: number;
  errors: number;
}

interface StatusBarState {
  branch: string;
  language: string;
  line: number;
  col: number;
  problems: ProblemsCount;
  isFormatting: boolean;
  encoding: string;
  eol: string;
  indentation: string;
  setBranch: (branch: string) => void;
  setLanguage: (lang: string) => void;
  setCursor: (line: number, col: number) => void;
  setProblems: (problems: ProblemsCount) => void;
  setFormatting: (formatting: boolean) => void;
  setEncoding: (enc: string) => void;
  setEol: (eol: string) => void;
  setIndentation: (indent: string) => void;
}

export const useStatusBarStore = create<StatusBarState>((set) => ({
  branch: 'main',
  language: 'TypeScript',
  line: 1,
  col: 1,
  problems: { warnings: 0, errors: 0 },
  isFormatting: false,
  encoding: 'UTF-8',
  eol: 'LF',
  indentation: 'Spaces: 2',

  setBranch: (branch) => set({ branch }),
  setLanguage: (language) => set({ language }),
  setCursor: (line, col) => set({ line, col }),
  setProblems: (problems) => set({ problems }),
  setFormatting: (isFormatting) => set({ isFormatting }),
  setEncoding: (encoding) => set({ encoding }),
  setEol: (eol) => set({ eol }),
  setIndentation: (indentation) => set({ indentation }),
}));
