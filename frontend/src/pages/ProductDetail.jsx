import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { useDispatch } from 'react-redux';
import { addToCart } from '../redux/cartSlice';
import { toast } from '../components/Toast';
import { inr, starGlyphs } from '../utils/format';
import '../styles/product.css';

const ProductDetail = () => {
  const { id } = useParams();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [qty, setQty] = useState(1);
  const dispatch = useDispatch();
  const navigate = useNavigate();

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const res = await fetch(`/api/products/${id}`);
        const data = await res.json();
        setProduct(data);
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    fetchProduct();
  }, [id]);

  const handleAddToCart = (goToCart = false) => {
    if (!product) return;
    dispatch(addToCart({
      productId: product._id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      qty,
    }));
    if (goToCart) {
      navigate('/cart');
    } else {
      toast(`${product.name} added to your cart`);
    }
  };

  if (loading) {
    return (
      <div className="product-detail">
        <div className="skeleton" style={{ aspectRatio: '1 / 1', borderRadius: 20 }} />
        <div>
          <div className="skeleton skeleton-line" style={{ height: 40, margin: '0 0 20px' }} />
          <div className="skeleton skeleton-line" style={{ margin: '0 0 14px' }} />
          <div className="skeleton skeleton-line short" style={{ margin: 0 }} />
        </div>
      </div>
    );
  }

  if (!product || !product._id) {
    return (
      <div className="empty-state">
        <div className="mark">◇</div>
        <h3>We couldn't find that product</h3>
        <p>It may have sold out or been retired from the collection.</p>
        <Link to="/shop" className="btn">Back to the collection</Link>
      </div>
    );
  }

  const outOfStock = product.stock <= 0;

  return (
    <div className="product-detail-wrapper">
      <nav className="breadcrumb">
        <Link to="/">Home</Link>
        <span className="sep">/</span>
        <Link to="/shop">Shop</Link>
        <span className="sep">/</span>
        <span className="current">{product.name}</span>
      </nav>

      <div className="product-detail">
        <div className="detail-media">
          <img src={product.imageUrl} alt={product.name} className="detail-image" />
        </div>

        <div className="detail-info">
          <span className="eyebrow">{product.category}</span>
          <h1>{product.name}</h1>

          <div className="rating">
            <span className="stars" aria-hidden="true">{starGlyphs(product.ratings)}</span>
            <span>{Number(product.ratings || 0).toFixed(1)} · {product.numReviews || 0} reviews</span>
          </div>

          <p className="detail-price">
            {inr(product.price)}
            <span className="tax">Inclusive of all taxes</span>
          </p>

          <div className="detail-actions">
            <button
              onClick={() => handleAddToCart(false)}
              className="btn"
              disabled={outOfStock}
            >
              {outOfStock ? 'Sold out' : 'Add to cart'}
            </button>
            <button
              onClick={() => handleAddToCart(true)}
              className="btn btn-ghost"
              disabled={outOfStock}
            >
              Buy it now
            </button>
          </div>

          {!outOfStock && (
            <div className="qty-controls" style={{ marginBottom: 22 }}>
              <button onClick={() => setQty((q) => Math.max(1, q - 1))} disabled={qty <= 1} aria-label="Decrease quantity">−</button>
              <span>{qty}</span>
              <button onClick={() => setQty((q) => Math.min(product.stock, q + 1))} disabled={qty >= product.stock} aria-label="Increase quantity">+</button>
            </div>
          )}

          <p className={`stock ${outOfStock ? 'out' : ''}`}>
            <span className="dot" />
            {outOfStock ? 'Temporarily out of stock' : `In stock — ${product.stock} available`}
          </p>

          <div className="detail-section">
            <h4>The formula</h4>
            <p>{product.description}</p>
          </div>

          <div className="detail-section">
            <h4>Details</h4>
            <dl className="spec-list">
              <div className="spec-row"><dt>Category</dt><dd>{product.category}</dd></div>
              <div className="spec-row"><dt>Rating</dt><dd>{Number(product.ratings || 0).toFixed(1)} / 5</dd></div>
              <div className="spec-row"><dt>Reviews</dt><dd>{product.numReviews || 0}</dd></div>
              <div className="spec-row"><dt>Shipping</dt><dd>Complimentary above ₹2,000</dd></div>
            </dl>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProductDetail;
