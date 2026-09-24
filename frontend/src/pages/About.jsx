import React from 'react';
import { Link } from 'react-router-dom';

const About = () => (
  <div className="about-page">
    <div className="section-head">
      <div>
        <span className="eyebrow">Our story</span>
        <h2>A smaller shelf, chosen carefully</h2>
        <p>
          ShopNest exists because buying good skincare online is harder
          than it should be — too much choice, too little honesty.
        </p>
      </div>
    </div>
    <hr className="rule" />

    <div className="panel panel-pad" style={{ maxWidth: 860, margin: '0 auto' }}>
      <p style={{ marginBottom: 22 }}>
        We stock a deliberately small edit of skincare from houses that have
        spent decades refining a single formula — La Mer, SK-II, Estée Lauder,
        Shiseido, Tatcha, Fresh and Augustinus Bader. Every product is sourced
        direct, never through the grey market, and arrives exactly as the
        house intended it.
      </p>

      <p style={{ marginBottom: 22 }}>
        There is no endless catalogue here, and that is the point. A shelf
        you can read in a minute is worth more than a warehouse you have to
        search. We would rather carry eight products we can vouch for than
        eight hundred we cannot.
      </p>

      <h4 style={{ color: 'var(--gold)', marginTop: 34, marginBottom: 12, letterSpacing: '0.18em', textTransform: 'uppercase', fontSize: '0.74rem' }}>
        What we promise
      </h4>
      <p style={{ marginBottom: 22 }}>
        Authentic products, secure payment through Razorpay, and a returns
        policy written in plain language. If something isn't right, we would
        rather hear about it than keep your money.
      </p>

      <h4 style={{ color: 'var(--gold)', marginTop: 34, marginBottom: 12, letterSpacing: '0.18em', textTransform: 'uppercase', fontSize: '0.74rem' }}>
        Where we're going
      </h4>
      <p style={{ marginBottom: 32 }}>
        To become the place people trust for skincare worth the ritual —
        growing slowly, and only ever adding a product when it earns its
        place on the shelf.
      </p>

      <Link to="/shop" className="btn">Browse the collection</Link>
    </div>
  </div>
);

export default About;
