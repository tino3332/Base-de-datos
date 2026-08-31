# AGENTS.md

## What this repo is

PostgreSQL-only project for a university course (TPI Base de Datos). A food store database: schema, seed data, views/functions/triggers, queries, and transaction demos. No application code, no build system, no tests, no CI.

## Files and execution order

Run scripts in DBeaver or `psql` in this exact order:

1. `schema.sql` — enums, sequences, tables, PKs, FKs, constraints, indexes
2. `Data.sql` — seed INSERTs (note: capital D in filename)
3. `objects.sql` — views, `calcular_total_pedido()`, triggers (`fn_recalcular_total`, `fn_set_subtotal`), `sp_crear_pedido` procedure
4. `queries.sql` — run query by query (contains DML like INSERT/UPDATE that mutate state)
5. `transacciones.sql` — manual transaction demos with ROLLBACK and `FOR UPDATE`

## Key conventions

- All tables use soft deletes (`eliminado boolean DEFAULT false`). Never `DELETE` rows — always `UPDATE eliminado = TRUE`.
- Views filter by `eliminado = false` automatically.
- `sp_crear_pedido` takes `(usuario_id, forma_pago, jsonb_items)` — it validates stock, locks rows with `FOR UPDATE`, deducts stock, and sets `precio_unitario` via trigger.
- `fn_set_subtotal` trigger auto-fills `precio_unitario` from `producto` if null, and computes `subtotal = cantidad * precio_unitario`.
- `fn_recalcular_total` trigger recalculates `pedido.total` from `detalle_pedido` rows.
- Enum types: `estado_pedido` (PENDIENTE/CONFIRMADO/TERMINADO/CANCELADO), `forma_pago` (TARJETA/TRANSFERENCIA/EFECTIVO), `rol` (ADMIN/USUARIO).

## Gotchas

- `queries.sql` is not idempotent — running it twice will duplicate data or error on unique constraints.
- `transacciones.sql` contains deliberate failures (product 9999) and ROLLBACKs; run carefully in a test database.
- `Data.sql` hardcodes `categoria_id` values (1–4) in product and pedido INSERTs — order-dependent on `schema.sql` identity sequences.
- Table/file naming inconsistency: file is `Data.sql` but references say `data.sql`.
