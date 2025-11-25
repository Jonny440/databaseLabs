
--task one creating function

create or replace function calculate_discount(
    original_price numeric,
    discount_percent numeric
)
returns numeric
language plpgsql
as $$
begin
    return original_price - (original_price * discount_percent / 100);
end;
$$;

select calculate_discount(100, 15);
select calculate_discount(250.50, 20);

--task two out param

create or replace function film_stats(
    p_rating varchar,
    out total_films integer,
    out avg_rental_rate numeric
)
language plpgsql
as $$
begin
    select
        count(*),
        avg(rental_rate)
    into total_films, avg_rental_rate
    from film
    where rating = p_rating;
end;
$$;

SELECT * FROM film_stats('PG');
SELECT * FROM film_stats('R');

--task three return table

create or replace function get_customer_rentals(
    p_customer_id integer
)
returns table (
    rental_date date,
    film_title varchar,
    return_date date
)
language plpgsql
as $$
begin
    return query
    select
        r.rental_date::date,
        f.title,
        r.return_date::date
    from rental r
    join inventory i on r.inventory_id = i.inventory_id
    join film f on i.film_id = f.film_id
    where r.customer_id = p_customer_id
    order by r.rental_date;
end;
$$;

select * from get_customer_rentals(1);
select * from get_customer_rentals(5) limit 5;

-- task four function overload
--version one
create or replace function search_films(
    p_title_pattern varchar
)
returns table (
    title varchar,
    release_year int
)
language plpgsql
as $$
begin
    return query
    select title, release_year
    from film
    where title ilike p_title_pattern;
end;
$$;

--version two
create or replace function search_films(
    p_title_pattern varchar,
    p_rating varchar
)
returns table (
    title varchar,
    release_year int,
    rating varchar
)
language plpgsql
as $$
begin
    return query
    select title, release_year, rating
    from film
    where title ilike p_title_pattern
      and rating = p_rating;
end;
$$;

SELECT * FROM search_films('A%');
SELECT * FROM search_films('A%', 'PG');