from __future__ import annotations

import inspect
import logging
import os
import re
import time
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Iterator

from sqlalchemy import DateTime, ForeignKey, Integer, SmallInteger, Text, create_engine, event, func, select, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, joinedload, mapped_column, relationship, selectinload

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://msbd:msbd2026@localhost:5433/pagila",
)
REPORT_PATH = Path(__file__).with_name("lab5_orm_hasil.md")


# Q16 - Model deklaratif: semua class memakai gaya SQLAlchemy 2.0
# dengan Mapped, mapped_column, dan relationship.
class Base(DeclarativeBase):
    pass


# Q16 - Customer dipetakan ke public.customer.
# Relasi rentals sengaja dibiarkan lazy secara default agar Q17
# bisa memperlihatkan masalah N+1 saat c.rentals diakses.
class Customer(Base):
    __tablename__ = "customer"
    __table_args__ = {"schema": "public"}

    customer_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    first_name: Mapped[str] = mapped_column(Text)
    last_name: Mapped[str] = mapped_column(Text)

    rentals: Mapped[list["Rental"]] = relationship(back_populates="customer")


# Q16 - Rental dipetakan ke public.rental dan dihubungkan balik
# ke Customer melalui customer_id.
class Rental(Base):
    __tablename__ = "rental"
    __table_args__ = {"schema": "public"}

    rental_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    rental_date: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    inventory_id: Mapped[int] = mapped_column(Integer, ForeignKey("public.inventory.inventory_id"))
    customer_id: Mapped[int] = mapped_column(SmallInteger, ForeignKey("public.customer.customer_id"))

    customer: Mapped[Customer] = relationship(back_populates="rentals")
    inventory: Mapped["Inventory"] = relationship(back_populates="rentals")


# Q20 - Inventory dan Film adalah model pendukung untuk query analitik
# lima film tersewa terbanyak.
class Inventory(Base):
    __tablename__ = "inventory"
    __table_args__ = {"schema": "public"}

    inventory_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    film_id: Mapped[int] = mapped_column(SmallInteger, ForeignKey("public.film.film_id"))

    film: Mapped["Film"] = relationship(back_populates="inventories")
    rentals: Mapped[list[Rental]] = relationship(back_populates="inventory")


class Film(Base):
    __tablename__ = "film"
    __table_args__ = {"schema": "public"}

    film_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(Text)

    inventories: Mapped[list[Inventory]] = relationship(back_populates="film")


# Q20 - Potongan kode ORM yang disimpan ke laporan sebagai versi ORM.
ORM_TOP_FILMS_CODE = """\
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
"""

# Q20 - Versi SQL mentah dari query analitik yang sama.
RAW_TOP_FILMS_SQL = """
SELECT f.film_id, f.title, COUNT(r.rental_id) AS rental_count
FROM public.film AS f
JOIN public.inventory AS i ON i.film_id = f.film_id
JOIN public.rental AS r ON r.inventory_id = i.inventory_id
GROUP BY f.film_id, f.title
ORDER BY rental_count DESC, f.film_id
LIMIT 5
"""


@dataclass
class Measurement:
    select_count: int = 0
    elapsed_ms: float = 0.0
    logs: list[str] = field(default_factory=list)


@dataclass
class QueryResult:
    rows: list[Any]
    measurement: Measurement


class EchoCapture(logging.Handler):
    def __init__(self) -> None:
        super().__init__(level=logging.INFO)
        self.messages: list[str] = []

    def emit(self, record: logging.LogRecord) -> None:
        self.messages.append(record.getMessage())


def is_select(statement: str) -> bool:
    return statement.lstrip().upper().startswith("SELECT")


@contextmanager
def measured_selects(engine: Engine) -> Iterator[Measurement]:
    measurement = Measurement()
    capture = EchoCapture()
    logger = logging.getLogger("sqlalchemy.engine.Engine")

    def before_cursor_execute(
        conn: Any,
        cursor: Any,
        statement: str,
        parameters: Any,
        context: Any,
        executemany: bool,
    ) -> None:
        if is_select(statement):
            measurement.select_count += 1

    logger.addHandler(capture)
    event.listen(engine, "before_cursor_execute", before_cursor_execute)
    start = time.perf_counter()
    try:
        yield measurement
    finally:
        measurement.elapsed_ms = (time.perf_counter() - start) * 1000
        measurement.logs = capture.messages
        event.remove(engine, "before_cursor_execute", before_cursor_execute)
        logger.removeHandler(capture)


def compact_sql(message: str) -> str:
    return re.sub(r"\s+", " ", message).strip()


def select_log_snippet(logs: list[str], max_selects: int = 3) -> str:
    blocks: list[str] = []
    for index, message in enumerate(logs):
        if not is_select(message):
            continue

        block = compact_sql(message)
        if index + 1 < len(logs) and logs[index + 1].lstrip().startswith("["):
            block = f"{block}\n{logs[index + 1]}"
        blocks.append(block)

        if len(blocks) == max_selects:
            break

    return "\n\n".join(blocks)


def model_snippet() -> str:
    # Q16 - Ambil potongan model Customer dan Rental untuk dicetak/disimpan.
    return "\n\n".join(
        [
            inspect.getsource(Customer).strip(),
            inspect.getsource(Rental).strip(),
        ]
    )


def top_films_orm_statement():
    # Q20 - Bentuk ORM dari query lima film tersewa terbanyak.
    rental_count = func.count(Rental.rental_id).label("rental_count")
    return (
        select(Film.film_id, Film.title, rental_count)
        .join(Inventory, Inventory.film_id == Film.film_id)
        .join(Rental, Rental.inventory_id == Inventory.inventory_id)
        .group_by(Film.film_id, Film.title)
        .order_by(rental_count.desc(), Film.film_id)
        .limit(5)
    )


def prime_engine(engine: Engine) -> None:
    original_echo = engine.echo
    engine.echo = False
    try:
        with engine.connect() as conn:
            conn.exec_driver_sql("SELECT 1")
    finally:
        engine.echo = original_echo


def q17_n_plus_one(engine: Engine) -> QueryResult:
    # Q17 - Ambil 10 customer, lalu akses c.rentals satu per satu.
    # Karena relasi masih lazy, total SELECT yang ditargetkan adalah 1 + 10 = 11.
    with measured_selects(engine) as measurement:
        with Session(engine) as session:
            rows = session.scalars(select(Customer).limit(10)).all()
            summary = [(c.customer_id, len(c.rentals)) for c in rows]
    return QueryResult(summary, measurement)


def q18_selectinload(engine: Engine) -> QueryResult:
    # Q18 - selectinload mengambil customer dalam satu SELECT, lalu semua rental
    # terkait dalam SELECT kedua memakai WHERE customer_id IN (...).
    with measured_selects(engine) as measurement:
        with Session(engine) as session:
            rows = session.scalars(select(Customer).options(selectinload(Customer.rentals)).limit(10)).all()
            summary = [(c.customer_id, len(c.rentals)) for c in rows]
    return QueryResult(summary, measurement)


def q19_joinedload(engine: Engine) -> QueryResult:
    # Q19 - joinedload mengambil customer dan rental dalam satu SELECT
    # memakai LEFT OUTER JOIN; unique() diperlukan karena satu customer bisa
    # muncul berkali-kali akibat banyak rental.
    with measured_selects(engine) as measurement:
        with Session(engine) as session:
            rows = session.scalars(select(Customer).options(joinedload(Customer.rentals)).limit(10)).unique().all()
            summary = [(c.customer_id, len(c.rentals)) for c in rows]
    return QueryResult(summary, measurement)


def q20_top_films(engine: Engine) -> tuple[QueryResult, QueryResult, str]:
    # Q20 - Jalankan query analitik yang sama dengan ORM dan SQL mentah,
    # lalu simpan hasil serta waktu eksekusi masing-masing.
    orm_stmt = top_films_orm_statement()
    compiled_orm_sql = str(orm_stmt.compile(engine, compile_kwargs={"literal_binds": True}))

    with measured_selects(engine) as orm_measurement:
        with Session(engine) as session:
            orm_rows = session.execute(orm_stmt).all()

    with measured_selects(engine) as raw_measurement:
        with Session(engine) as session:
            raw_rows = session.execute(text(RAW_TOP_FILMS_SQL)).all()

    return QueryResult(orm_rows, orm_measurement), QueryResult(raw_rows, raw_measurement), compiled_orm_sql


def comparison_sentence(q18: QueryResult, q19: QueryResult) -> str:
    # Q19 - Kalimat ringkas yang membandingkan bentuk SQL selectinload vs joinedload.
    return (
        f"Q18 selectinload menghasilkan {q18.measurement.select_count} SELECT: satu SELECT customer "
        "lalu satu SELECT rental dengan WHERE rental.customer_id IN (...), sedangkan Q19 joinedload "
        f"menghasilkan {q19.measurement.select_count} SELECT berbentuk LEFT OUTER JOIN antara subquery "
        "customer ber-LIMIT dan tabel rental."
    )


def write_report(
    q17: QueryResult,
    q18: QueryResult,
    q19: QueryResult,
    q20_orm: QueryResult,
    q20_raw: QueryResult,
    q20_compiled_orm_sql: str,
) -> None:
    report = f"""# Hasil Lab 5 ORM

## Q16 - Model deklaratif

```python
{model_snippet()}
```

## Q17 - Bukti N+1

Jumlah SELECT: {q17.measurement.select_count} statement. Target: 11 statement.

Hasil ringkas:

```text
{q17.rows}
```

Potongan log:

```text
{select_log_snippet(q17.measurement.logs, max_selects=4)}
```

## Q18 - selectinload

Jumlah SELECT: {q18.measurement.select_count} statement. Target: 2 statement.

Hasil ringkas:

```text
{q18.rows}
```

Potongan log:

```text
{select_log_snippet(q18.measurement.logs, max_selects=2)}
```

## Q19 - joinedload

Jumlah SELECT: {q19.measurement.select_count} statement.

{comparison_sentence(q18, q19)}

Potongan log:

```text
{select_log_snippet(q19.measurement.logs, max_selects=1)}
```

## Q20 - ORM dibanding SQL mentah

Versi ORM:

```python
{ORM_TOP_FILMS_CODE}
```

SQL hasil kompilasi ORM:

```sql
{q20_compiled_orm_sql}
```

Versi SQL mentah:

```sql
{RAW_TOP_FILMS_SQL.strip()}
```

Waktu ORM: {q20_orm.measurement.elapsed_ms:.3f} ms.

Waktu SQL mentah: {q20_raw.measurement.elapsed_ms:.3f} ms.

Hasil ORM:

```text
{q20_orm.rows}
```

Hasil SQL mentah:

```text
{q20_raw.rows}
```
"""
    REPORT_PATH.write_text(report, encoding="utf-8")


def print_result(title: str, result: QueryResult, max_selects: int = 3, target_selects: int | None = None) -> None:
    print(f"\n--- {title} ---")
    if target_selects is None:
        print(f"SELECT count: {result.measurement.select_count}")
    else:
        print(f"SELECT count: {result.measurement.select_count} (target: {target_selects})")
    print(f"Elapsed: {result.measurement.elapsed_ms:.3f} ms")
    print(f"Rows: {result.rows}")
    print("Log snippet:")
    print(select_log_snippet(result.measurement.logs, max_selects=max_selects))


def main() -> int:
    print("--- Q16: Model deklaratif ---")
    print(model_snippet())

    engine = create_engine(DATABASE_URL, echo=True)
    try:
        prime_engine(engine)
    except OperationalError as exc:
        print("\nTidak bisa terhubung ke database.")
        print(f"DSN: {DATABASE_URL}")
        print(exc)
        return 1

    q17 = q17_n_plus_one(engine)
    print_result("Q17: Bukti N+1", q17, max_selects=4, target_selects=11)

    q18 = q18_selectinload(engine)
    print_result("Q18: selectinload", q18, max_selects=2, target_selects=2)

    q19 = q19_joinedload(engine)
    print_result("Q19: joinedload", q19, max_selects=1)
    print(comparison_sentence(q18, q19))

    q20_orm, q20_raw, q20_compiled_orm_sql = q20_top_films(engine)
    print_result("Q20: ORM top 5 film", q20_orm, max_selects=1)
    print_result("Q20: SQL mentah top 5 film", q20_raw, max_selects=1)

    write_report(q17, q18, q19, q20_orm, q20_raw, q20_compiled_orm_sql)
    print(f"\nLaporan disimpan ke: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
