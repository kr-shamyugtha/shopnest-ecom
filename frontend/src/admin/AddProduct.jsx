import React, { useState, useContext, useEffect } from 'react';
import { AuthContext } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { CATEGORIES } from '../utils/catalog';
import { toast } from '../components/Toast';
import { inr } from '../utils/format';
import '../styles/admin.css';

const AddProduct = () => {
  const { user } = useContext(AuthContext);
  const navigate = useNavigate();

  const [formData, setFormData] = useState({
    name: '', description: '', price: '', category: '', stock: ''
  });
  const [image, setImage] = useState(null);
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(false);

  // Redirecting during render is a side effect React warns about, and
  // it fired on every render for non-admins. Do it after commit.
  useEffect(() => {
    if (!user || user.role !== 'admin') navigate('/');
  }, [user, navigate]);

  // Object URLs leak until revoked, and this form can go through many
  // images in one admin session.
  useEffect(() => {
    if (!image) { setPreview(null); return; }
    const url = URL.createObjectURL(image);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [image]);

  if (!user || user.role !== 'admin') return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!image) { toast('Please choose a product image'); return; }

    setLoading(true);
    const data = new FormData();
    Object.entries(formData).forEach(([k, v]) => data.append(k, v));
    data.append('image', image);

    try {
      const res = await fetch('/api/products', {
        method: 'POST',
        headers: { Authorization: `Bearer ${user.token}` },
        body: data
      });
      const responseData = await res.json();

      if (res.ok) {
        toast(`${formData.name} published to ${formData.category}`);
        navigate('/shop');
      } else {
        toast(responseData.message || 'Could not create the product');
      }
    } catch (error) {
      console.error(error);
      toast('Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const set = (field) => (e) => setFormData({ ...formData, [field]: e.target.value });

  return (
    <div className="admin-form-page">
      <div className="section-head">
        <div>
          <span className="eyebrow">Catalogue</span>
          <h2>Add a product</h2>
        </div>
      </div>
      <hr className="rule" />

      <form onSubmit={handleSubmit} className="panel panel-pad admin-form">
        <label>
          <span>Product name</span>
          <input type="text" required value={formData.name} onChange={set('name')} placeholder="e.g. Crème de la Mer" />
        </label>

        <label>
          <span>Description</span>
          <textarea required rows="4" value={formData.description} onChange={set('description')} placeholder="What it is and what it does" />
        </label>

        <div className="admin-form-row">
          <label>
            <span>Price (₹)</span>
            <input type="number" min="0" required value={formData.price} onChange={set('price')} placeholder="32000" />
            {formData.price && <small className="field-hint">Shows as {inr(Number(formData.price))}</small>}
          </label>

          <label>
            <span>Stock</span>
            <input type="number" min="0" required value={formData.stock} onChange={set('stock')} placeholder="8" />
          </label>
        </div>

        <label>
          <span>Category</span>
          <select required value={formData.category} onChange={set('category')}>
            <option value="" disabled>Select a category</option>
            {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
          </select>
        </label>

        <div className="upload-field">
          <span className="upload-label">Product image</span>
          {preview ? (
            <div className="upload-preview">
              <img src={preview} alt="Selected product" />
              <button type="button" className="btn-remove" onClick={() => setImage(null)}>
                Choose a different image
              </button>
            </div>
          ) : (
            <p className="field-hint">Portrait images look best — the card crops to 4:5.</p>
          )}
          <input type="file" accept="image/*" required={!image} onChange={(e) => setImage(e.target.files[0])} />
          <small className="field-hint">Uploaded to Cloudinary on publish.</small>
        </div>

        <button type="submit" disabled={loading} className="btn">
          {loading ? 'Uploading…' : 'Publish product'}
        </button>
      </form>
    </div>
  );
};

export default AddProduct;
