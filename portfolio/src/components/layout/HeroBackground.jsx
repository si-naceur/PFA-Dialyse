import { motion } from 'framer-motion';
import { useReducedMotion } from '../../hooks/useReducedMotion';

const nodes = [
  { x: '12%', y: '22%' },
  { x: '78%', y: '18%' },
  { x: '55%', y: '45%' },
  { x: '25%', y: '62%' },
  { x: '88%', y: '58%' },
  { x: '42%', y: '78%' },
];

export function HeroBackground() {
  const reduced = useReducedMotion();

  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none" aria-hidden>
      <div className="absolute inset-0 grid-bg opacity-60" />
      <div className="absolute inset-0 bg-gradient-to-b from-bg via-transparent to-bg" />
      <svg className="absolute inset-0 w-full h-full opacity-[0.15]">
        <defs>
          <linearGradient id="lineGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#2563EB" stopOpacity="0" />
            <stop offset="50%" stopColor="#2563EB" stopOpacity="1" />
            <stop offset="100%" stopColor="#2563EB" stopOpacity="0" />
          </linearGradient>
        </defs>
        <path
          d="M0 120 Q 400 80 800 140 T 1600 100"
          fill="none"
          stroke="url(#lineGrad)"
          strokeWidth="1"
        />
        <path
          d="M0 280 Q 500 320 900 260 T 1800 300"
          fill="none"
          stroke="#2563EB"
          strokeWidth="0.5"
          opacity="0.5"
        />
      </svg>
      {nodes.map((n, i) => (
        <motion.span
          key={i}
          className="absolute w-1.5 h-1.5 rounded-full bg-accent/80"
          style={{ left: n.x, top: n.y }}
          animate={
            reduced
              ? undefined
              : {
                  opacity: [0.3, 0.9, 0.3],
                  scale: [1, 1.2, 1],
                }
          }
          transition={
            reduced
              ? undefined
              : { duration: 3 + i * 0.4, repeat: Infinity, ease: 'easeInOut' }
          }
        />
      ))}
    </div>
  );
}
