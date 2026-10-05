import { Github, Linkedin, Mail } from 'lucide-react';
import { personal } from '../../data/site';
import { scrollToSection } from '../../utils/scrollTo';

export function Footer() {
  return (
    <footer className="border-t border-border bg-bg-elevated">
      <div className="section-padding py-12 md:py-16">
        <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-8">
          <div>
            <p className="text-xl font-semibold text-slate-50">{personal.name}</p>
            <p className="text-sm text-muted mt-1">{personal.title}</p>
            <p className="text-xs font-mono text-muted mt-3">
              IoT • Embedded • AI • Cybersecurity • Software
            </p>
          </div>
          <div className="flex items-center gap-4">
            <a
              href={personal.github[0].url}
              target="_blank"
              rel="noopener noreferrer"
              className="text-muted hover:text-accent transition-colors"
              aria-label="GitHub"
            >
              <Github className="w-5 h-5" />
            </a>
            {personal.linkedin ? (
              <a
                href={personal.linkedin}
                target="_blank"
                rel="noopener noreferrer"
                className="text-muted hover:text-accent transition-colors"
                aria-label="LinkedIn"
              >
                <Linkedin className="w-5 h-5" />
              </a>
            ) : (
              <button
                type="button"
                onClick={() => scrollToSection('contact')}
                className="text-muted hover:text-accent transition-colors"
                aria-label="Contact"
              >
                <Linkedin className="w-5 h-5" />
              </button>
            )}
            {personal.email ? (
              <a
                href={`mailto:${personal.email}`}
                className="text-muted hover:text-accent transition-colors"
                aria-label="Email"
              >
                <Mail className="w-5 h-5" />
              </a>
            ) : (
              <button
                type="button"
                onClick={() => scrollToSection('contact')}
                className="text-muted hover:text-accent transition-colors"
                aria-label="Contact"
              >
                <Mail className="w-5 h-5" />
              </button>
            )}
          </div>
        </div>
        <p className="text-xs text-muted mt-10">© 2026 {personal.name}</p>
      </div>
    </footer>
  );
}
