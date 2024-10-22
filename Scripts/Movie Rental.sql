select 
	m.genre,
	round(AVG(r.rating), 2) as avg_rating
from movies as m
left join renting as r
on m.movie_id = r.movie_id
group by m.genre
order by avg_rating asc;