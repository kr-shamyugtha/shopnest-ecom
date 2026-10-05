import { inr, starGlyphs } from './format';

// Intl output uses a non-breaking space in some ICU versions; normalise it.
const norm = (s) => s.replace(/ /g, ' ');

describe('inr', () => {
  it('formats whole rupees with Indian digit grouping and no decimals', () => {
    expect(norm(inr(8500))).toBe('₹8,500');
    expect(norm(inr(3200000))).toBe('₹32,00,000');
  });

  it('keeps both paise digits so a total never silently rounds away money', () => {
    expect(norm(inr(1249.5))).toBe('₹1,249.50');
  });

  it('treats missing or invalid values as zero', () => {
    expect(norm(inr(undefined))).toBe('₹0');
    expect(norm(inr('abc'))).toBe('₹0');
    expect(norm(inr(null))).toBe('₹0');
  });

  it('accepts numeric strings', () => {
    expect(norm(inr('500'))).toBe('₹500');
  });
});

describe('starGlyphs', () => {
  it('always returns five glyphs', () => {
    [0, 1, 2.5, 3.4, 4.5, 5].forEach((r) => {
      expect(Array.from(starGlyphs(r))).toHaveLength(5);
    });
  });

  it('fills whole stars', () => {
    expect(starGlyphs(3)).toBe('★★★☆☆');
  });

  it('shows a half star from .5 upwards and not below', () => {
    expect(starGlyphs(3.5)).toBe('★★★⯨☆');
    expect(starGlyphs(3.4)).toBe('★★★☆☆');
  });

  it('clamps out-of-range and invalid ratings', () => {
    expect(starGlyphs(9)).toBe('★★★★★');
    expect(starGlyphs(-2)).toBe('☆☆☆☆☆');
    expect(starGlyphs('x')).toBe('☆☆☆☆☆');
    expect(starGlyphs()).toBe('☆☆☆☆☆');
  });
});
