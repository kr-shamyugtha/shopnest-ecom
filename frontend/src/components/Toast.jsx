import React, { useEffect, useState } from 'react';

// A module-level dispatcher rather than a context provider: any module
// can call toast() without the component tree having to thread a hook
// down to it, and the single <ToastStack /> in App.jsx picks it up.
const EVENT = 'shopnest:toast';
let seq = 0;

export const toast = (message) => {
  window.dispatchEvent(new CustomEvent(EVENT, { detail: { id: ++seq, message } }));
};

const ToastStack = () => {
  const [items, setItems] = useState([]);

  useEffect(() => {
    const onToast = (e) => {
      const item = e.detail;
      setItems((prev) => [...prev, item]);
      setTimeout(() => {
        setItems((prev) => prev.filter((t) => t.id !== item.id));
      }, 2600);
    };
    window.addEventListener(EVENT, onToast);
    return () => window.removeEventListener(EVENT, onToast);
  }, []);

  if (!items.length) return null;

  return (
    // aria-live so the confirmation is announced, not just seen.
    <div className="toast-stack" role="status" aria-live="polite">
      {items.map((t) => (
        <div className="toast" key={t.id}>
          <span className="tick">✓</span>
          {t.message}
        </div>
      ))}
    </div>
  );
};

export default ToastStack;
