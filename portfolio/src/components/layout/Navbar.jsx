import { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X } from 'lucide-react';
import { navLinks, personal } from '../../data/site';
import { useActiveSection } from '../../hooks/useActiveSection';
import { scrollToSection } from '../../utils/scrollTo';

export function Navbar() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const location = useLocation();
  const onHome = location.pathname === '/';
  const sectionIds = navLinks.map((l) => l.id);
  const active = useActiveSection(onHome ? sectionIds : []);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    setOpen(false);
  }, [location.pathname]);

  const handleNav = (id) => {
    if (onHome) {
      scrollToSection(id);
    } else {
      window.location.href = `/#${id}`;
    }
    setOpen(false);
  };

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-colors duration-300 ${
        scrolled ? 'bg-bg/90 backdrop-blur-md border-b border-border' : 'bg-transparent'
      }`}
    >
      <nav
        className="section-padding flex items-center justify-between h-16 md:h-[4.25rem]"
        aria-label="Main navigation"
      >
        <Link
          to="/"
          className="font-semibold text-slate-100 tracking-tight hover:text-white transition-colors"
          onClick={() => onHome && scrollToSection('home')}
        >
          NZ<span className="text-accent">.</span>
        </Link>

        <ul className="hidden lg:flex items-center gap-1">
          {navLinks.map(({ id, label }) => (
            <li key={id}>
              <button
                type="button"
                onClick={() => handleNav(id)}
                className={`px-3 py-2 text-sm rounded-md transition-colors ${
                  onHome && active === id
                    ? 'text-white bg-white/5'
                    : 'text-muted hover:text-white'
                }`}
              >
                {label}
              </button>
            </li>
          ))}
        </ul>

        <button
          type="button"
          className="lg:hidden p-2 text-slate-100 rounded-lg border border-border hover:border-accent/50"
          aria-expanded={open}
          aria-controls="mobile-menu"
          onClick={() => setOpen((v) => !v)}
        >
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          <span className="sr-only">Toggle menu</span>
        </button>
      </nav>

      <div
        id="mobile-menu"
        className={`lg:hidden overflow-hidden transition-[max-height] duration-300 border-b border-border bg-bg-elevated ${
          open ? 'max-h-[80vh]' : 'max-h-0'
        }`}
      >
        <ul className="section-padding py-4 flex flex-col gap-1">
          {navLinks.map(({ id, label }) => (
            <li key={id}>
              <button
                type="button"
                onClick={() => handleNav(id)}
                className="w-full text-left px-3 py-3 text-sm text-muted hover:text-white rounded-lg hover:bg-white/5"
              >
                {label}
              </button>
            </li>
          ))}
          <li className="pt-2 border-t border-border mt-2">
            <p className="px-3 text-xs text-muted">{personal.title}</p>
          </li>
        </ul>
      </div>
    </header>
  );
}
