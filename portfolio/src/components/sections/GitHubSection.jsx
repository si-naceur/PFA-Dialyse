import { githubRepos } from '../../data/projects';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';
import { Github, Star } from 'lucide-react';

export function GitHubSection() {
  return (
    <section className="py-16 md:py-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="GitHub"
          title="Selected repositories"
          description="Modular list — add public repositories in src/data/projects.js."
        />
        <div className="space-y-4 max-w-2xl">
          {githubRepos.map((repo, idx) => (
            <Reveal key={repo.url} delay={idx * 0.06}>
              <a
                href={repo.url}
                target="_blank"
                rel="noopener noreferrer"
                className="block rounded-xl border border-border bg-bg-card p-5 hover:border-accent/40 transition-colors group"
              >
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <p className="flex items-center gap-2 text-slate-100 font-medium group-hover:text-accent transition-colors">
                      <Github className="w-4 h-4" />
                      {repo.name}
                      {repo.highlight && (
                        <Star className="w-3.5 h-3.5 text-accent fill-accent" aria-label="Highlighted" />
                      )}
                    </p>
                    <p className="mt-2 text-sm text-muted">{repo.description}</p>
                  </div>
                  <span className="text-xs font-mono text-muted shrink-0">{repo.language}</span>
                </div>
              </a>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
