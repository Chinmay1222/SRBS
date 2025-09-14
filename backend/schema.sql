CREATE DATABASE IF NOT EXISTS srbs_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE srbs_db;

DROP TABLE IF EXISTS bill_items;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS products;
CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL UNIQUE,
    category VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    price DECIMAL(10, 2) NOT NULL,
    gst_rate DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    stock_quantity INT NOT NULL DEFAULT 0
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL UNIQUE,
    password_hash VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
    role VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'cashier' -- e.g., 'admin', 'cashier'
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
    phone VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci UNIQUE,
    email VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci UNIQUE,
    loyalty_points INT DEFAULT 0
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bill_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    customer_id INT,
    subtotal_amount DECIMAL(10, 2) NOT NULL,
    discount_percentage DECIMAL(5, 2) DEFAULT 0.00,
    total_tax_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    final_total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS bill_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bill_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price_at_sale DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (bill_id) REFERENCES bills(id),
        FOREIGN KEY (product_id) REFERENCES products(product_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (1, 'Veg Biryani', 'Food', 1654.45, 12, 258);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (2, 'Coffee', 'Beverages', 327.59, 12, 467);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (3, 'Burger', 'Snacks', 668.66, 5, 176);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (4, 'Laptop Charger', 'Electronics', 181.61, 18, 371);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (5, 'Belt', 'Accessories', 154.89, 12, 415);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (6, 'Masala Dosa', 'Food', 367.78, 18, 253);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (7, 'Lassi', 'Beverages', 1552.88, 12, 445);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (8, 'Vada Pav', 'Snacks', 1903.43, 12, 193);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (9, 'USB Cable', 'Electronics', 1271.28, 12, 95);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (10, 'Sunglasses', 'Accessories', 391.96, 18, 58);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (11, 'Poori Bhaji', 'Food', 79.46, 18, 73);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (12, 'Mineral Water', 'Beverages', 931.47, 18, 270);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (13, 'Chips', 'Snacks', 1820.47, 18, 227);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (14, 'Laptop Charger', 'Electronics', 556.78, 18, 378);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (15, 'Belt', 'Accessories', 473.28, 18, 413);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (16, 'Fried Rice', 'Food', 466.98, 12, 435);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (17, 'Coffee', 'Beverages', 414.56, 18, 212);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (18, 'Burger', 'Snacks', 1286.17, 18, 236);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (19, 'Wireless Mouse', 'Electronics', 1393.11, 18, 460);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (20, 'Shoes', 'Accessories', 1802.81, 18, 104);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (21, 'Fried Rice', 'Food', 1683.26, 12, 297);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (22, 'Sprite', 'Beverages', 770.26, 5, 346);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (23, 'Pani Puri', 'Snacks', 1032.07, 5, 92);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (24, 'Bluetooth Speaker', 'Electronics', 1622.67, 18, 361);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (25, 'Keychain', 'Accessories', 55.56, 5, 17);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (26, 'Fish Fry', 'Food', 1864.52, 5, 123);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (27, 'Lassi', 'Beverages', 121.63, 5, 68);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (28, 'French Fries', 'Snacks', 166.13, 18, 238);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (29, 'Headphones', 'Electronics', 1140.05, 18, 54);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (30, 'Cap', 'Accessories', 222.95, 18, 328);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (31, 'Veg Biryani', 'Food', 926.33, 12, 376);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (32, 'Lassi', 'Beverages', 1166.9, 5, 382);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (33, 'Pizza Slice', 'Snacks', 332.36, 5, 100);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (34, 'Headphones', 'Electronics', 707.6, 5, 479);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (35, 'Shoes', 'Accessories', 194.28, 12, 497);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (36, 'Fish Fry', 'Food', 885.65, 18, 213);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (37, 'Mango Shake', 'Beverages', 1408.15, 18, 414);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (38, 'Vada Pav', 'Snacks', 1882.62, 5, 385);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (39, 'Mobile Cover', 'Electronics', 1258.84, 12, 28);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (40, 'Sunglasses', 'Accessories', 708.82, 5, 414);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (41, 'Idli (2 pcs)', 'Food', 199.94, 5, 486);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (42, 'Orange Juice', 'Beverages', 1204.29, 5, 297);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (43, 'Vada Pav', 'Snacks', 1136.56, 18, 218);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (44, 'Mobile Cover', 'Electronics', 1354.52, 5, 213);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (45, 'Shoes', 'Accessories', 537.47, 18, 24);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (46, 'Paneer Butter Masala', 'Food', 1592.07, 5, 333);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (47, 'Mango Shake', 'Beverages', 785.84, 12, 189);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (48, 'Bhel Puri', 'Snacks', 20.1, 5, 228);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (49, 'Laptop Charger', 'Electronics', 988.23, 18, 395);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (50, 'Watch', 'Accessories', 1213.67, 18, 389);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (51, 'Paneer Butter Masala', 'Food', 1821.67, 5, 173);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (52, 'Pepsi', 'Beverages', 1064.85, 18, 269);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (53, 'Burger', 'Snacks', 919.97, 5, 312);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (54, 'Keyboard', 'Electronics', 1837.63, 5, 235);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (55, 'Keychain', 'Accessories', 1908.22, 5, 182);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (56, 'Idli (2 pcs)', 'Food', 1027.85, 5, 479);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (57, 'Orange Juice', 'Beverages', 572.11, 5, 317);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (58, 'Sandwich', 'Snacks', 166.09, 12, 145);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (59, 'Headphones', 'Electronics', 375.18, 18, 93);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (60, 'Keychain', 'Accessories', 1070.01, 12, 61);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (61, 'Chicken Curry', 'Food', 1596.49, 5, 182);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (62, 'Mango Shake', 'Beverages', 594.34, 5, 399);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (63, 'Sandwich', 'Snacks', 1661.98, 18, 74);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (64, 'Keyboard', 'Electronics', 1111.9, 18, 448);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (65, 'Sunglasses', 'Accessories', 909.59, 18, 135);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (66, 'Masala Dosa', 'Food', 1855.17, 12, 367);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (67, 'Coca Cola (500ml)', 'Beverages', 1177.13, 5, 135);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (68, 'Pizza Slice', 'Snacks', 1946.06, 5, 125);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (69, 'Smart Watch', 'Electronics', 984.01, 5, 42);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (70, 'Shoes', 'Accessories', 983.02, 5, 359);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (71, 'Idli (2 pcs)', 'Food', 384.97, 12, 445);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (72, 'Coffee', 'Beverages', 1036.77, 5, 423);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (73, 'Samosa', 'Snacks', 1547.9, 12, 492);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (74, 'Mobile Cover', 'Electronics', 1524.4, 5, 325);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (75, 'Sunglasses', 'Accessories', 1392.79, 18, 70);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (76, 'Idli (2 pcs)', 'Food', 656.69, 18, 58);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (77, 'Coca Cola (500ml)', 'Beverages', 567.15, 12, 167);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (78, 'Bhel Puri', 'Snacks', 864.9, 12, 60);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (79, 'Laptop Charger', 'Electronics', 1597.39, 12, 352);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (80, 'Shoes', 'Accessories', 1674.34, 18, 175);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (81, 'Veg Biryani', 'Food', 20.24, 5, 96);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (82, 'Pepsi', 'Beverages', 473.09, 18, 144);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (83, 'Vada Pav', 'Snacks', 198.19, 18, 349);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (84, 'Power Bank', 'Electronics', 25.27, 18, 104);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (85, 'Bag', 'Accessories', 1816.49, 18, 143);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (86, 'Fish Fry', 'Food', 436.06, 18, 54);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (87, 'Coffee', 'Beverages', 1013.07, 18, 63);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (88, 'Burger', 'Snacks', 226.94, 18, 355);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (89, 'Laptop Charger', 'Electronics', 1530.29, 12, 496);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (90, 'Cap', 'Accessories', 1974.75, 5, 296);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (91, 'Pav Bhaji', 'Food', 1114.55, 18, 281);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (92, 'Cold Coffee', 'Beverages', 438.95, 12, 163);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (93, 'French Fries', 'Snacks', 674.18, 5, 336);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (94, 'Laptop Charger', 'Electronics', 1272.54, 12, 482);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (95, 'Scarf', 'Accessories', 427.46, 12, 435);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (96, 'Fish Fry', 'Food', 624.3, 18, 54);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (97, 'Pepsi', 'Beverages', 597.49, 12, 180);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (98, 'Samosa', 'Snacks', 1110.8, 12, 31);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (99, 'Power Bank', 'Electronics', 970.87, 12, 234);
INSERT IGNORE INTO products (product_id, product_name, category, price, gst_rate, stock_quantity) VALUES (100, 'Watch', 'Accessories', 1201.6, 18, 19);
