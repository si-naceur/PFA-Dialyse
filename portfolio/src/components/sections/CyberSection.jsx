import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';

const topics = ['Network Analysis', 'Wireshark', 'Nmap', 'Linux', 'Security Fundamentals'];

export function CyberSection() {
  return (
    <section className="py-16 md:py-20 border-t border-border/60 bg-bg-elevated/40">
      <div className="section-padding">
        <SectionHeading
          label="Cybersecurity"
          title="Security as a technical interest"
          description="Structured training and lab work in network analysis and security fundamentals — complementary to IoT and software projects, not professional cybersecurity employment."
        />
        <Reveal delay={0.08}>
          <ul className="flex flex-wrap gap-2">
            {topics.map((t) => (
              <li
                key={t}
                className="text-sm px-3 py-2 rounded-lg border border-border bg-bg-card text-slate-300"
              >
                {t}
              </li>
            ))}
          </ul>
        </Reveal>
      </div>
    </section>
  );
}
