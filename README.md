# TPI Base de Datos - Food Store

Trabajo Práctico Integrador para la materia Base de Datos (PostgreSQL).

## Archivos del repositorio

* `schema.sql`: tiene la creación de las tablas, PKs, FKs, restricciones e índices[cite: 1].
* `data.sql`: los datos de prueba (INSERTs) para poblar las tablas[cite: 1].
* `objects.sql`: las vistas, la función del total, los triggers y el procedimiento `sp_crear_pedido`[cite: 1].
* `queries.sql`: las consultas de las historias de usuario y las analíticas[cite: 1].
* `transacciones.sql`: las pruebas de rollback, transacciones manuales y concurrencia (`FOR UPDATE`)[cite: 1].
* `README.md`: este archivo.

## Cómo correr los scripts

Para armar la base desde cero hay que ejecutar los archivos en DBeaver (o psql) en este orden exacto:

1. `schema.sql`
2. `data.sql`
3. `objects.sql`
4. `queries.sql` (ejecutar consulta por consulta)
5. `transacciones.sql`