import { useState } from 'react';
import { User } from 'lucide-react';
import { personal } from '../../data/site';

export function ProfilePhoto({ className = '' }) {
  const [error, setError] = useState(false);

  if (error) {
    return (
      <div
        className={`flex items-center justify-center rounded-2xl border border-border bg-bg-card text-muted ${className}`}
        aria-label="Profile photo placeholder"
      >
        <User className="w-12 h-12 opacity-40" />
      </div>
    );
  }

  return (
    <img
      src={personal.profileImage}
      alt="Naceur Zidi"
      onError={() => setError(true)}
      className={`rounded-2xl object-cover border border-border ${className}`}
      loading="lazy"
    />
  );
}
