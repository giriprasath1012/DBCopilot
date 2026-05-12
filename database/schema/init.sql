-- ============================================================
-- DBCopilot Database Schema  (Spring Boot JPA manages: users, query_history)
-- ============================================================

-- ── Core tables ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS customers (
    customer_id   SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city          VARCHAR(100),
    status        VARCHAR(20)  DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
    email         VARCHAR(150),
    phone         VARCHAR(20),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id   SERIAL PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department    VARCHAR(100),
    designation   VARCHAR(100),
    salary        NUMERIC(12,2),
    joining_date  DATE,
    status        VARCHAR(20)  DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE'))
);

CREATE TABLE IF NOT EXISTS products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(100),
    price        NUMERIC(10,2),
    stock        INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    product_id  INT REFERENCES products(product_id),
    amount      NUMERIC(12,2),
    order_date  DATE DEFAULT CURRENT_DATE,
    status      VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING','COMPLETED','CANCELLED'))
);

-- ── New tables ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS departments (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    head_name       VARCHAR(100),
    budget          NUMERIC(15,2),
    location        VARCHAR(100),
    employee_count  INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id    SERIAL PRIMARY KEY,
    supplier_name  VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    email          VARCHAR(150),
    phone          VARCHAR(20),
    city           VARCHAR(100),
    status         VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE'))
);

CREATE TABLE IF NOT EXISTS supplier_products (
    id          SERIAL PRIMARY KEY,
    supplier_id INT REFERENCES suppliers(supplier_id),
    product_id  INT REFERENCES products(product_id),
    unit_cost   NUMERIC(10,2),
    lead_days   INT DEFAULT 7,
    UNIQUE(supplier_id, product_id)
);

CREATE TABLE IF NOT EXISTS invoices (
    invoice_id   SERIAL PRIMARY KEY,
    order_id     INT REFERENCES orders(order_id),
    invoice_date DATE NOT NULL,
    due_date     DATE NOT NULL,
    amount       NUMERIC(12,2),
    status       VARCHAR(20) DEFAULT 'UNPAID' CHECK (status IN ('PAID','UNPAID','OVERDUE'))
);

CREATE TABLE IF NOT EXISTS leave_requests (
    leave_id    SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    leave_type  VARCHAR(20) CHECK (leave_type IN ('SICK','CASUAL','EARNED','MATERNITY','PATERNITY')),
    from_date   DATE NOT NULL,
    to_date     DATE NOT NULL,
    days        INT,
    reason      VARCHAR(255),
    status      VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED'))
);

-- ============================================================
-- Seed Data
-- ============================================================

-- ── Customers (50) ─────────────────────────────────────────
INSERT INTO customers (customer_name, city, status, email, phone, created_at) VALUES
('Rahul Sharma',       'Bangalore',        'ACTIVE',   'rahul.sharma@gmail.com',       '9876543210', '2023-01-05'),
('Priya Singh',        'Mumbai',           'ACTIVE',   'priya.singh@gmail.com',         '9876543211', '2023-01-12'),
('Arjun Nair',         'Bangalore',        'ACTIVE',   'arjun.nair@gmail.com',          '9876543212', '2023-01-18'),
('Sneha Reddy',        'Hyderabad',        'INACTIVE', 'sneha.reddy@gmail.com',         '9876543213', '2023-02-03'),
('Vikram Patel',       'Ahmedabad',        'ACTIVE',   'vikram.patel@gmail.com',        '9876543214', '2023-02-10'),
('Anjali Kumar',       'Delhi',            'ACTIVE',   'anjali.kumar@gmail.com',        '9876543215', '2023-02-20'),
('Rohan Mehta',        'Pune',             'INACTIVE', 'rohan.mehta@gmail.com',         '9876543216', '2023-03-01'),
('Deepa Iyer',         'Chennai',          'ACTIVE',   'deepa.iyer@gmail.com',          '9876543217', '2023-03-08'),
('Karan Malhotra',     'Bangalore',        'ACTIVE',   'karan.malhotra@gmail.com',      '9876543218', '2023-03-15'),
('Neha Gupta',         'Mumbai',           'ACTIVE',   'neha.gupta@gmail.com',          '9876543219', '2023-03-22'),
('Sanjay Verma',       'Delhi',            'ACTIVE',   'sanjay.verma@gmail.com',        '9811223344', '2023-04-02'),
('Pooja Desai',        'Pune',             'ACTIVE',   'pooja.desai@gmail.com',         '9822334455', '2023-04-10'),
('Amit Kapoor',        'Jaipur',           'ACTIVE',   'amit.kapoor@gmail.com',         '9833445566', '2023-04-18'),
('Divya Rao',          'Hyderabad',        'ACTIVE',   'divya.rao@gmail.com',           '9844556677', '2023-05-01'),
('Nikhil Sharma',      'Mumbai',           'ACTIVE',   'nikhil.sharma@gmail.com',       '9855667788', '2023-05-10'),
('Rekha Pillai',       'Chennai',          'ACTIVE',   'rekha.pillai@gmail.com',        '9866778899', '2023-05-18'),
('Suresh Babu',        'Bangalore',        'ACTIVE',   'suresh.babu@gmail.com',         '9877889900', '2023-06-01'),
('Preeti Singh',       'Delhi',            'ACTIVE',   'preeti.singh@gmail.com',        '9888990011', '2023-06-10'),
('Gaurav Mehta',       'Kolkata',          'ACTIVE',   'gaurav.mehta@gmail.com',        '9899001122', '2023-06-20'),
('Lakshmi Nair',       'Kochi',            'ACTIVE',   'lakshmi.nair@gmail.com',        '9800112233', '2023-07-01'),
('Sachin Tiwari',      'Lucknow',          'ACTIVE',   'sachin.tiwari@gmail.com',       '9812345678', '2023-07-10'),
('Smita Joshi',        'Nagpur',           'INACTIVE', 'smita.joshi@gmail.com',         '9823456789', '2023-07-18'),
('Vivek Agarwal',      'Surat',            'ACTIVE',   'vivek.agarwal@gmail.com',       '9834567890', '2023-08-01'),
('Swati Mishra',       'Bhopal',           'ACTIVE',   'swati.mishra@gmail.com',        '9845678901', '2023-08-12'),
('Deepak Banerjee',    'Kolkata',          'ACTIVE',   'deepak.banerjee@gmail.com',     '9856789012', '2023-08-22'),
('Meenal Pandey',      'Delhi',            'ACTIVE',   'meenal.pandey@gmail.com',       '9867890123', '2023-09-01'),
('Harish Kumar',       'Bangalore',        'ACTIVE',   'harish.kumar@gmail.com',        '9878901234', '2023-09-10'),
('Shruti Chauhan',     'Mumbai',           'ACTIVE',   'shruti.chauhan@gmail.com',      '9889012345', '2023-09-20'),
('Varun Srivastava',   'Hyderabad',        'ACTIVE',   'varun.srivastava@gmail.com',    '9890123456', '2023-10-01'),
('Ananya Saxena',      'Pune',             'ACTIVE',   'ananya.saxena@gmail.com',       '9801234567', '2023-10-10'),
('Rajesh Khanna',      'Delhi',            'ACTIVE',   'rajesh.khanna@gmail.com',       '9813579246', '2023-10-20'),
('Jyoti Chaturvedi',   'Jaipur',           'ACTIVE',   'jyoti.chaturvedi@gmail.com',    '9824680135', '2023-11-01'),
('Kunal Bose',         'Kolkata',          'ACTIVE',   'kunal.bose@gmail.com',          '9835791246', '2023-11-10'),
('Ramya Menon',        'Kochi',            'ACTIVE',   'ramya.menon@gmail.com',         '9846802357', '2023-11-18'),
('Abhishek Gupta',     'Bangalore',        'ACTIVE',   'abhishek.gupta@gmail.com',      '9857913468', '2023-12-01'),
('Pallavi Singh',      'Chennai',          'ACTIVE',   'pallavi.singh@gmail.com',       '9868024579', '2023-12-10'),
('Mohit Sharma',       'Hyderabad',        'INACTIVE', 'mohit.sharma@gmail.com',        '9879135680', '2023-12-18'),
('Shalini Reddy',      'Hyderabad',        'ACTIVE',   'shalini.reddy@gmail.com',       '9880246791', '2024-01-05'),
('Tarun Verma',        'Delhi',            'ACTIVE',   'tarun.verma@gmail.com',         '9891357802', '2024-01-15'),
('Nisha Patel',        'Ahmedabad',        'ACTIVE',   'nisha.patel@gmail.com',         '9802468913', '2024-01-25'),
('Ravi Chandra',       'Bangalore',        'ACTIVE',   'ravi.chandra@gmail.com',        '9814579024', '2024-02-05'),
('Yamini Iyer',        'Chennai',          'ACTIVE',   'yamini.iyer@gmail.com',         '9825680135', '2024-02-15'),
('Siddharth Mehta',    'Mumbai',           'ACTIVE',   'siddharth.mehta@gmail.com',     '9836791246', '2024-02-25'),
('Geeta Kapoor',       'Delhi',            'ACTIVE',   'geeta.kapoor@gmail.com',        '9847802357', '2024-03-05'),
('Ajay Malhotra',      'Chandigarh',       'ACTIVE',   'ajay.malhotra@gmail.com',       '9858913468', '2024-03-15'),
('Madhuri Pillai',     'Kochi',            'ACTIVE',   'madhuri.pillai@gmail.com',      '9869024579', '2024-03-25'),
('Mukesh Joshi',       'Indore',           'ACTIVE',   'mukesh.joshi@gmail.com',        '9870135680', '2024-04-05'),
('Usha Verma',         'Coimbatore',       'ACTIVE',   'usha.verma@gmail.com',          '9881246791', '2024-04-15'),
('Shyam Desai',        'Visakhapatnam',    'ACTIVE',   'shyam.desai@gmail.com',         '9892357802', '2024-04-25'),
('Archana Nair',       'Mysuru',           'ACTIVE',   'archana.nair@gmail.com',        '9803468913', '2024-05-05')
ON CONFLICT DO NOTHING;

-- ── Employees (35) ─────────────────────────────────────────
INSERT INTO employees (employee_name, department, designation, salary, joining_date, status) VALUES
-- Engineering (12)
('Nitin Gupta',        'Engineering', 'Principal Engineer',    140000, '2021-07-05', 'ACTIVE'),
('Sunita Rao',         'Engineering', 'Tech Lead',             115000, '2022-09-14', 'ACTIVE'),
('Suresh Babu',        'Engineering', 'Senior Developer',       92000, '2022-11-20', 'ACTIVE'),
('Kiran Rao',          'Engineering', 'Senior Developer',       90000, '2022-12-10', 'ACTIVE'),
('Manoj Tiwari',       'Engineering', 'Engineering Manager',   130000, '2022-06-30', 'ACTIVE'),
('Shalini Joshi',      'Engineering', 'Data Engineer',          98000, '2023-02-14', 'ACTIVE'),
('Amit Verma',         'Engineering', 'Junior Developer',       75000, '2023-01-15', 'ACTIVE'),
('Praveen Kumar',      'Engineering', 'DevOps Engineer',        95000, '2023-05-12', 'ACTIVE'),
('Anita Sharma',       'Engineering', 'QA Engineer',            72000, '2023-08-20', 'ACTIVE'),
('Ritu Sharma',        'Engineering', 'Senior Developer',       88000, '2024-01-08', 'ACTIVE'),
('Preethi Nair',       'Engineering', 'QA Engineer',            75000, '2024-02-20', 'ACTIVE'),
('Rohan Das',          'Engineering', 'Junior Developer',       68000, '2024-03-01', 'ACTIVE'),
-- HR (4)
('Pooja Desai',        'HR',          'HR Manager',             75000, '2023-03-10', 'ACTIVE'),
('Rajan Nair',         'HR',          'HR Business Partner',    70000, '2023-01-25', 'ACTIVE'),
('Meghna Pillai',      'HR',          'Talent Acquisition Specialist', 60000, '2023-07-18', 'ACTIVE'),
('Anil Chandra',       'HR',          'HR Executive',           52000, '2024-04-22', 'ACTIVE'),
-- Marketing (5)
('Karthik Rajan',      'Marketing',   'Brand Manager',          90000, '2022-08-14', 'ACTIVE'),
('Meera Pillai',       'Marketing',   'Marketing Manager',      80000, '2024-02-01', 'ACTIVE'),
('Suraj Sharma',       'Marketing',   'Content Strategist',     62000, '2023-09-15', 'ACTIVE'),
('Priya Kapoor',       'Marketing',   'SEO Specialist',         55000, '2023-11-01', 'ACTIVE'),
('Kavya Menon',        'Marketing',   'Marketing Executive',    58000, '2024-05-10', 'ACTIVE'),
-- Finance (4)
('Ananya Sinha',       'Finance',     'Senior Finance Analyst', 85000, '2022-10-20', 'ACTIVE'),
('Rajesh Kumar',       'Finance',     'Finance Manager',       100000, '2023-07-05', 'ACTIVE'),
('Dinesh Joshi',       'Finance',     'Finance Analyst',        72000, '2023-12-01', 'ACTIVE'),
('Mohit Agarwal',      'Finance',     'Finance Analyst',        68000, '2024-06-01', 'ACTIVE'),
-- Sales (5)
('Ashish Mehta',       'Sales',       'Regional Sales Manager', 115000, '2021-12-15', 'ACTIVE'),
('Vivek Singh',        'Sales',       'Sales Manager',          95000, '2022-11-05', 'ACTIVE'),
('Deepak Verma',       'Sales',       'Senior Sales Executive',  72000, '2023-04-20', 'ACTIVE'),
('Neetha Krishnan',    'Sales',       'Sales Executive',         55000, '2023-08-10', 'ACTIVE'),
('Shruti Rao',         'Sales',       'Sales Executive',         52000, '2024-07-01', 'ACTIVE'),
-- Operations (3)
('Vikas Sharma',       'Operations',  'Operations Manager',     88000, '2022-04-10', 'ACTIVE'),
('Shilpa Gupta',       'Operations',  'Operations Executive',   58000, '2023-06-25', 'ACTIVE'),
('Gopal Das',          'Operations',  'Supply Chain Analyst',   70000, '2023-03-08', 'ACTIVE'),
-- Customer Support (2)
('Rekha Menon',        'Customer Support', 'Support Lead',      62000, '2023-02-28', 'ACTIVE'),
('Arjun Nambiar',      'Customer Support', 'Customer Success Manager', 78000, '2022-07-19', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- ── Products (30) ──────────────────────────────────────────
INSERT INTO products (product_name, category, price, stock) VALUES
-- Electronics
('Laptop Pro 15',         'Electronics',  85000,  42),
('Laptop Air 13',         'Electronics',  65000,  38),
('Wireless Mouse',        'Electronics',   1200, 185),
('Gaming Mouse',          'Electronics',   2500, 120),
('Mechanical Keyboard',   'Electronics',   3500, 140),
('Wireless Keyboard',     'Electronics',   1800, 160),
('USB-C Hub 7-in-1',      'Electronics',   2200, 175),
('Monitor 27" FHD',       'Electronics',  22000,  28),
('Monitor 32" 4K',        'Electronics',  45000,  18),
('Headphones BT Pro',     'Electronics',   4500,  72),
('TWS Earbuds',           'Electronics',   2800,  95),
('Webcam HD 1080p',       'Electronics',   3200,  85),
('External SSD 1TB',      'Electronics',   8500,  60),
('Pen Drive 128GB',       'Electronics',    850, 300),
('Smartphone X12',        'Electronics',  55000,  25),
('Tablet Pro 10"',        'Electronics',  40000,  20),
-- Furniture
('Ergonomic Chair',       'Furniture',    18000,  22),
('Office Chair Standard', 'Furniture',    12000,  35),
('Standing Desk',         'Furniture',    35000,  12),
('Conference Table',      'Furniture',    55000,   6),
('Storage Cabinet',       'Furniture',     8000,  18),
-- Stationery
('Notebook Pack (5)',     'Stationery',     250, 480),
('Premium Pen Set',       'Stationery',     120, 750),
('Whiteboard A0',         'Stationery',    3500,  30),
('Marker Set (12)',       'Stationery',     350, 420),
('File Organizer',        'Stationery',     480, 310),
-- Networking
('WiFi Router AC1200',    'Networking',    4200,  55),
('Network Switch 24-Port','Networking',   12000,  14),
('Ethernet Cable Box',    'Networking',    1500,  80),
('Patch Panel 24-Port',   'Networking',    5500,  20)
ON CONFLICT DO NOTHING;

-- ── Orders (120) ───────────────────────────────────────────
INSERT INTO orders (customer_id, product_id, amount, order_date, status) VALUES
-- 2023 Q1
(1,  1,  85000, '2023-01-10', 'COMPLETED'),
(2,  3,   1200, '2023-01-15', 'COMPLETED'),
(3,  8,  22000, '2023-01-22', 'COMPLETED'),
(5,  5,   3500, '2023-01-28', 'COMPLETED'),
(6, 10,   4500, '2023-02-03', 'COMPLETED'),
(8, 17,  18000, '2023-02-08', 'COMPLETED'),
(4, 22,    250, '2023-02-14', 'CANCELLED'),
(9,  2,  65000, '2023-02-20', 'COMPLETED'),
(10, 7,   2200, '2023-02-25', 'COMPLETED'),
(11, 4,   2500, '2023-03-01', 'COMPLETED'),
(12,18,  12000, '2023-03-05', 'COMPLETED'),
(13, 6,   1800, '2023-03-10', 'COMPLETED'),
(14,27,   4200, '2023-03-15', 'COMPLETED'),
(15,13,   8500, '2023-03-20', 'COMPLETED'),
(1, 19,  35000, '2023-03-25', 'COMPLETED'),
-- 2023 Q2
(16,11,   2800, '2023-04-02', 'COMPLETED'),
(17, 1,  85000, '2023-04-07', 'COMPLETED'),
(18,23,    120, '2023-04-12', 'COMPLETED'),
(19,12,   3200, '2023-04-18', 'COMPLETED'),
(20,15,  55000, '2023-04-22', 'COMPLETED'),
(2, 9,  45000, '2023-04-28', 'COMPLETED'),
(21, 5,  3500, '2023-05-03', 'COMPLETED'),
(22,18,  12000, '2023-05-08', 'CANCELLED'),
(23,14,    850, '2023-05-12', 'COMPLETED'),
(24,16,  40000, '2023-05-18', 'COMPLETED'),
(25, 7,   2200, '2023-05-22', 'COMPLETED'),
(26,29,   1500, '2023-05-28', 'COMPLETED'),
(27,10,   4500, '2023-06-02', 'COMPLETED'),
(28, 2,  65000, '2023-06-08', 'COMPLETED'),
(29,21,   8000, '2023-06-14', 'COMPLETED'),
(30, 6,   1800, '2023-06-20', 'COMPLETED'),
-- 2023 Q3
(31, 1,  85000, '2023-07-03', 'COMPLETED'),
(3, 8,  22000, '2023-07-08', 'COMPLETED'),
(32,17,  18000, '2023-07-12', 'COMPLETED'),
(33,28,  12000, '2023-07-18', 'COMPLETED'),
(34,13,   8500, '2023-07-22', 'COMPLETED'),
(35, 4,   2500, '2023-07-28', 'COMPLETED'),
(36, 3,   1200, '2023-08-02', 'COMPLETED'),
(6,  9,  45000, '2023-08-07', 'COMPLETED'),
(37,22,    250, '2023-08-12', 'CANCELLED'),
(38,11,   2800, '2023-08-18', 'COMPLETED'),
(39,15,  55000, '2023-08-22', 'COMPLETED'),
(40,20,  55000, '2023-08-28', 'COMPLETED'),
(41,14,    850, '2023-09-03', 'COMPLETED'),
(42, 7,   2200, '2023-09-08', 'COMPLETED'),
(43,16,  40000, '2023-09-14', 'COMPLETED'),
(44, 5,   3500, '2023-09-18', 'COMPLETED'),
(45,27,   4200, '2023-09-24', 'COMPLETED'),
-- 2023 Q4
(1, 10,   4500, '2023-10-02', 'COMPLETED'),
(2, 12,   3200, '2023-10-07', 'COMPLETED'),
(46,19,  35000, '2023-10-12', 'COMPLETED'),
(47,21,   8000, '2023-10-18', 'COMPLETED'),
(48, 6,   1800, '2023-10-22', 'COMPLETED'),
(9, 2,   65000, '2023-10-28', 'COMPLETED'),
(49,23,    120, '2023-11-02', 'COMPLETED'),
(50, 4,   2500, '2023-11-07', 'COMPLETED'),
(11,29,   1500, '2023-11-12', 'COMPLETED'),
(12,13,   8500, '2023-11-18', 'COMPLETED'),
(13, 8,  22000, '2023-11-22', 'COMPLETED'),
(14, 1,  85000, '2023-11-28', 'COMPLETED'),
(15,18,  12000, '2023-12-03', 'COMPLETED'),
(16,11,   2800, '2023-12-08', 'COMPLETED'),
(17,30,   5500, '2023-12-12', 'COMPLETED'),
(18, 7,   2200, '2023-12-18', 'COMPLETED'),
(19, 3,   1200, '2023-12-22', 'COMPLETED'),
(20,16,  40000, '2023-12-28', 'COMPLETED'),
-- 2024 Q1
(21, 2,  65000, '2024-01-04', 'COMPLETED'),
(22,17,  18000, '2024-01-09', 'COMPLETED'),
(23, 9,  45000, '2024-01-14', 'COMPLETED'),
(24,14,    850, '2024-01-18', 'COMPLETED'),
(25, 5,   3500, '2024-01-24', 'COMPLETED'),
(26,20,  55000, '2024-01-28', 'COMPLETED'),
(27,10,   4500, '2024-02-03', 'COMPLETED'),
(28,22,    250, '2024-02-07', 'COMPLETED'),
(29,15,  55000, '2024-02-12', 'COMPLETED'),
(30, 8,  22000, '2024-02-18', 'COMPLETED'),
(31,27,   4200, '2024-02-22', 'COMPLETED'),
(32, 6,   1800, '2024-02-27', 'COMPLETED'),
(33, 1,  85000, '2024-03-04', 'COMPLETED'),
(34,12,   3200, '2024-03-08', 'COMPLETED'),
(35,21,   8000, '2024-03-14', 'COMPLETED'),
(36,13,   8500, '2024-03-18', 'COMPLETED'),
(37,29,   1500, '2024-03-22', 'CANCELLED'),
(38, 4,   2500, '2024-03-28', 'COMPLETED'),
-- 2024 Q2
(39, 2,  65000, '2024-04-03', 'COMPLETED'),
(40,11,   2800, '2024-04-08', 'COMPLETED'),
(41,19,  35000, '2024-04-12', 'COMPLETED'),
(42, 7,   2200, '2024-04-18', 'COMPLETED'),
(43,16,  40000, '2024-04-22', 'COMPLETED'),
(44, 3,   1200, '2024-04-28', 'COMPLETED'),
(45, 9,  45000, '2024-05-03', 'COMPLETED'),
(46, 5,   3500, '2024-05-08', 'COMPLETED'),
(47,28,  12000, '2024-05-14', 'COMPLETED'),
(48,14,    850, '2024-05-18', 'COMPLETED'),
(49,10,   4500, '2024-05-22', 'COMPLETED'),
(50, 1,  85000, '2024-05-28', 'COMPLETED'),
(1, 17,  18000, '2024-06-03', 'COMPLETED'),
(2, 12,   3200, '2024-06-08', 'COMPLETED'),
(3, 20,  55000, '2024-06-14', 'COMPLETED'),
(4, 30,   5500, '2024-06-18', 'CANCELLED'),
-- 2024 Q3–Q4
(5,  2,  65000, '2024-07-02', 'COMPLETED'),
(6, 11,   2800, '2024-07-08', 'COMPLETED'),
(7,  8,  22000, '2024-07-14', 'COMPLETED'),
(8,  4,   2500, '2024-07-20', 'COMPLETED'),
(9, 19,  35000, '2024-08-03', 'COMPLETED'),
(10,27,   4200, '2024-08-10', 'COMPLETED'),
(11, 9,  45000, '2024-09-05', 'COMPLETED'),
(12, 3,   1200, '2024-09-15', 'COMPLETED'),
(13,15,  55000, '2024-10-08', 'COMPLETED'),
(14, 7,   2200, '2024-10-20', 'COMPLETED'),
(15,13,   8500, '2024-11-05', 'COMPLETED'),
(16, 6,   1800, '2024-11-18', 'COMPLETED'),
(17,16,  40000, '2024-12-03', 'COMPLETED'),
(18, 1,  85000, '2024-12-15', 'COMPLETED'),
-- 2025 (recent — PENDING)
(19, 2,  65000, '2025-01-10', 'COMPLETED'),
(20, 5,   3500, '2025-01-20', 'COMPLETED'),
(21,11,   2800, '2025-02-05', 'PENDING'),
(22,17,  18000, '2025-02-15', 'PENDING'),
(23, 9,  45000, '2025-03-01', 'PENDING'),
(24,14,    850, '2025-03-10', 'COMPLETED'),
(25,28,  12000, '2025-03-20', 'PENDING'),
(26, 4,   2500, '2025-04-01', 'PENDING'),
(27, 7,   2200, '2025-04-10', 'PENDING')
ON CONFLICT DO NOTHING;

-- ── Departments (8) ────────────────────────────────────────
INSERT INTO departments (department_name, head_name, budget, location, employee_count) VALUES
('Engineering',       'Nitin Gupta',    12000000, 'Bangalore', 12),
('HR',                'Pooja Desai',     3000000, 'Delhi',      4),
('Marketing',         'Karthik Rajan',   5000000, 'Mumbai',     5),
('Finance',           'Rajesh Kumar',    4500000, 'Delhi',      4),
('Sales',             'Ashish Mehta',    8000000, 'Pan India',  5),
('Operations',        'Vikas Sharma',    6000000, 'Bangalore',  3),
('Customer Support',  'Arjun Nambiar',   2500000, 'Hyderabad',  2),
('Product Management','Saurabh Gupta',   4000000, 'Bangalore',  0)
ON CONFLICT DO NOTHING;

-- ── Suppliers (10) ─────────────────────────────────────────
INSERT INTO suppliers (supplier_name, contact_person, email, phone, city, status) VALUES
('TechWorld Electronics',  'Ramesh Iyer',     'ramesh@techworld.in',     '8011223344', 'Bangalore', 'ACTIVE'),
('OfficeZone Supplies',    'Kavitha Reddy',   'kavitha@officezone.in',   '8022334455', 'Delhi',     'ACTIVE'),
('FurniturePlus India',    'Sunil Sharma',    'sunil@furnitureplus.in',  '8033445566', 'Pune',      'ACTIVE'),
('NetConnect Solutions',   'Pradeep Nair',    'pradeep@netconnect.in',   '8044556677', 'Hyderabad', 'ACTIVE'),
('StatioMart',             'Anita Desai',     'anita@statiomartindia.in','8055667788', 'Mumbai',    'ACTIVE'),
('GadgetHub Pvt Ltd',      'Vikram Menon',    'vikram@gadgethub.in',     '8066778899', 'Bangalore', 'ACTIVE'),
('CloudTech Hardware',     'Deepa Krishnan',  'deepa@cloudtech.in',      '8077889900', 'Chennai',   'ACTIVE'),
('PrimeDesk Interiors',    'Mohan Pillai',    'mohan@primedesk.in',      '8088990011', 'Kolkata',   'ACTIVE'),
('QuickStock Stationery',  'Sneha Agarwal',   'sneha@quickstock.in',     '8099001122', 'Jaipur',    'INACTIVE'),
('ByteSource Systems',     'Arjun Verma',     'arjun@bytesource.in',     '8000112233', 'Bangalore', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- ── Supplier-Products (25) ─────────────────────────────────
INSERT INTO supplier_products (supplier_id, product_id, unit_cost, lead_days) VALUES
-- TechWorld: Laptops, Monitors
(1,  1,  68000, 5),
(1,  2,  50000, 5),
(1,  8,  17000, 7),
(1,  9,  36000, 7),
-- OfficeZone: Stationery
(2, 22,    180, 3),
(2, 23,     80, 3),
(2, 26,    340, 4),
(2, 25,    240, 4),
-- FurniturePlus: Chairs, Desks
(3, 17,  13500, 10),
(3, 18,   9000, 10),
(3, 19,  27000, 14),
(3, 21,   6000, 10),
-- NetConnect: Networking
(4, 27,   3100, 5),
(4, 28,   9500, 7),
(4, 29,   1100, 3),
(4, 30,   4200, 5),
-- GadgetHub: Peripherals
(6,  3,    800, 4),
(6,  4,   1800, 4),
(6, 12,   2400, 5),
(6, 11,   2000, 5),
-- CloudTech: Storage, Laptops
(7,  2,  51000, 6),
(7, 13,   6500, 5),
(7, 14,    600, 3),
-- ByteSource: Accessories
(10, 7,   1600, 4),
(10,10,   3400, 5)
ON CONFLICT DO NOTHING;

-- ── Invoices (90) — generated for COMPLETED and PENDING orders ─
INSERT INTO invoices (order_id, invoice_date, due_date, amount, status) VALUES
(1,  '2023-01-10', '2023-01-25',  85000, 'PAID'),
(2,  '2023-01-15', '2023-01-30',   1200, 'PAID'),
(3,  '2023-01-22', '2023-02-06',  22000, 'PAID'),
(4,  '2023-01-28', '2023-02-12',   3500, 'PAID'),
(5,  '2023-02-03', '2023-02-18',   4500, 'PAID'),
(6,  '2023-02-08', '2023-02-23',  18000, 'PAID'),
(8,  '2023-02-20', '2023-03-07',  65000, 'PAID'),
(9,  '2023-02-25', '2023-03-12',   2200, 'PAID'),
(10, '2023-03-01', '2023-03-16',   2500, 'PAID'),
(11, '2023-03-05', '2023-03-20',  12000, 'PAID'),
(12, '2023-03-10', '2023-03-25',   1800, 'PAID'),
(13, '2023-03-15', '2023-03-30',   4200, 'PAID'),
(14, '2023-03-20', '2023-04-04',   8500, 'PAID'),
(15, '2023-03-25', '2023-04-09',  35000, 'PAID'),
(16, '2023-04-02', '2023-04-17',   2800, 'PAID'),
(17, '2023-04-07', '2023-04-22',  85000, 'PAID'),
(18, '2023-04-12', '2023-04-27',    120, 'PAID'),
(19, '2023-04-18', '2023-05-03',   3200, 'PAID'),
(20, '2023-04-22', '2023-05-07',  55000, 'PAID'),
(21, '2023-04-28', '2023-05-13',  45000, 'PAID'),
(22, '2023-05-03', '2023-05-18',   3500, 'PAID'),
(24, '2023-05-12', '2023-05-27',    850, 'PAID'),
(25, '2023-05-18', '2023-06-02',  40000, 'PAID'),
(26, '2023-05-22', '2023-06-06',   2200, 'PAID'),
(27, '2023-05-28', '2023-06-12',   1500, 'PAID'),
(28, '2023-06-02', '2023-06-17',   4500, 'PAID'),
(29, '2023-06-08', '2023-06-23',  65000, 'PAID'),
(30, '2023-06-14', '2023-06-29',   8000, 'PAID'),
(31, '2023-06-20', '2023-07-05',   1800, 'PAID'),
(32, '2023-07-03', '2023-07-18',  85000, 'PAID'),
(33, '2023-07-08', '2023-07-23',  22000, 'PAID'),
(34, '2023-07-12', '2023-07-27',  18000, 'PAID'),
(35, '2023-07-18', '2023-08-02',  12000, 'PAID'),
(36, '2023-07-22', '2023-08-06',   8500, 'PAID'),
(37, '2023-07-28', '2023-08-12',   2500, 'PAID'),
(38, '2023-08-02', '2023-08-17',   1200, 'PAID'),
(39, '2023-08-07', '2023-08-22',  45000, 'PAID'),
(41, '2023-08-18', '2023-09-02',   2800, 'PAID'),
(42, '2023-08-22', '2023-09-06',  55000, 'PAID'),
(43, '2023-08-28', '2023-09-12',  55000, 'PAID'),
(44, '2023-09-03', '2023-09-18',    850, 'PAID'),
(45, '2023-09-08', '2023-09-23',   2200, 'PAID'),
(46, '2023-09-14', '2023-09-29',  40000, 'PAID'),
(47, '2023-09-18', '2023-10-03',   3500, 'PAID'),
(48, '2023-09-24', '2023-10-09',   4200, 'PAID'),
(49, '2023-10-02', '2023-10-17',   4500, 'PAID'),
(50, '2023-10-07', '2023-10-22',   3200, 'PAID'),
(51, '2023-10-12', '2023-10-27',  35000, 'PAID'),
(52, '2023-10-18', '2023-11-02',   8000, 'PAID'),
(53, '2023-10-22', '2023-11-06',   1800, 'PAID'),
(54, '2023-10-28', '2023-11-12',  65000, 'PAID'),
(55, '2023-11-02', '2023-11-17',    120, 'PAID'),
(56, '2023-11-07', '2023-11-22',   2500, 'PAID'),
(57, '2023-11-12', '2023-11-27',   1500, 'PAID'),
(58, '2023-11-18', '2023-12-03',   8500, 'PAID'),
(59, '2023-11-22', '2023-12-07',  22000, 'PAID'),
(60, '2023-11-28', '2023-12-13',  85000, 'PAID'),
(61, '2023-12-03', '2023-12-18',  12000, 'PAID'),
(62, '2023-12-08', '2023-12-23',   2800, 'PAID'),
(63, '2023-12-12', '2023-12-27',   5500, 'PAID'),
(64, '2023-12-18', '2024-01-02',   2200, 'PAID'),
(65, '2023-12-22', '2024-01-06',   1200, 'PAID'),
(66, '2023-12-28', '2024-01-12',  40000, 'PAID'),
(67, '2024-01-04', '2024-01-19',  65000, 'PAID'),
(68, '2024-01-09', '2024-01-24',  18000, 'PAID'),
(69, '2024-01-14', '2024-01-29',  45000, 'PAID'),
(70, '2024-01-18', '2024-02-02',    850, 'PAID'),
(71, '2024-01-24', '2024-02-08',   3500, 'PAID'),
(72, '2024-01-28', '2024-02-12',  55000, 'PAID'),
(73, '2024-02-03', '2024-02-18',   4500, 'PAID'),
(74, '2024-02-07', '2024-02-22',    250, 'PAID'),
(75, '2024-02-12', '2024-02-27',  55000, 'PAID'),
(76, '2024-02-18', '2024-03-04',  22000, 'PAID'),
(77, '2024-02-22', '2024-03-08',   4200, 'PAID'),
(78, '2024-02-27', '2024-03-13',   1800, 'PAID'),
(79, '2024-03-04', '2024-03-19',  85000, 'PAID'),
(80, '2024-03-08', '2024-03-23',   3200, 'PAID'),
(81, '2024-03-14', '2024-03-29',   8000, 'PAID'),
(82, '2024-03-18', '2024-04-02',   8500, 'PAID'),
(84, '2024-03-28', '2024-04-12',   2500, 'PAID'),
(85, '2024-04-03', '2024-04-18',  65000, 'PAID'),
(86, '2024-04-08', '2024-04-23',   2800, 'PAID'),
(87, '2024-04-12', '2024-04-27',  35000, 'PAID'),
(88, '2024-04-18', '2024-05-03',   2200, 'PAID'),
(89, '2024-04-22', '2024-05-07',  40000, 'PAID'),
(90, '2024-04-28', '2024-05-13',   1200, 'PAID'),
-- 2025 pending orders get UNPAID/OVERDUE invoices
(113,'2025-01-10','2025-01-25',  65000, 'PAID'),
(114,'2025-01-20','2025-02-04',   3500, 'PAID'),
(115,'2025-02-05','2025-02-20',   2800, 'OVERDUE'),
(116,'2025-02-15','2025-03-02',  18000, 'OVERDUE'),
(117,'2025-03-01','2025-03-16',  45000, 'UNPAID'),
(118,'2025-03-10','2025-03-25',    850, 'PAID'),
(119,'2025-03-20','2025-04-04',  12000, 'UNPAID'),
(120,'2025-04-01','2025-04-16',   2500, 'UNPAID'),
(121,'2025-04-10','2025-04-25',   2200, 'UNPAID')
ON CONFLICT DO NOTHING;

-- ── Leave Requests (45) ────────────────────────────────────
INSERT INTO leave_requests (employee_id, leave_type, from_date, to_date, days, reason, status) VALUES
(7,  'SICK',       '2023-02-06', '2023-02-07', 2,  'Fever and cold',                        'APPROVED'),
(13, 'CASUAL',     '2023-02-15', '2023-02-15', 1,  'Personal work',                          'APPROVED'),
(3,  'EARNED',     '2023-03-01', '2023-03-05', 5,  'Family vacation',                        'APPROVED'),
(16, 'CASUAL',     '2023-03-20', '2023-03-21', 2,  'Attend a wedding',                       'APPROVED'),
(22, 'SICK',       '2023-04-10', '2023-04-11', 2,  'Stomach infection',                      'APPROVED'),
(5,  'EARNED',     '2023-04-24', '2023-04-28', 5,  'Planned leave — Diwali travel',          'APPROVED'),
(9,  'CASUAL',     '2023-05-08', '2023-05-08', 1,  'Bank work',                              'APPROVED'),
(19, 'SICK',       '2023-05-22', '2023-05-24', 3,  'Viral fever',                            'APPROVED'),
(2,  'EARNED',     '2023-06-05', '2023-06-09', 5,  'Anniversary trip',                       'APPROVED'),
(26, 'CASUAL',     '2023-06-19', '2023-06-19', 1,  'Vehicle registration',                   'APPROVED'),
(11, 'SICK',       '2023-07-03', '2023-07-04', 2,  'Back pain',                              'APPROVED'),
(14, 'EARNED',     '2023-07-17', '2023-07-21', 5,  'Home town visit',                        'APPROVED'),
(8,  'CASUAL',     '2023-08-01', '2023-08-02', 2,  'House shifting',                         'APPROVED'),
(28, 'SICK',       '2023-08-14', '2023-08-15', 2,  'Food poisoning',                         'APPROVED'),
(1,  'EARNED',     '2023-08-28', '2023-09-01', 5,  'Onam vacation',                          'APPROVED'),
(31, 'CASUAL',     '2023-09-12', '2023-09-12', 1,  'Child school admission',                 'APPROVED'),
(6,  'SICK',       '2023-09-25', '2023-09-27', 3,  'Dengue — doctor advised rest',          'APPROVED'),
(20, 'EARNED',     '2023-10-09', '2023-10-13', 5,  'Navratri holiday — home visit',         'APPROVED'),
(34, 'CASUAL',     '2023-10-23', '2023-10-23', 1,  'Personal errand',                        'APPROVED'),
(10, 'SICK',       '2023-11-06', '2023-11-07', 2,  'Migraine',                               'APPROVED'),
(17, 'EARNED',     '2023-11-20', '2023-11-24', 5,  'Christmas vacation',                     'APPROVED'),
(23, 'CASUAL',     '2023-12-04', '2023-12-05', 2,  'Passport renewal',                       'APPROVED'),
(4,  'SICK',       '2023-12-18', '2023-12-19', 2,  'Flu symptoms',                           'APPROVED'),
(29, 'EARNED',     '2024-01-02', '2024-01-05', 4,  'New Year travel',                        'APPROVED'),
(12, 'MATERNITY',  '2024-01-15', '2024-04-14', 90, 'Maternity leave',                        'APPROVED'),
(15, 'CASUAL',     '2024-02-05', '2024-02-05', 1,  'Tax filing appointment',                 'APPROVED'),
(27, 'SICK',       '2024-02-19', '2024-02-21', 3,  'Knee injury',                            'APPROVED'),
(7,  'EARNED',     '2024-03-04', '2024-03-08', 5,  'Holi holiday — home visit',             'APPROVED'),
(21, 'CASUAL',     '2024-03-18', '2024-03-18', 1,  'Home repair work',                       'APPROVED'),
(32, 'SICK',       '2024-04-01', '2024-04-02', 2,  'Cold and cough',                         'APPROVED'),
(18, 'EARNED',     '2024-04-15', '2024-04-19', 5,  'Summer vacation',                        'APPROVED'),
(35, 'CASUAL',     '2024-05-06', '2024-05-07', 2,  'Sibling wedding',                        'APPROVED'),
(24, 'SICK',       '2024-05-20', '2024-05-21', 2,  'High temperature',                       'APPROVED'),
(3,  'EARNED',     '2024-06-03', '2024-06-07', 5,  'Annual family trip',                     'APPROVED'),
(30, 'CASUAL',     '2024-06-17', '2024-06-17', 1,  'Driving license renewal',                'APPROVED'),
(8,  'SICK',       '2024-07-01', '2024-07-03', 3,  'Typhoid — antibiotics prescribed',       'APPROVED'),
(13, 'EARNED',     '2024-07-15', '2024-07-19', 5,  'Independence Day week leave',            'APPROVED'),
(25, 'CASUAL',     '2024-08-05', '2024-08-06', 2,  'Property document work',                 'APPROVED'),
(1,  'SICK',       '2024-08-19', '2024-08-20', 2,  'Seasonal flu',                           'APPROVED'),
(33, 'EARNED',     '2024-09-02', '2024-09-06', 5,  'Ganesh Chaturthi — home town',          'APPROVED'),
(11, 'CASUAL',     '2024-09-23', '2024-09-23', 1,  'Bank KYC update',                        'APPROVED'),
(6,  'EARNED',     '2024-10-14', '2024-10-18', 5,  'Dussehra — Diwali vacation',            'APPROVED'),
(19, 'SICK',       '2024-11-04', '2024-11-05', 2,  'Throat infection',                       'APPROVED'),
(22, 'CASUAL',     '2025-01-13', '2025-01-13', 1,  'Government office work',                 'APPROVED'),
(9,  'EARNED',     '2025-02-17', '2025-02-21', 5,  'Family function',                        'PENDING'),
(14, 'SICK',       '2025-03-03', '2025-03-04', 2,  'Back spasm',                             'PENDING'),
(26, 'CASUAL',     '2025-04-07', '2025-04-08', 2,  'School admission for child',             'PENDING')
ON CONFLICT DO NOTHING;
