import { motion } from 'framer-motion';
import { ChevronRight } from 'lucide-react';
import { useReducedMotion } from '../../hooks/useReducedMotion';

export function ArchitectureDiagram({ steps, interactive = true }) {
  const reduced = useReducedMotion();

  return (
    <div
      className="overflow-x-auto pb-2 -mx-2 px-2"
      role="list"
      aria-label="System architecture flow"
    >
      <div className="flex flex-wrap md:flex-nowrap items-stretch gap-2 min-w-min">
        {steps.map((step, i) => (
          <div key={step} className="flex items-center gap-2" role="listitem">
            <motion.div
              className={`relative rounded-lg border border-border bg-bg-card px-3 py-2.5 sm:px-4 sm:py-3 min-w-[120px] max-w-[200px] ${interactive ? 'hover:border-accent/50 transition-colors' : ''}`}
              initial={reduced ? false : { opacity: 0, y: 8 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.06, duration: 0.35 }}
            >
              <span className="font-mono text-[10px] text-accent/80">0{i + 1}</span>
              <p className="text-xs sm:text-sm font-medium text-slate-100 mt-0.5 leading-snug">
                {step}
              </p>
            </motion.div>
            {i < steps.length - 1 && (
              <ChevronRight className="w-4 h-4 text-accent shrink-0 hidden sm:block" aria-hidden />
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
