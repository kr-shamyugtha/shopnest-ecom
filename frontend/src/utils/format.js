// Prices are stored as plain numbers and shown across the catalogue,
// cart, checkout and admin. Formatting them in one place keeps
// "₹8,500" from drifting into "₹8500.00" on half the screens.

const inrFormatter = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  minimumFractionDigits: 0,
  maximumFractionDigits: 0,
});

const inrFormatterPaise = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/**
 * Whole rupees render without a decimal tail (₹32,000), but anything
 * with paise keeps both digits (₹1,249.50) so a cart total never
 * silently rounds away money.
 */
export const inr = (value) => {
  const n = Number(value) || 0;
  return Number.isInteger(n) ? inrFormatter.format(n) : inrFormatterPaise.format(n);
};

/** Five glyphs, filled to the nearest half. */
export const starGlyphs = (rating = 0) => {
  const r = Math.max(0, Math.min(5, Number(rating) || 0));
  const full = Math.floor(r);
  const half = r - full >= 0.5;
  return '★'.repeat(full) + (half ? '⯨' : '') + '☆'.repeat(5 - full - (half ? 1 : 0));
};
