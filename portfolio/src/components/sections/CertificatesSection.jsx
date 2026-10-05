import { certificates } from '../../data/certificates';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';

export function CertificatesSection() {
  return (
    <section id="certificates" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="Certificates"
          title="Training & certifications"
          description="Documented learning — including cybersecurity training, agile fundamentals, Security+ preparation, and media literacy programs."
        />
        <div className="grid sm:grid-cols-2 gap-6">
          {certificates.map((cert, idx) => (
            <Reveal key={cert.id} delay={idx * 0.05}>
              <article className="h-full rounded-2xl border border-border bg-bg-card p-6">
                <p className="text-xs font-mono text-accent uppercase tracking-wider">{cert.status}</p>
                <h3 className="mt-2 text-lg font-medium text-slate-50">{cert.title}</h3>
                <p className="text-sm text-muted mt-1">{cert.issuer}</p>
                <p className="mt-4 text-sm text-muted leading-relaxed">{cert.note}</p>
              </article>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
