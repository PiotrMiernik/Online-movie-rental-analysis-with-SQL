 

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
ON a1.name = a.name
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

select distinct a.gender
from actors as a;

select distinct a.nationality 
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

	-- All data types are correct

-- Business questions related to customer and their preferencies:

-- What are the top 3 most popular movie genres among customers from a specific country?

select
	m.genre,
	count(*) as num_of_rentals	 
from renting as r
left join movies as m
on r.movie_id = m.movie_id
left join customers as c
on r.customer_id = c.customer_id 
group by m.genre
order by count(*) desc 
limit 3;

	-- In general top 3 most popular movie genre are drama (319 rentals), SF&Fantasy (95) and comedy (69). The company needs more drama!

with top_genre as (
	select
		c.country,
		m.genre,
		count(*) as num_of_rentals,
		row_number() over (partition by c.country order by count(*) desc) as rank_genre 
	from renting as r
	left join movies as m
	on r.movie_id = m.movie_id
	left join customers as c
	on r.customer_id = c.customer_id
	group by m.genre, c.country
)
select
	country,
	genre,
	num_of_rentals	
from top_genre
where rank_genre <= 3 and
country = 'Poland';
	
	-- with above query we can check top 3 (5/10/...) genres for different countries


-- Which actors are most frequently rented by young customers (under 30)?

select
	a."name", 
	count(*) as num_of_rentals
from renting as r
inner join customers as c
on r.customer_id = c.customer_id
inner join movies as m
on r.movie_id = m.movie_id 
inner join actsin as ac
on m.movie_id = ac.movie_id 
inner join actors as a 
on ac.actor_id = a.actor_id
where (date_part('year', now()) - date_part('year', c.date_of_birth)) < 30
group by a."name"
order by num_of_rentals desc 
limit 3;
	
	-- Most frequently rented actors for customers under 30 are: Emma Watson, Daniel Radcliffe and Rupert Grint. Harry Potter rules!
		

-- What is the average rating for movies in each genre (with number of renting > 10), and what is the average rating for english-speaking and non-english speaking actors?

select
	m.genre,
	count(*),
	round(AVG(r.rating), 2) as avg_rating
from renting as r
inner join movies as m
on r.movie_id = m.movie_id
group by m.genre
having count(*) > 10
order by avg_rating desc;

	-- Action&Adventure movies have the highest rating (9.09) and Mystery&Suspense the lowest (6.83). The company needs more high quality detective stories!

select
	case 
		when a.nationality in ('Australia', 'British', 'Canada', 'Ireland', 'USA') then 'english'
		else 'non_english' 
	end as language_group,
	round(AVG(r.rating), 2) as avg_rating
from renting as r
inner join movies as m
on r.movie_id = m.movie_id 
inner join actsin as ac
on m.movie_id = ac.movie_id 
inner join actors as a
on ac.actor_id = a.actor_id
group by language_group;

	-- Non-English speaking actors appear in movies with a slightly higher rating (8.49) then English-speaking one (7.89). 
	-- But do people truly prefer art over entertainment? Let's find out!

with movie_stats as (
	select 
		r.movie_id,
		avg(r.rating) as avg_rating,
		count(*) as num_rentings
	from renting as r
	group by r.movie_id
)
select
	corr(avg_rating, num_rentings) as correlation
from movie_stats;

	-- Correlation coefficient equals 0.13 - there is no lineral relationship between rating and number of rentals
	-- But maybe relation between these two variables is mediated by another features like customer gender or movie genre? 

with movie_stats as (
	select
		c.gender,
		r.movie_id,
		avg(r.rating) as avg_rating,
		count(*) as num_rentings
	from renting as r
	inner join customers as c on r.customer_id = c.customer_id
	group by r.movie_id, c.gender
)
select
	gender,
	corr(avg_rating, num_rentings) as correlation
from movie_stats
group by gender;

	--	Correlation coefficients equal - 0.16 for female and 0.05 for male

with movie_stats as (
	select
		m.genre,
		r.movie_id,
		avg(r.rating) as avg_rating,
		count(*) as num_rentings
	from renting as r
	inner join movies as m on r.movie_id = m.movie_id
	group by r.movie_id, m.genre 
)
select
	count(*),
	genre,
	corr(avg_rating, num_rentings) as correlation
from movie_stats 
group by genre
having count(*) > 5
order by correlation desc;

/*
	In the query above, I only considered correlations for film genres with more than 5 rentals. Comedies have a correlation coefficient of 0.71, 
	indicating a fairly strong positive relationship between rating and number of rentals. 
	For the remaining genres, correlations are close to 0. This is an interesting insight!
*/ 	

-- Which customers rent the most movies in each year?

with customer_ranking as (
	select
		date_part('year', date_renting) as year_of_renting,
		c.name,
		count(*) as num_of_rentals,
		dense_rank() over (partition by date_part('year', r.date_renting) order by count(*) desc) as ranking  
	from renting r 
	inner join customers as c
	on r.customer_id = c.customer_id
	group by c.name, year_of_renting
)
select *
from customer_ranking
where ranking < 4;

	-- with above query we can check the company's best customers by number of rentals (top 3/5/10/...) in every year 

-- What percentage of customers rented at least one movie in each year?

with customer_one as(
	select
		r.customer_id,
		date_part('year', r.date_renting) as year_of_renting,
		count(*) as num_of_rentings 
	from renting as r
	group by r.customer_id, year_of_renting
	having count(*) >= 1
),
total_customers as (
	select 
		count(distinct r.customer_id) as num_customers
	from renting as r
)
select
	year_of_renting,
	count(customer_one.customer_id)::float / total_customers.num_customers * 100 as perc_of_customers
from customer_one, total_customers
group by year_of_renting, total_customers.num_customers 
order by year_of_renting;

	
	-- For 2017 there was 33 % of customers withe at least 

-- Business questions related to movies and their popularity

-- Which movies were most frequently rented in each quarter of a given year?

-- What is the correlation between movie length and its rating? Does a correlation differ depending on gender and movie genre?

-- Which movies had the biggest drop in popularity compared to the previous year?

-- What are the top 10 most popular actor pairs (i.e., actors who frequently appear together in rented movies)?

-- How has the average movie rating changed over time?
























