import { designGallery, designSection } from '../../data/design';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';
import { ProjectImage } from '../ui/ProjectImage';

export function DesignSection() {
  return (
    <section id="design" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="Design"
          title={designSection.title}
          description={designSection.subtitle}
        />
        <Reveal>
          <div className="flex flex-wrap gap-2 mb-8">
            {designSection.skills.map((s) => (
              <span
                key={s}
                className="text-xs px-3 py-1 rounded-lg border border-border text-muted"
              >
                {s}
              </span>
            ))}
          </div>
        </Reveal>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {designGallery.map((item, idx) => (
            <Reveal key={item.id} delay={idx * 0.04}>
              <figure className="group rounded-xl overflow-hidden border border-border bg-bg-card">
                <ProjectImage
                  src={item.src}
                  alt={`${item.category}: ${item.title}`}
                  className="w-full aspect-[4/3] group-hover:scale-[1.03] transition-transform duration-500"
                />
                <figcaption className="p-3">
                  <p className="text-[10px] font-mono text-accent uppercase">{item.category}</p>
                  <p className="text-sm text-slate-200 mt-0.5">{item.title}</p>
                </figcaption>
              </figure>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
