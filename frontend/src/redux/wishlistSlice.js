import { createSlice } from '@reduxjs/toolkit';

// Same per-user scoping as the cart: a wishlist is personal, and must
// not follow one account into the next person's session.
const PREFIX = 'shopnest:wishlist:';

const currentOwner = () => {
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
    /* ignore */
  }
};

const owner = currentOwner();

const wishlistSlice = createSlice({
  name: 'wishlist',
  initialState: { owner, items: read(owner) },
  reducers: {
    toggleWishlist: (state, action) => {
      const product = action.payload;
      const exists = state.items.find((x) => x.productId === product.productId);
      state.items = exists
        ? state.items.filter((x) => x.productId !== product.productId)
        : [...state.items, product];
      write(state.owner, state.items);
    },
    removeFromWishlist: (state, action) => {
      state.items = state.items.filter((x) => x.productId !== action.payload);
      write(state.owner, state.items);
    },
    setWishlistOwner: (state, action) => {
      state.owner = action.payload || 'guest';
      state.items = read(state.owner);
    },
  },
});

export const { toggleWishlist, removeFromWishlist, setWishlistOwner } = wishlistSlice.actions;
export default wishlistSlice.reducer;
