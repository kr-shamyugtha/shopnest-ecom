import React from 'react';

const textualStyle = {
  maxWidth: '900px',
  margin: '0 auto',
  padding: '40px',
  background: '#18181b',
  borderRadius: '16px',
  border: '1px solid rgba(255, 255, 255, 0.05)',
  lineHeight: '1.8',
  color: '#a1a1aa'
};

const About = () => {
  return (
    <div style={textualStyle}>
      <h2 style={{ color: '#fff', marginBottom: '20px', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '15px' }}>
        About Us
      </h2>
      
      <p style={{ marginBottom: '20px' }}>
        At ShopNest, we believe shopping should be simple, enjoyable, and accessible to everyone. Our platform brings together a carefully curated collection of quality products across electronics, fashion, home essentials, and lifestyle categories, ensuring you can find everything you need in one place.

We are committed to providing an exceptional shopping experience through an intuitive interface, secure transactions, fast order processing, and reliable customer support. Every feature of ShopNest is designed with our customers in mind, making it easy to browse, compare, and purchase products with confidence.

Whether you're looking for the latest gadgets, everyday essentials, or unique finds, ShopNest strives to deliver quality, value, and convenience with every order.
      </p>

      <h4 style={{ color: '#f97316', marginTop: '25px', marginBottom: '10px' }}>Our Mission</h4>
      <p style={{ marginBottom: '15px' }}>
        To empower customers with a seamless and trustworthy online shopping experience by combining innovative technology, quality products, and outstanding service.
      </p>

      <h4 style={{ color: '#f97316', marginTop: '25px', marginBottom: '10px' }}>Our Vision</h4>
      <p style={{ marginBottom: '15px' }}>
        To become a leading digital marketplace that connects customers with products they love while fostering trust, innovation, and long-term customer relationships.
      </p>

      <p style={{ marginTop: '30px', fontStyle: 'italic', fontSize: '0.9rem' }}>
        Thank you for choosing ShopNest. We look forward to being your preferred destination for online shopping.</p>
    </div>
  );
};

export default About;
