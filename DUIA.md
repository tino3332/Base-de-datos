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
