# Protocolo de Seguridad — TPI Food Store DB

Este protocolo define las tres prácticas obligatorias que deben aplicarse al trabajar sobre la base de datos del proyecto. Ninguna de las tres tiene excepciones: siempre se ejecutan antes de cualquier cambio.

---

## 1. Copia de trabajo

**Principio:** nunca se trabaja directamente sobre la base que contiene datos que importan.

Antes de empezar cualquier sesión de desarrollo o prueba, crear una copia de trabajo a partir de la base original:

```bash
createdb -T food_store food_store_dev
```

- `food_store` es la base original (plantilla).
- `food_store_dev` es la copia sobre la que se trabaja.

Todo el desarrollo, prueba de scripts y validación de cambios se hace sobre `food_store_dev`. La base original permanece intacta.

> Si la copia ya existe de una sesión anterior y se quiere recrearla limpia:
> ```bash
> dropdb food_store_dev
> createdb -T food_store food_store_dev
> ```

---

## 2. Transacción antes de confirmar cualquier escritura

**Principio:** todo script que escribe (INSERT, UPDATE, DELETE, o llamadas a `sp_crear_pedido`) corre primero con `ROLLBACK` para inspeccionar el resultado antes de persistirlo.

### Flujo de trabajo

```sql
-- Paso 1: abrir transacción y ejecutar el script
BEGIN;

  -- Ejemplo: baja lógica de un producto
  UPDATE producto
  SET    eliminado = TRUE
  WHERE  id = 3 AND eliminado = FALSE;

  -- Inspeccionar el efecto (filas afectadas, estado actual)
  SELECT id, nombre, eliminado FROM producto WHERE id = 3;

-- Paso 2: si el resultado es el esperado → COMMIT; si no → ROLLBACK
ROLLBACK;  -- cambiar a COMMIT solo cuando el resultado es correcto
```

Esto aplica a todas las operaciones DML del proyecto:

| Operación | Ejemplo en el proyecto |
|---|---|
| Crear categoría/producto/usuario | `INSERT INTO categoria …` |
| Editar precio, stock, estado | `UPDATE producto SET precio = … ` |
| Baja lógica | `UPDATE … SET eliminado = TRUE` |
| Crear pedido con detalles | `CALL sp_crear_pedido(…)` |
| Baja lógica de pedido y detalles | bloque `BEGIN … COMMIT` de HU-PED-04 |

> **Nota sobre `sp_crear_pedido`:** el procedimiento maneja su propia transacción interna. Si ocurre un error (usuario inexistente, producto eliminado, stock insuficiente), PostgreSQL revierte automáticamente. Aun así, ejecutar la llamada dentro de un `BEGIN … ROLLBACK` externo permite inspeccionar el efecto completo antes de confirmarlo.

---

## 3. Respaldo antes de cambios estructurales (DDL)

**Principio:** antes de ejecutar cualquier `ALTER TABLE`, `DROP`, migración o cambio de esquema, se genera un dump de la copia de trabajo para poder revertir sin depender del `ROLLBACK`.

### Comando de respaldo

```bash
pg_dump -Fc food_store_dev -f respaldo_antes_ddl_$(Get-Date -Format "yyyyMMdd_HHmmss").dump
```

En sistemas Unix/Linux/macOS:

```bash
pg_dump -Fc food_store_dev -f respaldo_antes_ddl_$(date +%Y%m%d_%H%M%S).dump
```

### Restaurar desde el respaldo

```bash
dropdb food_store_dev
createdb food_store_dev
pg_restore -d food_store_dev respaldo_antes_ddl_<timestamp>.dump
```

### Cuándo es obligatorio el respaldo

| Acción | ¿Requiere respaldo previo? |
|---|---|
| `ALTER TABLE` (agregar/quitar columna, cambiar tipo) | ✅ Sí |
| `DROP TABLE` / `DROP TYPE` / `DROP INDEX` | ✅ Sí |
| Cambios en triggers o funciones (`CREATE OR REPLACE`) | ✅ Sí |
| Cambios en `sp_crear_pedido` | ✅ Sí |
| Scripts DML puros (INSERT, UPDATE, DELETE) | ❌ No (cubierto por la transacción) |

---

## Orden de ejecución recomendado por sesión

```
1. createdb -T food_store food_store_dev        ← copia de trabajo
2. pg_dump … (solo si hay DDL pendiente)         ← respaldo
3. BEGIN; … tu script … ; ROLLBACK;             ← validar sin persistir
4. Revisar el resultado de la inspección
5. Cambiar ROLLBACK por COMMIT si todo está bien
```

---

## Scripts del proyecto y su clasificación

| Archivo | Tipo | Requiere BEGIN/ROLLBACK | Requiere respaldo previo |
|---|---|---|---|
| `schema.sql` | DDL | No | ✅ Sí (recrea toda la estructura) |
| `data.sql` | DML | ✅ Sí | No |
| `objects.sql` | DDL (vistas, funciones, triggers, SP) | No | ✅ Sí |
| `queries.sql` | DML + SELECT | ✅ Sí (para DML) | No |
| `transacciones.sql` | DML transaccional | Ya incluye BEGIN/COMMIT/ROLLBACK | No |
