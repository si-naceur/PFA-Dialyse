import { experience } from '../../data/experience';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';

export function ExperienceSection() {
  return (
    <section id="experience" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="Experience"
          title="Leadership, production & internships"
          description="Real roles positioned honestly — coordination, communication, design production, and technical internship work."
        />
        <ol className="relative border-l border-border ml-3 space-y-10">
          {experience.map((item, idx) => (
            <Reveal key={item.id} delay={idx * 0.06}>
              <li className="ml-8 relative">
                <span
                  className="absolute -left-[1.95rem] top-1.5 w-3 h-3 rounded-full bg-accent ring-4 ring-bg"
                  aria-hidden
                />
                <p className="text-xs font-mono text-accent">{item.period}</p>
                <h3 className="text-xl font-medium text-slate-50 mt-1">{item.role}</h3>
                <p className="text-muted">{item.organization}</p>
                <p className="text-xs text-muted mt-1">{item.type}</p>
                <ul className="mt-4 space-y-2">
                  {item.highlights.map((h) => (
                    <li key={h} className="text-sm text-muted flex gap-2">
                      <span className="text-accent">—</span>
                      {h}
                    </li>
                  ))}
                </ul>
              </li>
            </Reveal>
          ))}
        </ol>
      </div>
    </section>
  );
}
