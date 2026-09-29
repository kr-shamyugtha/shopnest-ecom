const load = (userInfo) => {
  localStorage.clear();
  if (userInfo) localStorage.setItem('userInfo', JSON.stringify(userInfo));
  let mod;
  jest.isolateModules(() => {
    mod = require('./cartSlice');
  });
  return mod;
};

const item = (id, qty = 1) => ({ productId: id, name: `P${id}`, price: 100, qty });

describe('cartSlice', () => {
  it('starts empty for a guest', () => {
    const { default: reducer } = load();
    const state = reducer(undefined, { type: 'init' });
    expect(state).toEqual({ owner: 'guest', cartItems: [] });
  });

  it('adds a new item', () => {
    const { default: reducer, addToCart } = load();
    const state = reducer(undefined, addToCart(item('a')));
    expect(state.cartItems).toEqual([item('a')]);
  });

  it('replaces an existing product instead of duplicating it', () => {
    const { default: reducer, addToCart } = load();
    let state = reducer(undefined, addToCart(item('a', 1)));
    state = reducer(state, addToCart(item('a', 4)));
    expect(state.cartItems).toHaveLength(1);
    expect(state.cartItems[0].qty).toBe(4);
  });

  it('removes only the requested product', () => {
    const { default: reducer, addToCart, removeFromCart } = load();
    let state = reducer(undefined, addToCart(item('a')));
    state = reducer(state, addToCart(item('b')));
    state = reducer(state, removeFromCart('a'));
    expect(state.cartItems.map((x) => x.productId)).toEqual(['b']);
  });

  it('clears the cart', () => {
    const { default: reducer, addToCart, clearCart } = load();
    let state = reducer(undefined, addToCart(item('a')));
    state = reducer(state, clearCart());
    expect(state.cartItems).toEqual([]);
  });

  it('persists to localStorage under the owner key', () => {
    const { default: reducer, addToCart } = load({ _id: 'u1' });
    reducer(undefined, addToCart(item('a')));
    expect(JSON.parse(localStorage.getItem('shopnest:cart:u1'))).toEqual([item('a')]);
  });

  it("loads the signed-in user's saved cart on startup", () => {
    localStorage.clear();
    localStorage.setItem('userInfo', JSON.stringify({ _id: 'u1' }));
    localStorage.setItem('shopnest:cart:u1', JSON.stringify([item('saved')]));
    let mod;
    jest.isolateModules(() => { mod = require('./cartSlice'); });
    expect(mod.default(undefined, { type: 'init' }).cartItems).toEqual([item('saved')]);
  });

  it("switching owner swaps baskets so one user's items never leak into another's", () => {
    const { default: reducer, addToCart, setCartOwner } = load({ _id: 'u1' });
    let state = reducer(undefined, addToCart(item('mine')));

    state = reducer(state, setCartOwner('u2'));
    expect(state.owner).toBe('u2');
    expect(state.cartItems).toEqual([]);

    state = reducer(state, setCartOwner('u1'));
    expect(state.cartItems).toEqual([item('mine')]);
  });

  it('signing out (no owner) falls back to the guest basket', () => {
    const { default: reducer, setCartOwner } = load({ _id: 'u1' });
    const state = reducer(undefined, setCartOwner(null));
    expect(state.owner).toBe('guest');
  });

  it('retires the legacy shared cart key', () => {
    localStorage.clear();
    localStorage.setItem('cartItems', JSON.stringify([item('stale')]));
    jest.isolateModules(() => { require('./cartSlice'); });
    expect(localStorage.getItem('cartItems')).toBeNull();
  });

  it('survives corrupt stored data', () => {
    localStorage.clear();
    localStorage.setItem('userInfo', '{not json');
    localStorage.setItem('shopnest:cart:guest', '{not json');
    let mod;
    jest.isolateModules(() => { mod = require('./cartSlice'); });
    expect(mod.default(undefined, { type: 'init' })).toEqual({ owner: 'guest', cartItems: [] });
  });

  it('currentOwner reads the signed-in user id', () => {
    const { currentOwner } = load({ _id: 'u9' });
    expect(currentOwner()).toBe('u9');
  });
});
