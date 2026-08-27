CREATE OR REPLACE VIEW public.v_categorias_vigentes
AS SELECT id,
    nombre,
    descripcion
   FROM categoria
  WHERE eliminado = false;

CREATE OR REPLACE VIEW public.v_pedido_detalle
AS SELECT dp.pedido_id,
    pr.nombre AS producto,
    dp.cantidad,
    dp.precio_unitario,
    dp.subtotal
   FROM detalle_pedido dp
     JOIN producto pr ON pr.id = dp.producto_id
  WHERE dp.eliminado = false;

CREATE OR REPLACE VIEW public.v_pedidos_resumen
AS SELECT ped.id,
    (u.nombre::text || ' '::text) || u.apellido::text AS usuario,
    ped.fecha,
    ped.estado,
    ped.forma_pago,
    ped.total
   FROM pedido ped
     JOIN usuario u ON u.id = ped.usuario_id
  WHERE ped.eliminado = false;

CREATE OR REPLACE VIEW public.v_productos_vigentes
AS SELECT p.id,
    p.nombre,
    p.precio,
    p.stock,
    c.nombre AS categoria
   FROM producto p
     JOIN categoria c ON c.id = p.categoria_id
  WHERE p.eliminado = false AND c.eliminado = false;

-- DROP FUNCTION public.calcular_total_pedido(int8);

CREATE OR REPLACE FUNCTION public.calcular_total_pedido(p_pedido_id bigint)
 RETURNS numeric
 LANGUAGE sql
 STABLE
AS $function$
    SELECT COALESCE(SUM(subtotal), 0)
    FROM   detalle_pedido
    WHERE  pedido_id = p_pedido_id AND eliminado = FALSE;
$function$
;

-- DROP FUNCTION public.fn_recalcular_total();

CREATE OR REPLACE FUNCTION public.fn_recalcular_total()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE pedido p
    SET total = calcular_total_pedido(p.id)
    WHERE p.id IN (SELECT pedido_id FROM afectados);
    RETURN NULL;
END;
$function$
;

-- DROP FUNCTION public.fn_set_subtotal();

CREATE OR REPLACE FUNCTION public.fn_set_subtotal()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.precio_unitario IS NULL THEN
        SELECT precio INTO NEW.precio_unitario
        FROM producto WHERE id = NEW.producto_id;
    END IF;
    NEW.subtotal := NEW.cantidad * NEW.precio_unitario;
    RETURN NEW;
END;
$function$
;

-- DROP PROCEDURE public.sp_crear_pedido(int8, forma_pago, jsonb);

CREATE OR REPLACE PROCEDURE public.sp_crear_pedido(IN p_usuario_id bigint, IN p_forma_pago forma_pago, IN p_items jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_pedido_id BIGINT;
    v_item      JSONB;
    v_producto_id BIGINT;
    v_cantidad    INTEGER;
    v_stock       INTEGER;
    v_disponible  BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id = p_usuario_id AND eliminado = FALSE) THEN
        RAISE EXCEPTION 'Usuario % inexistente o eliminado', p_usuario_id;
    END IF;

    INSERT INTO pedido(usuario_id, forma_pago)
    VALUES (p_usuario_id, p_forma_pago)
    RETURNING id INTO v_pedido_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
        v_producto_id := (v_item->>'producto_id')::BIGINT;
        v_cantidad    := (v_item->>'cantidad')::INTEGER;

        SELECT stock, disponible INTO v_stock, v_disponible
        FROM producto WHERE id = v_producto_id AND eliminado = FALSE
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Producto % inexistente o eliminado', v_producto_id;
        END IF;
        IF NOT v_disponible THEN
            RAISE EXCEPTION 'Producto % no disponible', v_producto_id;
        END IF;
        IF v_stock < v_cantidad THEN
            RAISE EXCEPTION 'Stock insuficiente (producto %): hay %, se piden %',
                            v_producto_id, v_stock, v_cantidad;
        END IF;

        INSERT INTO detalle_pedido(pedido_id, producto_id, cantidad)
        VALUES (v_pedido_id, v_producto_id, v_cantidad);

        UPDATE producto SET stock = stock - v_cantidad WHERE id = v_producto_id;
    END LOOP;
END;
$procedure$
;