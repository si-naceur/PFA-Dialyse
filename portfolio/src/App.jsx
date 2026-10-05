import { BrowserRouter, Route, Routes } from 'react-router-dom';
import { SkipLink } from './components/SkipLink';
import { Navbar } from './components/layout/Navbar';
import { Footer } from './components/layout/Footer';
import { ScrollToHash } from './components/ScrollToHash';
import { StructuredData } from './components/StructuredData';
import { HomePage } from './pages/HomePage';
import { ProjectCaseStudyPage } from './pages/ProjectCaseStudyPage';

export default function App() {
  return (
    <BrowserRouter>
      <StructuredData />
      <ScrollToHash />
      <div className="min-h-screen flex flex-col bg-bg text-slate-100">
        <SkipLink />
        <Navbar />
        <main className="flex-1">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/projects/:slug" element={<ProjectCaseStudyPage />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </BrowserRouter>
  );
}
