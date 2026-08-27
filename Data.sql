-- =============================================================================
-- ARCHIVO: data.sql
-- DESCRIPCIÓN: Carga de datos iniciales (Seed Data)
-- =============================================================================

-- 1. USUARIOS
INSERT INTO usuario (nombre, apellido, mail, celular, contrasena, rol) VALUES
('Juan', 'Pérez', 'juan.perez@email.com', '1122334455', 'hash_pass_1', 'USUARIO'),
('María', 'Gómez', 'maria.gomez@email.com', '1166778899', 'hash_pass_2', 'USUARIO'),
('Carlos', 'López', 'carlos.lopez@email.com', '1144556677', 'hash_pass_3', 'ADMIN'),
('Ana', 'Martínez', 'ana.martinez@email.com', '1188990011', 'hash_pass_4', 'USUARIO');

-- 2. CATEGORÍAS
INSERT INTO categoria (nombre, descripcion) VALUES
('Hamburguesas', 'Hamburguesas artesanales de carne y vegetarianas'),
('Pizzas', 'Pizzas al horno de barro variadas'),
('Bebidas', 'Gaseosas, aguas y jugos naturales'),
('Postres', 'Helados y postres caseros');

-- 3. PRODUCTOS
INSERT INTO producto (nombre, precio, descripcion, stock, disponible, categoria_id) VALUES
('Hamburguesa Clásica', 4500.00, 'Medallón de carne 180g, queso cheddar, lechuga y tomate', 50, TRUE, 1),
('Hamburguesa Doble Bacon', 6200.00, 'Doble medallón de carne, doble cheddar y panceta crocante', 35, TRUE, 1),
('Pizza Muzzarella', 5800.00, 'Salsa de tomate, muzzarella y aceitunas verdes', 20, TRUE, 2),
('Pizza Napolitana', 6400.00, 'Salsa de tomate, muzzarella, tomate en rodajas y ajo', 15, TRUE, 2),
('Gaseosa Cola 500ml', 1500.00, 'Bebida sin alcohol sabor cola', 100, TRUE, 3),
('Agua Mineral 500ml', 1200.00, 'Agua mineral sin gas', 80, TRUE, 3),
('Volcán de Chocolate', 2800.00, 'Postre tibio de chocolate con bocha de helado de crema', 10, TRUE, 4);

-- 4. PEDIDOS E HISTORIAL INICIAL
INSERT INTO pedido (fecha, estado, total, forma_pago, usuario_id) VALUES
('2026-02-01', 'TERMINADO', 10500.00, 'EFECTIVO', 1),
('2026-02-02', 'CONFIRMADO', 7700.00, 'TARJETA', 2),
('2026-02-03', 'PENDIENTE', 1500.00, 'TRANSFERENCIA', 4);

-- 5. DETALLE DE PEDIDOS
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 1, 4500.00, 4500.00), -- 1x Hamburguesa Clásica
(1, 3, 1, 5800.00, 5800.00), -- 1x Pizza Muzzarella
(2, 2, 1, 6200.00, 6200.00), -- 1x Hamburguesa Doble Bacon
(2, 5, 1, 1500.00, 1500.00), -- 1x Gaseosa Cola
(3, 5, 1, 1500.00, 1500.00);  -- 1x Gaseosa Cola