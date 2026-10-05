import { forwardRef } from 'react';

const variants = {
  primary:
    'bg-accent text-white hover:bg-accent-dim border border-transparent shadow-[0_0_24px_rgb(37_99_235/0.25)]',
  secondary:
    'bg-transparent text-slate-100 border border-border hover:border-accent/60 hover:text-white',
  ghost: 'bg-transparent text-muted hover:text-white border border-transparent',
};

export const Button = forwardRef(function Button(
  { as: Comp = 'button', variant = 'primary', className = '', children, ...props },
  ref,
) {
  return (
    <Comp
      ref={ref}
      className={`inline-flex items-center justify-center gap-2 rounded-lg px-5 py-2.5 text-sm font-medium transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent ${variants[variant] ?? variants.primary} ${className}`}
      {...props}
    >
      {children}
    </Comp>
  );
});
