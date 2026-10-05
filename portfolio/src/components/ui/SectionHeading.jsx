import { Reveal } from './Reveal';

export function SectionHeading({ label, title, description, align = 'left' }) {
  const alignClass = align === 'center' ? 'text-center mx-auto' : '';

  return (
    <div className={`mb-12 md:mb-16 max-w-3xl ${alignClass}`}>
      {label && (
        <Reveal>
          <p className="font-mono text-xs uppercase tracking-[0.2em] text-accent mb-3">{label}</p>
        </Reveal>
      )}
      <Reveal delay={0.05}>
        <h2 className="text-3xl sm:text-4xl md:text-5xl font-semibold tracking-tight text-slate-50">
          {title}
        </h2>
      </Reveal>
      {description && (
        <Reveal delay={0.1}>
          <p className="mt-4 text-base md:text-lg text-muted leading-relaxed">{description}</p>
        </Reveal>
      )}
    </div>
  );
}
