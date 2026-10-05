import { useEffect, useState } from 'react';
import { Github, Linkedin, Mail, Download } from 'lucide-react';
import { personal } from '../../data/site';
import { HeroBackground } from '../layout/HeroBackground';
import { Button } from '../ui/Button';
import { Reveal } from '../ui/Reveal';
import { scrollToSection } from '../../utils/scrollTo';
import { handleCvDownload } from '../../utils/cvDownload';

export function HeroSection() {
  const [keywordIndex, setKeywordIndex] = useState(0);

  useEffect(() => {
    const id = setInterval(() => {
      setKeywordIndex((i) => (i + 1) % personal.rotatingKeywords.length);
    }, 2800);
    return () => clearInterval(id);
  }, []);

  return (
    <section
      id="home"
      className="relative min-h-[100svh] flex items-center pt-20 pb-16 scroll-mt-20"
    >
      <HeroBackground />
      <div className="section-padding relative w-full">
        <Reveal>
          <p className="font-mono text-xs sm:text-sm text-accent tracking-widest uppercase mb-4">
            {personal.location} · ISIMG
          </p>
        </Reveal>
        <Reveal delay={0.05}>
          <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-semibold tracking-tight max-w-4xl">
            <span className="text-gradient">{personal.name}</span>
          </h1>
        </Reveal>
        <Reveal delay={0.1}>
          <p className="mt-6 text-xl sm:text-2xl md:text-3xl text-slate-200 max-w-3xl leading-snug">
            {personal.tagline}
          </p>
        </Reveal>
        <Reveal delay={0.15}>
          <p className="mt-4 font-mono text-sm sm:text-base text-accent min-h-[1.5em]">
            {personal.rotatingKeywords[keywordIndex]}
          </p>
        </Reveal>
        <Reveal delay={0.2}>
          <p className="mt-6 text-base md:text-lg text-muted max-w-2xl leading-relaxed">
            {personal.subtitle}
          </p>
        </Reveal>
        <Reveal delay={0.25}>
          <div className="mt-10 flex flex-wrap gap-3">
            <Button type="button" onClick={() => scrollToSection('projects')}>
              Explore My Work
            </Button>
            <Button
              type="button"
              variant="secondary"
              onClick={() => handleCvDownload(personal.cvPath)}
            >
              <Download className="w-4 h-4" aria-hidden />
              Download CV
            </Button>
            <Button type="button" variant="ghost" onClick={() => scrollToSection('contact')}>
              Contact Me
            </Button>
          </div>
        </Reveal>
        <Reveal delay={0.3}>
          <div className="mt-10 flex items-center gap-5">
            <a
              href={personal.github[0].url}
              target="_blank"
              rel="noopener noreferrer"
              className="text-muted hover:text-white transition-colors"
              aria-label="GitHub profile"
            >
              <Github className="w-5 h-5" />
            </a>
            {personal.linkedin ? (
              <a
                href={personal.linkedin}
                target="_blank"
                rel="noopener noreferrer"
                className="text-muted hover:text-white transition-colors"
                aria-label="LinkedIn"
              >
                <Linkedin className="w-5 h-5" />
              </a>
            ) : (
              <button
                type="button"
                onClick={() => scrollToSection('contact')}
                className="text-muted hover:text-white transition-colors"
                aria-label="Contact"
              >
                <Linkedin className="w-5 h-5" />
              </button>
            )}
            {personal.email ? (
              <a
                href={`mailto:${personal.email}`}
                className="text-muted hover:text-white transition-colors"
                aria-label="Email"
              >
                <Mail className="w-5 h-5" />
              </a>
            ) : (
              <button
                type="button"
                onClick={() => scrollToSection('contact')}
                className="text-muted hover:text-white transition-colors"
                aria-label="Contact"
              >
                <Mail className="w-5 h-5" />
              </button>
            )}
          </div>
        </Reveal>
      </div>
    </section>
  );
}
