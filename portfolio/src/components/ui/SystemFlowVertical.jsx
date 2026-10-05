import { useState } from 'react';
import { motion } from 'framer-motion';
import { ChevronDown } from 'lucide-react';
import { systemFlow } from '../../data/site';
import { useReducedMotion } from '../../hooks/useReducedMotion';

export function SystemFlowVertical() {
  const [active, setActive] = useState(0);
  const reduced = useReducedMotion();

  return (
    <div className="flex flex-col lg:flex-row gap-8 lg:gap-12 items-stretch">
      <div className="flex flex-col items-center lg:items-start gap-1 py-2" role="list" aria-label="Full stack flow">
        {systemFlow.map((step, i) => (
          <div key={step} className="flex flex-col items-center lg:items-start" role="listitem">
            <button
              type="button"
              onMouseEnter={() => setActive(i)}
              onFocus={() => setActive(i)}
              onClick={() => setActive(i)}
              className={`text-left px-4 py-3 rounded-xl border transition-all duration-200 w-full min-w-[200px] max-w-xs ${
                active === i
                  ? 'border-accent bg-accent/10 text-slate-50 shadow-[0_0_0_1px_rgb(37_99_235/0.2)]'
                  : 'border-border bg-bg-elevated text-slate-300 hover:border-accent/40'
              }`}
            >
              <span className="font-mono text-[10px] text-accent/80">0{i + 1}</span>
              <span className="block text-sm font-medium mt-0.5">{step}</span>
            </button>
            {i < systemFlow.length - 1 && (
              <ChevronDown className="w-4 h-4 text-accent/60 my-1 lg:ml-6" aria-hidden />
            )}
          </div>
        ))}
      </div>
      <div className="flex-1 rounded-2xl border border-border bg-bg-elevated p-6 md:p-8 min-h-[200px] flex flex-col justify-center">
        {!reduced && (
          <motion.div
            key={active}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.25 }}
          >
            <p className="font-mono text-xs text-accent uppercase tracking-widest">Layer</p>
            <p className="mt-2 text-2xl font-semibold text-slate-50">{systemFlow[active]}</p>
            <p className="mt-4 text-muted leading-relaxed">{layerNotes[active]}</p>
          </motion.div>
        )}
        {reduced && (
          <p className="text-muted leading-relaxed">
            I work across {systemFlow.join(', ')} — connecting physical systems to software people
            can use.
          </p>
        )}
      </div>
    </div>
  );
}

const layerNotes = [
  'Sensors, actuators, and the physical devices that generate real-world signals.',
  'Firmware and low-level logic close to the machine — timing, GPIO, peripherals.',
  'MQTT, networking, and protocols that move data between edge and services.',
  'Computer vision, OCR, and local models that interpret captured information.',
  'APIs, databases, and business logic that structure and persist data.',
  'Web dashboards for monitoring and operational visibility.',
  'Flutter apps and interfaces that put data in the hands of users.',
];
