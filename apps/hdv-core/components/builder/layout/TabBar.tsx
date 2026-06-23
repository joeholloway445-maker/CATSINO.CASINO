import { useEditorStore } from '@/lib/builder/store/editorStore';
import { CloseIcon, AddIcon } from '@/components/builder/icons';

export function TabBar() {
  const { tabs, activeTabId, setActiveTab, closeTab, newUntitled } = useEditorStore();

  if (tabs.length === 0) return null;

  return (
    <div
      style={{
        height: 35,
        backgroundColor: 'var(--vscode-tab-bg)',
        display: 'flex',
        alignItems: 'flex-end',
        overflow: 'hidden',
        flexShrink: 0,
        userSelect: 'none',
      }}
    >
      {tabs.map((tab) => {
        const isActive = tab.id === activeTabId;
        return (
          <div
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              display: 'flex',
              alignItems: 'center',
              height: 35,
              padding: '0 8px 0 12px',
              backgroundColor: isActive ? 'var(--vscode-tab-activeBg)' : 'var(--vscode-tab-bg)',
              borderRight: '1px solid var(--vscode-tab-border)',
              borderTop: isActive ? '1px solid var(--vscode-focusBorder)' : '1px solid transparent',
              color: isActive ? 'var(--vscode-editor-fg)' : 'var(--vscode-fg)',
              fontSize: 13,
              fontWeight: isActive ? 500 : 400,
              cursor: 'pointer',
              maxWidth: 200,
              minWidth: 80,
              flexShrink: 0,
              gap: 6,
            }}
          >
            {/* Dirty indicator */}
            <span
              style={{
                fontSize: 10,
                color: tab.isDirty ? 'var(--vscode-fg)' : 'transparent',
                flexShrink: 0,
                opacity: 0.8,
                width: 8,
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {tab.isDirty ? '\u25CF' : ''}
            </span>

            {/* Filename */}
            <span
              style={{
                flex: 1,
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                whiteSpace: 'nowrap',
                fontStyle: tab.path.startsWith('Untitled') ? 'italic' : 'normal',
              }}
            >
              {tab.name}
            </span>

            {/* Close button */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                closeTab(tab.id);
              }}
              style={{
                width: 16,
                height: 16,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'transparent',
                border: 'none',
                color: 'inherit',
                cursor: 'pointer',
                borderRadius: 3,
                flexShrink: 0,
                opacity: 0.6,
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = 'var(--vscode-button-bg)';
                e.currentTarget.style.opacity = '1';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = 'transparent';
                e.currentTarget.style.opacity = '0.6';
              }}
            >
              <CloseIcon size={14} />
            </button>
          </div>
        );
      })}

      {/* New file button */}
      <button
        onClick={newUntitled}
        title="New File"
        style={{
          width: 35,
          height: 35,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'transparent',
          border: 'none',
          color: 'var(--vscode-fg)',
          cursor: 'pointer',
          flexShrink: 0,
          opacity: 0.6,
        }}
        onMouseEnter={(e) => (e.currentTarget.style.opacity = '1')}
        onMouseLeave={(e) => (e.currentTarget.style.opacity = '0.6')}
      >
        <AddIcon size={16} />
      </button>
    </div>
  );
}
