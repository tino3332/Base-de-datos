# Informe de Concurrencia — TPI Food Store DB

Laboratorio de anomalías con dos sesiones concurrentes sobre la base de datos del proyecto.
Cada escenario fue reproducido en DBeaver con dos editores SQL conectados a sesiones independientes (verificado con `pg_backend_pid()`).

---

## Escenario 1 — Lectura no repetible

### Cómo se reprodujo

| Paso | Sesión A | Sesión B |
|---|---|---|
| 1 | `BEGIN;` | |
| 2 | `SELECT id, nombre, stock FROM producto WHERE id = 1;` → stock = **18** | |
| 3 | | `UPDATE producto SET stock = 5 WHERE id = 1;` (autocommit) |
| 4 | `SELECT id, nombre, stock FROM producto WHERE id = 1;` → stock = **5** | |
| 5 | `ROLLBACK;` | |

### Qué se observó

La Sesión A leyó el mismo dato dos veces dentro de la misma transacción y obtuvo resultados distintos. Entre las dos lecturas, la Sesión B modificó y confirmó el cambio. Con **Read Committed** (nivel por defecto), la segunda lectura vio el valor nuevo.

### Explicación de la IA

*(Kiro — Amazon Claude Sonnet)*

> Con Read Committed, PostgreSQL lee siempre la última versión confirmada de cada fila en el momento de cada sentencia. Esto significa que dos SELECT consecutivos dentro de la misma transacción pueden devolver resultados distintos si otra sesión confirma un cambio entre medias. Este fenómeno se llama lectura no repetible. Para evitarlo, hay que usar Repeatable Read, que toma una "foto" del estado de la base al inicio de la transacción y todas las lecturas dentro de ella ven siempre esa foto.

### Verificación en el motor

Se repitió el experimento con `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ`:

| Paso | Sesión A | Sesión B |
|---|---|---|
| 1 | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | |
| 2 | `SELECT id, nombre, stock FROM producto WHERE id = 1;` → stock = **5** | |
| 3 | | `UPDATE producto SET stock = 99 WHERE id = 1;` (autocommit) |
| 4 | `SELECT id, nombre, stock FROM producto WHERE id = 1;` → stock = **5** | |
| 5 | `ROLLBACK;` | |

La segunda lectura devolvió 5, no 99. El cambio de la Sesión B no fue visible.

### Conclusión

La explicación de la IA se confirmó. **Repeatable Read** resuelve la lectura no repetible manteniendo una snapshot consistente durante toda la transacción.

---

## Escenario 2 — Espera por bloqueo

### Cómo se reprodujo

| Paso | Sesión A | Sesión B |
|---|---|---|
| 1 | `BEGIN;` | |
| 2 | `SELECT id, nombre, stock FROM producto WHERE id = 1 FOR UPDATE;` → devuelve fila | |
| 3 | | `BEGIN;` |
| 4 | | `SELECT id, nombre, stock FROM producto WHERE id = 1 FOR UPDATE;` → **queda esperando** |
| 5 | `COMMIT;` | |
| 6 | | Sesión B se desbloquea y devuelve la fila |
| 7 | | `ROLLBACK;` |

### Qué se observó

La Sesión B quedó bloqueada sin devolver resultado ni error, esperando que la Sesión A liberara el bloqueo. En cuanto la Sesión A hizo `COMMIT`, la Sesión B se desbloqueó y continuó normalmente.

### Explicación de la IA

*(Kiro — Amazon Claude Sonnet)*

> `SELECT ... FOR UPDATE` adquiere un bloqueo exclusivo sobre las filas seleccionadas. Mientras ese bloqueo esté activo, cualquier otra sesión que intente bloquear la misma fila queda en espera. Este mecanismo se llama bloqueo pesimista y es el que usa `sp_crear_pedido` para evitar sobreventa: bloquea el producto antes de verificar el stock, garantizando que ninguna otra sesión pueda modificarlo hasta que la transacción termine.

### Verificación en el motor

El comportamiento se confirmó directamente durante la reproducción. La Sesión B esperó activamente hasta el `COMMIT` de la Sesión A.

### Conclusión

La explicación de la IA se confirmó. **`FOR UPDATE`** es el mecanismo que resuelve la concurrencia sobre filas individuales, bloqueando el acceso hasta que la transacción propietaria del bloqueo termine.

---

## Escenario 3 — Lectura fantasma

### Cómo se reprodujo

| Paso | Sesión A | Sesión B |
|---|---|---|
| 1 | `BEGIN;` | |
| 2 | `SELECT COUNT(*) FROM pedido WHERE eliminado = FALSE;` → **1** | |
| 3 | | `INSERT INTO pedido (usuario_id, forma_pago) VALUES (1, 'EFECTIVO');` (autocommit) |
| 4 | `SELECT COUNT(*) FROM pedido WHERE eliminado = FALSE;` → **2** | |
| 5 | `ROLLBACK;` | |

### Qué se observó

La Sesión A ejecutó el mismo COUNT dos veces dentro de la misma transacción y obtuvo resultados distintos. La fila insertada por la Sesión B apareció como una fila "fantasma" en la segunda lectura.

### Explicación de la IA

*(Kiro — Amazon Claude Sonnet)*

> La lectura fantasma ocurre cuando una transacción ejecuta la misma consulta con una condición de rango o agregación y obtiene filas distintas porque otra sesión insertó o eliminó filas que cumplen esa condición. Con Read Committed esto ocurre porque cada sentencia ve la última versión confirmada. Con Repeatable Read, PostgreSQL congela la snapshot al inicio de la transacción e ignora las filas nuevas insertadas por otras sesiones.

### Verificación en el motor

Se repitió el experimento con `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ`:

| Paso | Sesión A | Sesión B |
|---|---|---|
| 1 | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | |
| 2 | `SELECT COUNT(*) FROM pedido WHERE eliminado = FALSE;` → **2** | |
| 3 | | `INSERT INTO pedido (usuario_id, forma_pago) VALUES (1, 'TARJETA');` (autocommit) |
| 4 | `SELECT COUNT(*) FROM pedido WHERE eliminado = FALSE;` → **2** | |
| 5 | `ROLLBACK;` | |

El COUNT no cambió aunque la Sesión B insertó un pedido nuevo.

### Conclusión

La explicación de la IA se confirmó. **Repeatable Read** resuelve la lectura fantasma manteniendo la snapshot congelada durante toda la transacción.

---

## Escenario 4 — Interbloqueo (opcional)

### Cómo se reprodujo

| Paso | Sesión A | Sesión B |
|---|---|---|
| 1 | `BEGIN;` | |
| 2 | `SELECT id, nombre FROM producto WHERE id = 1 FOR UPDATE;` → devuelve fila | |
| 3 | | `BEGIN;` |
| 4 | | `SELECT id, nombre FROM producto WHERE id = 2 FOR UPDATE;` → devuelve fila |
| 5 | `SELECT id, nombre FROM producto WHERE id = 2 FOR UPDATE;` → **queda esperando** | |
| 6 | | `SELECT id, nombre FROM producto WHERE id = 1 FOR UPDATE;` → **error 40P01** |
| 7 | `ROLLBACK;` | `ROLLBACK;` |

### Qué se observó

```
SQL Error [40P01]: ERROR: se ha detectado un deadlock
Detail: El proceso 9476 espera ShareLock en transacción 947; bloqueado por proceso 18632.
El proceso 18632 espera ShareLock en transacción 948; bloqueado por proceso 9476.
Where: mientras se bloqueaba la tupla (0,5) de la relación «producto»
```

PostgreSQL detectó el círculo de espera y abortó automáticamente una de las dos sesiones.

### Explicación de la IA

*(Kiro — Amazon Claude Sonnet)*

> Un interbloqueo ocurre cuando dos sesiones se esperan mutuamente en círculo: A espera a B y B espera a A. Ninguna puede avanzar sola. PostgreSQL tiene un detector de deadlocks que periódicamente revisa el grafo de esperas. Cuando detecta un ciclo, elige una víctima (generalmente la transacción con menos costo de rollback) y la aborta con el error 40P01, permitiendo que la otra continúe. La forma de evitarlo es que todas las transacciones adquieran bloqueos siempre en el mismo orden — por ejemplo, siempre bloquear primero el producto con menor id.

### Verificación en el motor

El error 40P01 se reprodujo exactamente como describió la IA. PostgreSQL abortó una de las sesiones automáticamente al detectar el ciclo de espera.

### Conclusión

La explicación de la IA se confirmó. El mecanismo de resolución de PostgreSQL es automático — detecta el deadlock y aborta una sesión. La prevención en el diseño consiste en **adquirir bloqueos siempre en el mismo orden** entre todas las transacciones.

---

## Resumen general

| Escenario | Nivel/Mecanismo que lo causa | Solución |
|---|---|---|
| Lectura no repetible | Read Committed (default) | Repeatable Read |
| Espera por bloqueo | FOR UPDATE | Esperado y deseable — garantiza exclusividad |
| Lectura fantasma | Read Committed (default) | Repeatable Read |
| Interbloqueo | Adquisición de bloqueos en orden cruzado | Adquirir bloqueos siempre en el mismo orden |
