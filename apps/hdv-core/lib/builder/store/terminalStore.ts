import { create } from 'zustand';

export interface OutputLine {
  type: 'prompt' | 'output' | 'error' | 'success' | 'info' | 'claude-input' | 'claude-output' | 'claude-tool';
  text: string;
}

export interface TerminalTab {
  id: string;
  name: string;
  cwd: string;
  history: string[];
  output: OutputLine[];
  mode: 'shell' | 'claude';
}

export interface TerminalState {
  terminals: TerminalTab[];
  activeTerminalId: string;
  showPanel: boolean;
  activePanelTab: 'terminal' | 'problems' | 'output' | 'debugConsole';
  createTerminal: (name?: string) => string;
  closeTerminal: (id: string) => void;
  setActiveTerminal: (id: string) => void;
  addOutput: (id: string, line: OutputLine) => void;
  setCwd: (id: string, cwd: string) => void;
  setMode: (id: string, mode: 'shell' | 'claude') => void;
  clearOutput: (id: string) => void;
  addHistory: (id: string, command: string) => void;
  togglePanel: () => void;
  showPanelFn: () => void;
  setActivePanelTab: (tab: 'terminal' | 'problems' | 'output' | 'debugConsole') => void;
  appendOutput: (id: string, text: string) => void;
}

// Initial terminal: one bash tab
const initialTerminal: TerminalTab = {
  id: 'term-1',
  name: 'bash',
  cwd: '/home/user/workspace',
  history: [],
  output: [],
  mode: 'shell',
};

let nextTermId = 2;

export const useTerminalStore = create<TerminalState>((set, get) => ({
  terminals: [initialTerminal],
  activeTerminalId: 'term-1',
  showPanel: false,
  activePanelTab: 'terminal',

  createTerminal: (name?: string) => {
    const id = `term-${nextTermId++}`;
    const termName = name || `bash-${nextTermId - 1}`;
    const newTerm: TerminalTab = {
      id,
      name: termName,
      cwd: '/home/user/workspace',
      history: [],
      output: [],
      mode: 'shell',
    };
    set({ terminals: [...get().terminals, newTerm], activeTerminalId: id, showPanel: true });
    return id;
  },

  closeTerminal: (id: string) => {
    const terms = get().terminals.filter(t => t.id !== id);
    if (terms.length === 0) {
      // Create a fresh default terminal
      const newId = `term-${nextTermId++}`;
      const newTerm: TerminalTab = {
        id: newId,
        name: 'bash',
        cwd: '/home/user/workspace',
        history: [],
        output: [],
        mode: 'shell',
      };
      set({ terminals: [newTerm], activeTerminalId: newId });
      return;
    }
    const newActive = get().activeTerminalId === id ? terms[0].id : get().activeTerminalId;
    set({ terminals: terms, activeTerminalId: newActive });
  },

  setActiveTerminal: (id: string) => {
    set({ activeTerminalId: id });
  },

  addOutput: (id: string, line: OutputLine) => {
    set({
      terminals: get().terminals.map(t =>
        t.id === id ? { ...t, output: [...t.output, line] } : t
      ),
    });
  },

  appendOutput: (id: string, text: string) => {
    set({
      terminals: get().terminals.map(t => {
        if (t.id !== id) return t;
        const out = [...t.output];
        if (out.length > 0 && out[out.length - 1].type === 'claude-output') {
          out[out.length - 1] = { ...out[out.length - 1], text: out[out.length - 1].text + text };
        } else {
          out.push({ type: 'claude-output', text });
        }
        return { ...t, output: out };
      }),
    });
  },

  setCwd: (id: string, cwd: string) => {
    set({
      terminals: get().terminals.map(t =>
        t.id === id ? { ...t, cwd } : t
      ),
    });
  },

  setMode: (id: string, mode: 'shell' | 'claude') => {
    set({
      terminals: get().terminals.map(t =>
        t.id === id ? { ...t, mode } : t
      ),
    });
  },

  clearOutput: (id: string) => {
    set({
      terminals: get().terminals.map(t =>
        t.id === id ? { ...t, output: [] } : t
      ),
    });
  },

  addHistory: (id: string, command: string) => {
    set({
      terminals: get().terminals.map(t =>
        t.id === id ? { ...t, history: [...t.history, command] } : t
      ),
    });
  },

  togglePanel: () => set(s => ({ showPanel: !s.showPanel })),

  showPanelFn: () => set({ showPanel: true }),

  setActivePanelTab: (tab: 'terminal' | 'problems' | 'output' | 'debugConsole') => {
    set({ activePanelTab: tab });
  },
}));
