CREATE OR REPLACE PROCEDURE lab5.process_rental_safe(
  p_customer_id  integer,
  p_inventory_id integer,
  p_staff_id     integer,
  p_amount       numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id, status)
  VALUES (p_customer_id, p_inventory_id, p_staff_id, 'ACTIVE');

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (currval(pg_get_serial_sequence('lab5.rental_tx','rental_id'))::bigint, p_amount);

EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE NOTICE 'FK violation: customer/inventory/staff tidak valid. Rollback otomatis.';
END;
$$;