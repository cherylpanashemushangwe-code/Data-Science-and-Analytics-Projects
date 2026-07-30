
-- RetailPulse — Customer Revenue & Cohort Analytics Engine
-- 01_schema.sql | Database Schema Definition
-- Business Context: A mid-size e-commerce company with 5 years of order data
-- across 9 normalized tables. This schema supports the full analytics layer
-- from raw transactional data to business-ready insights.

-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS returns CASCADE;
DROP TABLE IF EXISTS product_reviews CASCADE;
DROP TABLE IF EXISTS shipping CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 
-- 1. CUSTOMERS
-- 
CREATE TABLE customers (
    customer_id       SERIAL PRIMARY KEY,
    first_name        VARCHAR(50)  NOT NULL,
    last_name         VARCHAR(50)  NOT NULL,
    email             VARCHAR(120) NOT NULL UNIQUE,
    signup_date       DATE         NOT NULL,
    city              VARCHAR(80),
    state             VARCHAR(2),
    acquisition_channel VARCHAR(30) CHECK (acquisition_channel IN (
        'organic','paid_search','social','referral','email','direct'
    ))
);

-- 
-- 2. CATEGORIES
-- 
CREATE TABLE categories (
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(60)  NOT NULL UNIQUE,
    margin_target NUMERIC(4,2) -- target gross margin %
);

-- 
-- 3. PRODUCTS
-- 
CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(120) NOT NULL,
    category_id   INT          NOT NULL REFERENCES categories(category_id),
    unit_cost     NUMERIC(10,2) NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL,
    launch_date   DATE          NOT NULL,
    is_active     BOOLEAN       DEFAULT TRUE
);

-- 
-- 4. ORDERS
-- 
CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT  NOT NULL REFERENCES customers(customer_id),
    order_date    DATE NOT NULL,
    order_status  VARCHAR(20) CHECK (order_status IN (
        'completed','cancelled','refunded','pending'
    ))
);

-- 
-- 5. ORDER_ITEMS (junction table - one order can have many products)
-- 
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT NOT NULL REFERENCES orders(order_id),
    product_id    INT NOT NULL REFERENCES products(product_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL,  -- price at time of sale
    discount_pct  NUMERIC(4,2) DEFAULT 0   -- applied discount
);

-- 
-- 6. PAYMENTS
-- 
CREATE TABLE payments (
    payment_id     SERIAL PRIMARY KEY,
    order_id       INT NOT NULL REFERENCES orders(order_id),
    payment_date   DATE NOT NULL,
    payment_method VARCHAR(20) CHECK (payment_method IN (
        'credit_card','debit_card','paypal','apple_pay','gift_card'
    )),
    amount         NUMERIC(10,2) NOT NULL
);

-- 
-- 7. SHIPPING
-- 
CREATE TABLE shipping (
    shipping_id    SERIAL PRIMARY KEY,
    order_id       INT NOT NULL REFERENCES orders(order_id),
    shipped_date   DATE,
    delivered_date DATE,
    carrier        VARCHAR(30),
    shipping_cost  NUMERIC(8,2)
);

-- 
-- 8. PRODUCT_REVIEWS
-- 
CREATE TABLE product_reviews (
    review_id    SERIAL PRIMARY KEY,
    product_id   INT  NOT NULL REFERENCES products(product_id),
    customer_id  INT  NOT NULL REFERENCES customers(customer_id),
    review_date  DATE NOT NULL,
    rating       INT  CHECK (rating BETWEEN 1 AND 5),
    review_text  TEXT
);

-- 
-- 9. RETURNS
-- 
CREATE TABLE returns (
    return_id     SERIAL PRIMARY KEY,
    order_item_id INT  NOT NULL REFERENCES order_items(order_item_id),
    return_date   DATE NOT NULL,
    reason        VARCHAR(40) CHECK (reason IN (
        'defective','wrong_item','not_as_described','changed_mind','other'
    )),
    refund_amount NUMERIC(10,2) NOT NULL
);

-- 
-- INDEXES 
-- 
CREATE INDEX idx_orders_customer     ON orders(customer_id);
CREATE INDEX idx_orders_date         ON orders(order_date);
CREATE INDEX idx_order_items_order   ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order      ON payments(order_id);
CREATE INDEX idx_shipping_order      ON shipping(order_id);
CREATE INDEX idx_reviews_product     ON product_reviews(product_id);
CREATE INDEX idx_returns_item        ON returns(order_item_id);
CREATE INDEX idx_customers_signup    ON customers(signup_date);
