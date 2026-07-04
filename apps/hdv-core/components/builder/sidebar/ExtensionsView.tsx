import { useState, useMemo } from 'react';
import { useExtensionStore } from '@/lib/builder/store/extensionStore';
import { ExtensionCard } from './ExtensionCard';
import { ExtensionDetail } from './ExtensionDetail';
import { SearchIcon } from '@/components/builder/icons';

type FilterTab = 'ALL' | 'INSTALLED' | 'POPULAR' | 'RECOMMENDED';

export function ExtensionsView() {
  const { extensions, install, uninstall, toggleEnabled } = useExtensionStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState<FilterTab>('ALL');
  const [selectedExtId, setSelectedExtId] = useState<string | null>(null);

  const selectedExt = useMemo(
    () => extensions.find(e => e.id === selectedExtId) || null,
    [extensions, selectedExtId]
  );

  const filtered = useMemo(() => {
    let result = extensions;

    // Filter by tab
    if (activeFilter === 'INSTALLED') {
      result = result.filter(e => e.installed);
    } else if (activeFilter === 'POPULAR') {
      result = [...result].sort((a, b) => parseFloat(b.downloads) - parseFloat(a.downloads));
    } else if (activeFilter === 'RECOMMENDED') {
      result = result.filter(e => e.isFunctional);
    }

    // Filter by search
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(
        e =>
          e.name.toLowerCase().includes(q) ||
          e.publisher.toLowerCase().includes(q) ||
          e.description.toLowerCase().includes(q)
      );
    }

    return result;
  }, [extensions, activeFilter, searchQuery]);

  if (selectedExt) {
    return (
      <ExtensionDetail
        ext={selectedExt}
        onBack={() => setSelectedExtId(null)}
        onInstall={() => install(selectedExt.id)}
        onUninstall={() => uninstall(selectedExt.id)}
        onToggleEnable={() => toggleEnabled(selectedExt.id)}
      />
    );
  }

  return (
    <div className="flex flex-col h-full text-[var(--vscode-fg)]">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2">
        <span className="text-xs font-bold tracking-wide opacity-80">EXTENSIONS</span>
      </div>

      {/* Search */}
      <div className="px-3 pb-2">
        <div className="relative">
          <SearchIcon size={14} className="absolute left-2 top-1/2 -translate-y-1/2 opacity-50" />
          <input
            type="text"
            placeholder="Search Extensions in Marketplace"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-7 pr-2 py-1 text-xs bg-[var(--vscode-input-bg)] border border-[var(--vscode-input-border)] rounded text-[var(--vscode-fg)] placeholder:opacity-50 outline-none focus:border-[var(--vscode-focusBorder)]"
          />
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1 px-3 pb-2 border-b border-[var(--vscode-border)]">
        {(['ALL', 'INSTALLED', 'POPULAR', 'RECOMMENDED'] as FilterTab[]).map(tab => (
          <button
            key={tab}
            onClick={() => setActiveFilter(tab)}
            className={`px-2 py-0.5 text-[10px] font-medium rounded ${
              activeFilter === tab
                ? 'bg-[var(--vscode-badge-bg)] text-[var(--vscode-badge-fg)]'
                : 'text-[var(--vscode-fg)] opacity-50 hover:opacity-80 hover:bg-[var(--vscode-list-hover)]'
            }`}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Extension list */}
      <div className="flex-1 overflow-auto">
        {filtered.length === 0 ? (
          <div className="p-4 text-xs opacity-50 text-center">No extensions found.</div>
        ) : (
          filtered.map(ext => (
            <ExtensionCard
              key={ext.id}
              ext={ext}
              onClick={() => setSelectedExtId(ext.id)}
              onInstall={() => install(ext.id)}
              onUninstall={() => uninstall(ext.id)}
              onToggleEnable={() => toggleEnabled(ext.id)}
            />
          ))
        )}
      </div>
    </div>
  );
}
