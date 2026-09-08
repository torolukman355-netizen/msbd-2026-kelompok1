-- ============================================
-- Q4: Film yang tidak pernah disewa
-- ============================================

-- Versi 1: pakai NOT IN
SELECT title
FROM film f
WHERE f.film_id NOT IN (
    SELECT i.film_id
    FROM inventory i
    JOIN rental r ON r.inventory_id = i.inventory_id
);

-- Versi 2: pakai NOT EXISTS
SELECT title
FROM film f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i
    JOIN rental r ON r.inventory_id = i.inventory_id
    WHERE i.film_id = f.film_id
);