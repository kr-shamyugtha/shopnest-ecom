import React, { createContext, useState } from 'react';
import { store } from '../redux/store';
import { setCartOwner } from '../redux/cartSlice';
import { setWishlistOwner } from '../redux/wishlistSlice';

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(
    localStorage.getItem('userInfo') ? JSON.parse(localStorage.getItem('userInfo')) : null
  );

  // The cart and wishlist live in Redux but are persisted per user, so
  // both have to be repointed whenever the signed-in user changes —
  // otherwise one account keeps browsing the previous one's basket.
  const swapOwner = (ownerId) => {
    store.dispatch(setCartOwner(ownerId));
    store.dispatch(setWishlistOwner(ownerId));
  };

  const login = (userData) => {
    setUser(userData);
    localStorage.setItem('userInfo', JSON.stringify(userData));
    swapOwner(userData && userData._id ? userData._id : 'guest');
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('userInfo');
    swapOwner('guest');
  };

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};
