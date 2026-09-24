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
    name: 'Dior J’adore Eau de Parfum',
    description: 'An iconic floral fragrance featuring elegant notes of jasmine, ylang-ylang, rose, and fruity accents.',
    price: 13500,
    category: 'Perfumes',
    stock: 14,
    imageUrl: 'https://www.dior.com/dw/image/v2/BGXS_PRD/on/demandware.static/-/Sites-master_dior/default/dw14fbf7bd/Y0998031/Y0998031_C099800246_E01_ZHC.jpg?sw=1280',
    ratings: 4.9,
    numReviews: 92
  },
  {
    name: 'Olaplex No.3 Hair Perfector',
    description: 'An intensive at-home hair treatment designed to strengthen and improve the appearance of damaged hair.',
    price: 3200,
    category: 'Haircare',
    stock: 25,
    imageUrl: 'https://www.kerastase.in/dw/image/v2/BJSQ_PRD/on/demandware.static/-/Sites-kerastase-master-catalog/en_IN/dw6bd7b0ed/Kerastase_range/Discipline/KER_00040_Discipline_Mask_texture_new.jpg?sw=1080&sh=1080&sm=cut&sfrm=jpg&q=80',
    ratings: 4.9,
    numReviews: 96
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
    name: 'Gucci Beauty Blush De Beauté',
    description: 'A luxury powder blush that delivers buildable color and a soft, radiant finish to the cheeks.',
    price: 5200,
    category: 'Makeup',
    stock: 18,
    imageUrl: 'https://delhidutyfree.co.in/media/catalog/product/cache/c3073cf0652b87af145d4aff9d92466d/1/0/1018742.webp',
    ratings: 4.8,
    numReviews: 41
  },
  {
    name: 'Kérastase Elixir Ultime Hair Oil',
    description: 'A lightweight luxury hair oil designed to nourish the hair while enhancing smoothness, softness, and shine.',
    price: 4800,
    category: 'Haircare',
    stock: 16,
    imageUrl: 'https://www.kerastase.in/dw/image/v2/BJSQ_PRD/on/demandware.static/-/Sites-kerastase-master-catalog/en_IN/dwaa1af992/2024/KER_00303/75ml/KER_00303_75ml_Packshot_Image11.jpg?sw=1080&sh=1080&sm=cut&sfrm=jpg&q=80',
    ratings: 4.8,
    numReviews: 52
  },
  {
    name: 'Chanel Coco Mademoiselle Eau de Parfum',
    description: 'A sophisticated feminine fragrance blending sparkling citrus, rose, jasmine, and warm patchouli notes.',
    price: 14500,
    category: 'Perfumes',
    stock: 15,
    imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTXSLIUuNcwA6_QaX-xXn8jkKhiuIm0JbIb2HzqloWs4A&s=10',
    ratings: 4.9,
    numReviews: 87
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
    name: 'Dior Addict Lip Glow Oil',
    description: 'A luxurious glossy lip oil that nourishes the lips while providing a subtle tint and radiant shine.',
    price: 3300,
    category: 'Makeup',
    stock: 30,
    imageUrl: 'https://www.dior.com/dw/image/v2/BGXS_PRD/on/demandware.static/-/Sites-master_dior/default/dw724a0506/Y0000163/Y0000163_E000001063_E01_RHC.jpg?sw=1024',
    ratings: 4.8,
    numReviews: 68
  },
  {
    name: 'Moroccanoil Treatment',
    description: 'A versatile argan oil treatment designed to smooth, condition, reduce frizz, and enhance hair shine.',
    price: 4320,
    category: 'Haircare',
    stock: 22,
    imageUrl: 'https://in.moroccanoil.com/cdn/shop/products/153_TREATMENT_ORIGINAL_100mL_v2.jpg?v=1683138179&width=1445',
    ratings: 4.9,
    numReviews: 88
  },
  {
    name: 'Parfums de Marly Delina Eau de Parfum',
    description: 'A luxurious floral fragrance featuring Turkish rose, lychee, rhubarb, vanilla, and soft musky notes.',
    price: 28500,
    category: 'Perfumes',
    stock: 7,
    imageUrl: 'https://mdpindia.com/cdn/shop/products/Delina_1800x1800.jpg?v=1736771962',
    ratings: 4.9,
    numReviews: 81
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
    name: 'Tom Ford Eye Color Quad',
    description: 'A luxurious four-shade eyeshadow palette featuring richly pigmented shades with elegant matte and shimmer finishes.',
    price: 8200,
    category: 'Makeup',
    stock: 10,
    imageUrl: 'https://www.tomfordbeauty.com/cdn/shop/files/tf_sku_T1QZ01_3000x3000_0.png?v=1790154314&width=840',
    ratings: 4.9,
    numReviews: 35
  },
  {
    name: 'Yves Saint Laurent Libre Eau de Parfum',
    description: 'An elegant floral fragrance combining lavender, orange blossom, and warm vanilla notes for a modern signature scent.',
    price: 9900,
    category: 'Perfumes',
    stock: 18,
    imageUrl: 'https://www.yslbeauty.com/dw/image/v2/BDCR_PRD/on/demandware.static/-/Sites-ysl-master-catalog/en/dwcbb6c7e4/Fragrance/Libre_EDP/3614272648418_libre_eau_de_parfum_50ml_alt1.webp?sw=1080&sh=1080&sm=cut&sfrm=png&q=85',
    ratings: 4.8,
    numReviews: 76
  },
  {
    name: 'Kérastase Nutritive Bain Satin Shampoo',
    description: 'A premium nourishing shampoo designed to gently cleanse and soften dry and dehydrated hair.',
    price: 2900,
    category: 'Haircare',
    stock: 20,
    imageUrl: 'https://www.kerastase.in/dw/image/v2/BJSQ_PRD/on/demandware.static/-/Sites-kerastase-master-catalog/en_IN/dwc36b4e2b/2024/KER_00049/250ml/KER_00049_Genesis_250ml_Shampoo_texture_new.jpg?sw=1080&sh=1080&sm=cut&sfrm=jpg&q=80',
    ratings: 4.8,
    numReviews: 61
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
  },
  {
    name: 'Charlotte Tilbury Airbrush Bronzer',
    description: 'A finely milled luxury bronzer designed to create a naturally sun-kissed and softly sculpted appearance.',
    price: 4900,
    category: 'Makeup',
    stock: 14,
    imageUrl: 'https://images-static.nykaa.com/media/catalog/product/3/5/35f71ca5060542727112_6.jpg?tr=w-500',
    ratings: 4.9,
    numReviews: 63
  },
  {
    name: 'Tom Ford Black Orchid Eau de Parfum',
    description: 'A rich and luxurious fragrance featuring dark florals, black truffle, patchouli, and warm woody notes.',
    price: 16500,
    category: 'Perfumes',
    stock: 8,
    imageUrl: 'https://www.tomfordbeauty.com/cdn/shop/files/tfb_sku_T00501_2000x2000_0.png?v=1790154325&width=840',
    ratings: 4.8,
    numReviews: 53
  },
  {
    name: 'OUAI Leave In Conditioner',
    description: 'A multi-purpose leave-in conditioner designed to detangle, hydrate, soften, and protect the hair.',
    price: 3137,
    category: 'Haircare',
    stock: 18,
    imageUrl: 'https://theouai.com/cdn/shop/files/LIC_Repack_Site_Asset_PDP_MP_Scent_Notes.jpg?v=1781183520&width=1100',
    ratings: 4.7,
    numReviews: 43
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
    name: 'YSL Rouge Pur Couture Lipstick',
    description: 'A premium lipstick delivering rich, intense color with a smooth and sophisticated satin finish.',
    price: 4800,
    category: 'Makeup',
    stock: 25,
    imageUrl: 'https://www.yslbeauty.com/dw/image/v2/BDCR_PRD/on/demandware.static/-/Sites-NGYSL-ILM-Library/default/dw5633637b/pdp/images/WW-51083YSL/tools-and-services-2.webp?sw=1500&sh=1500&sm=cut&sfrm=jpg&q=85',
    ratings: 4.8,
    numReviews: 74
  },
  {
    name: 'Lancôme La Vie Est Belle Eau de Parfum',
    description: 'A feminine gourmand fragrance blending iris, jasmine, praline, vanilla, and elegant fruity notes.',
    price: 9800,
    category: 'Perfumes',
    stock: 20,
    imageUrl: 'https://www.lancome-usa.com/dw/image/v2/AANG_PRD/on/demandware.static/-/Sites-lancome-us-master-catalog/default/dwf8960ed7/pdp/100606/ALT0-3605533286555-PACKSHOT.webp?sw=1356&sh=1356&sm=cut&sfrm=jpg&q=70',
    ratings: 4.7,
    numReviews: 69
  },
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
    name: 'Oribe Gold Lust Transformative Masque',
    description: 'A luxurious intensive hair mask designed to deeply condition and restore softness and shine.',
    price: 7200,
    category: 'Haircare',
    stock: 10,
    imageUrl: 'https://www.oribe.com/cdn/shop/products/1200Wx1200H-400108-2_0680091e-111c-4642-a59f-4b7530e3ce97.jpg?v=1713288362&width=3840',
    ratings: 4.8,
    numReviews: 39
  },
  {
    name: 'Dior Forever Skin Glow Foundation',
    description: 'A luxurious hydrating foundation offering buildable coverage with a natural radiant finish.',
    price: 6700,
    category: 'Makeup',
    stock: 20,
    imageUrl: 'https://www.dior.com/on/demandware.static/-/Sites-master_dior/default/dwc7d0d259/Y0000149/Y0000149_E000001419_E01_RHC.jpg?sw=932&sh=1398',
    ratings: 4.8,
    numReviews: 56
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
    name: 'Carolina Herrera Good Girl Eau de Parfum',
    description: 'A glamorous fragrance combining luminous jasmine with rich tonka bean and warm cocoa for a sophisticated finish.',
    price: 10500,
    category: 'Perfumes',
    stock: 12,
    imageUrl: 'https://images-static.nykaa.com/media/catalog/product/d/b/db992ab8411061819838_1.jpg',
    ratings: 4.8,
    numReviews: 64
  },
  {
    name: 'Kérastase Nutritive Lait Vital Conditioner',
    description: 'A lightweight nourishing conditioner designed to improve softness, smoothness, and manageability.',
    price: 3200,
    category: 'Haircare',
    stock: 18,
    imageUrl: 'https://www.kerastase.in/dw/image/v2/BJSQ_PRD/on/demandware.static/-/Sites-kerastase-master-catalog/en_IN/dw6bd7b0ed/Kerastase_range/Discipline/KER_00040_Discipline_Mask_texture_new.jpg?sw=1080&sh=1080&sm=cut&sfrm=jpg&q=80',
    ratings: 4.8,
    numReviews: 47
  },
  {
    name: 'Hourglass Veil Translucent Setting Powder',
    description: 'A finely milled luxury setting powder designed to blur imperfections and create a smooth makeup finish.',
    price: 5000,
    category: 'Makeup',
    stock: 16,
    imageUrl: 'https://www.hourglasscosmetics.com/cdn/shop/files/2000x2000-72dpi_0001_VeilSettingPowder_Open_64f22869-b80b-474e-b639-121b898f804f.png?v=1754510202&width=800',
    ratings: 4.7,
    numReviews: 45
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
    name: 'Valentino Born In Roma Uomo Intense Eau de Parfum',
    description: 'An iconic luxury fragrance featuring airy jasmine, saffron, amberwood, and warm woody accords.',
    price: 10000,
    category: 'Perfumes',
    stock: 6,
    imageUrl: 'https://valentino-cdn.thron.com/delivery/public/image/valentino/4db84195-6be9-4b5f-86eb-550f4c4d5d0d/ihqstx/std/2000x0/Born-In-Roma-Intense-Eau-De-Parfum-Spray-100Ml?quality=80&size=35&format=auto',
    ratings: 4.9,
    numReviews: 105
  },
  {
    name: 'Olaplex No.7 Bonding Oil',
    description: 'A lightweight styling oil designed to add shine, reduce frizz, and protect hair during heat styling.',
    price: 3200,
    category: 'Haircare',
    stock: 20,
    imageUrl: 'https://olaplex.com/cdn/shop/files/ClosetoFinal_Transparent_No7-Bottle_30ml_Product-Packshot_WS_FRONT_FPO_0040_MAIN.png?format=webp&v=1762285968&width=1400',
    ratings: 4.7,
    numReviews: 64
  },
  {
    name: 'Gucci Bloom Eau de Parfum',
    description: 'A luxurious floral fragrance inspired by a garden in full bloom, featuring jasmine, tuberose, and Rangoon creeper.',
    price: 9500,
    category: 'Perfumes',
    stock: 16,
    imageUrl: 'https://www.lojaglamourosa.com/resources/medias/shop/products/thumbnails/shop-image-large/shop-pf-02155-02-gucci-bloom-edp---50ml--1.jpg',
    ratings: 4.7,
    numReviews: 58
  },
  {
    name: 'Christian Louboutin So Kate 100mm Pumps',
    description: 'Iconic pointed-toe stiletto heels featuring a sleek silhouette designed for elegant evening and formal looks.',
    price: 74900,
    category: 'Heels',
    stock: 8,
    imageUrl: 'https://us.christianlouboutin.com/media/catalog/product/cache/c8e9b72c512eaa31cd76a11d9f425a9e/3/1/3191411bk01-3191411bk01-main_image-ecommerce-fw19_kate_100_patent.jpg',
    ratings: 4.9,
    numReviews: 42
  },
  {
    name: 'Jimmy Choo Romy 85 Pumps',
    description: 'Elegant pointed-toe pumps with a refined silhouette, perfect for sophisticated office and evening outfits.',
    price: 62500,
    category: 'Heels',
    stock: 10,
    imageUrl: 'https://media.jimmychoo.com/image/upload/f_auto,q_auto:best,dpr_2.0,w_520,h_520,c_fit/ROWPROD_PRODUCT/images/original/SACORA85FNB_000757_ANGLE_vg1042.jpg',
    ratings: 4.8,
    numReviews: 36
  },
  
  {
    name: 'Valentino Garavani Tan-Go Platform Pumps',
    description: 'Statement platform pumps featuring a bold silhouette and signature detailing for glamorous occasions.',
    price: 112000,
    category: 'Heels',
    stock: 5,
    imageUrl: 'https://valentino-cdn.thron.com/delivery/public/image/valentino/aedd920d-de0b-4939-95e6-c388ef9cf654/ihqstx/std/2000x0/Rockstud-Lace-Pump-With-Straps-100Mm?quality=80&size=35&format=auto',
    ratings: 4.8,
    numReviews: 29
  },
  {
    name: 'Amina Muaddi Begum Glass Slingback Heels',
    description: 'Sophisticated pointed-toe pumps combining sleek leather with transparent detailing for a modern luxury look.',
    price: 78000,
    category: 'Heels',
    stock: 7,
    imageUrl: 'https://www.aminamuaddi.com/cdn/shop/files/18S366569BEG_4.jpg?v=1788871726&width=1600',
    ratings: 4.8,
    numReviews: 34
  },
  {
    name: 'Saint Laurent Blade 90 Pumps',
    description: 'Elegant pointed-toe heels featuring delicate bow detailing and a refined silhouette for special occasions.',
    price: 69500,
    category: 'Heels',
    stock: 9,
    imageUrl: 'https://assets.levelshoes.com/cdn-cgi/image/width=720,height=1008,quality=85,format=webp/media/catalog/product/p/l/pl525684_3.jpg?ts=20250729053759',
    ratings: 4.7,
    numReviews: 27
  },
  {
    name: 'Dolce & Gabbana Crystal Embellished Sandals',
    description: 'Glamorous high-heeled sandals adorned with sparkling crystal embellishments for parties and evening events.',
    price: 73500,
    category: 'Heels',
    stock: 6,
    imageUrl: 'https://www.glamsteals.com/cdn/shop/files/8234584932487-v8.webp?v=1784648785&width=1200',
    ratings: 4.7,
    numReviews: 23
  },
  {
    name: 'Gucci Horsebit Slingback Pumps',
    description: 'Luxury slingback pumps featuring elegant horsebit-inspired detailing and a sophisticated pointed silhouette.',
    price: 68500,
    category: 'Heels',
    stock: 8,
    imageUrl: 'https://static.banananina.id/inventory/assets/img/product/01226709/01226709_D.jpg',
    ratings: 4.8,
    numReviews: 31
  },
  // ==================== DRESSES ====================

  {
    name: 'Reformation Silk Slip Midi Dress',
    description: 'An elegant silk slip midi dress featuring a sleek silhouette, delicate straps, and a timeless feminine design.',
    price: 28500,
    category: 'Dresses',
    stock: 15,
    imageUrl: 'https://media.thereformation.com/image/upload/f_auto,q_auto:eco,dpr_2.0/w_500/PRD-SFCC/1318344/PEAR/1318344.1.PEAR',
    ratings: 4.8,
    numReviews: 36
  },
  {
    name: 'Zimmermann Floral Puff-Sleeve Mini Dress',
    description: 'A romantic floral mini dress featuring voluminous puff sleeves, a fitted waist, and a playful feminine silhouette.',
    price: 52000,
    category: 'Dresses',
    stock: 10,
    imageUrl: 'https://www.zimmermann.com/media/catalog/product/2/_/2.0189df262.blkrm.black-rose-mallow.jpg?width=257&height=334&canvas=257:334&quality=90&bg-color=255,255,255&fit=bounds&dpr=2',
    ratings: 4.9,
    numReviews: 28
  },
  {
    name: 'Victoria Beckham Tailored Maxi Dress',
    description: 'A sophisticated tailored maxi dress with a structured silhouette, defined waist, and elegant floor-length design.',
    price: 68000,
    category: 'Dresses',
    stock: 8,
    imageUrl: 'https://cdn.shopify.com/s/files/1/3028/8266/files/VB_1226WDR006029A_BURGUNDY_13534_bf6cbcb9-9727-4d32-88ba-8c9907d0fbbb_720x.jpg?v=1784021496',
    ratings: 4.7,
    numReviews: 21
  },

  // ==================== PANTS ====================

  {
    name: 'Toteme Wide-Leg Tailored Trousers',
    description: 'Sophisticated wide-leg trousers with a clean tailored finish and relaxed silhouette for polished everyday styling.',
    price: 32000,
    category: 'Pants',
    stock: 18,
    imageUrl: 'https://toteme.com/cdn/shop/files/TOTEME_FLATS_FW26_264-WRB0289-FB0816-001_BOTTOMS_DOUBLE-PLEAT_FLUID_TROUSERS_BLACK_front_GB.jpg?v=1781707105&width=900',
    ratings: 4.8,
    numReviews: 34
  },
  {
    name: "Valentino Garavani Jeans",
    description: 'Classic high-rise jeans featuring a straight-leg silhouette and versatile denim construction for everyday wear.',
    price: 59500,
    category: 'Pants',
    stock: 25,
    imageUrl: 'https://d3vfig6e0r0snz.cloudfront.net/rcYjnYuenaTH5vyDF/images/products/70b56976982476566af57d5f4d5b654b.webp',
    ratings: 4.6,
    numReviews: 57
  },
  {
    name: 'Stella McCartney Satin Palazzo Pants',
    description: 'Luxurious satin palazzo pants with a flowing wide-leg silhouette designed for elegant evening and occasion styling.',
    price: 45000,
    category: 'Pants',
    stock: 12,
    imageUrl: 'https://hrd-live.cdn.scayle.cloud/images/a3d857cc0a915ec7aafa60a73fd4a13e.jpg?brightness=1&width=922&height=1230&quality=75&bg=ffffff',
    ratings: 4.8,
    numReviews: 19
  },

  // ==================== OVERCOATS ====================

  {
    name: 'Max Mara Wool Wrap Coat',
    description: 'A timeless wool wrap coat featuring a flattering belted waist, soft texture, and sophisticated longline silhouette.',
    price: 125000,
    category: 'Overcoats',
    stock: 6,
    imageUrl: 'https://b2c-media.maxmara.com/sys-master/m0/MM/2026/2/1086096206/015/s3details/1086096206015-b-mxmalcuno_normal.webp',
    ratings: 4.9,
    numReviews: 42
  },
  {
    name: 'Burberry Double-Breasted Trench Coat',
    description: 'A classic double-breasted trench coat with signature structured detailing, adjustable belt, and timeless outerwear silhouette.',
    price: 165000,
    category: 'Overcoats',
    stock: 7,
    imageUrl: 'https://assets.burberry.com/is/image/Burberryltd/E41BB139-56B2-4805-90D2-42C405AA1F88?$BBY_V3_ML_1$&wid=2100&hei=2100',
    ratings: 4.9,
    numReviews: 51
  },
  {
    name: 'Toteme Oversized Cocoon Coat',
    description: 'A modern oversized cocoon coat featuring a rounded silhouette, dropped shoulders, and minimalist Scandinavian-inspired design.',
    price: 89000,
    category: 'Overcoats',
    stock: 9,
    imageUrl: 'https://toteme.com/cdn/shop/files/TOTEME_ECOM_SEASONAL_SS25_OUTERWEAR_252-WRO0186-FB0385_SUMMER_COUNTRY_JACKET_PEANUT_066.jpg?v=1736363115&width=900',
    ratings: 4.7,
    numReviews: 26
  },

  // ==================== TOPS ====================

  {
    name: 'Self-Portrait Lace Peplum Top',
    description: 'A feminine lace peplum top featuring delicate texture, a defined waist, and an elegant structured silhouette.',
    price: 28000,
    category: 'Tops',
    stock: 14,
    imageUrl: 'https://assets.ajio.com/medias/sys_master/root/20210709/nWWL/60e864b9f997ddb312228e13/-473Wx593H-460888663-black-MODEL.jpg',
    ratings: 4.8,
    numReviews: 24
  },
  {
    name: 'Sandro Satin Cowl-Neck Blouse',
    description: 'An elegant satin blouse featuring a soft cowl neckline, fluid fabric, and relaxed silhouette for sophisticated styling.',
    price: 22000,
    category: 'Tops',
    stock: 16,
    imageUrl: 'https://eu.sandro-paris.com/dw/image/v2/BCMW_PRD/on/demandware.static/-/Sites-master-catalog/default/dwae88d7d3/images/hi-res/Sandro_SFPCM01778-10_F_4.jpg?sw=2000&sh=2000',
    ratings: 4.7,
    numReviews: 31
  },
  {
    name: 'Jacquemus Asymmetric Draped Top',
    description: 'A contemporary asymmetric top featuring an artistic draped silhouette and distinctive one-shoulder design.',
    price: 35000,
    category: 'Tops',
    stock: 11,
    imageUrl: 'https://cdn.endource.com/image/direct/36c425647c37c2b8c424c3cadaa4c9d8a74e7286/jacquemus-pablo-asymmetric-tulle-overlay-cropped-top.jpg?class=800&optimizer=image',
    ratings: 4.8,
    numReviews: 18
  },
  {
  name: 'Louis Vuitton Capucines MM Handbag',
  description: 'A sophisticated structured handbag featuring a refined top-handle design, elegant hardware, and a timeless silhouette.',
  price: 245000,
  category: 'Handbags',
  stock: 6,
  imageUrl: 'https://in.louisvuitton.com/images/is/image/lv/1/PP_VP_L/louis-vuitton--M25386_PM2_Front%20view.jpg?wid=1200',
  ratings: 4.9,
  numReviews: 38
},
{
  name: 'Chanel Classic Flap Bag',
  description: 'An iconic quilted flap handbag featuring a signature chain strap and polished hardware for an elegant everyday look.',
  price: 285000,
  category: 'Handbags',
  stock: 5,
  imageUrl: 'https://www.chanel.com/images/as///f_auto,q_auto:good,dpr_1.1/w_3200/-82040529.jpg%203200w',
  ratings: 4.9,
  numReviews: 52
},
{
  name: 'Dior Lady Dior Medium Bag',
  description: 'A luxurious structured handbag with distinctive quilted detailing, top handles, and an elegant compact silhouette.',
  price: 310000,
  category: 'Handbags',
  stock: 5,
  imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRwORtJMdJ7V5TKx29vM1mXcoxo8G9zrVofgE8UWvs8N16UWAIbAHdTGbg&s=10',
  ratings: 4.9,
  numReviews: 47
},
{
  name: 'Gucci Jackie 1961 Shoulder Bag',
  description: 'A curved shoulder bag with a distinctive vintage-inspired silhouette, polished hardware, and versatile styling.',
  price: 175000,
  category: 'Handbags',
  stock: 8,
  imageUrl: 'https://media.gucci.com/cms/spctf2/6NhszOPAzKUzaOLBpyH6dy/aa0e08dbf8f30e52190e475133627294/Navigation_866762FAFV99653_001_Default.png',
  ratings: 4.8,
  numReviews: 34
},
{
  name: 'Bottega Veneta Jodie Mini Bag',
  description: 'A distinctive woven mini handbag featuring a curved silhouette and compact top-handle design.',
  price: 155000,
  category: 'Handbags',
  stock: 9,
  imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQFNeCebyttfiHAWM4J74kQxD3e-rydDcRsHChObEAsethX06hhATwSbkg&s=10',
  ratings: 4.8,
  numReviews: 29
},
{
  name: 'Prada Re-Edition 2005 Re-Nylon Bag',
  description: 'A contemporary compact shoulder bag combining a sleek nylon body with a detachable pouch and practical styling.',
  price: 125000,
  category: 'Handbags',
  stock: 12,
  imageUrl: 'https://www.prada.com/content/dam/pradabkg_products/1/1BH/1BH204/R064F097W/1BH204_R064_F097W_V_V9L_SLF.jpg/_jcr_content/renditions/cq5dam.web.hebebed.600.600.jpg',
  ratings: 4.7,
  numReviews: 41
},
{
  name: 'Saint Laurent Le 5 À 7 Hobo Bag',
  description: 'A sleek hobo-style handbag featuring a relaxed curved shape, refined hardware, and an understated luxurious finish.',
  price: 165000,
  category: 'Handbags',
  stock: 7,
  imageUrl: 'https://hrd-live.cdn.scayle.cloud/images/a5579ea5f8ad68e7b86a008a58f1691c.jpg?brightness=1&width=922&height=1230&quality=75&bg=ffffff',
  ratings: 4.8,
  numReviews: 36
},
{
  name: 'Fendi Peekaboo ISeeU Bag',
  description: 'A sophisticated structured handbag featuring a distinctive framed opening, top handles, and an elegant architectural silhouette.',
  price: 275000,
  category: 'Handbags',
  stock: 5,
  imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJwODTz560oXYrxrGwn0JrdISyu-Iuf_rC4wfv-w8gSWSlAat0J-ZfAHSm&s=10',
  ratings: 4.9,
  numReviews: 31
},
{
  name: 'Loewe Puzzle Fold Tote',
  description: 'A modern foldable tote featuring geometric construction, spacious proportions, and a minimalist contemporary design.',
  price: 145000,
  category: 'Handbags',
  stock: 10,
  imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTY7zC4liNGgujK9rOnKXlFwDCwv-aqDw9Xopgw7Hh35Tz6RV-VP2L7V8qS&s=10',
  ratings: 4.7,
  numReviews: 25
},
{
  name: 'Cartier Love Bracelet',
  description: 'An iconic luxury bracelet featuring a sleek oval silhouette and distinctive screw-inspired detailing for a timeless statement.',
  price: 520000,
  category: 'Jewellery',
  stock: 5,
  imageUrl: 'https://www.cartier.com/dw/image/v2/BGTJ_PRD/on/demandware.static/-/Sites-cartier-master/default/dw2f4239d6/images/large/139877a864fc56eba6237d447f0079fd.png?sw=750&sh=750&sm=fit&sfrm=png',
  ratings: 4.9,
  numReviews: 48
},
{
  name: 'Tiffany HardWear Link Necklace',
  description: 'A bold statement necklace featuring oversized polished links that create a modern and sculptural silhouette.',
  price: 285000,
  category: 'Jewellery',
  stock: 7,
  imageUrl: 'https://cdn.fynd.com/v2/falling-surf-7c8bb8/fyprod/wrkr/products/pictures/item/free/resize-w:1280/tiffany-co/75384/0/uY_MZFiDZv-8079578_1.jpg?dpr=1',
  ratings: 4.8,
  numReviews: 32
},
{
  name: 'Bulgari Serpenti Viper Ring',
  description: 'A distinctive statement ring inspired by the iconic serpent motif, featuring a sculptural wraparound design.',
  price: 375000,
  category: 'Jewellery',
  stock: 6,
  imageUrl: 'https://www.bulgari.com/on/demandware.static/-/Sites-masterCatalog/default/dw4380944b/images/images/1352980.png',
  ratings: 4.9,
  numReviews: 41
},
{
  name: 'Van Cleef & Arpels Alhambra Pendant',
  description: 'An elegant pendant necklace featuring the signature four-leaf Alhambra motif and a refined delicate chain.',
  price: 315000,
  category: 'Jewellery',
  stock: 8,
  imageUrl: 'https://www.vancleefarpels.com/content/dam/rcq/vca/bs/tD/37/Ar/SJ/Cu/gX/c_/RV/sH/VA/bstD37ArSJCugXc_RVsHVA.png',
  ratings: 4.9,
  numReviews: 55
},
{
  name: 'Dior Tribale Drop Earrings',
  description: 'Elegant asymmetric drop earrings featuring a distinctive double-pearl design for a sophisticated feminine look.',
  price: 78000,
  category: 'Jewellery',
  stock: 12,
  imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSYOFGdiJXmfpFK1ozFlFJ00Xjd5Ytz7HdAFngwF7V6wJ0JjbnjoX_m_jHh&s=10',
  ratings: 4.7,
  numReviews: 37
},
{
  name: 'Chanel CC Crystal Hoop Earrings',
  description: 'Statement hoop earrings featuring a polished circular silhouette accented with sparkling crystal detailing and signature branding.',
  price: 95000,
  category: 'Jewellery',
  stock: 10,
  imageUrl: 'https://emier.com.au/cdn/shop/files/DSC00000_0004_DSC02172_800x.jpg?v=1719278122',
  ratings: 4.8,
  numReviews: 29
},
{
  name: 'Boucheron Quatre Cuff',
  description: 'A contemporary open cuff featuring layered geometric bands and contrasting textures for a sophisticated architectural look.',
  price: 410000,
  category: 'Jewellery',
  stock: 4,
  imageUrl: 'https://damasset.boucheron.com/kpk-image/SXWQsS9xyj8gX-BGUwNmxBbILYB7WjC16jR8oEPYyLo/resize?src=kpk://boucheron/11353/100057/17224-cpm5lhh8ul.jpg&w=809&h=809&f=webp&ex=true',
  ratings: 4.9,
  numReviews: 26
},
{
  name: 'Chopard Happy Hearts Bracelet',
  description: 'A delicate bracelet featuring playful heart-shaped motifs arranged along a refined chain for an elegant everyday style.',
  price: 185000,
  category: 'Jewellery',
  stock: 9,
  imageUrl: 'https://objects-prod.cdn.chopard.com/q_auto,f_auto,dpr_auto/e_trim/c_lpad,w_iw,h_ih/c_lpad,ar_1:1,w_800,g_center/ProductsAssets/Web/@857482-5510_10.png',
  ratings: 4.8,
  numReviews: 34
},
{
  name: 'Messika Move Uno Layered Necklace',
  description: 'A modern layered necklace featuring delicate chains and movable diamond-inspired pendants for a refined contemporary look.',
  price: 245000,
  category: 'Jewellery',
  stock: 7,
  imageUrl: 'https://www.messika.com/media-cms/messika_-_packshot_-_collier_2_rangs_move_uno_pav_vue_1_07174_yg_1.jpg',
  ratings: 4.8,
  numReviews: 31
},
{
  name: 'Cartier Tank Française Watch',
  description: 'An elegant rectangular watch featuring a refined bracelet design and timeless French-inspired styling.',
  price: 485000,
  category: 'Watches',
  stock: 6,
  imageUrl: 'https://www.cartier.com/dw/image/v2/BGTJ_PRD/on/demandware.static/-/Sites-cartier-master/default/dw70a3bac1/images/large/9ff7c758cca15dd6928dbf3ad1e74976.png?sw=750&sh=750&sm=fit&sfrm=png',
  ratings: 4.9,
  numReviews: 42
},
{
  name: 'Rolex Datejust 31 Watch',
  description: 'A sophisticated luxury watch featuring a classic round case, elegant dial, and iconic date display.',
  price: 925000,
  category: 'Watches',
  stock: 4,
  imageUrl: 'https://media.rolex.com/image/upload/q_auto/f_auto/t_v7-cover-majesty-landscape/c_limit,w_800/v1/a677b2c664f6/catalogue/2026/upright-c/m278278-0036',
  ratings: 4.9,
  numReviews: 57
},
{
  name: 'Hermès Heure H Watch',
  description: 'A distinctive fashion watch featuring the signature H-shaped case with a refined leather strap.',
  price: 315000,
  category: 'Watches',
  stock: 7,
  imageUrl: 'https://assets.hermes.com/is/image/hermesproduct/heure-h-watch-small-model-25mm--403484WW00-front-wm-1-0-0-2000-2000-q99_g.jpg',
  ratings: 4.8,
  numReviews: 31
},
{
  name: 'Bulgari Serpenti Tubogas Watch',
  description: 'A striking coiled watch inspired by the serpent, featuring a sculptural case and distinctive wraparound bracelet.',
  price: 785000,
  category: 'Watches',
  stock: 3,
  imageUrl: 'https://artoftimeindia.com/cdn/shop/files/102790-_6_600x.png?v=1758869473',
  ratings: 4.9,
  numReviews: 38
},
{
  name: 'Dior La D de Dior Watch',
  description: 'An elegant jewelry-inspired watch featuring a delicate round case, refined bracelet, and sophisticated feminine styling.',
  price: 395000,
  category: 'Watches',
  stock: 8,
  imageUrl: 'https://assets.christiandior.com/is/image/diorprod/CD04112X1754_SBG_E01-1?$r2x3_raw$&crop=0,0,1600,2000&wid=1334&hei=2000&scale=1&bfc=on&qlt=80',
  ratings: 4.8,
  numReviews: 29
},
{
  name: 'Michael Kors Parker Chronograph Watch',
  description: 'A glamorous chronograph watch featuring a sparkling bezel, multifunction dial, and polished bracelet design.',
  price: 42000,
  category: 'Watches',
  stock: 14,
  imageUrl: 'https://justintime.in/cdn/shop/files/MK5491.jpg?v=1727434275',
  ratings: 4.6,
  numReviews: 51
},
{
  name: 'Gucci GG Marmont Leather Belt',
  description: 'A refined leather belt featuring a distinctive designer buckle and an elegant silhouette for polished everyday styling.',
  price: 48000,
  category: 'Accessories',
  stock: 12,
  imageUrl: 'https://www.net-a-porter.com/variants/images/1647597341533816/in/w2000_q60.jpg',
  ratings: 4.7,
  numReviews: 28
},
{
  name: 'Celine Triomphe 01 Sunglasses',
  description: 'Elegant statement sunglasses featuring a sophisticated frame and signature-inspired detailing for a timeless finish.',
  price: 52000,
  category: 'Accessories',
  stock: 10,
  imageUrl: 'https://www.prestigeoptical.ca/cdn/shop/files/CL40194U01AQT.avif?v=1767135931&width=1445',
  ratings: 4.8,
  numReviews: 35
},
{
  name: 'Burberry Check Cashmere Scarf',
  description: 'A luxurious soft scarf featuring a classic check pattern and lightweight cashmere construction for sophisticated layering.',
  price: 65000,
  category: 'Accessories',
  stock: 9,
  imageUrl: 'https://www.net-a-porter.com/variants/images/1647597318802864/in/w2000_q60.jpg',
  ratings: 4.8,
  numReviews: 24
},
{
  name: 'Louis Vuitton Zippy Wallet',
  description: 'A spacious zip-around wallet featuring multiple compartments and a polished luxury finish for everyday organization.',
  price: 85000,
  category: 'Accessories',
  stock: 8,
  imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRPu9Yf2t0a-IVHlPYECUh6Q22XaPYxn1It1ecYxEWxFg&s=10',
  ratings: 4.8,
  numReviews: 39
},
{
  name: 'Prada Saffiano Leather Card Holder',
  description: 'A compact card holder crafted in textured leather with multiple card slots and a sleek minimalist design.',
  price: 42000,
  category: 'Accessories',
  stock: 15,
  imageUrl: 'https://cdn-images.farfetch-contents.com/30/55/40/85/30554085_59727128_600.jpg',
  ratings: 4.7,
  numReviews: 27
},
{
  name: 'Roger Vivier Broche Crystal-Embellished Hair Clip',
  description: 'An elegant statement hair clip crafted in grosgrain and finished with a sparkling crystal-embellished buckle detail.',
  price: 55000,
  category: 'Accessories',
  stock: 10,
  imageUrl: 'https://i.etsystatic.com/10071353/r/il/b4bc2c/5589282929/il_570xN.5589282929_5kwr.jpg',
  ratings: 4.8,
  numReviews: 22
},
{
  name: 'Loewe Anagram Leather Belt',
  description: 'A sophisticated leather belt featuring an iconic sculptural buckle and refined minimalist construction.',
  price: 58000,
  category: 'Accessories',
  stock: 11,
  imageUrl: 'https://cdn.clothbase.com/uploads/39ef3ceb-3c6e-4e93-b8d4-476508895dd0/P00888518_d3.jpg',
  ratings: 4.7,
  numReviews: 19
},
{
  name: 'Dior Oblique Bucket Hat',
  description: 'A contemporary bucket hat featuring a distinctive designer-inspired pattern and relaxed silhouette for fashionable everyday wear.',
  price: 62000,
  category: 'Accessories',
  stock: 8,
  imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS7EFF6V5lBU_V5OMX6diQDWouMDL4Bh5yJmD68GbAfGQ&s=10',
  ratings: 4.6,
  numReviews: 17
},
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
