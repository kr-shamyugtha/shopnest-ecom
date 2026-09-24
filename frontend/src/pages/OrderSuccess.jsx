import React from 'react';
import { Link } from 'react-router-dom';
import '../styles/cart.css';

const OrderSuccess = () => (
  <div className="order-success">
    <div className="seal">✓</div>
    <span className="eyebrow">Order confirmed</span>
    <h2>Thank you for your order</h2>
    <p>
      We've received your payment securely and your parcel is being
      prepared. A confirmation is on its way to your inbox.
    </p>
    <div style={{ display: 'flex', gap: 14, justifyContent: 'center', flexWrap: 'wrap' }}>
      <Link to="/shop" className="btn">Continue shopping</Link>
      <Link to="/profile" className="btn btn-ghost">View your orders</Link>
    </div>
  </div>
);

export default OrderSuccess;
