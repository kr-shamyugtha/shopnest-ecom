import React, { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import ProductCard from '../components/ProductCard';
import ProductSkeleton from '../components/ProductSkeleton';
import { CATEGORIES } from '../utils/catalog';
import '../styles/product.css';

const SORTS = {
  featured: { label: 'Featured', fn: null },
  priceAsc: { label: 'Price — low to high', fn: (a, b) => a.price - b.price },
  priceDesc: { label: 'Price — high to low', fn: (a, b) => b.price - a.price },
  rating: { label: 'Best rated', fn: (a, b) => (b.ratings || 0) - (a.ratings || 0) },
  name: { label: 'Alphabetical', fn: (a, b) => a.name.localeCompare(b.name) },
};

const Shop = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState('featured');

  // The category lives in the URL, so /shop?category=Handbags is
  // shareable, bookmarkable and survives a refresh — and the category
  // tiles on the home page are ordinary links rather than state pokes.
  const [searchParams, setSearchParams] = useSearchParams();
  const category = searchParams.get('category') || 'All';

  const setCategory = (next) => {
    const params = new URLSearchParams(searchParams);
    if (next === 'All') params.delete('category');
    else params.set('category', next);
    setSearchParams(params, { replace: true });
  };

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const res = await fetch('/api/products');
        const data = await res.json();
        setProducts(Array.isArray(data) ? data : []);
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    fetchProducts();
  }, []);

  // How many products sit in each category, so a chip can show its
  // count and an empty one can be marked rather than hidden.
  const counts = useMemo(() => {
    return products.reduce((acc, p) => {
      if (p.category) acc[p.category] = (acc[p.category] || 0) + 1;
      return acc;
    }, {});
  }, [products]);

  // Every canonical category is always offered, whether or not it has
  // stock — shoppers need to see the full range of what the shop sells.
  // Anything in the data that isn't canonical is appended rather than
  // dropped, so a legacy category never becomes unreachable.
  const categories = useMemo(() => {
    const extra = Object.keys(counts).filter((c) => !CATEGORIES.includes(c));
    return ['All', ...CATEGORIES, ...extra];
  }, [counts]);

  const visible = useMemo(() => {
    const term = search.trim().toLowerCase();
    const list = products.filter((p) => {
      const matchesCategory = category === 'All' || p.category === category;
      const matchesTerm =
        !term ||
        p.name.toLowerCase().includes(term) ||
        (p.category || '').toLowerCase().includes(term) ||
        (p.description || '').toLowerCase().includes(term);
      return matchesCategory && matchesTerm;
    });
    const sorter = SORTS[sort]?.fn;
    return sorter ? [...list].sort(sorter) : list;
  }, [products, search, category, sort]);

  return (
    <div className="shop-container">
      <div className="section-head">
        <div>
          <span className="eyebrow">{category === 'All' ? 'The Collection' : category}</span>
          <h2>{category === 'All' ? 'Everything we carry' : category}</h2>
          <p>Browse by category, search by name, or sort to taste.</p>
        </div>
      </div>

      <div className="shop-controls">
        <div className="search-wrap">
          <span className="icon">⌕</span>
          <input
            type="search"
            placeholder="Search by name or category"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="search-bar"
            aria-label="Search products"
          />
        </div>

        <select
          className="sort-select"
          value={sort}
          onChange={(e) => setSort(e.target.value)}
          aria-label="Sort products"
        >
          {Object.entries(SORTS).map(([key, { label }]) => (
            <option key={key} value={key}>{label}</option>
          ))}
        </select>
      </div>

      <div className="chips chips-row">
        {categories.map((c) => {
          const n = c === 'All' ? products.length : (counts[c] || 0);
          return (
            <button
              key={c}
              className={`chip ${category === c ? 'active' : ''} ${n === 0 ? 'empty' : ''}`}
              onClick={() => setCategory(c)}
              aria-pressed={category === c}
            >
              {c}
              <span className="chip-count">{n}</span>
            </button>
          );
        })}
      </div>

      {loading ? (
        <ProductSkeleton count={8} />
      ) : (
        <>
          <p className="result-count">
            {visible.length} {visible.length === 1 ? 'product' : 'products'}
            {category !== 'All' && ` in ${category}`}
          </p>

          {visible.length === 0 ? (
            <div className="empty-state">
              <div className="mark">◇</div>
              <h3>
                {counts[category] === 0 && !search.trim()
                  ? `No ${category.toLowerCase()} just yet`
                  : 'Nothing matches that'}
              </h3>
              <p>
                {counts[category] === 0 && !search.trim()
                  ? 'This part of the collection is still being assembled. Do come back.'
                  : 'Try a different search, or browse the whole collection.'}
              </p>
              <button
                className="btn btn-ghost"
                onClick={() => { setSearch(''); setCategory('All'); }}
              >
                View everything
              </button>
            </div>
          ) : (
            <div className="product-grid stagger">
              {visible.map((product) => (
                <ProductCard key={product._id} product={product} />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default Shop;
