import { useEffect, useState } from 'react';
import { Download, Github, Linkedin, Mail } from 'lucide-react';
import { personal } from '../../data/site';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';
import { Button } from '../ui/Button';
import { handleCvDownload } from '../../utils/cvDownload';

export function ContactSection() {
  const [cvNotice, setCvNotice] = useState(false);

  useEffect(() => {
    const onMissing = () => setCvNotice(true);
    window.addEventListener('cv-missing', onMissing);
    return () => window.removeEventListener('cv-missing', onMissing);
  }, []);

  return (
    <section id="contact" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="Contact"
          title="Have a project, internship opportunity, or technical challenge?"
          description="I'm always interested in learning, building, and collaborating on meaningful technology projects."
          align="center"
        />
        <Reveal>
          <div className="max-w-xl mx-auto text-center space-y-6">
            <div className="flex flex-wrap justify-center gap-3">
              {personal.email && (
                <Button as="a" href={`mailto:${personal.email}`} variant="primary">
                  <Mail className="w-4 h-4" />
                  Email Me
                </Button>
              )}
              <Button
                as="a"
                href={personal.github[0].url}
                target="_blank"
                rel="noopener noreferrer"
                variant={personal.email ? 'secondary' : 'primary'}
              >
                <Github className="w-4 h-4" />
                GitHub
              </Button>
              {personal.linkedin && (
                <Button
                  as="a"
                  href={personal.linkedin}
                  target="_blank"
                  rel="noopener noreferrer"
                  variant="secondary"
                >
                  <Linkedin className="w-4 h-4" />
                  LinkedIn
                </Button>
              )}
              <Button type="button" variant="ghost" onClick={() => handleCvDownload(personal.cvPath)}>
                <Download className="w-4 h-4" />
                Download CV
              </Button>
            </div>
            {cvNotice && (
              <p className="text-xs text-amber-400/90" role="status">
                Add your CV at <span className="font-mono">public/Naceur-Zidi-CV.pdf</span> to enable
                download.
              </p>
            )}
            <div className="pt-6 text-left rounded-xl border border-border bg-bg-card p-5 text-sm text-muted space-y-2">
              <p>
                <span className="text-slate-300">GitHub:</span>{' '}
                {personal.github.map((g) => (
                  <a
                    key={g.url}
                    href={g.url}
                    className="text-accent hover:underline mr-3"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {g.label}
                  </a>
                ))}
              </p>
              <p>
                <span className="text-slate-300">Location:</span> {personal.location}
              </p>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
