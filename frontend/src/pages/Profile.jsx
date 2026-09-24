import React, { useEffect, useState, useContext, useCallback } from 'react';
import { AuthContext } from '../context/AuthContext';
import { useNavigate, Link } from 'react-router-dom';
import { toast } from '../components/Toast';
import { inr } from '../utils/format';
import { isCancellable, statusColor } from '../utils/catalog';

const Profile = () => {
  const { user, logout } = useContext(AuthContext);
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState(null);

  const handleAuthFailure = useCallback(() => {
    logout();
    navigate('/login');
  }, [logout, navigate]);

  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }
    const fetchMyOrders = async () => {
      try {
        const res = await fetch('/api/orders/myorders', {
          headers: { Authorization: `Bearer ${user.token}` },
        });
        const data = await res.json();
        if (res.ok) {
          setOrders(Array.isArray(data) ? data : []);
        } else {
          if (res.status === 401) handleAuthFailure();
          setOrders([]);
        }
      } catch (error) {
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    fetchMyOrders();
  }, [user, navigate, handleAuthFailure]);

  const handleCancel = async (orderId) => {
    setCancelling(orderId);
    try {
      const res = await fetch(`/api/orders/${orderId}/cancel`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${user.token}` },
      });
      const data = await res.json();
      if (res.ok) {
        // Trust the server's version of the order rather than assuming
        // the new status — it owns the lifecycle rules.
        setOrders((prev) => prev.map((o) => (o._id === orderId ? { ...o, status: data.status } : o)));
        toast('Your order has been cancelled');
      } else {
        toast(data.message || 'That order could not be cancelled');
      }
    } catch (error) {
      console.error(error);
      toast('Something went wrong. Please try again.');
    } finally {
      setCancelling(null);
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  if (!user) return null;

  return (
    <div className="profile-page">
      <div className="profile-head panel panel-pad">
        <div>
          <span className="eyebrow">Your account</span>
          <h2>{user.name}</h2>
          <p className="profile-email">{user.email}</p>
          <span className="role-badge">{user.role === 'admin' ? 'Administrator' : 'Member'}</span>
        </div>
        <button onClick={handleLogout} className="btn btn-ghost">Sign out</button>
      </div>

      <div className="section-head" style={{ marginTop: 56 }}>
        <div>
          <span className="eyebrow">History</span>
          <h2>Your orders</h2>
        </div>
      </div>
      <hr className="rule" />

      {loading ? (
        <div className="order-card"><div className="skeleton skeleton-line" style={{ margin: 0, height: 18 }} /></div>
      ) : orders.length === 0 ? (
        <div className="empty-state">
          <div className="mark">◇</div>
          <h3>No orders yet</h3>
          <p>When you place an order it will appear here, with its progress.</p>
          <Link to="/shop" className="btn">Start shopping</Link>
        </div>
      ) : (
        <div className="order-list">
          {orders.map((order) => (
            <div key={order._id} className="order-card">
              <div className="order-meta">
                <p className="order-id">Order <span>{order._id}</span></p>
                <p>Placed on {new Date(order.createdAt).toLocaleDateString('en-IN', {
                  day: 'numeric', month: 'long', year: 'numeric',
                })}</p>
                <p className="order-total">{inr(order.totalAmount)}</p>
              </div>

              <div className="order-actions">
                <span
                  className="status-pill"
                  style={{ color: statusColor(order.status), borderColor: statusColor(order.status) }}
                >
                  {order.status}
                </span>

                {isCancellable(order.status) && (
                  <button
                    className="btn-remove"
                    onClick={() => handleCancel(order._id)}
                    disabled={cancelling === order._id}
                  >
                    {cancelling === order._id ? 'Cancelling…' : 'Cancel order'}
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Profile;
