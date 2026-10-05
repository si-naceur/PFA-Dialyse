import { aiLab } from '../../data/aiLab';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';
import { Cloud, Cpu } from 'lucide-react';

export function AiLabSection() {
  return (
    <section id="lab" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading label="AI Lab" title={aiLab.title} description={aiLab.subtitle} />
        <Reveal>
          <div className="flex flex-wrap gap-2 mb-10">
            {aiLab.experiments.map((e) => (
              <span
                key={e}
                className="text-xs font-mono px-3 py-1.5 rounded-md border border-border bg-bg-card hover:border-accent/40 transition-colors"
              >
                {e}
              </span>
            ))}
          </div>
        </Reveal>
        <div className="grid md:grid-cols-2 gap-6">
          <Reveal delay={0.05}>
            <article className="rounded-2xl border border-border bg-bg-card p-6">
              <div className="flex items-center gap-2 text-muted mb-4">
                <Cloud className="w-5 h-5 text-accent" />
                <h3 className="text-sm font-medium text-slate-100">Cloud AI</h3>
              </div>
              <ul className="space-y-2">
                {aiLab.cloudVsEdge.cloud.map((item) => (
                  <li key={item} className="text-sm text-muted flex gap-2">
                    <span className="text-accent">·</span>
                    {item}
                  </li>
                ))}
              </ul>
            </article>
          </Reveal>
          <Reveal delay={0.1}>
            <article className="rounded-2xl border border-accent/30 bg-bg-card p-6">
              <div className="flex items-center gap-2 text-muted mb-4">
                <Cpu className="w-5 h-5 text-accent" />
                <h3 className="text-sm font-medium text-slate-100">Local / Edge AI</h3>
              </div>
              <ul className="space-y-2">
                {aiLab.cloudVsEdge.edge.map((item) => (
                  <li key={item} className="text-sm text-muted flex gap-2">
                    <span className="text-accent">·</span>
                    {item}
                  </li>
                ))}
              </ul>
            </article>
          </Reveal>
        </div>
        <Reveal delay={0.15}>
          <p className="mt-8 text-sm text-muted max-w-2xl">{aiLab.note}</p>
        </Reveal>
      </div>
    </section>
  );
}
