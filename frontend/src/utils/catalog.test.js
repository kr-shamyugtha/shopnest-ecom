import {
  CATEGORIES,
  CATEGORY_IMAGES,
  ORDER_STATUSES,
  isCancellable,
  statusColor,
  categoryImage,
} from './catalog';

describe('order status helpers', () => {
  it('only a Placed order is cancellable', () => {
    expect(isCancellable('Placed')).toBe(true);
    ['Shipped', 'Delivered', 'Cancelled', undefined].forEach((s) => {
      expect(isCancellable(s)).toBe(false);
    });
  });

  it('keeps the lifecycle order the admin dropdown relies on', () => {
    expect(ORDER_STATUSES).toEqual(['Placed', 'Shipped', 'Delivered', 'Cancelled']);
  });

  it('gives every status a colour, with a fallback for unknown ones', () => {
    ORDER_STATUSES.forEach((s) => expect(statusColor(s)).toMatch(/^var\(--/));
    expect(statusColor('Something else')).toBe(statusColor('Placed'));
  });
});

describe('category helpers', () => {
  it('has no duplicate categories', () => {
    expect(new Set(CATEGORIES).size).toBe(CATEGORIES.length);
  });

  it('has an image for every category, so the home tiles never fall back', () => {
    CATEGORIES.forEach((c) => expect(CATEGORY_IMAGES).toHaveProperty(c));
  });

  it('resolves a known category and falls back for an unknown one', () => {
    expect(categoryImage('Skincare')).toBe('/skinc.jpg');
    expect(categoryImage('Nope')).toBe('/placeholder-product.svg');
  });
});
