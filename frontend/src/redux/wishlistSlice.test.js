const load = (userInfo) => {
  localStorage.clear();
  if (userInfo) localStorage.setItem('userInfo', JSON.stringify(userInfo));
  let mod;
  jest.isolateModules(() => {
    mod = require('./wishlistSlice');
  });
  return mod;
};

const product = (id) => ({ productId: id, name: `P${id}` });

describe('wishlistSlice', () => {
  it('toggling adds a product, toggling again removes it', () => {
    const { default: reducer, toggleWishlist } = load();
    let state = reducer(undefined, toggleWishlist(product('a')));
    expect(state.items).toEqual([product('a')]);
    state = reducer(state, toggleWishlist(product('a')));
    expect(state.items).toEqual([]);
  });

  it('does not affect other products when toggling one off', () => {
    const { default: reducer, toggleWishlist } = load();
    let state = reducer(undefined, toggleWishlist(product('a')));
    state = reducer(state, toggleWishlist(product('b')));
    state = reducer(state, toggleWishlist(product('a')));
    expect(state.items).toEqual([product('b')]);
  });

  it('removeFromWishlist removes by product id', () => {
    const { default: reducer, toggleWishlist, removeFromWishlist } = load();
    let state = reducer(undefined, toggleWishlist(product('a')));
    state = reducer(state, removeFromWishlist('a'));
    expect(state.items).toEqual([]);
  });

  it('persists per owner and swaps on setWishlistOwner', () => {
    const { default: reducer, toggleWishlist, setWishlistOwner } = load({ _id: 'u1' });
    let state = reducer(undefined, toggleWishlist(product('a')));
    expect(JSON.parse(localStorage.getItem('shopnest:wishlist:u1'))).toEqual([product('a')]);

    state = reducer(state, setWishlistOwner('u2'));
    expect(state.items).toEqual([]);
    state = reducer(state, setWishlistOwner('u1'));
    expect(state.items).toEqual([product('a')]);
  });

  it('falls back to guest when there is no owner', () => {
    const { default: reducer, setWishlistOwner } = load({ _id: 'u1' });
    expect(reducer(undefined, setWishlistOwner('')).owner).toBe('guest');
  });
});
