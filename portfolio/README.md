# Naceur Zidi — Portfolio

Premium personal portfolio (React + Vite + Tailwind CSS + Framer Motion).

## Setup

```bash
cd portfolio
npm install
npm run dev
```

Production build:

```bash
npm run build
npm run preview
```

## Content

Edit structured data (no need to touch components for most updates):

| File | Purpose |
|------|---------|
| `src/data/site.js` | Name, links, CV path, email, LinkedIn |
| `src/data/projects.js` | Projects & PFA-Dialyse case study |
| `src/data/skills.js` | Skill categories |
| `src/data/experience.js` | Timeline |
| `src/data/education.js` | Education |
| `src/data/certificates.js` | Certifications |
| `src/data/enactus.js` | Enactus initiatives |
| `src/data/design.js` | Design gallery |
| `src/data/aiLab.js` | AI Lab section |

## Assets

- CV: `public/Naceur-Zidi-CV.pdf`
- Profile photo: `public/images/profile/naceur.jpg`
- Project photos: `public/images/projects/`
- Design work: `public/images/design/`

Suggested PFA-Dialyse screenshots (copy from repo root):

- `ecran_machine.jpeg` → `public/images/projects/pfa-dialyse/cover.jpg` (update path in `projects.js`)
- `data/*.jpeg` → `public/images/projects/pfa-dialyse/screen-*.jpg`

## Deploy

Build output is in `dist/`. Deploy to Vercel, Netlify, GitHub Pages (with base config if needed), or any static host.
