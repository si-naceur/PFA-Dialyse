import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowUpRight, Github } from 'lucide-react';
import { projectFilters } from '../../data/site';
import { projects } from '../../data/projects';
import { SectionHeading } from '../ui/SectionHeading';
import { Reveal } from '../ui/Reveal';
import { ProjectImage } from '../ui/ProjectImage';
import { ArchitectureDiagram } from '../ui/ArchitectureDiagram';
import { architectureSteps, dialyseParameters } from '../../data/projects';

export function ProjectsSection() {
  const [filter, setFilter] = useState('All');

  const filtered = useMemo(() => {
    if (filter === 'All') return projects;
    return projects.filter((p) => p.filters.includes(filter));
  }, [filter]);

  const flagship = projects.find((p) => p.featured);

  return (
    <section id="projects" className="py-20 md:py-28 scroll-mt-20 border-t border-border/60">
      <div className="section-padding">
        <SectionHeading
          label="Projects"
          title="Engineering work & explorations"
          description="Filter by domain. Flagship academic prototype: PFA-Dialyse — a complete IoT and AI-assisted monitoring system."
        />

        <Reveal>
          <div
            className="flex flex-wrap gap-2 mb-10"
            role="tablist"
            aria-label="Project filters"
          >
            {projectFilters.map((f) => (
              <button
                key={f}
                type="button"
                role="tab"
                aria-selected={filter === f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1.5 rounded-full text-xs sm:text-sm font-medium border transition-colors ${
                  filter === f
                    ? 'bg-accent text-white border-accent'
                    : 'border-border text-muted hover:text-white hover:border-accent/40'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
        </Reveal>

        {flagship && filter === 'All' && (
          <Reveal>
            <article className="mb-12 rounded-2xl border border-accent/30 bg-bg-card overflow-hidden">
              <div className="grid lg:grid-cols-2 gap-0">
                <ProjectImage
                  src={flagship.image}
                  alt={`${flagship.shortTitle} project cover`}
                  className="w-full h-56 lg:h-full min-h-[220px]"
                />
                <div className="p-6 md:p-10 flex flex-col justify-center">
                  <p className="font-mono text-xs text-accent uppercase tracking-widest">
                    Flagship · {flagship.status}
                  </p>
                  <h3 className="mt-2 text-2xl md:text-3xl font-semibold text-slate-50">
                    {flagship.title}
                  </h3>
                  <p className="mt-4 text-muted leading-relaxed">{flagship.description}</p>
                  <div className="mt-6">
                    <p className="text-xs font-mono text-muted mb-3">Architecture</p>
                    <ArchitectureDiagram steps={architectureSteps} />
                  </div>
                  <div className="mt-6 flex flex-wrap gap-2">
                    {dialyseParameters.slice(0, 4).map((p) => (
                      <span
                        key={p.code}
                        className="text-[10px] font-mono px-2 py-1 rounded border border-border text-slate-400"
                        title={p.name}
                      >
                        {p.code}
                      </span>
                    ))}
                    <span className="text-[10px] text-muted self-center">+ more parameters</span>
                  </div>
                  <div className="mt-8 flex flex-wrap gap-3">
                    <Link
                      to={`/projects/${flagship.slug}`}
                      className="inline-flex items-center gap-2 text-sm font-medium text-white bg-accent hover:bg-accent-dim px-5 py-2.5 rounded-lg transition-colors"
                    >
                      View case study
                      <ArrowUpRight className="w-4 h-4" />
                    </Link>
                    <a
                      href={flagship.github}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-2 text-sm font-medium border border-border px-5 py-2.5 rounded-lg text-muted hover:text-white hover:border-accent/50 transition-colors"
                    >
                      <Github className="w-4 h-4" />
                      GitHub
                    </a>
                  </div>
                </div>
              </div>
            </article>
          </Reveal>
        )}

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {filtered
            .filter((p) => !p.featured || filter !== 'All')
            .map((project, idx) =>
              project.featured && filter === 'All' ? null : (
                <Reveal key={project.id} delay={idx * 0.05}>
                  <ProjectCard project={project} />
                </Reveal>
              ),
            )}
          {filtered.filter((p) => !(p.featured && filter === 'All')).length === 0 && (
            <p className="text-muted col-span-full">No projects in this category yet.</p>
          )}
        </div>
      </div>
    </section>
  );
}

function ProjectCard({ project }) {
  return (
    <article className="group flex flex-col h-full rounded-2xl border border-border bg-bg-card overflow-hidden hover:border-accent/40 transition-colors">
      <div className="overflow-hidden">
        <ProjectImage
          src={project.image}
          alt={project.title}
          className="w-full h-44 group-hover:scale-[1.02] transition-transform duration-500"
        />
      </div>
      <div className="p-5 flex flex-col flex-1">
        <p className="text-[10px] font-mono uppercase tracking-wider text-accent">{project.category}</p>
        <h3 className="mt-2 text-lg font-medium text-slate-50">{project.title}</h3>
        <p className="mt-2 text-sm text-muted line-clamp-3 flex-1">{project.description}</p>
        <p className="mt-3 text-[10px] text-muted font-mono">{project.status}</p>
        <div className="mt-4 flex flex-wrap gap-1.5">
          {project.technologies.slice(0, 4).map((t) => (
            <span key={t} className="text-[10px] px-1.5 py-0.5 rounded bg-bg-elevated border border-border">
              {t}
            </span>
          ))}
        </div>
        <div className="mt-5 flex gap-3 pt-4 border-t border-border">
          {project.hasCaseStudy && (
            <Link
              to={`/projects/${project.slug}`}
              className="text-sm text-accent hover:text-white transition-colors inline-flex items-center gap-1"
            >
              Case study <ArrowUpRight className="w-3.5 h-3.5" />
            </Link>
          )}
          {project.github && (
            <a
              href={project.github}
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-muted hover:text-white transition-colors ml-auto inline-flex items-center gap-1"
            >
              <Github className="w-3.5 h-3.5" /> GitHub
            </a>
          )}
        </div>
      </div>
    </article>
  );
}
