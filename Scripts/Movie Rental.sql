/*
 	- Business questions related to customer and their preferencies:		
 		What are the top 5 most popular movie genres among customers from a specific country?
		Which actors are most frequently rented by customers in different age ranges?
		What is the average rating for movies in each genre, and what is the average rating for movies with a specific actor?
		Which customers rent the most movies per year?
		What percentage of customers rented at least one movie every month in a given year?
	- Business questions related to movies and their popularity
		Which movies were most frequently rented in each quarter of a given year?
		What is the correlation between movie length and its rating? Does a correlation differ depending on gender and movie genre?
		Which movies had the biggest drop in popularity compared to the previous year?
		What are the top 10 most popular actor pairs (i.e., actors who frequently appear together in rented movies)?
		How has the average movie rating changed over time?
 */ 

-- What is the quality of data collected by the company? (duplicates, missing values, outliers, data consistency and types)

-- Duplicates

select count(*)
from renting as r
group by r.customer_id, r.movie_id, r.rating, r.date_renting 
having count(*) > 1;

select count(*)
from customers as c
group by c."name", c.country, c.gender, c.date_of_birth, c.date_account_start
having count(*) > 1;

select count(*)
from movies as m
group by m.title, m.genre, m.runtime, m.year_of_release, m.renting_price
having count(*) > 1;

select count(*)
from actors as a
group by a."name", a.year_of_birth, a.nationality, a.gender 
having count(*) > 1;

-- There is one duplicate in actors table. Which one?

SELECT a1.*
FROM actors AS a1
JOIN (
  SELECT name, year_of_birth, nationality, gender, COUNT(*)
  FROM actors
  GROUP BY name, year_of_birth, nationality, gender
  HAVING COUNT(*) > 1
) AS a
ON a1.name = a.name  -- Only check for a match on 'name'
ORDER BY name;

-- Removing the duplicated row

with duplicates as (
	select a."name", a.year_of_birth, a.nationality, a.gender,
	row_number() over (partition by a."name", a.year_of_birth, a.nationality, a.gender order by a.actor_id) as row_num 
	from actors as a
)
delete from actors 
where actor_id in ( 
	select actor_id
	from duplicates  
	where row_num >1
);

select count(*)
from actsin as ac
group by ac.movie_id, ac.actor_id 
having count(*) > 1;

-- missing values analysis
 
select *
from renting as r
where r.renting_id is null or r.customer_id is null or r.movie_id is null or r.rating is null or r.date_renting is null;

select count(*)
from renting as r
where rating is null;

select count(*)
from renting as r;

-- There is 250 out of total 578 rows with null values in 'rating' column. Customers should be encouraged to rate the movies they rent more often

select *
from customers as c
where c."name" is null or c.country is null or c.gender is null or c.date_of_birth is null or c.date_account_start is null; 

select *
from movies as m
where m.title is null or m.genre is null or m.runtime is null or m.year_of_release is null or m.renting_price is null;

select *
from actors as a
where a."name" is null or a.year_of_birth is null or a.nationality is null or a.gender is null;

-- Two rows in the actors table have null values in the 'year_of_birth' and 'nationality' columns.
-- No additional information about these actors could be found online, so the table cannot be completed.

-- Outliers and data consistency

select *
from renting as r
where r.rating < 0 or r.rating > 10;

select 
	min(r.date_renting),
	max(r.date_renting)
from renting as r;

select
	c.country,
	c.gender
from customers as c 
group by c.country, c.gender
order by c.gender; 

select
	min(c.date_of_birth),
	max(c.date_of_birth),
	min(c.date_account_start),
	max(c.date_account_start)
from customers as c;

select *
from customers as c
where c.date_of_birth > c.date_account_start;

select *
from customers as c
join renting as r
on c.customer_id = r.customer_id 
where c.date_account_start > r.date_renting; 

select *
from customers as c 
where name like '%[0-9]%' or name like '%,%' or name like '%;%';

select
	min(m.year_of_release),
	max(m.year_of_release),
	min(m.runtime),
	max(m.runtime),
	min(m.renting_price),
	max(m.renting_price)
from movies as m;

select distinct genre
from movies as m;

select 
	distinct a.gender
from actors as a;

select
	distinct a.nationality 
from actors as a;

select 
	min(a.year_of_birth),
	max(a.year_of_birth)
from actors as a;

select *
from actors as a
where a."name" like '%[0-9]%' or a."name" like '%,%' or a."name" like '%;%';

-- There is no outliers or error data values in the database. Data are consistent as well. Great job data engineers!

-- Data types checkout

select column_name, data_type
from information_schema.columns
where table_name = 'renting';

select column_name, data_type
from information_schema.columns
where table_name = 'customers';

select column_name, data_type
from information_schema.columns
where table_name = 'movies';

select column_name, data_type
from information_schema.columns
where table_name = 'actors';

select column_name, data_type
from information_schema.columns
where table_name = 'actsin';























