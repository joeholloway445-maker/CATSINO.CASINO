import type { SVGProps } from 'react';

interface IconProps extends SVGProps<SVGSVGElement> {
  size?: number;
}

function Icon({ size = 16, children, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 16 16"
      fill="currentColor"
      xmlns="http://www.w3.org/2000/svg"
      {...props}
    >
      {children}
    </svg>
  );
}

/* ---- Activity Bar ---- */

export function ExplorerIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M2 2h5v1H3v10h4v1H2V2zm11 0h-4v1h3v10h-3v1h4V2zM6.5 5.5l-.5.5v4l.5.5h3l.5-.5v-4l-.5-.5h-3zm.5 4V6h2v3.5H7z" />
    </Icon>
  );
}

export function SearchIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M6 2a4 4 0 013.2 6.4l3.8 3.8-.7.7-3.8-3.8A4 4 0 116 2zm0 1a3 3 0 100 6 3 3 0 000-6z" />
    </Icon>
  );
}

export function SourceControlIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M6 2.5a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zM4.5 4a.5.5 0 00-.5.5v3.279a1.5 1.5 0 110 .442V9.5a.5.5 0 00.5.5h3.279a1.5 1.5 0 110 .442L7.5 12.5a.5.5 0 00.5.5h3a.5.5 0 00.5-.5v-3a.5.5 0 00-.5-.5h-.721a1.5 1.5 0 110-.442L11 5.5a.5.5 0 00.5-.5v-3a.5.5 0 00-.5-.5h-3a.5.5 0 00-.5.5v1.279a1.5 1.5 0 11-1 0V4.5a.5.5 0 00-.5-.5H4.5zm4 1.5h2v2h-2V5.5zm0 5h2v2h-2v-2zm-7-5a.5.5 0 100-1 .5.5 0 000 1zm8 5a.5.5 0 100-1 .5.5 0 000 1z" />
    </Icon>
  );
}

export function RunIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M3.5 2.5v11l9-5.5-9-5.5z" />
    </Icon>
  );
}

export function ExtensionsIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M7.5 1.5l-2 2h2v3h-3v-2l-2 2 2 2v-2h3v3h-2l2 2 2-2h-2v-3h3v2l2-2-2-2v2h-3v-3h2l-2-2z" />
    </Icon>
  );
}

/* ---- File Tree ---- */

export function FileIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M3 2l.01 12L10 14l3-3V2H3zm8 9h-2v2L5 13V3h6v8z" />
    </Icon>
  );
}

export function FolderIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M1.5 3h2l.75 1.5h8.75l.5.5v7l-.5.5h-11l-.5-.5v-8.5l.5-.5zm1 1.5v6.5h9V5h-7.5l-.75-1.5h-1.25v1.5z" />
    </Icon>
  );
}

export function FolderOpenIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M1.5 3h2l.75 1.5h7.5l.5.5v1.5h-1V5h-7.5l-.75-1.5h-1.25v6.5h1v1h-1.5l-.5-.5v-8.5l.5-.5zm10.5 3l1.5 5h-9l1.5-5h6zm-4.5 1l-.75 3h4.5l-.75-3H7.5zm-2 0H2.5l-.75 3h3.25l.75-3h.75z" />
    </Icon>
  );
}

export function ChevronRightIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M6 3l5 5-5 5V3z" />
    </Icon>
  );
}

export function ChevronDownIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M3 6l5 5 5-5H3z" />
    </Icon>
  );
}

/* ---- UI Actions ---- */

export function CloseIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 6.586L5.722 4.308 4.308 5.722 6.586 8l-2.278 2.278 1.414 1.414L8 9.414l2.278 2.278 1.414-1.414L9.414 8l2.278-2.278-1.414-1.414L8 6.586z" />
    </Icon>
  );
}

export function AddIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 2.5v5h5v1h-5v5H7v-5H2v-1h5v-5h1z" />
    </Icon>
  );
}

export function RefreshIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 2.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zm0 1a4.5 4.5 0 110 9 4.5 4.5 0 010-9zm3.146 2.354l.708.708L8 10.207 4.146 6.354l.708-.708L8 8.793l3.146-3.147z" opacity="0" />
      <path d="M8 2.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM3.5 8a4.5 4.5 0 017.336-3.52l-5.856 5.856A4.48 4.48 0 013.5 8zm1.164 3.52l5.856-5.856A4.5 4.5 0 014.664 11.52z" />
    </Icon>
  );
}

export function SettingsIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 5.5a2.5 2.5 0 110 5 2.5 2.5 0 010-5zm0 1a1.5 1.5 0 100 3 1.5 1.5 0 000-3zM6 1v2.5h.5a5.9 5.9 0 00-.293.707L5.5 4.5l-1.75-1.75-.75.75 1.75 1.75-.293.207A5.9 5.9 0 004.5 5.5V6H2v1h2.5v.5c.05.243.11.48.207.707l-.207.293-1.75 1.75.75.75 1.75-1.75.293.207c.2.1.41.18.63.243V11.5h1V9h.5c.243-.05.48-.11.707-.207l.293.207 1.75 1.75.75-.75-1.75-1.75.207-.293a5.9 5.9 0 00.243-.63H14v-1h-2.5V6H14V5h-2.5v-.5a5.9 5.9 0 00-.207-.707l.207-.293 1.75-1.75-.75-.75-1.75 1.75-.293-.207A5.9 5.9 0 009.5 2.5V2H9V0H8v1.5h-.5a5.9 5.9 0 00-.707.293L6.5 2.5l-1.75-1.75-.75.75 1.75 1.75-.293.207A5.9 5.9 0 004.5 4.5V5H2v1h2.5v.5c.05.243.11.48.207.707l-.207.293-1.75 1.75.75.75 1.75-1.75.293.207c.2.1.41.18.63.243V11.5h1V9h.5c.243-.05.48-.11.707-.207l.293.207 1.75 1.75.75-.75-1.75-1.75.207-.293a5.9 5.9 0 00.243-.63H14v-1h-2.5V6H14V5h-2.5v-.5a5.9 5.9 0 00-.207-.707l.207-.293 1.75-1.75-.75-.75-1.75 1.75-.293-.207A5.9 5.9 0 009.5 2.5V2H9V0H8v1.5h-.5z" />
    </Icon>
  );
}

export function AccountIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1.5a3 3 0 110 6 3 3 0 010-6zm0 1a2 2 0 100 4 2 2 0 000-4zM3 14.5v-1.5c0-1.5 2-2.5 5-2.5s5 1 5 2.5v1.5h-1v-1.5c0-.8-1.3-1.5-4-1.5s-4 .7-4 1.5v1.5H3z" />
    </Icon>
  );
}

/* ---- Git / Debug ---- */

export function GitBranchIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M6 2.5a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zM4.5 4a.5.5 0 00-.5.5v5.279a1.5 1.5 0 101 0V4.5a.5.5 0 00-.5-.5zm5.5 1.5a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zM10 8.5v.721a1.5 1.5 0 101 0V7.5a.5.5 0 00-.5-.5h-3a.5.5 0 00-.5.5v.279a1.5 1.5 0 101 0V8h2.5z" />
    </Icon>
  );
}

export function GitCommitIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a3 3 0 00-2.95 2.5H2v1h3.05A3 3 0 008 8a3 3 0 002.95-2.5H14v-1h-3.05A3 3 0 008 1zm0 1a2 2 0 110 4 2 2 0 010-4z" />
    </Icon>
  );
}

export function GitCompareIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M4.5 1.5a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zM3 3a.5.5 0 00-.5.5v7.793l-1.146-1.147-.708.708 2 2 .708-.708V3.5A.5.5 0 003 3zm7.5 8.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3zm0 2a.5.5 0 110 1 .5.5 0 010-1zM10.5 1.5a.5.5 0 00-.5.5v7.793l-1.146-1.147-.708.708 2 2 .708-.708V2a.5.5 0 00-.5-.5z" />
    </Icon>
  );
}

export function PlayIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M4 2l9 6-9 6V2z" />
    </Icon>
  );
}

export function DebugIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm-.5 2.5v3H5v1h2.5v3h1v-3H11v-1H8.5v-3h-1z" />
    </Icon>
  );
}

/* ---- Status / Alerts ---- */

export function WarningIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M7.5 1l-7 13h14l-7-13zm0 2.5L12.5 13h-10L7.5 3.5zM7 6v4h1V6H7zm0 5v1h1v-1H7z" />
    </Icon>
  );
}

export function ErrorIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm-.5 3.5v5h1v-5h-1zm0 6v1h1v-1h-1z" />
    </Icon>
  );
}

export function InfoIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm.5 3.5v1h-1v-1h1zm0 2.5v4h-1V8h1z" />
    </Icon>
  );
}

export function CheckIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M12.5 4l-6.5 7-2.5-2.5.75-.75L6 9.5l5.75-6.25.75.75z" />
    </Icon>
  );
}

/* ---- Panel ---- */

export function TerminalIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M2 3h12v10H2V3zm1 1v8h10V4H3zm1.5 2l2.5 2-2.5 2-.75-.75L5.5 8 3.75 6.75 4.5 6zM8.5 10h3v1h-3v-1z" />
    </Icon>
  );
}

export function OutputIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M2 3h12v10H2V3zm1 1v8h10V4H3zm1 2h8v1H4V6zm0 2h5v1H4V8z" />
    </Icon>
  );
}

export function DebugConsoleIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M2 3h12v10H2V3zm1 1v8h10V4H3zm1 2l2.5 2-2.5 2v-4zm4 3h4v1H8v-1z" />
    </Icon>
  );
}

export function ProblemsIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm-.5 3.5v1h1v-1h-1zm0 2.5v4h1V8h-1z" />
    </Icon>
  );
}

/* ---- Commands ---- */

export function CommandPaletteIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M3 4h10v1H3V4zm0 3h7v1H3V7zm0 3h10v1H3v-1z" />
    </Icon>
  );
}

export function GoToFileIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M6 2l.01 10 4.5-5h-2.5l1.5-1.5h-1l-1.5 1.5v-5h-1zm0 1.5v2.5h1.5l-1.5 1.5v2l4.5-5h-2l2.5-2.5h-1.5l-2 2H6V3.5z" />
    </Icon>
  );
}

/* ---- Explorer Actions ---- */

export function NewFileIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M9 2v5h5v1H9v5H8V8H3V7h5V2h1z" />
    </Icon>
  );
}

export function NewFolderIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M7.5 3l-1 1H2v8h11V3H7.5zM7 4l.5-.5H12v1H3.5l.5-.5V4h3zm-3.5 1h10v6h-9V5z" />
    </Icon>
  );
}

export function RefreshExplorerIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 2.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zm0 1a4.5 4.5 0 110 9 4.5 4.5 0 010-9zm3.146 2.354l.708.708L8 10.207 4.146 6.354l.708-.708L8 8.793l3.146-3.147z" opacity="0" />
      <path d="M8 2.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM3.5 8a4.5 4.5 0 017.336-3.52l-5.856 5.856A4.48 4.48 0 013.5 8zm1.164 3.52l5.856-5.856A4.5 4.5 0 014.664 11.52z" />
    </Icon>
  );
}

export function CollapseAllIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 3l4 4h-3v4H7V7H4l4-4zM3 12h10v1H3v-1z" />
    </Icon>
  );
}

/* ---- Extra Icons ---- */

export function VSCodeLogoIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M12.75 1.25l2.5 1.5v10.5l-2.5 1.5-8.5-5.5-4.5 3v-8.5l4.5 3 8.5-5.5zm-1 2.5l-5.5 3.5 5.5 3.5V3.75zm-7.5 3l-2-1.25v5l2-1.25v-2.5z" />
    </Icon>
  );
}

export function BellIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1.5a2.5 2.5 0 00-2.5 2.5v1.5h-2v6h9v-6h-2V4A2.5 2.5 0 008 1.5zM6.5 4a1.5 1.5 0 113 0v1.5h-3V4zM4 6.5h8v4H4v-4zm3 6.5h2a1 1 0 01-2 0z" />
    </Icon>
  );
}

export function OpenFolderIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M1.5 3h2l.75 1.5h8.75l.5.5v7l-.5.5h-11l-.5-.5v-8.5l.5-.5zm1 1.5v6.5h9V5h-7.5l-.75-1.5h-1.25v1.5z" />
    </Icon>
  );
}

export function GitCloneIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1.5a5 5 0 00-1.832 9.657l-.668 2.343 2.343-.668A5 5 0 108 1.5zM5.5 8a.5.5 0 110-1 .5.5 0 010 1zm1.5 0a.5.5 0 110-1 .5.5 0 010 1zm2 0a.5.5 0 110-1 .5.5 0 010 1z" />
    </Icon>
  );
}

export const SplitEditorIcon = (props: IconProps) => (
  <Icon {...props}>
    <path d="M1.5 2.5h13v11h-13v-11zm1 1v9h4v-9h-4zm5 0v9h6v-9h-6z" />
  </Icon>
);

export const MoreHorizontalIcon = (props: IconProps) => (
  <Icon {...props}>
    <path d="M4 8a1 1 0 112 0 1 1 0 01-2 0zm4 0a1 1 0 112 0 1 1 0 01-2 0zm4 0a1 1 0 112 0 1 1 0 01-2 0z" />
  </Icon>
);
