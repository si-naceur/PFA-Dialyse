import { skillCategories, skillLevels } from '../../data/skills';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';

const levelStyles = {
  experienced: 'text-emerald-400/90 border-emerald-500/30',
  working: 'text-sky-400/90 border-sky-500/30',
  exploring: 'text-violet-400/90 border-violet-500/30',
};

export function SkillsSection() {
  return (
    <section id="skills" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="Skills"
          title="Technologies across the stack"
          description="Organized by domain — no arbitrary percentages, just honest categories: experienced with, working knowledge, and currently exploring."
        />
        <div className="grid md:grid-cols-2 gap-6">
          {skillCategories.map((cat, idx) => (
            <Reveal key={cat.id} delay={idx * 0.04}>
              <article className="h-full rounded-2xl border border-border bg-bg-card p-6 hover:border-accent/30 transition-colors">
                <div className="flex flex-wrap items-center justify-between gap-2 mb-4">
                  <h3 className="text-lg font-medium text-slate-50">{cat.title}</h3>
                  <span
                    className={`text-[10px] font-mono uppercase tracking-wider px-2 py-1 rounded border ${levelStyles[cat.level]}`}
                  >
                    {skillLevels[cat.level]}
                  </span>
                </div>
                <ul className="flex flex-wrap gap-2">
                  {cat.items.map((item) => (
                    <li
                      key={item}
                      className="text-xs sm:text-sm px-2.5 py-1 rounded-md bg-bg-elevated border border-border text-slate-300 hover:border-accent/40 transition-colors"
                    >
                      {item}
                    </li>
                  ))}
                </ul>
              </article>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
