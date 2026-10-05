import { internshipAreas } from '../../data/site';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';
import { Button } from '../ui/Button';
import { scrollToSection } from '../../utils/scrollTo';

export function InternshipSection() {
  return (
    <section className="py-20 md:py-28 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="PFE / Internship"
          title="Looking for a PFE / Internship"
          description="I am looking for an opportunity where I can contribute to real engineering projects while developing my skills in IoT, embedded systems, AI, computer vision, cybersecurity, software development, or connected technologies."
        />
        <Reveal>
          <div className="flex flex-wrap gap-2 mb-10">
            {internshipAreas.map((area) => (
              <span
                key={area}
                className="text-sm px-4 py-2 rounded-full border border-border bg-bg-card text-slate-200"
              >
                {area}
              </span>
            ))}
          </div>
        </Reveal>
        <Reveal delay={0.08}>
          <Button type="button" onClick={() => scrollToSection('contact')}>
            Let&apos;s build something together
          </Button>
        </Reveal>
      </div>
    </section>
  );
}
