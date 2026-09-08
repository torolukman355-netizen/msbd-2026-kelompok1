SELECT DISTINCT
    s.store_id,
    f.title,
    f.rental_rate
FROM film f
JOIN inventory i ON i.film_id = f.film_id
JOIN store s ON s.store_id = i.store_id
WHERE f.rental_rate = (
    SELECT MAX(f2.rental_rate)
    FROM film f2
    JOIN inventory i2 ON i2.film_id = f2.film_id
    WHERE i2.store_id = s.store_id
)
ORDER BY s.store_id;