import { useReducedMotion } from '../../hooks/useReducedMotion';

/** Edge-to-clients architecture for PFA-Dialyse case study */
export function PfaSystemDiagram({ className = '' }) {
  const reduced = useReducedMotion();

  return (
    <div
      className={`rounded-xl border border-border bg-bg-elevated p-4 sm:p-6 overflow-x-auto ${className}`}
      role="img"
      aria-label="System architecture: Camera to Raspberry Pi, AI and OCR, MQTT, Django backend, Dashboard and Flutter mobile"
    >
      <svg
        viewBox="0 0 520 420"
        className="w-full min-w-[280px] max-w-lg mx-auto"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <marker id="arrow" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
            <path d="M0,0 L6,3 L0,6 Z" fill="#64748b" />
          </marker>
        </defs>
        <Box x={200} y={16} w={120} h={36} label="Camera" />
        <Line x1={260} y1={52} x2={260} y2={72} />
        <Box x={180} y={72} w={160} h={40} label="Raspberry Pi" accent />
        <Line x1={260} y1={112} x2={260} y2={132} />
        <Box x={170} y={132} w={180} h={40} label="AI / OCR" accent />
        <Line x1={260} y1={172} x2={260} y2={192} />
        <Box x={190} y={192} w={140} h={36} label="MQTT" />
        <Line x1={260} y1={228} x2={260} y2={248} />
        <Box x={165} y={248} w={190} h={44} label="Django Backend" accent />
        <Line x1={220} y1={292} x2={120} y2={328} />
        <Line x1={300} y1={292} x2={400} y2={328} />
        <Box x={40} y={328} w={160} h={40} label="Dashboard" />
        <Box x={320} y={328} w={160} h={40} label="Flutter Mobile" />
        {!reduced && (
          <text x={260} y={400} textAnchor="middle" fill="#64748b" fontSize="10" fontFamily="monospace">
            academic engineering prototype
          </text>
        )}
      </svg>
    </div>
  );
}

function Box({ x, y, w, h, label, accent }) {
  return (
    <g>
      <rect
        x={x}
        y={y}
        width={w}
        height={h}
        rx={6}
        stroke={accent ? '#2563EB' : '#334155'}
        strokeWidth={1.5}
        fill="#0f1420"
      />
      <text
        x={x + w / 2}
        y={y + h / 2 + 4}
        textAnchor="middle"
        fill="#e2e8f0"
        fontSize="11"
        fontFamily="system-ui, sans-serif"
      >
        {label}
      </text>
    </g>
  );
}

function Line({ x1, y1, x2, y2 }) {
  return (
    <line x1={x1} y1={y1} x2={x2} y2={y2} stroke="#64748b" strokeWidth={1.5} markerEnd="url(#arrow)" />
  );
}
