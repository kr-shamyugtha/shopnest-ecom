import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import ProductCard from '../components/ProductCard';
import ProductSkeleton from '../components/ProductSkeleton';
import { CATEGORIES, categoryImage } from '../utils/catalog';
import '../styles/product.css';

const Home = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

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

  const counts = products.reduce((acc, p) => {
    if (p.category) acc[p.category] = (acc[p.category] || 0) + 1;
    return acc;
  }, {});

  const featured = products.slice(0, 4);
  // The hero collage borrows real catalogue imagery, so it can never
  // show something the shop doesn't actually stock.
  const art = products.slice(0, 3);

  return (
    <div className="home-container">
      <section className="hero">
        <div className="hero-copy">
          <span className="eyebrow">Est. 2026 — Fine Skincare</span>
          <h1>The quiet luxury of <em>looking after yourself</em></h1>
          <p>
            A small, deliberate collection from La Mer, SK-II, Tatcha and
            Augustinus Bader. No filler, no noise — only formulas worth
            the ritual.
          </p>
          <div className="hero-actions">
            <Link to="/shop" className="btn">Explore the collection</Link>
            <Link to="/about" className="btn btn-ghost">Our story</Link>
          </div>
        </div>

        {art.length === 3 && (
          <div className="hero-art">
            <figure className="tall">
              <img src={art[0].imageUrl} alt={art[0].name} />
            </figure>
            <figure className="wide">
              <img src={art[1].imageUrl} alt={art[1].name} />
            </figure>
            <figure className="wide">
              <img src={art[2].imageUrl} alt={art[2].name} />
            </figure>
          </div>
        )}
      </section>

      <section className="assurances">
        <div className="assurance">
          <div className="mark">✦</div>
          <h5>Sourced direct</h5>
          <p>Straight from the houses themselves. Never grey market.</p>
        </div>
        <div className="assurance">
          <div className="mark">◈</div>
          <h5>Complimentary shipping</h5>
          <p>On every order above ₹2,000, across India.</p>
        </div>
        <div className="assurance">
          <div className="mark">❖</div>
          <h5>Secure checkout</h5>
          <p>Payments handled by Razorpay. Cards never touch our servers.</p>
        </div>
        <div className="assurance">
          <div className="mark">✧</div>
          <h5>Considered returns</h5>
          <p>Unopened products, returnable within fourteen days.</p>
        </div>
      </section>

      <div className="section-head">
        <div>
          <span className="eyebrow">Browse</span>
          <h2>Shop by category</h2>
          <p>Thirteen edits, each chosen with the same eye.</p>
        </div>
        <Link to="/shop" className="btn btn-ghost">View all</Link>
      </div>
      <hr className="rule" />

      <div className="category-grid">
        {CATEGORIES.map((c) => {
          const n = counts[c] || 0;
          return (
            <Link
              key={c}
              to={`/shop?category=${encodeURIComponent(c)}`}
              className="category-tile"
              aria-label={`${c}, ${n} ${n === 1 ? 'piece' : 'pieces'}`}
            >
              {/* Decorative — the tile's own text already names the
                  category, so alt would only repeat it to a reader. */}
              <img src={categoryImage(c)} alt="" loading="lazy" className="category-img" />
              <span className="category-scrim" />
              <span className="category-body">
                <span className="category-name">{c}</span>
                <span className="category-meta">
                  {n > 0 ? `${n} ${n === 1 ? 'piece' : 'pieces'}` : 'Coming soon'}
                  <span className="category-go">Shop</span>
                </span>
              </span>
            </Link>
          );
        })}
      </div>

      <div className="section-head" style={{ marginTop: 92 }}>
        <div>
          <span className="eyebrow">The Edit</span>
          <h2>Featured this season</h2>
          <p>Four formulas our customers return to, chosen for results rather than novelty.</p>
        </div>
        <Link to="/shop" className="btn btn-ghost">View all</Link>
      </div>
      <hr className="rule" />

      {loading ? (
        <ProductSkeleton count={4} />
      ) : featured.length === 0 ? (
        <div className="empty-state">
          <div className="mark">◇</div>
          <h3>The shelves are being restocked</h3>
          <p>Nothing to show just yet. Do check back shortly.</p>
        </div>
      ) : (
        <div className="product-grid stagger">
          {featured.map((product) => (
            <ProductCard key={product._id} product={product} />
          ))}
        </div>
      )}
    </div>
  );
};

export default Home;
