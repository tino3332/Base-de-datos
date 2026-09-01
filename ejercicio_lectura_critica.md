# Ejercicio de Lectura Crítica — TPI Food Store DB

Análisis y corrección de dos scripts generados por IA para "dar de baja registros vencidos".

---

## Script 1

### Script original

```sql
-- Generado para: dar de baja las funciones de películas retiradas de cartel
UPDATE funcion
SET activa = FALSE;
```

### Análisis

El problema de este script es que no tiene cláusula `WHERE`, lo que significa que el cambio afecta a toda la tabla sin excepción. La consigna dice dar de baja solo las funciones de películas retiradas de cartel, pero tal como está escrito daría de baja todas las funciones, incluyendo las que deberían seguir activas.

### Script corregido

```sql
UPDATE funcion
SET activa = FALSE
WHERE fecha_fin < CURRENT_DATE
  AND activa = TRUE;
```

Con el `WHERE` el UPDATE afecta únicamente las funciones cuya fecha de fin ya pasó y que todavía figuran como activas.

---

## Script 2

### Script original

```sql
-- Generado para: limpiar las categorías sin productos asociados
DELETE FROM categoria
WHERE id NOT IN (SELECT categoria_id FROM producto);
```

### Análisis

Este script tiene dos problemas.

El primero es que usa `DELETE`, que borra físicamente los registros. En este proyecto todas las tablas usan baja lógica — nunca se borra una fila, siempre se marca con `eliminado = TRUE`. Usar `DELETE` viola esa convención y el cambio sería irreversible.

El segundo problema es el uso de `NOT IN` con una subconsulta que puede contener `NULL`. En SQL, cuando la subconsulta devuelve algún `NULL`, la condición `NOT IN` no puede evaluarse como verdadera para ninguna fila porque comparar cualquier valor con `NULL` da un resultado desconocido. Esto puede hacer que el script no borre nada, sin dar ningún error.

### Script corregido

```sql
UPDATE categoria
SET eliminado = TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM producto
    WHERE producto.categoria_id = categoria.id
      AND producto.eliminado = FALSE
)
AND eliminado = FALSE;
```

Se reemplaza `DELETE` por `UPDATE SET eliminado = TRUE` para respetar la baja lógica, y `NOT IN` por `NOT EXISTS` que no tiene el problema con los `NULL`.

---

## Conexión con los casos reales

Los cuatro incidentes de la Parte 3 comparten el mismo patrón que estos dos scripts: el código era sintácticamente correcto y la intención parecía razonable, pero nadie verificó qué haría realmente antes de ejecutarlo. El Script 1 habría dado de baja todas las funciones. El Script 2 habría borrado físicamente categorías en un esquema que nunca borra físicamente. En ambos casos el motor habría ejecutado sin error y el daño habría sido silencioso.
