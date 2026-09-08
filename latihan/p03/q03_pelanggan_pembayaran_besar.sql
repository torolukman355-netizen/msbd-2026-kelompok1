SELECT
    c.first_name,
    c.last_name
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM payment p
    WHERE p.customer_id = c.customer_id
      AND p.amount > 9.99
);