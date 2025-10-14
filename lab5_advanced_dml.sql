-- task 1.1
create table employees (
    employee_id integer,
    first_name text,
    last_name text,
    age integer check (age between 18 and 65),
    salary numeric check (salary > 0)
);

-- task 1.2
create table products_catalog (
    product_id integer,
    product_name text,
    regular_price numeric,
    discount_price numeric,
    constraint valid_discount check (
        regular_price > 0 
        and discount_price > 0 
        and discount_price < regular_price
    )
);

-- task 1.3
create table bookings (
    booking_id integer,
    check_in_date date,
    check_out_date date,
    num_guests integer check (num_guests between 1 and 10),
    check (check_out_date > check_in_date)
);

-- task 2.1
create table customers (
    customer_id integer not null,
    email text not null,
    phone text,
    registration_date date not null
);

-- task 2.2
create table inventory (
    item_id integer not null,
    item_name text not null,
    quantity integer not null check (quantity >= 0),
    unit_price numeric not null check (unit_price > 0),
    last_updated timestamp not null
);

-- task 3.1
create table users (
    user_id integer,
    username text unique,
    email text unique,
    created_at timestamp
);

-- task 3.2
create table course_enrollments (
    enrollment_id integer,
    student_id integer,
    course_code text,
    semester text,
    unique (student_id, course_code, semester)
);

-- task 3.3
drop table if exists users;
create table users (
    user_id integer,
    username text,
    email text,
    created_at timestamp,
    constraint unique_username unique (username),
    constraint unique_email unique (email)
);

-- task 4.1
create table departments (
    dept_id integer primary key,
    dept_name text not null,
    location text
);

insert into departments values (1, 'it', 'almaty');
insert into departments values (2, 'sales', 'astana');
insert into departments values (3, 'hr', 'shymkent');
insert into departments values (1, 'finance', 'aktobe'); -- has the same id wrong
insert into departments values (null, 'marketing', 'almaty'); -- has id as null wrong

-- task 4.2
create table student_courses (
    student_id integer,
    course_id integer,
    enrollment_date date,
    grade text,
    primary key (student_id, course_id)
);

--task 4.3
-- Unique can be null, Primary can not. Primary key uniquiely identifies each row, while unique can not do that.
-- single column primary key uses one column. When we can not identify unique row using only one column we use composite primary key using several columns.
-- a table can only have one official identifier for its rows — the primary key. While unique is just a keyword which can be used myltiple times

-- task 5.1
create table employees_dept (
    emp_id integer primary key,
    emp_name text not null,
    dept_id integer references departments(dept_id),
    hire_date date
);

insert into employees_dept values (1, 'john smith', 1, '2024-01-10');
insert into employees_dept values (2, 'sarah jones', 2, '2024-02-20');
insert into employees_dept values (3, 'mike brown', 99, '2024-03-15'); -- there is no 99 dept id

create table authors (
    author_id integer primary key,
    author_name text not null,
    country text
);

create table publishers (
    publisher_id integer primary key,
    publisher_name text not null,
    city text
);

create table books (
    book_id integer primary key,
    title text not null,
    author_id integer references authors(author_id),
    publisher_id integer references publishers(publisher_id),
    publication_year integer,
    isbn text unique
);

insert into authors values 
(1, 'jack london', 'colombia'),
(2, 'dostoebsky', 'russia');

insert into publishers values 
(1, 'little prince', 'new dehli'),
(2, 'mont oriol', 'paris');

insert into books values 
(1, 'one hundred years of solitude', 1, 1, 1967, '9780060883287'),
(2, 'crime and punishment', 2, 2, 1866, '9780140449136');

-- task 5.3
create table categories (
    category_id integer primary key,
    category_name text not null
);

create table products_fk (
    product_id integer primary key,
    product_name text not null,
    category_id integer references categories(category_id) on delete restrict
);

create table orders (
    order_id integer primary key,
    order_date date not null
);

create table order_items (
    item_id integer primary key,
    order_id integer references orders(order_id) on delete cascade,
    product_id integer references products_fk(product_id),
    quantity integer check (quantity > 0)
);

insert into categories values (1, 'electronics'), (2, 'furniture'), (3, 'hand made');
insert into products_fk values (1, 'laptop', 1), (2, 'chair', 2);
insert into orders values (1, '2025-01-10');
insert into order_items values (1, 1, 1, 2), (2, 1, 2, 1);

--task 6.1

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date DATE DEFAULT CURRENT_DATE,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);