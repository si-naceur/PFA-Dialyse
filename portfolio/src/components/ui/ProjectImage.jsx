import { useState } from 'react';
import { ImageIcon } from 'lucide-react';

export function ProjectImage({ src, alt, className = '', lazy = true }) {
  const [error, setError] = useState(false);

  if (!src || error) {
    return (
      <div
        className={`relative flex items-center justify-center overflow-hidden bg-bg-card border border-border ${className}`}
        role="img"
        aria-label={alt}
      >
        <div
          className="absolute inset-0 opacity-40"
          style={{
            backgroundImage:
              'linear-gradient(rgb(37 99 235 / 0.06) 1px, transparent 1px), linear-gradient(90deg, rgb(37 99 235 / 0.06) 1px, transparent 1px)',
            backgroundSize: '24px 24px',
          }}
          aria-hidden
        />
        <ImageIcon className="w-7 h-7 text-slate-600 relative z-[1]" aria-hidden />
        <span className="sr-only">{alt}</span>
      </div>
    );
  }

  return (
    <img
      src={src}
      alt={alt}
      loading={lazy ? 'lazy' : 'eager'}
      decoding="async"
      onError={() => setError(true)}
      className={`object-cover ${className}`}
    />
  );
}
