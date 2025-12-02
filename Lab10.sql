-- task one
create index emp_salary_idx on employees(salary);

select indexname, indexdef 
from pg_indexes 
where tablename = 'employees';

-- task two
create index emp_dept_idx on employees(dept_id);

select * from employees where dept_id = 101;

-- task three
select 
    tablename,
    indexname,
    indexdef
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;

-- task four
create index emp_dept_salary_idx on employees(dept_id, salary);

select emp_name, salary 
from employees 
where dept_id = 101 and salary > 52000;

create index emp_salary_dept_idx on employees(salary, dept_id);

select * from employees where dept_id = 102 and salary > 50000;
select * from employees where salary > 50000 and dept_id = 102;

-- task five
alter table employees add column email varchar(100);

update employees set email = 'john.smith@company.com' where emp_id = 1;
update employees set email = 'jane.doe@company.com' where emp_id = 2;
update employees set email = 'mike.johnson@company.com' where emp_id = 3;
update employees set email = 'sarah.williams@company.com' where emp_id = 4;
update employees set email = 'tom.brown@company.com' where emp_id = 5;

create unique index emp_email_unique_idx on employees(email);

insert into employees (emp_id, emp_name, dept_id, salary, email)
values (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- task six
alter table employees add column phone varchar(20) unique;

select indexname, indexdef 
from pg_indexes 
where tablename = 'employees' and indexname like '%phone%';

-- task seven
create index emp_salary_desc_idx on employees(salary desc);

select emp_name, salary 
from employees 
order by salary desc;

create index proj_budget_nulls_first_idx on projects(budget nulls first);

select proj_name, budget 
from projects 
order by budget nulls first;

-- task eight
create index emp_name_lower_idx on employees(lower(emp_name));

select * from employees where lower(emp_name) = 'john smith';

alter table employees add column hire_date date;

update employees set hire_date = '2020-01-15' where emp_id = 1;
update employees set hire_date = '2019-06-20' where emp_id = 2;
update employees set hire_date = '2021-03-10' where emp_id = 3;
update employees set hire_date = '2020-11-05' where emp_id = 4;
update employees set hire_date = '2018-08-25' where emp_id = 5;

create index emp_hire_year_idx on employees(extract(year from hire_date));

select emp_name, hire_date 
from employees 
where extract(year from hire_date) = 2020;

-- task nine
alter index emp_salary_idx rename to employees_salary_index;

select indexname 
from pg_indexes 
where tablename = 'employees';

drop index emp_salary_dept_idx;

reindex index employees_salary_index;

-- task ten
create index emp_salary_filter_idx on employees(salary) where salary > 50000;

create index proj_high_budget_idx on projects(budget) 
where budget > 80000;

select proj_name, budget 
from projects 
where budget > 80000;

explain select * from employees where salary > 52000;

-- task eleven
create index dept_name_hash_idx on departments using hash (dept_name);

select * from departments where dept_name = 'IT';

create index proj_name_btree_idx on projects(proj_name);
create index proj_name_hash_idx on projects using hash (proj_name);

select * from projects where proj_name = 'Website Redesign';
select * from projects where proj_name > 'Database';

-- task twelve
select 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;

drop index if exists proj_name_hash_idx;

create view index_documentation as
select 
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' as purpose
from pg_indexes
where schemaname = 'public' 
and indexname like '%salary%';

select * from index_documentation;