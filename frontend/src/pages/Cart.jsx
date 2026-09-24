import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { Link, useNavigate } from 'react-router-dom';
import { removeFromCart, addToCart } from '../redux/cartSlice';
import { inr } from '../utils/format';
import '../styles/cart.css';

const FREE_SHIPPING_ABOVE = 2000;
const SHIPPING_FEE = 149;

const Cart = () => {
  const cartItems = useSelector((state) => state.cart.cartItems);
  const dispatch = useDispatch();
  const navigate = useNavigate();

  const handleRemove = (id) => dispatch(removeFromCart(id));

  const handleUpdateQty = (item, qty) => {
    if (qty > 0) dispatch(addToCart({ ...item, qty }));
  };

  const subtotal = cartItems.reduce((acc, item) => acc + item.price * item.qty, 0);
  const shipping = subtotal >= FREE_SHIPPING_ABOVE || subtotal === 0 ? 0 : SHIPPING_FEE;
  const total = subtotal + shipping;
  const shortfall = FREE_SHIPPING_ABOVE - subtotal;

  if (cartItems.length === 0) {
    return (
      <div className="cart-container">
        <div className="empty-state">
          <div className="mark">◇</div>
          <h3>Your cart is empty</h3>
          <p>Nothing here yet. The collection is a good place to begin.</p>
          <Link to="/shop" className="btn">Browse the collection</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="cart-container">
      <div className="section-head">
        <div>
          <span className="eyebrow">Your selection</span>
          <h2>Shopping cart</h2>
        </div>
      </div>

      <div className="cart-layout">
        <div className="cart-items">
          {cartItems.map((item) => (
            <div key={item.productId} className="cart-item">
              <img src={item.imageUrl} alt={item.name} className="cart-item-image" />
              <div className="cart-item-details">
                <h4>{item.name}</h4>
                <p className="cart-item-price">{inr(item.price)} each</p>
                <div className="cart-item-row">
                  <div className="qty-controls">
                    <button
                      onClick={() => handleUpdateQty(item, item.qty - 1)}
                      disabled={item.qty <= 1}
                      aria-label={`Decrease quantity of ${item.name}`}
                    >−</button>
                    <span>{item.qty}</span>
                    <button
                      onClick={() => handleUpdateQty(item, item.qty + 1)}
                      aria-label={`Increase quantity of ${item.name}`}
                    >+</button>
                  </div>
                  <span className="line-total">{inr(item.price * item.qty)}</span>
                </div>
                <button onClick={() => handleRemove(item.productId)} className="btn-remove">
                  Remove
                </button>
              </div>
            </div>
          ))}
        </div>

        <aside className="cart-summary">
          <h3>Order summary</h3>

          <div className="summary-rows">
            <div className="summary-row">
              <span>Subtotal</span>
              <span>{inr(subtotal)}</span>
            </div>
            <div className="summary-row">
              <span>Shipping</span>
              {shipping === 0 ? <span className="free">Complimentary</span> : <span>{inr(shipping)}</span>}
            </div>
            {shortfall > 0 && (
              <div className="summary-row">
                <span style={{ color: 'var(--gold)' }}>
                  Add {inr(shortfall)} for free shipping
                </span>
              </div>
            )}
          </div>

          <div className="summary-total">
            <span>Total</span>
            <strong>{inr(total)}</strong>
          </div>

          <button onClick={() => navigate('/checkout')} className="btn btn-checkout">
            Proceed to checkout
          </button>

          <p className="summary-note">
            Secure payment via Razorpay.<br />Taxes included in the price shown.
          </p>
        </aside>
      </div>
    </div>
  );
};

export default Cart;
