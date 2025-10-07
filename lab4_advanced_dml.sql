-- Create tables

CREATE TABLE employees (
employee_id SERIAL PRIMARY KEY,
first_name VARCHAR(50),
last_name VARCHAR(50),
department VARCHAR(50),
salary NUMERIC(10,2),
hire_date DATE,
manager_id INTEGER,
email VARCHAR(100)
);

CREATE TABLE projects (
project_id SERIAL PRIMARY KEY,
project_name VARCHAR(100),
budget NUMERIC(12,2),
start_date DATE,
end_date DATE,
status VARCHAR(20)
);

CREATE TABLE assignments (
assignment_id SERIAL PRIMARY KEY,
employee_id INTEGER REFERENCES employees(employee_id),
project_id INTEGER REFERENCES projects(project_id),
hours_worked NUMERIC(5,1),
assignment_date DATE
);

-- Insert sample data
INSERT INTO employees (first_name, last_name, department,
salary, hire_date, manager_id, email) VALUES
('John', 'Smith', 'IT', 75000, '2020-01-15', NULL,
'john.smith@company.com'),
('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1,
'sarah.j@company.com'),
('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL,
'mbrown@company.com'),
('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL,
'emily.davis@company.com'),
('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3,
'lisa.a@company.com');

INSERT INTO projects (project_name, budget, start_date,
end_date, status) VALUES
('Website Redesign', 150000, '2024-01-01', '2024-06-30',
'Active'),
('CRM Implementation', 200000, '2024-02-15', '2024-12-31',
'Active'),
('Marketing Campaign', 80000, '2024-03-01', '2024-05-31',
'Completed'),
('Database Migration', 120000, '2024-01-10', NULL, 'Active');

INSERT INTO assignments (employee_id, project_id,
hours_worked, assignment_date) VALUES
(1, 1, 120.5, '2024-01-15'),
(2, 1, 95.0, '2024-01-20'),
(1, 4, 80.0, '2024-02-01'),
(3, 3, 60.0, '2024-03-05'),
(5, 2, 110.0, '2024-02-20'),
(6, 3, 75.5, '2024-03-10');

-- task 1.1
select 
    first_name || ' ' || last_name as full_name,
    department,
    salary
from employees;

-- task 1.2
select distinct department
from employees;

-- task 1.3
select 
    project_name,
    budget,
    case 
        when budget > 150000 then 'large'
        when budget between 100000 and 150000 then 'medium'
        else 'small'
    end as budget_category
from projects;

-- task 1.4
select 
    first_name || ' ' || last_name as full_name,
    coalesce(email, 'no email provided') as email
from employees;

-- task 2.1
select *
from employees
where hire_date > '2020-01-01';

-- task 2.2
select *
from employees
where salary between 60000 and 70000;

-- task 2.3
select *
from employees
where last_name like 'S%' or last_name like 'J%';

-- task 2.4
select *
from employees
where manager_id is not null
  and department = 'IT';

-- task 3.1
select 
    upper(first_name || ' ' || last_name) as full_name_upper,
    length(last_name) as last_name_length,
    substring(email from 1 for 3) as email_prefix
from employees;

-- task 3.2
select 
    first_name || ' ' || last_name as full_name,
    salary * 12 as annual_salary,
    round(salary, 2) as monthly_salary,
    salary * 0.10 as raise_amount
from employees;

-- task 3.3
select 
    format('project: %s - budget: $%s - status: %s', project_name, budget, status) as project_info
from projects;

-- task 3.4
select 
    first_name || ' ' || last_name as full_name,
    extract(year from age(current_date, hire_date)) as years_with_company
from employees;

-- task 4.1
select 
    department,
    avg(salary) as avg_salary
from employees
group by department;

-- task 4.2
select 
    p.project_name,
    sum(a.hours_worked) as total_hours
from assignments a
join projects p on a.project_id = p.project_id
group by p.project_name;

-- task 4.3
select 
    department,
    count(*) as employee_count
from employees
group by department
having count(*) > 1;

-- task 4.4
select 
    max(salary) as max_salary,
    min(salary) as min_salary,
    sum(salary) as total_payroll
from employees;

-- task 5.1
select 
    employee_id,
    first_name || ' ' || last_name as full_name,
    salary
from employees
where salary > 65000

union

select 
    employee_id,
    first_name || ' ' || last_name as full_name,
    salary
from employees
where hire_date > '2020-01-01';

-- task 5.2
select 
    employee_id,
    first_name || ' ' || last_name as full_name
from employees
where department = 'IT'

intersect

select 
    employee_id,
    first_name || ' ' || last_name as full_name
from employees
where salary > 65000;

-- task 5.3
select 
    employee_id,
    first_name || ' ' || last_name as full_name
from employees

except

select 
    e.employee_id,
    e.first_name || ' ' || e.last_name as full_name
from employees e
join assignments a on e.employee_id = a.employee_id;

-- task 6.1
select 
    employee_id,
    first_name || ' ' || last_name as full_name
from employees e
where exists (
    select 1 
    from assignments a
    where a.employee_id = e.employee_id
);

-- task 6.2
select 
    employee_id,
    first_name || ' ' || last_name as full_name
from employees
where employee_id in (
    select a.employee_id
    from assignments a
    join projects p on a.project_id = p.project_id
    where p.status = 'Active'
);

-- task 6.3
select 
    employee_id,
    first_name || ' ' || last_name as full_name,
    salary
from employees
where salary > any (
    select salary 
    from employees 
    where department = 'Sales'
);

-- task 7.1
select 
    e.first_name || ' ' || e.last_name as full_name,
    e.department,
    avg(a.hours_worked) as avg_hours_worked,
    rank() over (partition by e.department order by e.salary desc) as salary_rank
from employees e
join assignments a on e.employee_id = a.employee_id
group by e.employee_id, e.first_name, e.last_name, e.department, e.salary;

-- task 7.2
select 
    p.project_name,
    sum(a.hours_worked) as total_hours,
    count(distinct a.employee_id) as employee_count
from projects p
join assignments a on p.project_id = a.project_id
group by p.project_name
having sum(a.hours_worked) > 150;

-- task 7.3
select 
    department,
    count(*) as total_employees,
    avg(salary) as avg_salary,
    (select first_name || ' ' || last_name 
     from employees e2 
     where e2.department = e1.department 
     order by e2.salary desc 
     limit 1) as highest_paid_employee,
    greatest(avg(salary), max(salary)) as greatest_value,
    least(avg(salary), min(salary)) as least_value
from employees e1
group by department;