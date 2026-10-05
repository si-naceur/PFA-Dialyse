export async function handleCvDownload(cvPath) {
  try {
    const res = await fetch(cvPath, { method: 'HEAD' });
    if (res.ok) {
      const a = document.createElement('a');
      a.href = cvPath;
      a.download = 'Naceur-Zidi-CV.pdf';
      a.rel = 'noopener';
      document.body.appendChild(a);
      a.click();
      a.remove();
      return true;
    }
  } catch {
    /* fall through */
  }
  scrollToContactForCv();
  return false;
}

function scrollToContactForCv() {
  const el = document.getElementById('contact');
  if (el) el.scrollIntoView({ behavior: 'smooth' });
  window.dispatchEvent(new CustomEvent('cv-missing'));
}
