import React from 'react';
import { Link } from 'react-router-dom';
import { useSelector, useDispatch } from 'react-redux';
import { removeFromWishlist } from '../redux/wishlistSlice';
import { addToCart } from '../redux/cartSlice';
import { toast } from '../components/Toast';
import { inr } from '../utils/format';
import '../styles/product.css';

const Wishlist = () => {
  const items = useSelector((state) => state.wishlist.items);
  const dispatch = useDispatch();

  const moveToCart = (item) => {
    dispatch(addToCart({
      productId: item.productId,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      qty: 1,
    }));
    dispatch(removeFromWishlist(item.productId));
    toast(`${item.name} moved to your cart`);
  };

  if (items.length === 0) {
    return (
      <div className="empty-state">
        <div className="mark">♡</div>
        <h3>Your wishlist is empty</h3>
        <p>Tap the heart on anything you'd like to keep an eye on.</p>
        <Link to="/shop" className="btn">Browse the collection</Link>
      </div>
    );
  }

  return (
    <div className="wishlist-page">
      <div className="section-head">
        <div>
          <span className="eyebrow">Saved for later</span>
          <h2>Your wishlist</h2>
        </div>
      </div>
      <hr className="rule" />

      <p className="wishlist-note">
        {items.length} {items.length === 1 ? 'piece' : 'pieces'} saved. Kept to this account only.
      </p>

      <div className="product-grid stagger">
        {items.map((item) => (
          <article className="product-card" key={item.productId}>
            <div className="product-media">
              <Link to={`/product/${item.productId}`} aria-label={item.name}>
                <img src={item.imageUrl} alt={item.name} className="product-image" loading="lazy" />
              </Link>
              <button
                className="wish-btn on"
                onClick={() => dispatch(removeFromWishlist(item.productId))}
                aria-label={`Remove ${item.name} from wishlist`}
                title="Remove from wishlist"
              >
                ♥
              </button>
              <div className="quick-add">
                <button onClick={() => moveToCart(item)}>Move to cart</button>
              </div>
            </div>

            <div className="product-info">
              {item.category && <span className="product-cat">{item.category}</span>}
              <h3><Link to={`/product/${item.productId}`}>{item.name}</Link></h3>
              <div className="price-row">
                <span className="price">{inr(item.price)}</span>
                <Link to={`/product/${item.productId}`} className="price-link">Details</Link>
              </div>
            </div>
          </article>
        ))}
      </div>
    </div>
  );
};

export default Wishlist;
