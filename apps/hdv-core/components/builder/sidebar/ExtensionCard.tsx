import type { Extension } from '@/lib/builder/data/extensions';
import { StarIcon, DownloadIcon, GearIcon } from './ExtensionIcons';

interface Props {
  ext: Extension;
  onClick: () => void;
  onInstall: () => void;
  onUninstall: () => void;
  onToggleEnable: () => void;
}

export function ExtensionCard({ ext, onClick, onInstall, onUninstall, onToggleEnable }: Props) {
  const firstLetter = ext.name.charAt(0).toUpperCase();

  return (
    <div
      className="flex items-start gap-3 p-3 cursor-pointer hover:bg-[var(--vscode-list-hover)] border-b border-[var(--vscode-border)] group"
      onClick={onClick}
    >
      {/* Colored circle icon */}
      <div
        className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold text-lg flex-shrink-0"
        style={{ backgroundColor: ext.iconColor }}
      >
        {firstLetter}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-[var(--vscode-fg)] text-sm font-medium truncate">{ext.name}</span>
          {ext.installed && (
            <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-[var(--vscode-badge-bg)] text-[var(--vscode-badge-fg)]">
              {ext.enabled ? 'Enabled' : 'Disabled'}
            </span>
          )}
        </div>
        <div className="text-[var(--vscode-fg)] opacity-50 text-xs truncate">{ext.publisher}</div>
        <div className="text-[var(--vscode-fg)] opacity-70 text-xs truncate mt-0.5">{ext.description}</div>
        <div className="flex items-center gap-3 mt-1 text-xs text-[var(--vscode-fg)] opacity-50">
          <span className="flex items-center gap-0.5">
            <StarIcon size={10} />
            {ext.rating.toFixed(1)}
          </span>
          <span className="flex items-center gap-0.5">
            <DownloadIcon size={10} />
            {ext.downloads}
          </span>
          <span>v{ext.version}</span>
        </div>
      </div>

      {/* Actions */}
      <div className="flex flex-col gap-1 flex-shrink-0" onClick={(e) => e.stopPropagation()}>
        {ext.installed ? (
          <>
            <button
              onClick={onUninstall}
              className="px-2.5 py-1 text-xs bg-[var(--vscode-button-bg)] text-white rounded hover:opacity-90 opacity-0 group-hover:opacity-100 transition-opacity"
            >
              Uninstall
            </button>
            <button
              onClick={onToggleEnable}
              className="px-2.5 py-1 text-xs border border-[var(--vscode-border)] text-[var(--vscode-fg)] rounded hover:bg-[var(--vscode-list-hover)] opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
              title={ext.enabled ? 'Disable' : 'Enable'}
            >
              <GearIcon size={10} />
            </button>
          </>
        ) : (
          <button
            onClick={onInstall}
            className="px-2.5 py-1 text-xs bg-[var(--vscode-button-bg)] text-white rounded hover:opacity-90 opacity-0 group-hover:opacity-100 transition-opacity"
          >
            Install
          </button>
        )}
      </div>
    </div>
  );
}
