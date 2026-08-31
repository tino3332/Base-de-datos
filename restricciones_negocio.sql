-- =============================================================================
-- ARCHIVO: restricciones_negocio.sql
-- DESCRIPCIÓN: Restricciones de integridad para reglas de negocio del dominio
--              pedido que hoy dependen de validación en la aplicación.
--
-- REGLAS IMPLEMENTADAS:
--   1. Transiciones de estado válidas en pedido.estado
--   2. Pedidos con estado TERMINADO o CANCELADO no son modificables
-- =============================================================================


-- -----------------------------------------------------------------------------
-- FUNCIÓN: fn_validar_estado_pedido
-- Dispara BEFORE UPDATE sobre la tabla pedido.
-- Valida dos reglas en orden:
--   a) Si el pedido ya está TERMINADO o CANCELADO, bloquea cualquier UPDATE.
--   b) Si el pedido está en otro estado, valida que la nueva transición sea
--      permitida según el ciclo de vida definido.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_validar_estado_pedido()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Regla 2: pedido cerrado no modificable
    IF OLD.estado IN ('TERMINADO', 'CANCELADO') THEN
        RAISE EXCEPTION
            'El pedido % está en estado % y no puede ser modificado.',
            OLD.id, OLD.estado;
    END IF;

    -- Regla 1: transición de estado válida
    -- Solo se valida cuando el campo estado efectivamente cambia
    IF NEW.estado <> OLD.estado THEN
        IF NOT (
            (OLD.estado = 'PENDIENTE'  AND NEW.estado IN ('CONFIRMADO', 'CANCELADO')) OR
            (OLD.estado = 'CONFIRMADO' AND NEW.estado IN ('TERMINADO',  'CANCELADO'))
        ) THEN
            RAISE EXCEPTION
                'Transición de estado inválida en pedido %: % → %.',
                OLD.id, OLD.estado, NEW.estado;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


-- -----------------------------------------------------------------------------
-- TRIGGER: trg_validar_estado_pedido
-- Se ejecuta antes de cada UPDATE sobre pedido, para cada fila afectada.
-- -----------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_validar_estado_pedido ON pedido;

CREATE TRIGGER trg_validar_estado_pedido
BEFORE UPDATE ON pedido
FOR EACH ROW
EXECUTE FUNCTION fn_validar_estado_pedido();
