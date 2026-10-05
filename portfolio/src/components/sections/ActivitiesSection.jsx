import { enactusContent } from '../../data/enactus';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';

export function ActivitiesSection() {
  return (
    <section id="activities" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="Activities"
          title={enactusContent.title}
          description={enactusContent.intro}
        />
        <Reveal>
          <div className="flex flex-wrap gap-2 mb-12">
            {enactusContent.pillars.map((p) => (
              <span
                key={p}
                className="text-xs px-3 py-1.5 rounded-full border border-border bg-bg-card text-slate-300"
              >
                {p}
              </span>
            ))}
          </div>
        </Reveal>
        <div className="grid md:grid-cols-2 gap-6">
          {enactusContent.projects.map((proj, idx) => (
            <Reveal key={proj.id} delay={idx * 0.08}>
              <article className="rounded-2xl border border-border bg-bg-card p-6 md:p-8 h-full">
                <h3 className="text-xl font-medium text-slate-50">{proj.name}</h3>
                <p className="mt-3 text-muted leading-relaxed">{proj.description}</p>
                {proj.metric && (
                  <div className="mt-6 p-4 rounded-xl bg-bg-elevated border border-border">
                    <p className="text-2xl font-semibold text-accent">{proj.metric.value}</p>
                    <p className="text-sm text-slate-200 mt-1">{proj.metric.label}</p>
                    <p className="text-xs text-muted mt-1">{proj.metric.context}</p>
                  </div>
                )}
                {proj.figures && (
                  <ul className="mt-6 space-y-2">
                    {proj.figures.map((f) => (
                      <li key={f.label} className="flex justify-between text-sm gap-4">
                        <span className="text-muted">{f.label}</span>
                        <span className="text-slate-200 font-mono">{f.value}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </article>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
