import { personal, systemFlow } from '../../data/site';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';
import { ProfilePhoto } from '../ui/ProfilePhoto';
import { ChevronRight } from 'lucide-react';

export function AboutSection() {
  return (
    <section id="about" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="About"
          title="From hardware to interface."
          description={personal.brand}
        />
        <div className="grid lg:grid-cols-[1fr_280px] gap-12 items-start">
          <div className="space-y-6 text-muted leading-relaxed text-base md:text-lg">
            <Reveal>
              <p>
                I am an Information Systems Engineering student at ISIMG, specializing in{' '}
                <strong className="text-slate-200 font-medium">IoT & Embedded Systems</strong>. I
                enjoy building systems that combine hardware, software, AI, networking, mobile
                applications, backend services, and visual interfaces.
              </p>
            </Reveal>
            <Reveal delay={0.05}>
              <p>
                I am especially interested in real-world engineering problems and practical
                implementations — prototypes that can be tested, iterated, and explained across the
                full stack, from embedded constraints to user-facing apps.
              </p>
            </Reveal>
            <Reveal delay={0.1}>
              <p className="text-sm font-mono text-accent/90">
                From embedded hardware to intelligent software interfaces.
              </p>
            </Reveal>
          </div>
          <Reveal delay={0.1}>
            <ProfilePhoto className="w-full aspect-[4/5] max-w-[280px] mx-auto lg:mx-0" />
          </Reveal>
        </div>

        <Reveal delay={0.15}>
          <div className="mt-16 rounded-2xl border border-border bg-bg-card p-6 md:p-8">
            <p className="text-xs font-mono uppercase tracking-widest text-muted mb-6">
              System mindset
            </p>
            <div className="flex flex-wrap items-center gap-2 md:gap-3">
              {systemFlow.map((step, i) => (
                <div key={step} className="flex items-center gap-2">
                  <span className="px-3 py-2 rounded-lg bg-bg-elevated border border-border text-sm text-slate-100">
                    {step}
                  </span>
                  {i < systemFlow.length - 1 && (
                    <ChevronRight className="w-4 h-4 text-accent hidden sm:block" aria-hidden />
                  )}
                </div>
              ))}
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
