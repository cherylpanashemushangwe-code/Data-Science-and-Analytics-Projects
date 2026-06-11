-- ============================================================================
-- RetailPulse — Customer Revenue & Cohort Analytics Engine
-- 02_seed_data.sql | Realistic Synthetic Data (2020–2024)
-- ============================================================================
-- Generates ~2,000 customers, ~15,000 orders, ~35,000 line items,
-- payments, shipping, reviews, and returns with realistic distributions.
-- ============================================================================

-- ============================================================================
-- CATEGORIES (8 product categories with margin targets)
-- ============================================================================
INSERT INTO categories (category_name, margin_target) VALUES
    ('Electronics',      0.22),
    ('Clothing',         0.55),
    ('Home & Kitchen',   0.40),
    ('Beauty',           0.62),
    ('Sports & Outdoors',0.38),
    ('Books',            0.45),
    ('Toys & Games',     0.48),
    ('Office Supplies',  0.52);

-- ============================================================================
-- PRODUCTS (60 products across 8 categories)
-- ============================================================================
INSERT INTO products (product_name, category_id, unit_cost, unit_price, launch_date, is_active) VALUES
    -- Electronics (category 1)
    ('Wireless Earbuds Pro',        1, 18.50, 49.99,  '2020-01-15', TRUE),
    ('USB-C Charging Hub',          1, 12.00, 34.99,  '2020-03-01', TRUE),
    ('Portable Bluetooth Speaker',  1, 22.00, 59.99,  '2020-06-10', TRUE),
    ('Smart LED Desk Lamp',         1, 15.00, 44.99,  '2021-01-20', TRUE),
    ('Noise Cancelling Headphones', 1, 45.00, 129.99, '2021-07-01', TRUE),
    ('Wireless Phone Charger',      1, 8.00,  24.99,  '2022-02-14', TRUE),
    ('Fitness Tracker Band',        1, 25.00, 79.99,  '2022-09-01', TRUE),
    ('Mini Projector',              1, 55.00, 149.99, '2023-03-15', FALSE),
    -- Clothing (category 2)
    ('Classic Cotton T-Shirt',      2, 4.50,  19.99,  '2020-01-05', TRUE),
    ('Slim Fit Chinos',             2, 12.00, 44.99,  '2020-02-10', TRUE),
    ('Merino Wool Sweater',         2, 18.00, 69.99,  '2020-09-01', TRUE),
    ('Waterproof Rain Jacket',      2, 22.00, 89.99,  '2021-03-15', TRUE),
    ('Running Shorts',              2, 5.00,  24.99,  '2021-06-01', TRUE),
    ('Fleece Zip Hoodie',           2, 14.00, 54.99,  '2022-10-01', TRUE),
    ('Linen Button-Down Shirt',     2, 9.00,  39.99,  '2023-04-20', TRUE),
    -- Home & Kitchen (category 3)
    ('Stainless Steel Water Bottle',3, 5.00,  22.99,  '2020-01-10', TRUE),
    ('Bamboo Cutting Board Set',    3, 8.00,  29.99,  '2020-04-15', TRUE),
    ('French Press Coffee Maker',   3, 10.00, 34.99,  '2020-07-20', TRUE),
    ('Cast Iron Skillet 12-inch',   3, 15.00, 44.99,  '2021-01-05', TRUE),
    ('Silicone Baking Mat Set',     3, 4.00,  16.99,  '2021-08-10', TRUE),
    ('Electric Kettle',             3, 12.00, 39.99,  '2022-01-15', TRUE),
    ('Ceramic Dinner Plate Set',    3, 18.00, 54.99,  '2022-11-01', TRUE),
    ('Insulated Lunch Bag',         3, 6.00,  24.99,  '2023-06-01', TRUE),
    -- Beauty (category 4)
    ('Vitamin C Serum',             4, 3.50,  28.99,  '2020-02-14', TRUE),
    ('Hydrating Face Moisturizer',  4, 4.00,  32.99,  '2020-05-01', TRUE),
    ('Rosehip Facial Oil',          4, 3.00,  24.99,  '2020-08-15', TRUE),
    ('Charcoal Clay Mask',          4, 2.50,  18.99,  '2021-02-01', TRUE),
    ('SPF 50 Daily Sunscreen',      4, 3.00,  22.99,  '2021-06-15', TRUE),
    ('Retinol Night Cream',         4, 5.00,  38.99,  '2022-03-01', TRUE),
    ('Hyaluronic Acid Serum',       4, 2.80,  26.99,  '2023-01-10', TRUE),
    ('Lip Balm Trio Pack',          4, 1.50,  12.99,  '2023-09-01', TRUE),
    -- Sports & Outdoors (category 5)
    ('Yoga Mat Premium',            5, 8.00,  34.99,  '2020-01-20', TRUE),
    ('Resistance Band Set',         5, 4.00,  19.99,  '2020-05-10', TRUE),
    ('Foam Roller',                 5, 6.00,  24.99,  '2020-10-01', TRUE),
    ('Adjustable Jump Rope',        5, 3.50,  14.99,  '2021-01-15', TRUE),
    ('Camping Headlamp',            5, 5.00,  21.99,  '2021-07-20', TRUE),
    ('Insulated Hiking Flask',      5, 7.00,  29.99,  '2022-04-01', TRUE),
    ('Pull-Up Bar Doorframe',       5, 10.00, 39.99,  '2022-12-01', TRUE),
    -- Books (category 6)
    ('Data Science Handbook',       6, 8.00,  29.99,  '2020-01-01', TRUE),
    ('SQL Performance Explained',   6, 6.00,  24.99,  '2020-03-15', TRUE),
    ('Thinking Fast and Slow',      6, 5.00,  18.99,  '2020-06-01', TRUE),
    ('Atomic Habits',               6, 5.50,  16.99,  '2020-09-10', TRUE),
    ('The Art of Statistics',       6, 7.00,  22.99,  '2021-02-20', TRUE),
    ('Python Crash Course',         6, 9.00,  34.99,  '2021-08-01', TRUE),
    ('Storytelling with Data',      6, 8.00,  27.99,  '2022-05-15', TRUE),
    -- Toys & Games (category 7)
    ('1000-Piece Jigsaw Puzzle',    7, 5.00,  19.99,  '2020-04-01', TRUE),
    ('Strategy Board Game',         7, 12.00, 39.99,  '2020-07-15', TRUE),
    ('Building Block Set 500pc',    7, 10.00, 34.99,  '2020-11-20', TRUE),
    ('Card Game Party Pack',        7, 3.00,  14.99,  '2021-05-01', TRUE),
    ('Remote Control Car',          7, 15.00, 44.99,  '2021-12-01', TRUE),
    ('Science Experiment Kit',      7, 8.00,  29.99,  '2022-08-10', TRUE),
    ('Wooden Chess Set',            7, 11.00, 36.99,  '2023-02-01', TRUE),
    -- Office Supplies (category 8)
    ('Ergonomic Mouse Pad',         8, 3.00,  14.99,  '2020-01-10', TRUE),
    ('Dot Grid Notebook 3-Pack',    8, 4.00,  16.99,  '2020-03-20', TRUE),
    ('Standing Desk Converter',     8, 45.00, 129.99, '2020-08-01', TRUE),
    ('Monitor Light Bar',           8, 18.00, 49.99,  '2021-04-15', TRUE),
    ('Desk Cable Organizer',        8, 2.50,  11.99,  '2021-09-01', TRUE),
    ('Whiteboard Monthly Planner',  8, 6.00,  22.99,  '2022-01-05', TRUE),
    ('Mechanical Keyboard',         8, 28.00, 79.99,  '2022-07-20', TRUE),
    ('Laptop Stand Aluminum',       8, 14.00, 44.99,  '2023-05-01', TRUE);

-- ============================================================================
-- CUSTOMERS (~2,000 spread across 2020–2024 signup dates)
-- ============================================================================
-- Uses generate_series + arrays of common names for realistic distribution.
-- Signup volume grows ~20% YoY to mirror real e-commerce growth.

INSERT INTO customers (first_name, last_name, email, signup_date, city, state, acquisition_channel)
SELECT
    (ARRAY['James','Mary','Robert','Jennifer','Michael','Linda','David','Elizabeth',
           'William','Barbara','Richard','Susan','Joseph','Jessica','Thomas','Sarah',
           'Christopher','Karen','Daniel','Lisa','Matthew','Nancy','Anthony','Betty',
           'Mark','Margaret','Steven','Sandra','Andrew','Ashley','Joshua','Dorothy',
           'Kenneth','Kimberly','Kevin','Emily','Brian','Donna','George','Michelle',
           'Timothy','Carol','Ronald','Amanda','Jason','Melissa','Jeffrey','Deborah',
           'Ryan','Stephanie','Olivia','Aiden','Sophia','Liam','Isabella','Noah',
           'Mia','Ethan','Ava','Lucas','Charlotte','Mason','Amelia','Logan'])[
        1 + (random() * 63)::INT
    ] AS first_name,

    (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis',
           'Rodriguez','Martinez','Hernandez','Lopez','Gonzalez','Wilson','Anderson',
           'Thomas','Taylor','Moore','Jackson','Martin','Lee','Perez','Thompson',
           'White','Harris','Sanchez','Clark','Ramirez','Lewis','Robinson','Walker',
           'Young','Allen','King','Wright','Scott','Torres','Nguyen','Hill',
           'Flores','Green','Adams','Nelson','Baker','Hall','Rivera','Campbell',
           'Mitchell','Carter','Roberts','Chen','Kim','Patel','Shah','Singh'])[
        1 + (random() * 55)::INT
    ] AS last_name,

    'customer_' || gs || '@retailpulse.demo' AS email,

    -- Signup dates: weighted toward later years (growth pattern)
    ('2020-01-01'::DATE + (
        CASE
            WHEN random() < 0.12 THEN (random() * 365)::INT               -- 2020: ~12%
            WHEN random() < 0.30 THEN 365  + (random() * 365)::INT        -- 2021: ~18%
            WHEN random() < 0.52 THEN 730  + (random() * 365)::INT        -- 2022: ~22%
            WHEN random() < 0.78 THEN 1095 + (random() * 365)::INT        -- 2023: ~26%
            ELSE                      1461 + (random() * 364)::INT         -- 2024: ~22%
        END
    ))::DATE AS signup_date,

    (ARRAY['New York','Los Angeles','Chicago','Houston','Phoenix','Philadelphia',
           'San Antonio','San Diego','Dallas','Austin','Jacksonville','San Jose',
           'Columbus','Charlotte','Indianapolis','Denver','Seattle','Boston',
           'Nashville','Portland','Atlanta','Miami','Minneapolis','Raleigh',
           'Tampa','Detroit','Salt Lake City','Cleveland','Pittsburgh','Orlando'])[
        1 + (random() * 29)::INT
    ] AS city,

    (ARRAY['NY','CA','IL','TX','AZ','PA','TX','CA','TX','TX','FL','CA',
           'OH','NC','IN','CO','WA','MA','TN','OR','GA','FL','MN','NC',
           'FL','MI','UT','OH','PA','FL'])[
        1 + (random() * 29)::INT
    ] AS state,

    (ARRAY['organic','paid_search','social','referral','email','direct'])[
        1 + (random() * 5)::INT
    ] AS acquisition_channel

FROM generate_series(1, 2000) AS gs;

-- ============================================================================
-- ORDERS (~15,000 orders across 5 years)
-- ============================================================================
-- Realistic patterns: ~8% cancelled, ~4% refunded, ~3% pending (recent only)

INSERT INTO orders (customer_id, order_date, order_status)
SELECT
    (1 + (random() * 1999)::INT) AS customer_id,

    (c.signup_date + (random() * (
        LEAST('2024-12-31'::DATE, c.signup_date + 1800) - c.signup_date
    ))::INT)::DATE AS order_date,

    CASE
        WHEN random() < 0.85 THEN 'completed'
        WHEN random() < 0.93 THEN 'cancelled'
        WHEN random() < 0.97 THEN 'refunded'
        ELSE 'pending'
    END AS order_status

FROM generate_series(1, 15000) AS gs
JOIN customers c ON c.customer_id = (1 + (random() * 1999)::INT)
WHERE c.signup_date <= '2024-12-31';

-- Fix: ensure order_date >= signup_date
UPDATE orders o
SET order_date = c.signup_date + ((random() * 365)::INT)
FROM customers c
WHERE o.customer_id = c.customer_id
  AND o.order_date < c.signup_date;

-- ============================================================================
-- ORDER_ITEMS (~2.3 items per order average)
-- ============================================================================
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct)
SELECT
    o.order_id,
    (1 + (random() * 59)::INT) AS product_id,
    CASE
        WHEN random() < 0.60 THEN 1
        WHEN random() < 0.85 THEN 2
        WHEN random() < 0.95 THEN 3
        ELSE (4 + (random() * 3)::INT)
    END AS quantity,
    p.unit_price,
    CASE
        WHEN random() < 0.70 THEN 0.00
        WHEN random() < 0.85 THEN 0.10
        WHEN random() < 0.95 THEN 0.15
        ELSE 0.25
    END AS discount_pct
FROM orders o
CROSS JOIN LATERAL (
    SELECT generate_series(1,
        CASE
            WHEN random() < 0.35 THEN 1
            WHEN random() < 0.65 THEN 2
            WHEN random() < 0.85 THEN 3
            ELSE 4
        END
    ) AS item_num
) items
JOIN products p ON p.product_id = (1 + (random() * 59)::INT);

-- ============================================================================
-- PAYMENTS (one payment per completed/refunded order)
-- ============================================================================
INSERT INTO payments (order_id, payment_date, payment_method, amount)
SELECT
    o.order_id,
    o.order_date + (random() * 2)::INT AS payment_date,
    (ARRAY['credit_card','debit_card','paypal','apple_pay','gift_card'])[
        CASE
            WHEN random() < 0.45 THEN 1
            WHEN random() < 0.70 THEN 2
            WHEN random() < 0.85 THEN 3
            WHEN random() < 0.95 THEN 4
            ELSE 5
        END
    ] AS payment_method,
    COALESCE(oi_totals.total, 0) AS amount
FROM orders o
JOIN (
    SELECT order_id,
           SUM(quantity * unit_price * (1 - discount_pct)) AS total
    FROM order_items
    GROUP BY order_id
) oi_totals ON oi_totals.order_id = o.order_id
WHERE o.order_status IN ('completed', 'refunded');

-- ============================================================================
-- SHIPPING (for completed and refunded orders)
-- ============================================================================
INSERT INTO shipping (order_id, shipped_date, delivered_date, carrier, shipping_cost)
SELECT
    o.order_id,
    o.order_date + (1 + (random() * 2)::INT) AS shipped_date,
    o.order_date + (3 + (random() * 7)::INT) AS delivered_date,
    (ARRAY['USPS','UPS','FedEx','DHL','Amazon Logistics'])[
        1 + (random() * 4)::INT
    ] AS carrier,
    ROUND((3.99 + random() * 12)::NUMERIC, 2) AS shipping_cost
FROM orders o
WHERE o.order_status IN ('completed', 'refunded');

-- ============================================================================
-- PRODUCT_REVIEWS (~30% of completed orders get a review)
-- ============================================================================
INSERT INTO product_reviews (product_id, customer_id, review_date, rating, review_text)
SELECT DISTINCT ON (o.order_id)
    oi.product_id,
    o.customer_id,
    o.order_date + (5 + (random() * 30)::INT) AS review_date,
    CASE
        WHEN random() < 0.05 THEN 1
        WHEN random() < 0.12 THEN 2
        WHEN random() < 0.28 THEN 3
        WHEN random() < 0.60 THEN 4
        ELSE 5
    END AS rating,
    (ARRAY[
        'Great product, exactly as described.',
        'Good value for the price.',
        'Decent quality, would buy again.',
        'Not what I expected, a bit disappointed.',
        'Absolutely love it! Highly recommend.',
        'Arrived quickly, works perfectly.',
        'Average product, nothing special.',
        'Excellent quality and fast shipping.',
        'Would not purchase again.',
        'Perfect gift idea!',
        'Better than expected for the price.',
        'Solid build quality.'
    ])[1 + (random() * 11)::INT] AS review_text
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
  AND random() < 0.30;

-- ============================================================================
-- RETURNS (~7% of completed order items)
-- ============================================================================
INSERT INTO returns (order_item_id, return_date, reason, refund_amount)
SELECT
    oi.order_item_id,
    o.order_date + (10 + (random() * 20)::INT) AS return_date,
    (ARRAY['defective','wrong_item','not_as_described','changed_mind','other'])[
        CASE
            WHEN random() < 0.25 THEN 1
            WHEN random() < 0.40 THEN 2
            WHEN random() < 0.60 THEN 3
            WHEN random() < 0.90 THEN 4
            ELSE 5
        END
    ] AS reason,
    ROUND((oi.quantity * oi.unit_price * (1 - oi.discount_pct))::NUMERIC, 2) AS refund_amount
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'completed'
  AND random() < 0.07;

-- ============================================================================
-- DATA QUALITY CHECK
-- ============================================================================
SELECT 'customers'      AS tbl, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'categories',           COUNT(*) FROM categories
UNION ALL
SELECT 'products',             COUNT(*) FROM products
UNION ALL
SELECT 'orders',               COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',          COUNT(*) FROM order_items
UNION ALL
SELECT 'payments',             COUNT(*) FROM payments
UNION ALL
SELECT 'shipping',             COUNT(*) FROM shipping
UNION ALL
SELECT 'product_reviews',      COUNT(*) FROM product_reviews
UNION ALL
SELECT 'returns',              COUNT(*) FROM returns;
