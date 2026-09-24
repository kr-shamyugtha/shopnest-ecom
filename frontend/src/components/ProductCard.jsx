import React from 'react';
import { Link } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { addToCart } from '../redux/cartSlice';
import { toggleWishlist } from '../redux/wishlistSlice';
import { toast } from './Toast';
import { inr, starGlyphs } from '../utils/format';
import '../styles/product.css';

const ProductCard = ({ product }) => {
  const dispatch = useDispatch();
  const wishlist = useSelector((state) => state.wishlist.items);
  const wished = wishlist.some((w) => w.productId === product._id);
  const outOfStock = product.stock <= 0;
  const lowStock = !outOfStock && product.stock <= 10;

  const handleQuickAdd = (e) => {
    // The card is wrapped in a Link, so without this the add would
    // also navigate away from the grid the shopper is browsing.
    e.preventDefault();
    e.stopPropagation();
    if (outOfStock) return;
    dispatch(addToCart({
      productId: product._id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      qty: 1,
    }));
    toast(`${product.name} added to your cart`);
  };

  const handleWishlist = (e) => {
    e.preventDefault();
    e.stopPropagation();
    dispatch(toggleWishlist({
      productId: product._id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      category: product.category,
    }));
    toast(wished ? `${product.name} removed from wishlist` : `${product.name} saved to wishlist`);
  };

  return (
    <article className="product-card">
      <div className="product-media">
        <Link to={`/product/${product._id}`} aria-label={product.name}>
          <img
            src={product.imageUrl}
            alt={product.name}
            className="product-image"
            loading="lazy"
          />
        </Link>

        {outOfStock ? (
          <span className="product-badge low">Sold out</span>
        ) : lowStock ? (
          <span className="product-badge low">Only {product.stock} left</span>
        ) : (
          <span className="product-badge">{product.category}</span>
        )}

        <button
          className={`wish-btn ${wished ? 'on' : ''}`}
          onClick={handleWishlist}
          aria-pressed={wished}
          aria-label={wished ? `Remove ${product.name} from wishlist` : `Save ${product.name} to wishlist`}
          title={wished ? 'Remove from wishlist' : 'Save to wishlist'}
        >
          {wished ? '♥' : '♡'}
        </button>

        <div className="quick-add">
          <button onClick={handleQuickAdd} disabled={outOfStock}>
            {outOfStock ? 'Sold out' : 'Add to cart'}
          </button>
        </div>
      </div>

      <div className="product-info">
        <span className="product-cat">{product.category}</span>

        <h3>
          <Link to={`/product/${product._id}`}>{product.name}</Link>
        </h3>

        <div className="rating">
          <span className="stars" aria-hidden="true">{starGlyphs(product.ratings)}</span>
          <span>{Number(product.ratings || 0).toFixed(1)} ({product.numReviews || 0})</span>
        </div>

        <div className="price-row">
          <span className="price">{inr(product.price)}</span>
          <Link to={`/product/${product._id}`} className="price-link">Details</Link>
        </div>
      </div>
    </article>
  );
};

export default ProductCard;
