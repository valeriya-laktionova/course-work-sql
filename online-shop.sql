-- Таблица пользователей
CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    is_admin BOOLEAN DEFAULT FALSE
);

-- Таблица категорий
CREATE TABLE Categories (
    category_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Таблица товаров
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    category_id INT NOT NULL,
    brand VARCHAR(100),
    size VARCHAR(20),
    color VARCHAR(30),
    image_url TEXT,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- Таблица заказов
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'новый',
    total_price DECIMAL(10, 2),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Таблица позиций в заказе
CREATE TABLE OrderItems (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Таблица избранного
CREATE TABLE Wishlist (
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    created_at DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Таблица корзины
CREATE TABLE Cart (
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Таблица изменений остатков
CREATE TABLE InventoryChanges (
    change_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    change_amount INT NOT NULL,
    changed_by INT NOT NULL,
    change_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (changed_by) REFERENCES Users(user_id)
);

CREATE TABLE UserActions (
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    action_type VARCHAR(20) NOT NULL, 
    quantity INT,                     
    created_at DATE,                 
    PRIMARY KEY (user_id, product_id, action_type),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE users_tmp (
    user_id INT,
    full_name VARCHAR,
    email VARCHAR,
    password VARCHAR,
    phone VARCHAR,
    address TEXT,
    is_admin BOOLEAN
);

COPY users_tmp FROM '/Users/moramor/Documents/courseWork/users.csv' DELIMITER ',' CSV HEADER;


INSERT INTO Users (user_id, full_name, email, password, phone, address, is_admin)
SELECT t.user_id, t.full_name, t.email, t.password, t.phone, t.address, t.is_admin
FROM users_tmp t
WHERE NOT EXISTS (
    SELECT 1 FROM Users u WHERE u.user_id = t.user_id
);

CREATE TABLE categories_tmp (
    category_id INT,
    name VARCHAR
);

COPY categories_tmp FROM '/Users/moramor/Documents/courseWork/categories.csv' DELIMITER ',' CSV HEADER;

INSERT INTO Categories (category_id, name)
SELECT t.category_id, t.name
FROM categories_tmp t
WHERE NOT EXISTS (
    SELECT 1 FROM Categories c WHERE c.category_id = t.category_id
);

CREATE TABLE products_tmp (
    product_id INT,
    name VARCHAR(100),
    description TEXT,
    price DECIMAL(10,2),
    quantity INT,
    category_id INT,
    brand VARCHAR(100),
    size VARCHAR(30),
    color VARCHAR(30),
    image_url TEXT,
    change_id INT,
    change_amount INT,
    changed_by INT,
    change_date DATE
);

COPY products_tmp FROM '/Users/moramor/Documents/courseWork/products.csv' DELIMITER ',' CSV HEADER;

INSERT INTO Products (product_id, name, description, price, quantity, category_id, brand, size, color, image_url)
SELECT t.product_id, t.name, t.description, t.price, t.quantity, t.category_id, t.brand, t.size, t.color, t.image_url
FROM products_tmp t
WHERE NOT EXISTS (
    SELECT 1 FROM Products p WHERE p.product_id = t.product_id
);

INSERT INTO InventoryChanges (change_id, product_id, change_amount, changed_by, change_date)
SELECT t.change_id, t.product_id, t.change_amount, t.changed_by, t.change_date
FROM products_tmp t
WHERE t.change_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM InventoryChanges i WHERE i.change_id = t.change_id
);

CREATE TABLE orders_tmp (
    order_id INT,
    user_id INT,
    order_date DATE,
    status VARCHAR(50),
    total_price DECIMAL(10, 2),
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10, 2)
);


COPY orders_tmp(order_id, user_id, order_date, status, total_price, product_id, quantity, unit_price)
FROM '/Users/moramor/Documents/courseWork/orders.csv'
DELIMITER ',' CSV HEADER;

INSERT INTO Orders (order_id, user_id, order_date, status, total_price)
SELECT DISTINCT order_id, user_id, order_date, status, total_price
FROM orders_tmp
WHERE NOT EXISTS (
    SELECT 1 FROM Orders o WHERE o.order_id = orders_tmp.order_id
);

INSERT INTO OrderItems (order_id, product_id, quantity, unit_price)
SELECT order_id, product_id, quantity, unit_price
FROM orders_tmp
WHERE NOT EXISTS (
    SELECT 1 FROM OrderItems oi
    WHERE oi.order_id = orders_tmp.order_id
      AND oi.product_id = orders_tmp.product_id
)
AND product_id IN (
    SELECT product_id FROM Products
);

select * from OrderItems;

CREATE TABLE user_actions_tmp (
    user_id INT,
    product_id INT,
    action_type VARCHAR,
    quantity INT,
    created_at DATE
);

COPY user_actions_tmp FROM '/Users/moramor/Documents/courseWork/user_actions.csv' DELIMITER ',' CSV HEADER;

INSERT INTO UserActions (user_id, product_id, action_type, quantity, created_at)
SELECT t.user_id, t.product_id, t.action_type, t.quantity, t.created_at
FROM user_actions_tmp t
WHERE NOT EXISTS (
    SELECT 1 FROM UserActions ua
    WHERE ua.user_id = t.user_id AND ua.product_id = t.product_id AND ua.action_type = t.action_type
);

INSERT INTO Wishlist (user_id, product_id, created_at)
SELECT t.user_id, t.product_id, t.created_at
FROM user_actions_tmp t
WHERE t.action_type = 'wishlist'
AND NOT EXISTS (
    SELECT 1 FROM Wishlist w WHERE w.user_id = t.user_id AND w.product_id = t.product_id
);

INSERT INTO Cart (user_id, product_id, quantity)
SELECT t.user_id, t.product_id, t.quantity
FROM user_actions_tmp t
WHERE t.action_type = 'cart'
AND NOT EXISTS (
    SELECT 1 FROM Cart c WHERE c.user_id = t.user_id AND c.product_id = t.product_id
);


select * from dwh.Dim_Customer ;


-- Создание схемы для DWH
CREATE SCHEMA IF NOT EXISTS dwh;

-- Таблица Dim_Customer (SCD Type 2)
CREATE TABLE dwh.Dim_Customer (
    customer_sk SERIAL PRIMARY KEY,       
    customer_id INT NOT NULL,             
    full_name VARCHAR(100),
    email VARCHAR(100),
    address TEXT,
    phone VARCHAR(20),
    StartDate DATE NOT NULL,
    EndDate DATE,
    IsCurrent BOOLEAN DEFAULT TRUE
);

-- Таблица Dim_Product
CREATE TABLE dwh.Dim_Product (
    product_id INT PRIMARY KEY,           
    name VARCHAR(100),
    category VARCHAR(100),
    brand VARCHAR(100),
    size VARCHAR(20),
    color VARCHAR(30)
);

-- Таблица Dim_Time (генерируется вручную)
CREATE TABLE dwh.Dim_Time (
    time_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    day INT,
    month INT,
    quarter INT,
    year INT
);

-- Таблица Dim_Tag (ярлыки для фильтрации товаров)
CREATE TABLE dwh.Dim_Tag (
    tag_id SERIAL PRIMARY KEY,
    tag_name VARCHAR(100) NOT NULL UNIQUE
);

-- Таблица-мост Bridge_Product_Tags (товар ↔ тег)
CREATE TABLE dwh.Bridge_Product_Tags (
    product_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (product_id, tag_id),
    FOREIGN KEY (product_id) REFERENCES dwh.Dim_Product(product_id),
    FOREIGN KEY (tag_id) REFERENCES dwh.Dim_Tag(tag_id)
);

-- Фактовая таблица Fact_Sales (продажи по товарам)
CREATE TABLE dwh.Fact_Sales (
    sale_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    customer_sk INT NOT NULL,
    time_id INT NOT NULL,
    quantity_sold INT,
    total_revenue DECIMAL(10,2),
    FOREIGN KEY (product_id) REFERENCES dwh.Dim_Product(product_id),
    FOREIGN KEY (customer_sk) REFERENCES dwh.Dim_Customer(customer_sk),
    FOREIGN KEY (time_id) REFERENCES dwh.Dim_Time(time_id)
);

-- Фактовая таблица Fact_Orders (агрегация по заказам)
CREATE TABLE dwh.Fact_Orders (
    order_id INT PRIMARY KEY,
    customer_sk INT NOT NULL,
    time_id INT NOT NULL,
    order_total DECIMAL(10,2),
    item_count INT,
    FOREIGN KEY (customer_sk) REFERENCES dwh.Dim_Customer(customer_sk),
    FOREIGN KEY (time_id) REFERENCES dwh.Dim_Time(time_id)
);

-- Добавление новых клиентов или обновление существующих версий (SCD Type 2)
INSERT INTO dwh.Dim_Customer (customer_id, full_name, email, address, phone, StartDate, IsCurrent)
SELECT u.user_id, u.full_name, u.email, u.address, u.phone, CURRENT_DATE, TRUE
FROM public.Users u
WHERE NOT EXISTS (
    SELECT 1 FROM dwh.Dim_Customer d
    WHERE d.customer_id = u.user_id
    AND d.IsCurrent = TRUE
)
-- Или есть изменения
UNION ALL

SELECT u.user_id, u.full_name, u.email, u.address, u.phone, CURRENT_DATE, TRUE
FROM public.Users u
JOIN dwh.Dim_Customer d ON d.customer_id = u.user_id AND d.IsCurrent = TRUE
WHERE (
    d.full_name IS DISTINCT FROM u.full_name OR
    d.email IS DISTINCT FROM u.email OR
    d.address IS DISTINCT FROM u.address OR
    d.phone IS DISTINCT FROM u.phone
);

-- Закрываем старые версии
UPDATE dwh.Dim_Customer
SET EndDate = CURRENT_DATE - INTERVAL '1 day',
    IsCurrent = FALSE
WHERE customer_id IN (
    SELECT u.user_id
    FROM public.Users u
    JOIN dwh.Dim_Customer d ON d.customer_id = u.user_id AND d.IsCurrent = TRUE
    WHERE (
        d.full_name IS DISTINCT FROM u.full_name OR
        d.email IS DISTINCT FROM u.email OR
        d.address IS DISTINCT FROM u.address OR
        d.phone IS DISTINCT FROM u.phone
    )
);

-- Обновление справочника товаров
INSERT INTO dwh.Dim_Product (product_id, name, category, brand, size, color)
SELECT p.product_id, p.name, c.name AS category, p.brand, p.size, p.color
FROM public.Products p
JOIN public.Categories c ON c.category_id = p.category_id
WHERE NOT EXISTS (
    SELECT 1 FROM dwh.Dim_Product dp WHERE dp.product_id = p.product_id
);

-- Добавим только новые даты из заказов
INSERT INTO dwh.Dim_Time (date, day, month, quarter, year)
SELECT DISTINCT o.order_date,
       EXTRACT(DAY FROM o.order_date),
       EXTRACT(MONTH FROM o.order_date),
       EXTRACT(QUARTER FROM o.order_date),
       EXTRACT(YEAR FROM o.order_date)
FROM public.Orders o
WHERE NOT EXISTS (
    SELECT 1 FROM dwh.Dim_Time dt WHERE dt.date = o.order_date
);

-- Загрузка агрегатов по заказам
INSERT INTO dwh.Fact_Sales (product_id, customer_sk, time_id, quantity_sold, total_revenue)
SELECT 
    oi.product_id,
    dc.customer_sk,
    dt.time_id,
    oi.quantity,
    oi.quantity * oi.unit_price
FROM public.OrderItems oi
JOIN public.Orders o ON o.order_id = oi.order_id
JOIN dwh.Dim_Customer dc ON dc.customer_id = o.user_id AND dc.IsCurrent = TRUE
JOIN dwh.Dim_Time dt ON dt.date = o.order_date
LEFT JOIN dwh.Fact_Sales fs ON fs.product_id = oi.product_id 
                           AND fs.time_id = dt.time_id
                           AND fs.customer_sk = dc.customer_sk
WHERE fs.product_id IS NULL;

-- Загрузка агрегатов по заказам
INSERT INTO dwh.Fact_Orders (order_id, customer_sk, time_id, order_total, item_count)
SELECT 
    o.order_id,
    dc.customer_sk,
    dt.time_id,
    o.total_price,
    COUNT(oi.order_item_id) AS item_count
FROM public.Orders o
JOIN dwh.Dim_Customer dc ON dc.customer_id = o.user_id AND dc.IsCurrent = TRUE
JOIN dwh.Dim_Time dt ON dt.date = o.order_date
LEFT JOIN public.OrderItems oi ON oi.order_id = o.order_id
WHERE NOT EXISTS (
    SELECT 1 FROM dwh.Fact_Orders fo WHERE fo.order_id = o.order_id
)
GROUP BY o.order_id, dc.customer_sk, dt.time_id, o.total_price;

-- Добавление тегов вручную
INSERT INTO dwh.Dim_Tag (tag_name)
SELECT DISTINCT 'SALE'
WHERE NOT EXISTS (SELECT 1 FROM dwh.Dim_Tag WHERE tag_name = 'SALE');

-- Связь между продуктами и тегами
INSERT INTO dwh.Bridge_Product_Tags (product_id, tag_id)
SELECT p.product_id, t.tag_id
FROM public.Products p
JOIN dwh.Dim_Tag t ON t.tag_name = 'SALE'
WHERE p.price < 50 -- Например, SALE для дешёвых товаров
AND NOT EXISTS (
    SELECT 1 FROM dwh.Bridge_Product_Tags bpt
    WHERE bpt.product_id = p.product_id AND bpt.tag_id = t.tag_id
);

--OLTP Query 1:  Какие продукты чаще всего добавляли в корзину?
SELECT 
    p.name AS product_name,
    COUNT(ua.product_id) AS times_added_to_cart
FROM useractions ua
JOIN products p ON ua.product_id = p.product_id
WHERE ua.action_type = 'cart'
GROUP BY p.name
ORDER BY times_added_to_cart DESC;

--OLTP Query 2: Какие пользователи сделали больше всего заказов?
SELECT 
    u.full_name,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN users u ON o.user_id = u.user_id
GROUP BY u.full_name
ORDER BY total_orders DESC;

--OLTP Query 3: Какие товары были проданы наибольшим количеством единиц?
SELECT 
    p.name AS product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM orderitems oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_quantity_sold DESC;

--OLАP Query 1: Общая выручка по месяцам
SELECT u.age, AVG(f.totalprice) AS avg_order_value
FROM factorder f
JOIN dimuser u ON f.userid = u.userid
GROUP BY u.age
ORDER BY u.age;

--OLАP Query 2: Самые популярные товары (по количеству продаж)
SELECT dp.name AS product_name,
       SUM(fs.quantity_sold) AS total_quantity_sold
FROM dwh.Fact_Sales fs
JOIN dwh.Dim_Product dp
  ON fs.product_id = dp.product_id
GROUP BY dp.name
ORDER BY total_quantity_sold DESC
LIMIT 5;

--OLАP Query 3: Количество заказов по категориям

SELECT c.name AS category_name, COUNT(DISTINCT o.order_id) AS total_orders
FROM public.orders o
JOIN public.orderitems oi ON o.order_id = oi.order_id
JOIN public.products p ON oi.product_id = p.product_id
JOIN public.categories c ON p.category_id = c.category_id
GROUP BY c.name
ORDER BY total_orders DESC;
