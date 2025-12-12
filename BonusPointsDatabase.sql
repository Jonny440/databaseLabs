-- Database creation

create table customers (
    customer_id serial primary key,
    iin varchar(12) unique not null,
    full_name varchar not null,
    phone varchar,
    email varchar,
    status varchar default 'active' check ( status in ('active', 'blocked', 'frozen') ),
    created_at timestamp default current_timestamp,
    daily_limit_kzt numeric(15, 2) default 1000000.00
);

create table accounts (
    account_id serial primary key,
    customer_id integer references customers(customer_id),
    account_number varchar unique not null,
    currency varchar(3) not null check ( currency in ('KZT', 'USD', 'EUR', 'RUB')),
    balance numeric(15, 2) default 0.00,
    is_active boolean default true,
    opened_at timestamp default current_timestamp,
    closed_at timestamp
);

create table transactions (
    transaction_id serial primary key,
    from_account_id integer references accounts(account_id),
    to_account_id integer references accounts(account_id),
    amount numeric(15, 2) not null,
    currency varchar(3) not null,
    exchange_rate numeric(15, 6) default 1.0,
    amount_kzt numeric(15, 2),
    type varchar not null check ( type in ('transfer', 'deposit', 'withdrawal')),
    status varchar check ( status in ('pending', 'completed', 'failed', 'reversed')),
    created_at timestamp default current_timestamp,
    completed_at timestamp,
    description text
);

create table exchange_rates (
    rate_id serial primary key,
    from_currency varchar(3) not null,
    to_currency varchar(3) not null,
    rate numeric(15, 6) not null,
    valid_from timestamp default current_timestamp,
    valid_to timestamp
);

create table audit_log (
    log_id serial primary key,
    table_name varchar(100) not null,
    record_id integer not null,
    action varchar(10) not null check ( status in ('INSERT', 'UPDATE', 'DELETE')),
    old_values jsonb,
    new_values jsonb,
    changed_by varchar(100),
    changed_at timestamp default current_timestamp,
    ip_address inet
);

insert into customers (iin, full_name, phone, email, status) values
('123456789012', 'Zhabubev', '123', 'zhab@gmail.com', 'active'),
('234567890123', 'Zhanibek', '234', 'brother@gmail.com', 'active'),
('345678901234', 'Jonny', '345', 'superBro@gmail.com', 'active'),
('456789901234', 'Janibobster', '436', '12@gmail.com', 'blocked'),
('567890123456', 'Jan Clode', '273', '2@gmail.com', 'active'),
('678901234567', 'Van', '7342', '3@gmail.com', 'frozen'),
('890123456789', 'Dam', '2347', '4@gmail.com', 'active'),
('012345678901', 'Rembo', '423', '5@gmail.com', 'active'),
('123123123213', 'Alvarez', '2347', '6@gmail.com', 'active'),
('232124141241', 'Khabib', '2345', '7@gmail.com', 'blocked');



insert into accounts (customer_id, account_number, currency, balance, is_active) values
(1, 'asfsa12', 'KZT', 5000000.00, true),
(2, 'asdf2', 'USD', 10000.00, true),
(3, 'fadsf23', 'KZT', 8000000.00, true),
(4, 'gsakl32', 'EUR', 15000.00, true),
(5, 'faskl23', 'KZT', 12000000.00, true),
(6, 'gsadgklj23', 'KZT', 3000000.00, true),
(7, 'faskjl2', 'USD', 25000.00, true),
(8, 'flkj23', 'RUB', 500000.00, false),
(9, 'fasdf23', 'KZT', 50000000.00, true),
(10, 'fasdf2112', 'EUR', 20000.00, true);

insert into exchange_rates (from_currency, to_currency, rate, valid_from, valid_to) values
('USD', 'KZT', 450.00, current_timestamp, null),
('EUR', 'KZT', 495.00, current_timestamp, null),
('RUB', 'KZT', 4.80, current_timestamp, null),
('KZT', 'USD', 0.0022, current_timestamp, null),
('KZT', 'EUR', 0.0020, current_timestamp, null),
('KZT', 'RUB', 0.2083, current_timestamp, null),
('USD', 'EUR', 0.92, current_timestamp, null),
('EUR', 'USD', 1.09, current_timestamp, null),
('USD', 'RUB', 93.75, current_timestamp, null),
('RUB', 'USD', 0.0107, current_timestamp, null);

insert into transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, completed_at, description) values
(1, 3, 100000.00, 'KZT', 1.0, 100000.00, 'transfer', 'completed', current_timestamp, ''),
(2, 5, 500.00, 'USD', 450.00, 225000.00, 'transfer', 'completed', current_timestamp, ''),
(3, 1, 50000.00, 'KZT', 1.0, 50000.00, 'transfer', 'completed', current_timestamp, ''),
(5, 9, 1000.00, 'KZT', 1.0, 1000.00, 'transfer', 'completed', current_timestamp, ''),
(1, 3, 200000.00, 'KZT', 1.0, 200000.00, 'transfer', 'failed', null, ''),
(4, 10, 2000.00, 'EUR', 495.00, 990000.00, 'transfer', 'completed', current_timestamp, ''),
(9, 5, 5000000.00, 'KZT', 1.0, 5000000.00, 'transfer', 'completed', current_timestamp, ''),
(2, 7, 800.00, 'USD', 450.00, 360000.00, 'transfer', 'completed', current_timestamp, ''),
(3, 1, 150000.00, 'KZT', 1.0, 150000.00, 'transfer', 'completed', current_timestamp, ''),
(10, 4, 5000.00, 'EUR', 495.00, 2475000.00, 'transfer', 'completed', current_timestamp, '');

-- Task 1

create or replace function process_transfer(
    p_from_account_number varchar,
    p_to_account_number varchar,
    p_amount numeric,
    p_currency varchar,
    p_description text
) returns text as $$
declare
    v_from_account_id integer;
    v_to_account_id integer;
    v_from_customer_id integer;
    v_customer_status varchar;
    v_from_balance numeric;
    v_from_currency varchar;
    v_to_currency varchar;
    v_daily_limit numeric;
    v_today_total numeric;
    v_exchange_rate numeric;
    v_amount_kzt numeric;
    v_converted_amount numeric;
    v_transaction_id integer;
begin
    select account_id, customer_id, balance, currency, is_active
    into v_from_account_id, v_from_customer_id, v_from_balance, v_from_currency
    from accounts
    where account_number = p_from_account_number
    for update;
    -- check if from_account exists
    if not found then
        insert into audit_log (table_name, record_id, action, new_values, changed_by)
        values ('transactions', 0, 'INSERT', '{"error": "from account not found"}', current_user);
        return 'from account not found';
    end if;

    select account_id, currency, is_active
    into v_to_account_id, v_to_currency
    from accounts
    where account_number = p_to_account_number
    for update;
    -- check if to_account exists
    if not found then
        insert into audit_log (table_name, record_id, action, new_values, changed_by)
        values ('transactions', 0, 'INSERT', '{"error": "to account not found"}', current_user);
        return 'to account not found';
    end if;

    -- check is the user is active account
    if not (select is_active from accounts where account_id = v_from_account_id) then
        return 'from account not active';
    end if;

    -- check if the other user is active account
    if not (select is_active from accounts where account_id = v_to_account_id) then
        return 'to account not active';
    end if;

    select status, daily_limit_kzt
    into v_customer_status, v_daily_limit
    from customers
    where customer_id = v_from_customer_id;

    -- check if the customer is not blocked or frozen
    if v_customer_status != 'active' then
        return 'customer status is ' || v_customer_status;
    end if;

    --check if the customer has enough money
    if v_from_balance < p_amount then
        return 'insufficient balance';
    end if;

    if p_currency = 'KZT' then
        v_amount_kzt := p_amount;
    else
        select rate into v_exchange_rate
        from exchange_rates
        where from_currency = p_currency and to_currency = 'KZT'
        and valid_to is null
        order by valid_from desc
        limit 1;

        if not found then
            return 'exchange rate not found';
        end if;

        v_amount_kzt := p_amount * v_exchange_rate;
    end if;

    select coalesce(sum(amount_kzt), 0) into v_today_total
    from transactions
    where from_account_id = v_from_account_id
    and date(created_at) = current_date
    and status = 'completed';

    if (v_today_total + v_amount_kzt) > v_daily_limit then
        return 'daily limit exceeded';
    end if;

    if v_from_currency = v_to_currency then
        v_converted_amount := p_amount;
        v_exchange_rate := 1.0;
    else
        select rate into v_exchange_rate
        from exchange_rates
        where from_currency = v_from_currency and to_currency = v_to_currency
        and valid_to is null
        order by valid_from desc
        limit 1;

        if not found then
            return 'exchange rate not found';
        end if;

        v_converted_amount := p_amount * v_exchange_rate;
    end if;

    insert into transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, description)
    values (v_from_account_id, v_to_account_id, p_amount, p_currency, v_exchange_rate, v_amount_kzt, 'transfer', 'completed', p_description)
    returning transaction_id into v_transaction_id;

    update accounts
    set balance = balance - p_amount
    where account_id = v_from_account_id;

    update accounts
    set balance = balance + v_converted_amount
    where account_id = v_to_account_id;

    update transactions
    set completed_at = current_timestamp
    where transaction_id = v_transaction_id;

    insert into audit_log (table_name, record_id, action, new_values, changed_by)
    values ('transactions', v_transaction_id, 'INSERT',
            jsonb_build_object('transaction_id', v_transaction_id, 'amount', p_amount),
            current_user);

    return 'transaction completed';
end;
$$ language plpgsql;

-- Task 2

create view customer_balance_summary as
with account_balances as (
    select
        c.customer_id,
        c.full_name,
        a.account_number,
        a.currency,
        a.balance,
        case
            when a.currency = 'KZT' then a.balance
            else a.balance * er.rate
        end as balance_kzt,
        c.daily_limit_kzt,
        a.account_id
    from customers c
    join accounts a on c.customer_id = a.customer_id
    left join exchange_rates er on er.from_currency = a.currency
        and er.to_currency = 'KZT'
        and er.valid_to is null
    where a.is_active = true
),
daily_spending as (
    select
        from_account_id,
        sum(amount_kzt) as today_spent
    from transactions
    where date(created_at) = current_date
    and status = 'completed'
    group by from_account_id
)
select
    ab.customer_id,
    ab.full_name,
    ab.account_number,
    ab.currency,
    ab.balance,
    ab.balance_kzt,
    sum(ab.balance_kzt) over (partition by ab.customer_id) as total_balance_kzt,
    ab.daily_limit_kzt,
    ds.today_spent as today_spent,
    ds.today_spent * 100.0 / ab.daily_limit_kzt as limit_used_percent,
    rank() over (order by sum(ab.balance_kzt) over (partition by ab.customer_id) desc) as customer_rank
from account_balances ab
left join daily_spending ds on ab.account_id = ds.from_account_id;

create view daily_transaction_report as
with daily_stats as (
    select
        date(created_at) as transaction_date,
        type,
        count(*) as transaction_count,
        sum(amount_kzt) as total_volume_kzt,
        avg(amount_kzt) as avg_amount_kzt
    from transactions
    where status = 'completed'
    group by date(created_at), type
)
select
    transaction_date,
    type,
    transaction_count,
    total_volume_kzt,
    avg_amount_kzt,
    sum(total_volume_kzt) over (partition by type order by transaction_date) as running_total,
    lag(total_volume_kzt) over (partition by type order by transaction_date) as prev_day_volume,
    -- here we find growth rate using last row and previous to it row. And avoid dividing by zero using nullif
    round((total_volume_kzt - lag(total_volume_kzt) over (partition by type order by transaction_date)) * 100.0 / nullif(lag(total_volume_kzt) over (partition by type order by transaction_date), 0), 2) as growth_percent
from daily_stats;

create view suspicious_activity_view with (security_barrier = true) as
select
    t.transaction_id,
    c.customer_id,
    c.full_name,
    t.amount_kzt,
    t.created_at,
    'large transaction' as flag_reason
from transactions t
join accounts a on t.from_account_id = a.account_id
join customers c on a.customer_id = c.customer_id
where t.amount_kzt > 5000000
and t.status = 'completed'
union all
select
    t.transaction_id,
    c.customer_id,
    c.full_name,
    t.amount_kzt,
    t.created_at,
    'high frequency' as flag_reason
from transactions t
join accounts a on t.from_account_id = a.account_id
join customers c on a.customer_id = c.customer_id
where (select count(*)
       from transactions t2
       where t2.from_account_id = t.from_account_id
       and t2.created_at between t.created_at - interval '1 hour' and t.created_at
       and t2.status = 'completed') > 10
union all
select
    t.transaction_id,
    c.customer_id,
    c.full_name,
    t.amount_kzt,
    t.created_at,
    'rapid sequential' as flag_reason
from transactions t
join accounts a on t.from_account_id = a.account_id
join customers c on a.customer_id = c.customer_id
where exists (
    select 1
    from transactions t2
    where t2.from_account_id = t.from_account_id
    and t2.transaction_id != t.transaction_id
    and t2.created_at between t.created_at - interval '1 minute' and t.created_at
    and t2.status = 'completed'
);

-- Task 3

-- btree index
create index idx_accounts_customer on accounts(customer_id);

-- composite index
create index idx_transactions on transactions(from_account_id, created_at, status);

-- partial index (only for active ones)
create index idx_accounts_active on accounts(account_id) where is_active = true;

-- gin index
create index idx_audit_jsonb on audit_log using gin(new_values);

-- hash index
create index idx_account_hash on accounts using hash(account_id);

-- case insensitive index  for email
create index idx_customers_email on customers(lower(email));

-- Task 4

create or replace function process_salary_batch(
    p_company_account_number varchar,
    p_payments jsonb
) returns jsonb as $$
declare
    v_company_account_id integer;
    v_company_balance numeric;
    v_total_needed numeric := 0;
    v_payment jsonb;
    v_employee_iin varchar;
    v_amount numeric;
    v_description text;
    v_employee_account_id integer;
    v_success_count integer := 0;
    v_failed_count integer := 0;
    v_failed_list jsonb := '[]'::jsonb;
    v_transaction_id integer;
begin
    if not pg_try_advisory_lock(hashtext(p_company_account_number)) then
        return jsonb_build_object('error', 'batch already processing');
    end if;

    select account_id, balance
    into v_company_account_id, v_company_balance
    from accounts
    where account_number = p_company_account_number
    and is_active = true
    for update;

    if not found then
        perform pg_advisory_unlock(hashtext(p_company_account_number));
        return jsonb_build_object('error', 'company account not found');
    end if;

    for v_payment in select * from jsonb_array_elements(p_payments) loop
        v_total_needed := v_total_needed + (v_payment->>'amount')::numeric;
    end loop;

    if v_company_balance < v_total_needed then
        perform pg_advisory_unlock(hashtext(p_company_account_number));
        return jsonb_build_object('error', 'insufficient balance');
    end if;

    for v_payment in select * from jsonb_array_elements(p_payments) loop
        savepoint payment_point;

        begin
            v_employee_iin := v_payment->>'iin';
            v_amount := (v_payment->>'amount')::numeric;
            v_description := coalesce(v_payment->>'description', 'salary');

            select a.account_id into v_employee_account_id
            from accounts a
            join customers c on a.customer_id = c.customer_id
            where c.iin = v_employee_iin
            and a.is_active = true
            limit 1
            for update;

            if not found then
                raise exception 'employee account not found';
            end if;

            insert into transactions (from_account_id, to_account_id, amount, currency, amount_kzt, type, status, description)
            values (v_company_account_id, v_employee_account_id, v_amount, 'KZT', v_amount, 'transfer', 'completed', v_description)
            returning transaction_id into v_transaction_id;

            update transactions set completed_at = current_timestamp where transaction_id = v_transaction_id;

            v_success_count := v_success_count + 1;

            release savepoint payment_point;

        exception when others then
            rollback to savepoint payment_point;
            v_failed_count := v_failed_count + 1;
            v_failed_list := v_failed_list || jsonb_build_object('iin', v_employee_iin, 'error', sqlerrm);
        end;
    end loop;

    update accounts
    set balance = balance - (v_success_count * (v_total_needed / (v_success_count + v_failed_count)))
    where account_id = v_company_account_id;

    for v_payment in select * from jsonb_array_elements(p_payments) loop
        v_employee_iin := v_payment->>'iin';
        v_amount := (v_payment->>'amount')::numeric;

        if not exists(select 1 from jsonb_array_elements(v_failed_list) where value->>'iin' = v_employee_iin) then
            update accounts
            set balance = balance + v_amount
            where account_id in (
                select a.account_id
                from accounts a
                join customers c on a.customer_id = c.customer_id
                where c.iin = v_employee_iin
            );
        end if;
    end loop;

    perform pg_advisory_unlock(hashtext(p_company_account_number));

    return jsonb_build_object(
        'successful_count', v_success_count,
        'failed_count', v_failed_count,
        'failed_details', v_failed_list
    );
end;
$$ language plpgsql;

create materialized view salary_batch_summary as
select
    date(created_at) as payment_date,
    count(*) as payment_count,
    sum(amount_kzt) as total_amount,
    avg(amount_kzt) as avg_amount
from transactions
where description like '%salary%'
and status = 'completed'
group by date(created_at);