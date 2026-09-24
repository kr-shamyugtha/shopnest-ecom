// The canonical category list. Kept in one place so the shop filters,
// the admin product forms and any future seed all agree — a typo in an
// admin form used to be enough to create a category of one.
export const CATEGORIES = [
  // Beauty
  'Skincare',
  'Makeup',
  'Haircare',
  'Perfumes',
  // Apparel
  'Dresses',
  'Tops',
  'Pants',
  'Overcoats',
  // Accessories
  'Heels',
  'Handbags',
  'Jewellery',
  'Watches',
  'Accessories',
];

// 'Placed' replaced 'Pending' — see backend/models/Order.js. The order
// here is the lifecycle order, which the admin dropdown relies on.
export const ORDER_STATUSES = ['Placed', 'Shipped', 'Delivered', 'Cancelled'];

// Only a Placed order can still be withdrawn; the backend enforces this
// too, so a stale tab can't cancel something already shipped.
export const isCancellable = (status) => status === 'Placed';

export const statusColor = (status) => {
  switch (status) {
    case 'Delivered': return 'var(--success)';
    case 'Shipped': return 'var(--sage)';
    case 'Cancelled': return 'var(--danger)';
    default: return 'var(--gold)';
  }
};

// Editorial imagery for the home-page category browser. Files live in
// frontend/public, so these resolve identically in dev and behind nginx.
// A category with no entry falls back to the monogram placeholder
// rather than rendering a broken tile.
export const CATEGORY_IMAGES = {
  Skincare: '/skinc.jpg',
  Makeup: '/makeup.jpg',
  Haircare: '/hairc.jpg',
  Perfumes: '/perfume.jpg',
  Dresses: '/dress.jpg',
  Tops: '/tops.jpeg',
  Pants: '/pants.jpeg',
  Overcoats: '/overcoats.jpg',
  Heels: '/heels.jpg',
  Handbags: '/bags.jpeg',
  Jewellery: '/jewel.jpg',
  Watches: '/watch.jpeg',
  Accessories: '/accessories.jpg',
};

export const categoryImage = (category) =>
  CATEGORY_IMAGES[category] || '/placeholder-product.svg';
