const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const Product = require('./models/Product');
const connectDB = require('./config/db');

dotenv.config();

connectDB();

const importData = async () => {
  try {
    // Only the catalog is replaced. An unfiltered User.deleteMany() here
    // wiped every registered account while leaving orders and payment
    // attempts pointing at users that no longer existed.
    await Product.deleteMany();

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('password123', salt);

    // Upsert, not create — re-running this would otherwise collide with
    // the unique index on email now that the user table survives.
    await User.findOneAndUpdate(
      { email: 'admin@shopnest.com' },
      {
        name: 'Admin User',
        email: 'admin@shopnest.com',
        password: hashedPassword,
        role: 'admin'
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

const products = [
  {
    name: 'La Mer The Cleansing Foam',
    description: 'A luxurious facial cleanser that gently removes impurities while leaving the skin feeling soft, refreshed, and comfortable.',
    price: 8500,
    category: 'Skincare',
    stock: 20,
    imageUrl: 'https://cdn.fynd.com/v2/falling-surf-7c8bb8/fyprod/wrkr/products/pictures/item/free/original/000000000494431078/_mWggB5e5-000000000494431078_4.jpg',
    ratings: 4.8,
    numReviews: 42
  },
  {
    name: 'SK-II Facial Treatment Essence',
    description: 'A premium essence formulated to hydrate the skin and improve the appearance of texture, clarity, and radiance.',
    price: 15500,
    category: 'Skincare',
    stock: 15,
    imageUrl: 'https://images.ctfassets.net/jopdimxwavth/4OipOlCGjSWG9YBEGv5io1/41d4d4c235fe363376e9685a2f5a9338/FTE-Overview-PC.png?fm=webp&w=3840&q=90',
    ratings: 4.9,
    numReviews: 67
  },
  {
    name: 'Estée Lauder Advanced Night Repair',
    description: 'A luxurious nighttime serum designed to hydrate, smooth, and improve the appearance of fine lines and tired-looking skin.',
    price: 9900,
    category: 'Skincare',
    stock: 18,
    imageUrl: 'https://encrypted-tbn3.gstatic.com/shopping?q=tbn:ANd9GcR9Ap5o_wKKiGwcHCUAgZjJe1z9ifAojM5ZkmYkC-VSAXowOoOazvGxljFV6ZGNHEMROBUXogO_HwCgH3MWZd0RolGiKcLJ',
    ratings: 4.8,
    numReviews: 85
  },
  {
    name: 'Shiseido Ultimune Power Infusing Concentrate',
    description: 'An advanced facial concentrate designed to support skin resilience while improving hydration and radiance.',
    price: 8900,
    category: 'Skincare',
    stock: 12,
    imageUrl: 'https://www.shiseido.com/dw/image/v2/BBSK_PRD/on/demandware.static/-/Sites-itemmaster_shiseido/default/dw9ab70d0d/images/2025/May/Ultimune/9990000000232_3.jpg?sw=800&sh=800&sm=fit&strip=false',
    ratings: 4.7,
    numReviews: 53
  },
  {
    name: 'La Mer Crème de la Mer',
    description: 'An iconic luxury moisturizer formulated to deeply hydrate, nourish, and soften the appearance of dry skin.',
    price: 32000,
    category: 'Skincare',
    stock: 8,
    imageUrl: 'https://www.cremedelamer.com/media/export/cms/products/responsive/lm_prod_12343_US_4x5_1.png?width=900&height=1125',
    ratings: 4.9,
    numReviews: 91
  },

  {
    name: 'Fresh Black Tea Instant Perfecting Mask',
    description: 'A luxurious face mask designed to hydrate, soften, and refresh tired-looking skin for a smoother appearance.',
    price: 5500,
    category: 'Skincare',
    stock: 14,
    imageUrl: 'https://www.cultbeauty.com/images?url=https://static.thcdn.com/productimg/original/13127406-8434876946241012.jpg&format=webp&auto=avif&width=1200&height=1200&fit=cover',
    ratings: 4.7,
    numReviews: 31
  },
  {
    name: 'Tatcha The Rice Polish',
    description: 'A gentle exfoliating powder cleanser designed to polish away dead surface cells while leaving skin smooth and refreshed.',
    price: 6200,
    category: 'Skincare',
    stock: 16,
    imageUrl: 'https://tatcha.com/cdn/shop/files/RicePolishGentle-pdp-FullSize-Hand-1200x1200.jpg?v=21013?width=1000',
    ratings: 4.8,
    numReviews: 44
  },
  {
    name: 'Augustinus Bader The Rich Cream',
    description: 'A luxurious intensive face cream designed to deeply hydrate and nourish dry, stressed-looking skin.',
    price: 28000,
    category: 'Skincare',
    stock: 7,
    imageUrl: 'https://augustinusbader.com/cdn/shop/files/Copy_of_The_Rich_Cream_All_Sizes_Lifestyle_01.jpg?v=1786042006&width=960',
    ratings: 4.9,
    numReviews: 72
  }
];



    await Product.insertMany(products);
    
    console.log('✅ Data Imported Successfully!');
    process.exit();
  } catch (error) {
    console.error(`❌ Error with data import: ${error.message}`);
    process.exit(1);
  }
};

importData();
