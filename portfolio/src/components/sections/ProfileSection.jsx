import { contributions } from '../../data/site';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';
import { Check } from 'lucide-react';

export function ProfileSection() {
  return (
    <section className="py-20 md:py-28 border-t border-border/60 bg-bg-elevated/30">
      <div className="section-padding">
        <SectionHeading
          label="Profile"
          title="What I can contribute"
          description="Capability-oriented statements — student engineer in training, ready to contribute on real projects."
        />
        <ul className="grid sm:grid-cols-2 gap-3 max-w-4xl">
          {contributions.map((item, idx) => (
            <Reveal key={item} delay={idx * 0.03}>
              <li className="flex gap-3 text-sm text-muted">
                <Check className="w-4 h-4 text-accent shrink-0 mt-0.5" aria-hidden />
                {item}
              </li>
            </Reveal>
          ))}
        </ul>
      </div>
    </section>
  );
}
