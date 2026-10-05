import { engineeringPrinciples, engineeringStack } from '../../data/site';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';

export function EngineeringSection() {
  return (
    <section className="py-20 md:py-28 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="Engineering mindset"
          title="Across the complete stack"
          description="I don't only build the interface. I want to understand what happens behind it — from firmware to user experience."
        />
        <Reveal>
          <div className="flex flex-wrap gap-3 mb-10">
            {engineeringPrinciples.map((p) => (
              <span
                key={p}
                className="font-mono text-xs sm:text-sm tracking-widest px-4 py-2 rounded-lg border border-accent/40 text-accent bg-accent/5"
              >
                {p}
              </span>
            ))}
          </div>
        </Reveal>
        <Reveal delay={0.08}>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-7 gap-3">
            {engineeringStack.map((layer) => (
              <div
                key={layer}
                className="text-center px-2 py-4 rounded-xl border border-border bg-bg-card text-xs sm:text-sm text-slate-200"
              >
                {layer}
              </div>
            ))}
          </div>
        </Reveal>
      </div>
    </section>
  );
}
