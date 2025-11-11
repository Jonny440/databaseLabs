-- Create table: employees
CREATE TABLE employees (
emp_id INT PRIMARY KEY,
emp_name VARCHAR(50),
dept_id INT,
salary DECIMAL(10, 2)
);
-- Create table: departments
CREATE TABLE departments (
dept_id INT PRIMARY KEY,
dept_name VARCHAR(50),
location VARCHAR(50)
);
-- Create table: projects
CREATE TABLE projects (
project_id INT PRIMARY KEY,
project_name VARCHAR(50),
dept_id INT,
budget DECIMAL(10, 2)
);

-- Insert data into employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);
-- Insert data into departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');
-- Insert data into projects
INSERT INTO projects (project_id, project_name, dept_id,
budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

-- task 2.1

create view employee_details as
select
    e.employee_id,
    e.first_name,
    e.last_name,
    e.salary,
    d.dept_name as department_name,
    d.location as department_location
from employees e
inner join departments d
on e.dept_id = d.dept_id;

select * from employee_details;

-- task 2.2

create view dept_statistics as
select
    d.dept_id,
    d.dept_name,
    count(e.employee_id) as employee_count,
    coalesce(avg(e.salary), 0) as average_salary,
    coalesce(max(e.salary), 0) as max_salary,
    coalesce(min(e.salary), 0) as min_salary
from departments d
left join employees e on d.dept_id = e.dept_id
group by d.dept_id, d.dept_name;

select * from dept_statistics
order by employee_count desc;

-- task 2.3

create view project_overview as
select
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    count(e.employee_id) as team_size
from projects p
join departments d on p.dept_id = d.dept_id
left join employees e on d.dept_id = e.dept_id
group by p.project_name, p.budget, d.dept_name, d.location;

-- task 2.4

create view high_earners as
select
    e.first_name || ' ' || e.last_name as full_name,
    e.salary,
    d.dept_name
from employees e
join departments d on e.dept_id = d.dept_id
where e.salary > 55000;

select * from high_earners;

-- task 3.1

create or replace view employee_details as
select
    e.first_name || ' ' || e.last_name as full_name,
    e.salary,
    d.dept_name,
    d.location,
    case
        when e.salary > 60000 then 'High'
        when e.salary > 50000 then 'Medium'
        else 'Standard'
    end as salary_grade
from employees e
join departments d on e.dept_id = d.dept_id;

-- task 3.2

alter view high_earners rename to top_performers;

-- task 3.3

create view temp_view as
select
    e.first_name || ' ' || e.last_name as full_name,
    e.salary,
    d.dept_name
from employees e
join departments d on e.dept_id = d.dept_id
where e.salary < 50000;

select * from temp_view;

drop view temp_view;

-- task 4.1

create or replace view employee_salaries as
select
    emp_id,
    emp_name,
    dept_id,
    salary
from employees;

-- task 4.2

update employee_salaries
set salary = 52000
where emp_name = 'John Smith';

-- task 4.3

insert into employee_salaries (emp_id, emp_name, dept_id, salary)
values (6, 'Alice Johnson', 102, 58000);

-- task 4.4

create or replace view it_employees as
select
    emp_id,
    emp_name,
    dept_id,
    salary
from employees
where dept_id = 101
with local check option;

-- task 5.1

create materialized view dept_summary_mv as
select
    d.dept_id,
    d.dept_name,
    coalesce(count(distinct e.emp_id), 0) as total_employees,
    coalesce(sum(e.salary), 0) as total_salaries,
    coalesce(count(distinct p.project_id), 0) as total_projects,
    coalesce(sum(p.budget), 0) as total_project_budget
from departments d
left join employees e on d.dept_id = e.dept_id
left join projects p on d.dept_id = p.dept_id
group by d.dept_id, d.dept_name
with data;

select * from dept_summary_mv
order by total_employees desc;

-- task 5.2

insert into employees (emp_id, emp_name, dept_id, salary)
values (8, 'Charlie Brown', 101, 54000);

-- query before refresh
select * from dept_summary_mv;

-- refresh
refresh materialized view dept_summary_mv;

-- query after refresh
select * from dept_summary_mv;

-- task 5.3

create unique index dept_summary_mv_idx on dept_summary_mv(dept_id);

refresh materialized view concurrently dept_summary_mv;

-- task 5.4

create materialized view project_stats_mv as
select
    p.project_name,
    p.budget,
    d.dept_name,
    count(e.emp_id) as employee_count
from projects p
left join departments d on p.dept_id = d.dept_id
left join employees e on d.dept_id = e.dept_id
group by p.project_name, p.budget, d.dept_name
with no data;

-- task 6.1

create role analyst no login;
create role data_viewer login password 'viewer123';
create role report_user login password 'report456';

select rolname from pg_roles where rolname not like 'pg_%';

-- task 6.2

create role db_creator login createdb password 'creator789';
create role user_manager login createrole password 'manager101';
create role admin_user superuser login password 'admin999';

-- task 6.3

grant select on employees, departments, projects to analyst;
grant all privileges on employee_details to data_viewer;
grant select, insert on employees to report_user;

-- task 6.4

create role hr_team;
create role finance_team;
create role it_team;

create role hr_user1 login password 'hr001';
create role hr_user2 login password 'hr002';
create role finance_user1 login password 'fin001';

grant hr_team to hr_user1;
grant hr_team to hr_user2;
grant finance_team to finance_user1;

grant select, update on employees to hr_team;
grant select on dept_statistics to finance_team;

-- task 6.5

revoke update on employees from hr_team;
revoke hr_team from hr_user2;
revoke all privileges on employee_details from data_viewer;

-- task 6.6

alter role analyst login password 'analyst123';
alter role user_manager superuser;
alter role analyst password null;
alter role data_viewer connection limit 5;


--task 7.1

create role read_only;

grant select on all tables in schema public to read_only;

create role junior_analyst login password 'junior123';
create role senior_analyst login password 'senior123';

grant read_only to junior_analyst;
grant read_only to senior_analyst;

grant insert, update on employees to senior_analyst;

-- task 7.2

create role project_manager login password 'pm123';

alter view dept_statistics owner to project_manager;
alter table projects owner to project_manager;

select tablename, tableowner
from pg_tables
where schemaname = 'public';

-- task 7.3
create role temp_owner login;

create table temp_table (id int);

alter table temp_table owner to temp_owner;

reassign owned by temp_owner to postgres;

drop owned by temp_owner;

drop role temp_owner;

-- task 7.4
create or replace view hr_employee_view as
select *
from employees
where dept_id = 102;

grant select on hr_employee_view to hr_team;

create or replace view finance_employee_view as
select emp_id, emp_name, salary
from employees;

grant select on finance_employee_view to finance_team;