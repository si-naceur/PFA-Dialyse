import { education } from '../../data/education';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';

export function EducationSection() {
  return (
    <section id="education" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading label="Education" title="Academic path" />
        <div className="space-y-6 max-w-3xl">
          {education.map((item, idx) => (
            <Reveal key={item.id} delay={idx * 0.08}>
              <article className="rounded-2xl border border-border bg-bg-card p-6 md:p-8">
                <p className="font-mono text-sm text-accent">{item.period}</p>
                <h3 className="mt-2 text-lg font-medium text-slate-50">{item.institution}</h3>
                <p className="mt-2 text-muted">{item.degree}</p>
                {item.specialization && (
                  <p className="mt-2 text-sm text-slate-300">Specialization: {item.specialization}</p>
                )}
              </article>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
