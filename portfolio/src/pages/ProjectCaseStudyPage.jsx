import { Link, Navigate, useParams } from 'react-router-dom';
import { ArrowLeft, Github } from 'lucide-react';
import { projects, pfaDialyseCaseStudy, dialyseParameters } from '../data/projects';
import { ArchitectureDiagram } from '../components/ui/ArchitectureDiagram';
import { ProjectImage } from '../components/ui/ProjectImage';
import { Reveal } from '../components/ui/Reveal';
import { Button } from '../components/ui/Button';

const caseSections = [
  { num: '01', key: 'overview', title: 'Overview' },
  { num: '02', key: 'problem', title: 'Problem' },
  { num: '03', key: 'objectives', title: 'Objectives', list: true },
  { num: '04', key: 'architecture', title: 'Architecture', architecture: true },
  { num: '05', key: 'technologies', title: 'Technologies', list: true },
  { num: '06', key: 'implementation', title: 'Implementation', list: true },
  { num: '07', key: 'challenges', title: 'Challenges', list: true },
  { num: '08', key: 'solutions', title: 'Solutions', list: true },
  { num: '09', key: 'results', title: 'Results' },
  { num: '10', key: 'screenshots', title: 'Screenshots', gallery: true },
  { num: '11', key: 'lessons', title: 'Lessons Learned', list: true },
  { num: '12', key: 'future', title: 'Future Improvements', list: true },
  { num: '13', key: 'github', title: 'GitHub', github: true },
];

export function ProjectCaseStudyPage() {
  const { slug } = useParams();
  const project = projects.find((p) => p.slug === slug);

  if (!project || !project.hasCaseStudy) {
    return <Navigate to="/" replace />;
  }

  const study = slug === 'pfa-dialyse' ? pfaDialyseCaseStudy : null;
  if (!study) return <Navigate to="/" replace />;

  const content = study.sections;

  return (
    <article className="pt-24 pb-20">
      <div className="section-padding max-w-4xl">
        <Link
          to="/#projects"
          className="inline-flex items-center gap-2 text-sm text-muted hover:text-white transition-colors mb-8"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to projects
        </Link>
        <Reveal>
          <p className="font-mono text-xs text-accent uppercase tracking-widest">Case study</p>
          <h1 className="mt-2 text-3xl sm:text-4xl md:text-5xl font-semibold text-slate-50">
            {project.title}
          </h1>
          <p className="mt-2 text-muted">{project.status}</p>
        </Reveal>

        <div className="mt-12 space-y-16">
          {caseSections.map((section, idx) => (
            <Reveal key={section.key} delay={idx * 0.02}>
              <section aria-labelledby={`cs-${section.key}`}>
                <h2
                  id={`cs-${section.key}`}
                  className="font-mono text-sm text-accent mb-3"
                >
                  {section.num} — {section.title}
                </h2>
                {section.architecture && (
                  <>
                    <ArchitectureDiagram steps={content.architecture} />
                    <div className="mt-6 flex flex-wrap gap-2">
                      {dialyseParameters.map((p) => (
                        <span
                          key={p.code}
                          className="text-xs font-mono px-2 py-1 rounded border border-border"
                          title={p.name}
                        >
                          {p.code}
                        </span>
                      ))}
                    </div>
                  </>
                )}
                {section.gallery && (
                  <div className="grid sm:grid-cols-2 gap-4">
                    {study.images.map((img) => (
                      <ProjectImage
                        key={img.src}
                        src={img.src}
                        alt={img.alt}
                        className="w-full aspect-video rounded-xl"
                      />
                    ))}
                  </div>
                )}
                {section.github && (
                  <Button
                    as="a"
                    href={content.github}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <Github className="w-4 h-4" />
                    View repository
                  </Button>
                )}
                {!section.architecture && !section.gallery && !section.github && (
                  <>
                    {section.list ? (
                      <ul className="space-y-2 text-muted">
                        {(content[section.key] ?? []).map((item) => (
                          <li key={item} className="flex gap-2 text-sm md:text-base">
                            <span className="text-accent">—</span>
                            {item}
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p className="text-muted leading-relaxed">{content[section.key]}</p>
                    )}
                  </>
                )}
              </section>
            </Reveal>
          ))}
        </div>
      </div>
    </article>
  );
}
