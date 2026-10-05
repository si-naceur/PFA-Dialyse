import { personal } from '../data/site';

export function StructuredData() {
  const json = {
    '@context': 'https://schema.org',
    '@type': 'Person',
    name: personal.name,
    jobTitle: personal.title,
    address: {
      '@type': 'PostalAddress',
      addressCountry: 'TN',
    },
    url: typeof window !== 'undefined' ? window.location.origin : '',
    sameAs: personal.github.map((g) => g.url),
    knowsAbout: [
      'IoT',
      'Embedded Systems',
      'Artificial Intelligence',
      'Computer Vision',
      'Cybersecurity',
      'Flutter',
    ],
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(json) }}
    />
  );
}
