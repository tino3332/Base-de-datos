-- =============================================================================
-- ARCHIVO: transacciones.sql
-- DESCRIPCIÓN: Escenarios transaccionales, Rollback y Concurrencia
-- =============================================================================

-- 1. DEMOSTRACIÓN DE ATOMICIDAD Y ROLLBACK (Error por producto inexistente)
-- Al intentar insertar un producto inexistente, la transacción se aborta por completo.
BEGIN;
  CALL sp_crear_pedido(
       1,
       'EFECTIVO',
       '[{"producto_id": 9999, "cantidad": 1}]'::jsonb
  );
-- Nota: Lanzará la excepción "Producto 9999 inexistente o eliminado" provocando un ROLLBACK automático.
ROLLBACK;


-- 2. TRANSACCIÓN MANUAL CON COMMIT Y ROLLBACK
-- Ejemplo A: Transacción exitosa guardada con COMMIT
BEGIN;
  INSERT INTO categoria(nombre, descripcion) 
  VALUES ('Bebidas', 'Gaseosas y Jugos');
COMMIT;

-- Ejemplo B: Transacción cancelada manualmente con ROLLBACK
BEGIN;
  INSERT INTO categoria(nombre, descripcion) 
  VALUES ('Postres Test', 'Prueba de rollback');
ROLLBACK;
-- Comprobación: 'Postres Test' no fue guardado en la tabla categoria.


-- 3. DEMOSTRACIÓN DE CONCURRENCIA Y BLOQUEOS (SELECT FOR UPDATE)
-- Simula la prevención de sobreventa sobre el stock del producto 1.
BEGIN;
  -- Bloquea la fila del producto impidiendo que otra sesión modifique el stock simultáneamente
  SELECT id, nombre, stock, disponible 
  FROM producto 
  WHERE id = 1 AND eliminado = FALSE 
  FOR UPDATE;
  
  -- Descuento seguro del stock
  UPDATE producto 
  SET stock = stock - 1 
  WHERE id = 1;
COMMIT;