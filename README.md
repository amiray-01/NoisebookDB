# NoiseBook Database

## Overview
NoiseBook is a social network centered on music. This project implements the database backend in PostgreSQL, covering:

- **Conceptual Model**  
  The Entity–Relationship diagram and normalization are detailed in `Schema.pdf`.

- **Schema Definition**  
  `tables.sql` contains all `CREATE TABLE` statements, primary/foreign keys, and integrity constraints.

- **Data Population**  
  The `data_csv/` directory holds CSV files for each entity. You can load them using `\copy` in psql or integrate COPY commands into your SQL scripts.

- **Example Queries**  
  `requetes.sql` provides a suite of 20+ parameterized queries demonstrating:
  - Multi‑table joins
  - Recursive and window functions
  - Aggregations with `GROUP BY`/`HAVING`
  - Subqueries (in `WHERE`, in `FROM`, correlated)
  - Self‑joins and external joins
