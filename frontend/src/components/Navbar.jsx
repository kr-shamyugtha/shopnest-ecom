import React, { useContext } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { AuthContext } from '../context/AuthContext';
import { useSelector } from 'react-redux';
import '../styles/navbar.css';

const Navbar = () => {
  const { user, logout } = useContext(AuthContext);
  const cartItems = useSelector((state) => state.cart.cartItems);
  const wishlist = useSelector((state) => state.wishlist.items);
  const navigate = useNavigate();

  // Count units, not lines — three of one serum should read as 3.
  const cartCount = cartItems.reduce((n, item) => n + (item.qty || 1), 0);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <>
      <div className="announce">
        Complimentary shipping on orders above <span>₹2,000</span>
      </div>

      <nav className="navbar">
        <div className="navbar-brand">
          <Link to="/">
            <img src="/ShopNestLogo.png" alt="" />
            ShopNest
          </Link>
        </div>

        <ul className="navbar-links">
          <li><Link to="/">Home</Link></li>
          <li><Link to="/shop">Shop</Link></li>
          <li><Link to="/about">About</Link></li>
          <li>
            <Link to="/wishlist" className="cart-link">
              Wishlist
              {wishlist.length > 0 && <span className="cart-count">{wishlist.length}</span>}
            </Link>
          </li>
          <li>
            <Link to="/cart" className="cart-link">
              Cart
              {cartCount > 0 && <span className="cart-count">{cartCount}</span>}
            </Link>
          </li>
          {user ? (
            <>
              <li>
                <Link to="/profile" className="nav-greet">
                  Hi, <strong>{user.name}</strong>
                </Link>
              </li>
              {user.role === 'admin' && (
                <li><Link to="/admin" className="nav-admin">Admin</Link></li>
              )}
              <li><button onClick={handleLogout} className="btn-logout">Logout</button></li>
            </>
          ) : (
            <li><Link to="/login">Login</Link></li>
          )}
        </ul>
      </nav>
    </>
  );
};

export default Navbar;
