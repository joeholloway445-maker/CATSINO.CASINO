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

export function StarIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1.5l1.76 3.57 3.94.57-2.85 2.78.67 3.93L8 10.5l-3.52 1.85.67-3.93L2.3 5.64l3.94-.57L8 1.5z" />
    </Icon>
  );
}

export function DownloadIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8.5 1.5v7.2l2.1-2.1.7.7-3.3 3.3-3.3-3.3.7-.7 2.1 2.1V1.5h1zM2.5 12.5v1h11v-1h-11z" />
    </Icon>
  );
}

export function GearIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 5a3 3 0 110 6 3 3 0 010-6zm0 1a2 2 0 100 4 2 2 0 000-4zM6 1h4v1.05a2.5 2.5 0 011.25.7l.9-.52.5.87-.9.52a2.5 2.5 0 010 1.4l.9.52-.5.87-.9-.52a2.5 2.5 0 01-1.25.7V8H6v-1.05a2.5 2.5 0 01-1.25-.7l-.9.52-.5-.87.9-.52a2.5 2.5 0 010-1.4l-.9-.52.5-.87.9.52A2.5 2.5 0 016 2.05V1.5z" />
    </Icon>
  );
}

export function BackIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M6.5 3L2 8l4.5 5v-3.5H14V6.5H6.5V3z" />
    </Icon>
  );
}

export function CaseSensitiveIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <text x="2" y="12" fontSize="10" fontWeight="bold" fontFamily="monospace" fill="currentColor">Aa</text>
    </Icon>
  );
}

export function WholeWordIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <text x="0" y="12" fontSize="9" fontWeight="bold" fontFamily="monospace" fill="currentColor">\b</text>
    </Icon>
  );
}

export function RegexIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <text x="2" y="12" fontSize="10" fontWeight="bold" fontFamily="monospace" fill="currentColor">.*</text>
    </Icon>
  );
}

export function ReplaceIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M11 1.5l2.5 2.5-2.5 2.5V4H6.5v1h-1V3H11V1.5zM5 14.5L2.5 12l2.5-2.5V12h4.5v-1h1v2H5v1.5z" />
    </Icon>
  );
}

export function ReplaceAllIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M11 1.5l2.5 2.5-2.5 2.5V4H6.5v1h-1V3H11V1.5zM5 14.5L2.5 12l2.5-2.5V12h4.5v-1h1v2H5v1.5zM9 7h1v2H9V7zM6 7h1v2H6V7z" />
    </Icon>
  );
}

export function RefreshCwIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M13 5.5a5.5 5.5 0 01-9.8 3.5l1.1-1.1a4 4 0 007.1-2.4H13v2zM3 10.5A5.5 5.5 0 0112.8 7L11.7 8.1a4 4 0 00-7.1 2.4H3v-2z" />
    </Icon>
  );
}

export function PlusIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 2.5v5h5v1h-5v5H7v-5H2v-1h5v-5h1z" />
    </Icon>
  );
}

export function MinusIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M2 7.5h12v1H2v-1z" />
    </Icon>
  );
}

export function CheckCircleIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm3.35 4.35l-4 4-2.7-2.7.7-.7 2 2 3.3-3.3.7.7z" />
    </Icon>
  );
}

export function BugIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm-.5 2.5v3H5v1h2.5v4h1v-4H11v-1H8.5v-3h-1z" />
    </Icon>
  );
}

export function ListTreeIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M4.5 2.5v2h-2v1h2v6h-2v1h2v2h1v-2h6v2h1v-2h2v-1h-2v-6h2v-1h-2v-2h-1v2h-6v-2h-1zm1 3h6v6h-6v-6z" />
    </Icon>
  );
}

export function PlayCircleIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm-1.5 2.5v7l6-3.5-6-3.5z" />
    </Icon>
  );
}

export function StopCircleIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm0 1a6 6 0 110 12A6 6 0 018 2zm-2.5 2.5h5v5h-5v-5z" />
    </Icon>
  );
}

export function StepOverIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 2.5a4.5 4.5 0 100 9 4.5 4.5 0 000-9zM1.5 7a6.5 6.5 0 0112-3.5l.5.5V2h1v4h-4V5h2.5a5.5 5.5 0 00-10 2H1.5z" />
    </Icon>
  );
}

export function StepIntoIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 2.5v7.8L5.35 7.65l-.7.7L8.5 12l3.85-3.65-.7-.7L9 10.3V2.5H8zM4 13.5h9v1H4v-1z" />
    </Icon>
  );
}

export function StepOutIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 1.5l-3.85 3.65.7.7L7.5 3.5v7.8h1V3.5l2.65 2.35.7-.7L8 1.5zM4 11.5h9v1H4v-1z" />
    </Icon>
  );
}

export function TrashIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M6 2.5h4v1H6v-1zM3 4v1h1v8.5l.5.5h7l.5-.5V5h1V4H3zm2 1h6v8H5V5z" />
    </Icon>
  );
}

export function ExpandIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 4l-4 4h8L8 4z" />
    </Icon>
  );
}

export function CollapseIcon(props: IconProps) {
  return (
    <Icon {...props}>
      <path d="M8 12l4-4H4l4 4z" />
    </Icon>
  );
}
