import { useState } from 'react';
import type { Extension } from '@/lib/builder/data/extensions';
import { BackIcon, StarIcon, DownloadIcon } from './ExtensionIcons';

type Tab = 'DETAILS' | 'FEATURES' | 'CHANGELOG';

interface Props {
  ext: Extension;
  onBack: () => void;
  onInstall: () => void;
  onUninstall: () => void;
  onToggleEnable: () => void;
}

export function ExtensionDetail({ ext, onBack, onInstall, onUninstall, onToggleEnable }: Props) {
  const [activeTab, setActiveTab] = useState<Tab>('DETAILS');
  const firstLetter = ext.name.charAt(0).toUpperCase();

  const tabs: Tab[] = ['DETAILS', 'FEATURES', 'CHANGELOG'];

  return (
    <div className="flex flex-col h-full text-[var(--vscode-fg)]">
      {/* Header with back button */}
      <div className="flex items-center gap-2 p-2 border-b border-[var(--vscode-border)]">
        <button
          onClick={onBack}
          className="w-7 h-7 flex items-center justify-center hover:bg-[var(--vscode-list-hover)] rounded"
          title="Back"
        >
          <BackIcon size={16} />
        </button>
        <span className="text-xs opacity-60">Extensions</span>
      </div>

      {/* Extension info */}
      <div className="p-4 flex items-start gap-4">
        <div
          className="w-16 h-16 rounded-full flex items-center justify-center text-white font-bold text-2xl flex-shrink-0"
          style={{ backgroundColor: ext.iconColor }}
        >
          {firstLetter}
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-[var(--vscode-fg)] text-base font-semibold">{ext.name}</div>
          <div className="text-[var(--vscode-fg)] opacity-50 text-xs">{ext.publisher}</div>
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
      </div>

      {/* Action buttons */}
      <div className="px-4 pb-3 flex gap-2">
        {ext.installed ? (
          <>
            <button
              onClick={onUninstall}
              className="px-4 py-1.5 text-xs bg-[var(--vscode-button-bg)] text-white rounded hover:opacity-90"
            >
              Uninstall
            </button>
            <button
              onClick={onToggleEnable}
              className="px-4 py-1.5 text-xs border border-[var(--vscode-border)] text-[var(--vscode-fg)] rounded hover:bg-[var(--vscode-list-hover)]"
            >
              {ext.enabled ? 'Disable' : 'Enable'}
            </button>
          </>
        ) : (
          <button
            onClick={onInstall}
            className="px-4 py-1.5 text-xs bg-[var(--vscode-button-bg)] text-white rounded hover:opacity-90"
          >
            Install
          </button>
        )}
      </div>

      {/* Tabs */}
      <div className="flex border-b border-[var(--vscode-border)]">
        {tabs.map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-3 py-1.5 text-xs font-medium ${
              activeTab === tab
                ? 'text-[var(--vscode-fg)] border-b-2 border-[var(--vscode-focusBorder)]'
                : 'text-[var(--vscode-fg)] opacity-50 hover:opacity-80'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Tab content */}
      <div className="flex-1 overflow-auto p-4 text-sm">
        {activeTab === 'DETAILS' && (
          <div style={{ fontSize: 13, lineHeight: '20px' }}>
            {ext.readme.split('\n').map((line, i) => {
              if (line.startsWith('# ')) return <h2 key={i} style={{ fontSize: 16, fontWeight: 600, margin: '12px 0 8px' }}>{line.slice(2)}</h2>;
              if (line.startsWith('## ')) return <h3 key={i} style={{ fontSize: 14, fontWeight: 600, margin: '10px 0 6px' }}>{line.slice(3)}</h3>;
              if (line.startsWith('- ')) return <li key={i} style={{ marginLeft: 16 }}>{line.slice(2)}</li>;
              if (line === '') return <div key={i} style={{ height: 8 }} />;
              return <p key={i} style={{ margin: '4px 0' }}>{line}</p>;
            })}
            {ext.isFunctional && (
              <div className="mt-4 p-3 bg-[var(--vscode-input-bg)] rounded text-xs opacity-70">
                This extension provides interactive functionality within the editor.
              </div>
            )}
          </div>
        )}
        {activeTab === 'FEATURES' && (
          <ul style={{ listStyle: 'disc', paddingLeft: 20, fontSize: 13, lineHeight: '22px' }}>
            {ext.features.map((f, i) => <li key={i}>{f}</li>)}
          </ul>
        )}
        {activeTab === 'CHANGELOG' && (
          <div style={{ fontSize: 13 }}>
            {ext.changelog.map((entry, i) => (
              <div key={i} style={{ marginBottom: 12, paddingBottom: 8, borderBottom: '1px solid var(--vscode-border)' }}>
                <div style={{ fontWeight: 600 }}>{entry.version} <span style={{ opacity: 0.5, fontWeight: 400 }}>({entry.date})</span></div>
                <div style={{ marginTop: 4 }}>{entry.notes}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
