-- ============================================================
-- DBCopilot Database Schema
-- Creates all business tables with sample structure
-- Spring Boot JPA will create: users, query_history
-- ============================================================

-- Business tables (not managed by JPA)

CREATE TABLE IF NOT EXISTS customers (
    customer_id  SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city          VARCHAR(100),
    status        VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
    email         VARCHAR(150),
    phone         VARCHAR(20),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id   SERIAL PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department    VARCHAR(100),
    salary        NUMERIC(12, 2),
    joining_date  DATE,
    status        VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE'))
);

CREATE TABLE IF NOT EXISTS products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(100),
    price        NUMERIC(10, 2),
    stock        INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    product_id  INT REFERENCES products(product_id),
    amount      NUMERIC(12, 2),
    order_date  DATE DEFAULT CURRENT_DATE,
    status      VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING','COMPLETED','CANCELLED'))
);

-- ============================================================
-- Seed Data
-- ============================================================

INSERT INTO customers (customer_name, city, status, email, phone) VALUES
('Rahul Sharma',    'Bangalore', 'ACTIVE',   'rahul.sharma@email.com',   '9876543210'),
('Priya Singh',     'Mumbai',    'ACTIVE',   'priya.singh@email.com',    '9876543211'),
('Arjun Nair',      'Bangalore', 'ACTIVE',   'arjun.nair@email.com',     '9876543212'),
('Sneha Reddy',     'Hyderabad', 'INACTIVE', 'sneha.reddy@email.com',    '9876543213'),
('Vikram Patel',    'Ahmedabad', 'ACTIVE',   'vikram.patel@email.com',   '9876543214'),
('Anjali Kumar',    'Delhi',     'ACTIVE',   'anjali.kumar@email.com',   '9876543215'),
('Rohan Mehta',     'Pune',      'INACTIVE', 'rohan.mehta@email.com',    '9876543216'),
('Deepa Iyer',      'Chennai',   'ACTIVE',   'deepa.iyer@email.com',     '9876543217'),
('Karan Malhotra',  'Bangalore', 'ACTIVE',   'karan.malhotra@email.com', '9876543218'),
('Neha Gupta',      'Mumbai',    'ACTIVE',   'neha.gupta@email.com',     '9876543219')
ON CONFLICT DO NOTHING;

INSERT INTO employees (employee_name, department, salary, joining_date, status) VALUES
('Amit Verma',      'Engineering',  75000, '2023-01-15', 'ACTIVE'),
('Pooja Desai',     'HR',           55000, '2023-03-10', 'ACTIVE'),
('Suresh Babu',     'Engineering',  80000, '2022-11-20', 'ACTIVE'),
('Meera Pillai',    'Marketing',    60000, '2024-02-01', 'ACTIVE'),
('Rajesh Kumar',    'Finance',      70000, '2023-07-05', 'ACTIVE'),
('Sunita Rao',      'Engineering',  85000, '2022-09-14', 'ACTIVE'),
('Anil Chandra',    'HR',           52000, '2024-04-22', 'ACTIVE'),
('Kavya Menon',     'Marketing',    58000, '2024-05-10', 'ACTIVE'),
('Dinesh Joshi',    'Finance',      72000, '2023-12-01', 'ACTIVE'),
('Ritu Sharma',     'Engineering',  78000, '2024-01-08', 'ACTIVE'),
('Manoj Tiwari',    'Engineering',  82000, '2022-06-30', 'INACTIVE'),
('Lakshmi Nair',    'Marketing',    62000, '2024-03-15', 'ACTIVE')
ON CONFLICT DO NOTHING;

INSERT INTO products (product_name, category, price, stock) VALUES
('Laptop Pro 15',       'Electronics',  85000,  50),
('Wireless Mouse',      'Electronics',   1200, 200),
('Mechanical Keyboard', 'Electronics',   3500, 150),
('USB-C Hub',           'Electronics',   2200, 180),
('Monitor 27"',         'Electronics',  22000,  30),
('Office Chair',        'Furniture',    12000,  25),
('Standing Desk',       'Furniture',    35000,  15),
('Notebook Pack',       'Stationery',     250, 500),
('Pen Set',             'Stationery',     120, 800),
('Headphones BT',       'Electronics',   4500,  75)
ON CONFLICT DO NOTHING;

INSERT INTO orders (customer_id, product_id, amount, order_date, status) VALUES
(1, 1,  85000, '2024-01-10', 'COMPLETED'),
(2, 2,   1200, '2024-01-15', 'COMPLETED'),
(3, 5,  22000, '2024-02-01', 'COMPLETED'),
(1, 4,   2200, '2024-02-14', 'COMPLETED'),
(4, 6,  12000, '2024-02-20', 'CANCELLED'),
(5, 3,   3500, '2024-03-05', 'COMPLETED'),
(6, 10,  4500, '2024-03-12', 'COMPLETED'),
(7, 7,  35000, '2024-03-18', 'PENDING'),
(8, 1,  85000, '2024-04-01', 'COMPLETED'),
(9, 2,   1200, '2024-04-10', 'COMPLETED'),
(2, 5,  22000, '2024-04-22', 'COMPLETED'),
(3, 9,    120, '2024-05-01', 'COMPLETED'),
(10,4,  2200, '2024-05-08', 'PENDING'),
(1, 10,  4500, '2024-05-11', 'COMPLETED'),
(5, 8,    250, '2024-05-15', 'COMPLETED')
ON CONFLICT DO NOTHING;
