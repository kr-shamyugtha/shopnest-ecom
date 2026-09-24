import React from 'react';

// Placeholder that mirrors the real card's proportions, so the grid
// doesn't reflow the moment products arrive.
const ProductSkeleton = ({ count = 4 }) => (
  <div className="product-grid" aria-hidden="true">
    {Array.from({ length: count }).map((_, i) => (
      <div className="skeleton-card" key={i}>
        <div className="skeleton skeleton-thumb" />
        <div className="skeleton skeleton-line short" />
        <div className="skeleton skeleton-line" />
        <div className="skeleton skeleton-line short" style={{ marginBottom: 22 }} />
      </div>
    ))}
  </div>
);

export default ProductSkeleton;
