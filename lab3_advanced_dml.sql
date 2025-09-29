-- task 1
create database advanced_lab;

use advanced_lab;

create table employees (
    emp_id int auto_increment primary key,
    first_name varchar(100),
    last_name varchar(100),
    department varchar(100),
    salary int,
    hire_date date,
    status varchar(100) default 'active'
);

create table departments (
    dept_id int auto_increment primary key,
    dept_name varchar(100),
    budget int,
    manager_id int
);

create table projects (
    project_id int auto_increment primary key,
    project_name varchar(100),
    dept_id int,
    start_date date,
    end_date date,
    budget int
);

-- task 2

insert into employees (emp_id, first_name, last_name, department)
values (1, 'zhanibek', 'nurzhan', 'it');

insert into employees (first_name, last_name, department, salary, hire_date, status)
values ('baubek', 'askar', 'hr', default, '2025-09-30', default);

insert into departments (dept_name, budget, manager_id)
values 
('it', 50, 1),
('hr', 23, 2),
('finance', 13, 3);

insert into employees (first_name, last_name, department, salary, hire_date)
values ('arman', 'bek', 'finance', 50000 * 1.1, current_date());

create temporary table temp_employees as
select * from employees where department = 'it';

-- task 3

update employees
set salary = salary * 1.10;

update employees
set status = 'Senior'
where salary > 60000 and hire_date < '2020-01-01';

update employees
set department = case
    when salary > 80000 then 'Management'
    when salary between 50000 and 80000 then 'Senior'
    else 'Junior'
end;

update employees
set department = default
where status = 'Inactive';

update departments d
set budget = (select avg(salary) * 1.20
              from employees e
              where e.department = d.dept_name);

update employees
set salary = salary * 1.15,
    status = 'Promoted'
where department = 'Sales';

-- task 4

delete from employees
where status = 'Terminated';

delete from employees
where salary < 40000
  and hire_date > '2023-01-01'
  and department is null;

delete from departments
where dept_id not in (
    select distinct department
    from employees
    where department is not null
);

delete from projects
where end_date < '2023-01-01'
returning *;

-- task 5

insert into employees (first_name, last_name, department, salary, hire_date)
values ('zheka', 'ali', null, null, current_date());

update employees
set department = 'Unassigned'
where department is null;

delete from employees
where salary is null
   or department is null;


-- task 6

insert into employees (first_name, last_name, department, salary, hire_date)
values ('nurbol', 'samat', 'it', 70000, current_date())
returning emp_id, concat(first_name, ' ', last_name) as full_name;

update employees
set salary = salary + 5000
where department = 'it'
returning emp_id, salary - 5000 as old_salary, salary as new_salary;

delete from employees
where hire_date < '2020-01-01'
returning *;
