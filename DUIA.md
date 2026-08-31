# Declaración de Uso de IA (DUIA)
## Parte 1 — Integridad versionada: restricciones de negocio en la base de datos

| Campo | Detalle |
|---|---|
| **Herramienta** | Kiro (Amazon — Claude Sonnet) |
| **Spec o prompt utilizado** | Ver abajo |
| **Qué generó** | Ver abajo |
| **Qué se aceptó** | Ver abajo |
| **Qué se modificó o descartó, y por qué** | Ver abajo |
| **Verificación realizada** | Ver abajo |

---

## Spec o prompt utilizado

Texto exacto de la consigna dada a la IA:

> **Regla 1:** El campo `pedido.estado` solo puede avanzar en el ciclo de vida: `PENDIENTE → CONFIRMADO → TERMINADO`. Un pedido puede cancelarse desde `PENDIENTE` o `CONFIRMADO`, pero nunca puede volver atrás ni reactivarse desde `TERMINADO` o `CANCELADO`.
>
> **Regla 2:** Un pedido con `pedido.estado = 'TERMINADO'` o `pedido.estado = 'CANCELADO'` no puede recibir ningún UPDATE en sus campos.

---

## Qué generó

Kiro generó el archivo `restricciones_negocio.sql` con:

- La función `fn_validar_estado_pedido()` en PL/pgSQL que implementa ambas reglas dentro de un trigger `BEFORE UPDATE` sobre la tabla `pedido`.
- El trigger `trg_validar_estado_pedido` que asocia la función a la tabla `pedido`.

---

## Qué se aceptó

El archivo `restricciones_negocio.sql` se aceptó íntegramente tal como lo generó Kiro, sin modificaciones.

---

## Qué se modificó o descartó, y por qué

No se realizaron modificaciones ni descartes. El script se aplicó tal cual fue generado.

---

## Verificación realizada

Las pruebas se ejecutaron en DBeaver conectado a la base de datos del proyecto, con el pedido 1 en estado `PENDIENTE`.

| Operación ejecutada | Resultado esperado | Resultado obtenido |
|---|---|---|
| `UPDATE pedido SET estado = 'TERMINADO' WHERE id = 1` (estado actual: `PENDIENTE`) | ❌ Error — salto de estado inválido | ❌ `ERROR: Transición de estado inválida en pedido 1: PENDIENTE → TERMINADO.` |
| `UPDATE pedido SET estado = 'CONFIRMADO' WHERE id = 1` (estado actual: `PENDIENTE`) | ✅ OK — transición válida | ✅ Ejecutado sin error |
| `UPDATE pedido SET estado = 'PENDIENTE' WHERE id = 1` (estado actual: `CONFIRMADO`) | ❌ Error — retroceso de estado | ❌ `ERROR: Transición de estado inválida en pedido 1: CONFIRMADO → PENDIENTE.` |

Todos los resultados coinciden con lo esperado. El trigger funciona correctamente.

---

# Declaración de Uso de IA (DUIA)
## Parte 2 — Laboratorio: anomalías con dos sesiones concurrentes

| Campo | Detalle |
|---|---|
| **Herramienta** | Kiro (Amazon — Claude Sonnet) |
| **Spec o prompt utilizado** | Ver abajo |
| **Qué generó** | Ver abajo |
| **Qué se aceptó** | Ver abajo |
| **Qué se modificó o descartó, y por qué** | Ver abajo |
| **Verificación realizada** | Ver abajo |

---

## Spec o prompt utilizado

Se le pidió a la IA que guiara la reproducción de los cuatro escenarios de concurrencia (lectura no repetible, espera por bloqueo, lectura fantasma e interbloqueo) sobre las tablas `producto` y `pedido` del proyecto, y que explicara qué nivel de aislamiento o mecanismo resuelve cada uno.

---

## Qué generó

- Comandos exactos paso a paso para reproducir cada escenario en dos sesiones simultáneas en DBeaver.
- Explicación de qué ocurre en cada escenario y por qué.
- Explicación del nivel de aislamiento o mecanismo que resuelve cada problema.
- El archivo `informe_concurrencia.md` con las cuatro secciones completas.

---

## Qué se aceptó

- Los comandos SQL de cada escenario se aceptaron tal cual los propuso la IA.
- Las explicaciones de cada escenario se aceptaron tal cual y se copiaron en el informe.
- La estructura del informe (tabla por escenario con los campos de la consigna) se aceptó tal cual.

---

## Qué se modificó o descartó, y por qué

- Los valores de stock y COUNT en las tablas del informe se ajustaron a los resultados reales obtenidos en el motor (18, 5, 99, 1, 2), ya que la IA no podía conocer el estado exacto de la base de datos de antemano.
- El mensaje de error del interbloqueo se reemplazó por el texto exacto que devolvió PostgreSQL durante la reproducción.

---

## Verificación realizada

Todos los escenarios fueron reproducidos en DBeaver con dos sesiones independientes (verificado con `pg_backend_pid()`). Los resultados obtenidos coincidieron con los esperados según la explicación de la IA:

| Escenario | Resultado con Read Committed | Resultado con Repeatable Read / FOR UPDATE |
|---|---|---|
| Lectura no repetible | Segunda lectura devolvió stock distinto (18 → 5) | Segunda lectura devolvió el mismo valor (5) |
| Espera por bloqueo | Sesión B quedó bloqueada hasta el COMMIT de Sesión A | — |
| Lectura fantasma | Segundo COUNT devolvió valor distinto (1 → 2) | Segundo COUNT devolvió el mismo valor (2) |
| Interbloqueo | PostgreSQL lanzó error 40P01 y abortó una sesión | — |

Todas las explicaciones de la IA se confirmaron en el motor.
