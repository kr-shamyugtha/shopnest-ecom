import { createSlice } from '@reduxjs/toolkit';

// Carts used to live under one global "cartItems" key, so every account
// signing in on the same browser inherited whatever the last person had
// left behind — including products long since removed from the
// catalogue. Storage is now scoped to the signed-in user.
const PREFIX = 'shopnest:cart:';
const LEGACY_KEY = 'cartItems';

export const currentOwner = () => {
  try {
    const u = JSON.parse(localStorage.getItem('userInfo'));
    return u && u._id ? u._id : 'guest';
  } catch {
    return 'guest';
  }
};

const read = (owner) => {
  try {
    const raw = localStorage.getItem(PREFIX + owner);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
};

const write = (owner, items) => {
  try {
    localStorage.setItem(PREFIX + owner, JSON.stringify(items));
  } catch {
    /* quota or private mode — the cart still works for this session */
  }
};

// Retire the shared key outright. Leaving it would mean the stale cart
// reappears for anyone whose id happens to be absent.
try { localStorage.removeItem(LEGACY_KEY); } catch { /* ignore */ }

const owner = currentOwner();

const cartSlice = createSlice({
  name: 'cart',
  initialState: { owner, cartItems: read(owner) },
  reducers: {
    addToCart: (state, action) => {
      const item = action.payload;
      const exists = state.cartItems.find((x) => x.productId === item.productId);
      if (exists) {
        state.cartItems = state.cartItems.map((x) =>
          x.productId === item.productId ? item : x
        );
      } else {
        state.cartItems.push(item);
      }
      write(state.owner, state.cartItems);
    },
    removeFromCart: (state, action) => {
      state.cartItems = state.cartItems.filter((x) => x.productId !== action.payload);
      write(state.owner, state.cartItems);
    },
    clearCart: (state) => {
      state.cartItems = [];
      write(state.owner, []);
    },
    // Dispatched on sign-in and sign-out. Swapping the owner swaps the
    // basket rather than carrying one person's items into another's
    // session.
    setCartOwner: (state, action) => {
      state.owner = action.payload || 'guest';
      state.cartItems = read(state.owner);
    },
  },
});

export const { addToCart, removeFromCart, clearCart, setCartOwner } = cartSlice.actions;
export default cartSlice.reducer;
