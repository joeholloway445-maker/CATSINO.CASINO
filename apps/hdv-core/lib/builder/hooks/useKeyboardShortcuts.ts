import { useEffect } from 'react';

export type CommandId =
  | 'toggleSidebar'
  | 'togglePanel'
  | 'commandPalette'
  | 'quickOpen'
  | 'save'
  | 'closeTab'
  | 'newFile'
  | 'newWindow'
  | 'toggleZenMode'
  | 'splitEditor';

interface ShortcutDef {
  key: string;
  ctrl?: boolean;
  shift?: boolean;
  alt?: boolean;
  meta?: boolean;
}

const SHORTCUTS: Record<CommandId, ShortcutDef> = {
  toggleSidebar: { key: 'b', ctrl: true },
  togglePanel: { key: 'j', ctrl: true },
  commandPalette: { key: 'p', ctrl: true, shift: true },
  quickOpen: { key: 'p', ctrl: true },
  save: { key: 's', ctrl: true },
  closeTab: { key: 'w', ctrl: true },
  newFile: { key: 'n', ctrl: true },
  newWindow: { key: 'n', ctrl: true, shift: true },
  toggleZenMode: { key: 'k', ctrl: true, shift: true },
  splitEditor: { key: '\\', ctrl: true },
};

type CommandHandler = () => void;

class CommandRegistry {
  private handlers = new Map<CommandId, Set<CommandHandler>>();

  register(commandId: CommandId, handler: CommandHandler): () => void {
    if (!this.handlers.has(commandId)) {
      this.handlers.set(commandId, new Set());
    }
    this.handlers.get(commandId)!.add(handler);
    return () => {
      this.handlers.get(commandId)?.delete(handler);
    };
  }

  execute(commandId: CommandId): void {
    const handlers = this.handlers.get(commandId);
    if (handlers) {
      handlers.forEach((h) => h());
    }
  }

  hasHandler(commandId: CommandId): boolean {
    return (this.handlers.get(commandId)?.size ?? 0) > 0;
  }
}

export const commandRegistry = new CommandRegistry();

export function useKeyboardShortcuts() {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Skip when typing in input/textarea
      const target = e.target as HTMLElement;
      if (
        target.tagName === 'INPUT' ||
        target.tagName === 'TEXTAREA' ||
        target.isContentEditable
      ) {
        return;
      }

      for (const [commandId, shortcut] of Object.entries(SHORTCUTS) as [CommandId, ShortcutDef][]) {
        const isCtrl = shortcut.ctrl && (e.ctrlKey || e.metaKey);
        const isShift = shortcut.shift && e.shiftKey;
        const isAlt = shortcut.alt && e.altKey;
        const isMeta = shortcut.meta && e.metaKey;

        const matchesKey = e.key.toLowerCase() === shortcut.key.toLowerCase();
        const matchesModifiers =
          (!shortcut.ctrl || isCtrl) &&
          (!shortcut.shift || isShift) &&
          (!shortcut.alt || isAlt) &&
          (!shortcut.meta || isMeta);

        if (matchesKey && matchesModifiers) {
          e.preventDefault();
          commandRegistry.execute(commandId);
          break;
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);
}

export function registerShortcut(commandId: CommandId, handler: () => void): () => void {
  return commandRegistry.register(commandId, handler);
}
