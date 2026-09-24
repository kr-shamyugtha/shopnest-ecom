import React from 'react';
import { Link } from 'react-router-dom';
import '../styles/footer.css';

const Footer = () => {
  return (
    <footer className="site-footer">
      <div className="footer-inner">
        <div className="footer-brand">
          <h3>ShopNest</h3>
          <p>
            A considered edit of skincare from houses that have spent
            decades getting a single formula right.
          </p>
        </div>

        <nav className="footer-col">
          <h5>Shop</h5>
          <Link to="/shop">All products</Link>
          <Link to="/cart">Your cart</Link>
          <Link to="/profile">Your orders</Link>
        </nav>

        <nav className="footer-col">
          <h5>Company</h5>
          <Link to="/about">About us</Link>
          <Link to="/return">Return policy</Link>
          <Link to="/disclaimer">Disclaimer</Link>
        </nav>

        <div className="footer-col">
          <h5>Care</h5>
          <p>Monday to Friday, 9am–6pm IST</p>
          <p>Authentic products, sourced direct</p>
        </div>
      </div>

      <div className="footer-base">
        <span>&copy; {new Date().getFullYear()} ShopNest. All rights reserved.</span>
        <span className="footer-mark">Crafted with care</span>
      </div>
    </footer>
  );
};

export default Footer;
