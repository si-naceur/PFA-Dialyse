import { Download } from 'lucide-react';
import { personal } from '../../data/site';
import { useCvAvailable } from '../../hooks/useCvAvailable';
import { Button } from './Button';
import { handleCvDownload } from '../../utils/cvDownload';

export function CvDownloadButton({ variant = 'secondary', className = '' }) {
  const available = useCvAvailable();

  if (!available) return null;

  return (
    <Button
      type="button"
      variant={variant}
      className={className}
      onClick={() => handleCvDownload(personal.cvPath)}
    >
      <Download className="w-4 h-4" aria-hidden />
      Download CV
    </Button>
  );
}
