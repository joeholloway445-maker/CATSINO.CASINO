import { useEditorStore } from '@/lib/builder/store/editorStore';
import { useFileSystemStore } from '@/lib/builder/store/fileSystemStore';
import { getLanguageFromFilename } from '@/lib/builder/utils/language';
import {
  NewFileIcon,
  GoToFileIcon,
  CommandPaletteIcon,
  OpenFolderIcon,
  GitCloneIcon,
  FileIcon,
  InfoIcon,
} from '@/components/builder/icons';

export function WelcomePage() {
  const { openFile, newUntitled } = useEditorStore();
  const { root } = useFileSystemStore();

  const handleOpenFile = (path: string, name: string) => {
    const findNode = (nodes: typeof root): { content: string; path: string; name: string } | undefined => {
      for (const node of nodes) {
        if (node.path === path) return { content: node.content || '', path, name };
        if (node.children) {
          const found = findNode(node.children);
          if (found) return found;
        }
      }
      return undefined;
    };
    const result = findNode(root);
    if (result) {
      const lang = getLanguageFromFilename(name);
      openFile(result.path, name, result.content, lang);
    }
  };

  const recentFiles = [
    { name: 'App.tsx', path: 'src/App.tsx' },
    { name: 'Button.tsx', path: 'src/components/Button.tsx' },
    { name: 'index.css', path: 'src/index.css' },
    { name: 'README.md', path: 'README.md' },
  ];

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100%',
        color: 'var(--vscode-fg)',
        fontSize: 13,
        userSelect: 'none',
      }}
    >
      {/* VS Code Logo */}
      <svg width="96" height="96" viewBox="0 0 100 100" fill="none" style={{ marginBottom: 24, opacity: 0.5 }}>
        <path
          d="M70.4 6.7L30.8 37.2 12.4 23.5 5 28.4v43.2l7.4 4.9 18.4-13.7 39.6 30.5 22-13.3V20L70.4 6.7zM12.4 65V35l16 15-16 15zm58 11.3L38.8 50l31.6-26.3v52.6z"
          fill="#0078d4"
        />
      </svg>

      <h1
        style={{
          fontSize: 26,
          fontWeight: 300,
          marginBottom: 32,
          letterSpacing: 1,
        }}
      >
        VS Code Web
      </h1>

      <div style={{ display: 'flex', gap: 64 }}>
        {/* Start section */}
        <div style={{ minWidth: 200 }}>
          <h2
            style={{
              fontSize: 11,
              fontWeight: 600,
              textTransform: 'uppercase' as const,
              letterSpacing: '0.5px',
              marginBottom: 12,
              opacity: 0.6,
            }}
          >
            Start
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <WelcomeLink
              icon={<NewFileIcon size={16} />}
              label="New File..."
              shortcut="Ctrl+N"
              onClick={newUntitled}
            />
            <WelcomeLink
              icon={<OpenFolderIcon size={16} />}
              label="Open Folder..."
              shortcut="Ctrl+K Ctrl+O"
              onClick={() => {}}
            />
            <WelcomeLink
              icon={<GitCloneIcon size={16} />}
              label="Clone Repository..."
              onClick={() => {}}
            />
          </div>
        </div>

        {/* Recent section */}
        <div style={{ minWidth: 220 }}>
          <h2
            style={{
              fontSize: 11,
              fontWeight: 700,
              textTransform: 'uppercase' as const,
              letterSpacing: 0.5,
              marginBottom: 12,
              opacity: 0.6,
            }}
          >
            Recent
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {recentFiles.map((file) => (
              <WelcomeLink
                key={file.path}
                icon={<FileIcon size={16} />}
                label={file.name}
                onClick={() => handleOpenFile(file.path, file.name)}
              />
            ))}
          </div>
        </div>

        {/* Walkthroughs section */}
        <div style={{ minWidth: 200 }}>
          <h2
            style={{
              fontSize: 11,
              fontWeight: 700,
              textTransform: 'uppercase' as const,
              letterSpacing: 0.5,
              marginBottom: 12,
              opacity: 0.6,
            }}
          >
            Walkthroughs
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <WelcomeLink
              icon={<CommandPaletteIcon size={16} />}
              label="Command Palette"
              shortcut="Ctrl+Shift+P"
            />
            <WelcomeLink
              icon={<GoToFileIcon size={16} />}
              label="Quick File Open"
              shortcut="Ctrl+P"
            />
            <WelcomeLink
              icon={<InfoIcon size={16} />}
              label="Interface Overview"
            />
          </div>
        </div>
      </div>

      {/* Footer */}
      <div
        style={{
          position: 'absolute',
          bottom: 16,
          right: 16,
          fontSize: 11,
          opacity: 0.4,
        }}
      >
        v1.0.0
      </div>
    </div>
  );
}

function WelcomeLink({
  icon,
  label,
  shortcut,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  shortcut?: string;
  onClick?: () => void;
}) {
  return (
    <button
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        padding: '4px 8px',
        background: 'transparent',
        border: 'none',
        color: 'var(--vscode-fg)',
        cursor: 'pointer',
        fontSize: 13,
        fontFamily: 'inherit',
        textAlign: 'left',
        width: '100%',
        borderRadius: 3,
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.backgroundColor = 'var(--vscode-list-hover)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.backgroundColor = 'transparent';
      }}
    >
      <span style={{ display: 'flex', alignItems: 'center', opacity: 0.6 }}>{icon}</span>
      <span style={{ flex: 1 }}>{label}</span>
      {shortcut && (
        <span style={{ fontSize: 11, opacity: 0.4, marginLeft: 8 }}>{shortcut}</span>
      )}
    </button>
  );
}
