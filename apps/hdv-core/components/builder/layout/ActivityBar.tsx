import { useSidebarStore } from '@/lib/builder/store/sidebarStore';
import type { SidebarView } from '@/lib/builder/store/sidebarStore';

const VIEW_ITEMS: { view: SidebarView; codicon: string; tooltip: string }[] = [
  { view: 'explorer', codicon: 'codicon-files', tooltip: 'Explorer (Ctrl+Shift+E)' },
  { view: 'search', codicon: 'codicon-search', tooltip: 'Search (Ctrl+Shift+F)' },
  { view: 'scm', codicon: 'codicon-source-control', tooltip: 'Source Control (Ctrl+Shift+G)' },
  { view: 'run', codicon: 'codicon-debug-alt', tooltip: 'Run and Debug (Ctrl+Shift+D)' },
  { view: 'extensions', codicon: 'codicon-extensions', tooltip: 'Extensions (Ctrl+Shift+X)' },
];

export function ActivityBar() {
  const { activeView, isVisible, setView } = useSidebarStore();

  const handleClick = (view: SidebarView) => {
    setView(view);
  };

  return (
    <div className="activity-bar"
      style={{
        width: 48,
        backgroundColor: 'var(--vscode-activityBar-bg)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        paddingTop: 4,
        flexShrink: 0,
        userSelect: 'none',
      }}
    >
      {/* Main view icons */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 0, flex: 1 }}>
        {VIEW_ITEMS.map(({ view, codicon, tooltip }) => {
          const isActive = isVisible && activeView === view;
          return (
            <button
              key={view}
              title={tooltip}
              className={isActive ? 'active' : ''}
              onClick={() => handleClick(view)}
              style={{
                position: 'relative',
                width: 48,
                height: 48,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'transparent',
                border: 'none',
                cursor: 'pointer',
                color: isActive ? '#ffffff' : '#858585',
                transition: 'color 0.1s',
              }}
              onMouseEnter={(e) => {
                if (!isActive) e.currentTarget.style.color = '#cccccc';
              }}
              onMouseLeave={(e) => {
                if (!isActive) e.currentTarget.style.color = '#858585';
              }}
            >
              {/* Active indicator bar */}
              {isActive && (
                <div
                  style={{
                    position: 'absolute',
                    left: 0,
                    top: 8,
                    bottom: 8,
                    width: 2,
                    backgroundColor: '#007acc',
                    borderRadius: '0 1px 1px 0',
                  }}
                />
              )}
              <i className={`codicon ${codicon}`} />
            </button>
          );
        })}
      </div>

      {/* Bottom icons */}
      <div style={{ display: 'flex', flexDirection: 'column', paddingBottom: 4 }}>
        <button
          title="Accounts"
          style={{
            width: 48,
            height: 48,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'transparent',
            border: 'none',
            cursor: 'pointer',
            color: '#858585',
          }}
          onMouseEnter={(e) => (e.currentTarget.style.color = '#cccccc')}
          onMouseLeave={(e) => (e.currentTarget.style.color = '#858585')}
        >
          <i className="codicon codicon-account" />
        </button>
        <button
          title="Manage"
          style={{
            width: 48,
            height: 48,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'transparent',
            border: 'none',
            cursor: 'pointer',
            color: '#858585',
          }}
          onMouseEnter={(e) => (e.currentTarget.style.color = '#cccccc')}
          onMouseLeave={(e) => (e.currentTarget.style.color = '#858585')}
        >
          <i className="codicon codicon-settings-gear" />
        </button>
      </div>
    </div>
  );
}
