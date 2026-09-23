# Hasil Lab 5 ORM

## Q16 - Model deklaratif

```python
class Customer(Base):
    __tablename__ = "customer"
    __table_args__ = {"schema": "public"}

    customer_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    first_name: Mapped[str] = mapped_column(Text)
    last_name: Mapped[str] = mapped_column(Text)

    rentals: Mapped[list["Rental"]] = relationship(back_populates="customer")

class Rental(Base):
    __tablename__ = "rental"
    __table_args__ = {"schema": "public"}

    rental_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    rental_date: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    inventory_id: Mapped[int] = mapped_column(Integer, ForeignKey("public.inventory.inventory_id"))
    customer_id: Mapped[int] = mapped_column(SmallInteger, ForeignKey("public.customer.customer_id"))

    customer: Mapped[Customer] = relationship(back_populates="rentals")
    inventory: Mapped["Inventory"] = relationship(back_populates="rentals")
```

## Q17 - Bukti N+1

Jumlah SELECT: 11 statement. Target: 11 statement.

Hasil ringkas:

```text
[(1, 32), (2, 27), (3, 26), (4, 22), (5, 38), (6, 28), (7, 33), (8, 24), (9, 23), (10, 25)]
```

Potongan log:

```text
SELECT public.customer.customer_id, public.customer.first_name, public.customer.last_name FROM public.customer LIMIT %(param_1)s::INTEGER
[generated in 0.00416s] {'param_1': 10}

SELECT public.rental.rental_id AS public_rental_rental_id, public.rental.rental_date AS public_rental_rental_date, public.rental.inventory_id AS public_rental_inventory_id, public.rental.customer_id AS public_rental_customer_id FROM public.rental WHERE %(param_1)s::INTEGER = public.rental.customer_id
[generated in 0.00092s] {'param_1': 1}

SELECT public.rental.rental_id AS public_rental_rental_id, public.rental.rental_date AS public_rental_rental_date, public.rental.inventory_id AS public_rental_inventory_id, public.rental.customer_id AS public_rental_customer_id FROM public.rental WHERE %(param_1)s::INTEGER = public.rental.customer_id
[cached since 0.06999s ago] {'param_1': 2}

SELECT public.rental.rental_id AS public_rental_rental_id, public.rental.rental_date AS public_rental_rental_date, public.rental.inventory_id AS public_rental_inventory_id, public.rental.customer_id AS public_rental_customer_id FROM public.rental WHERE %(param_1)s::INTEGER = public.rental.customer_id
[cached since 0.09197s ago] {'param_1': 3}
```

## Q18 - selectinload

Jumlah SELECT: 2 statement. Target: 2 statement.

Hasil ringkas:

```text
[(1, 32), (2, 27), (3, 26), (4, 22), (5, 38), (6, 28), (7, 33), (8, 24), (9, 23), (10, 25)]
```

Potongan log:

```text
SELECT public.customer.customer_id, public.customer.first_name, public.customer.last_name FROM public.customer LIMIT %(param_1)s::INTEGER
[generated in 0.00182s] {'param_1': 10}

SELECT public.rental.customer_id AS public_rental_customer_id, public.rental.rental_id AS public_rental_rental_id, public.rental.rental_date AS public_rental_rental_date, public.rental.inventory_id AS public_rental_inventory_id FROM public.rental WHERE public.rental.customer_id IN (%(primary_keys_1)s::SMALLINT, %(primary_keys_2)s::SMALLINT, %(primary_keys_3)s::SMALLINT, %(primary_keys_4)s::SMALLINT, %(primary_keys_5)s::SMALLINT, %(primary_keys_6)s::SMALLINT, %(primary_keys_7)s::SMALLINT, %(primary_keys_8)s::SMALLINT, %(primary_keys_9)s::SMALLINT, %(primary_keys_10)s::SMALLINT)
[generated in 0.00201s] {'primary_keys_1': 1, 'primary_keys_2': 2, 'primary_keys_3': 3, 'primary_keys_4': 4, 'primary_keys_5': 5, 'primary_keys_6': 6, 'primary_keys_7': 7, 'primary_keys_8': 8, 'primary_keys_9': 9, 'primary_keys_10': 10}
```

## Q19 - joinedload

Jumlah SELECT: 1 statement.

Q18 selectinload menghasilkan 2 SELECT: satu SELECT customer lalu satu SELECT rental dengan WHERE rental.customer_id IN (...), sedangkan Q19 joinedload menghasilkan 1 SELECT berbentuk LEFT OUTER JOIN antara subquery customer ber-LIMIT dan tabel rental.

Potongan log:

```text
SELECT anon_1.customer_id, anon_1.first_name, anon_1.last_name, rental_1.rental_id, rental_1.rental_date, rental_1.inventory_id, rental_1.customer_id AS customer_id_1 FROM (SELECT public.customer.customer_id AS customer_id, public.customer.first_name AS first_name, public.customer.last_name AS last_name FROM public.customer LIMIT %(param_1)s::INTEGER) AS anon_1 LEFT OUTER JOIN public.rental AS rental_1 ON anon_1.customer_id = rental_1.customer_id
[generated in 0.00307s] {'param_1': 10}
```

## Q20 - ORM dibanding SQL mentah

Versi ORM:

```python
rental_count = func.count(Rental.rental_id).label("rental_count")
stmt = (
    select(Film.film_id, Film.title, rental_count)
    .join(Inventory, Inventory.film_id == Film.film_id)
    .join(Rental, Rental.inventory_id == Inventory.inventory_id)
    .group_by(Film.film_id, Film.title)
    .order_by(rental_count.desc(), Film.film_id)
    .limit(5)
)
rows = session.execute(stmt).all()

```

SQL hasil kompilasi ORM:

```sql
SELECT public.film.film_id, public.film.title, count(public.rental.rental_id) AS rental_count 
FROM public.film JOIN public.inventory ON public.inventory.film_id = public.film.film_id JOIN public.rental ON public.rental.inventory_id = public.inventory.inventory_id GROUP BY public.film.film_id, public.film.title ORDER BY rental_count DESC, public.film.film_id 
 LIMIT 5
```

Versi SQL mentah:

```sql
SELECT f.film_id, f.title, COUNT(r.rental_id) AS rental_count
FROM public.film AS f
JOIN public.inventory AS i ON i.film_id = f.film_id
JOIN public.rental AS r ON r.inventory_id = i.inventory_id
GROUP BY f.film_id, f.title
ORDER BY rental_count DESC, f.film_id
LIMIT 5
```

Waktu ORM: 97.406 ms.

Waktu SQL mentah: 45.637 ms.

Hasil ORM:

```text
[(103, 'BUCKET BROTHERHOOD', 34), (738, 'ROCKETEER MOTHER', 33), (331, 'FORWARD TEMPLE', 32), (382, 'GRIT CLOCKWORK', 32), (489, 'JUGGLER HARDLY', 32)]
```

Hasil SQL mentah:

```text
[(103, 'BUCKET BROTHERHOOD', 34), (738, 'ROCKETEER MOTHER', 33), (331, 'FORWARD TEMPLE', 32), (382, 'GRIT CLOCKWORK', 32), (489, 'JUGGLER HARDLY', 32)]
```
