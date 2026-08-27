-- DROP SCHEMA public;

-- DROP TYPE public.estado_pedido;

CREATE TYPE public.estado_pedido AS ENUM (
	'PENDIENTE',
	'CONFIRMADO',
	'TERMINADO',
	'CANCELADO');

-- DROP TYPE public.forma_pago;

CREATE TYPE public.forma_pago AS ENUM (
	'TARJETA',
	'TRANSFERENCIA',
	'EFECTIVO');

-- DROP TYPE public.rol;

CREATE TYPE public.rol AS ENUM (
	'ADMIN',
	'USUARIO');

-- DROP SEQUENCE public.categoria_id_seq;

CREATE SEQUENCE public.categoria_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE public.detalle_pedido_id_seq;

CREATE SEQUENCE public.detalle_pedido_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE public.pedido_id_seq;

CREATE SEQUENCE public.pedido_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE public.producto_id_seq;

CREATE SEQUENCE public.producto_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
-- DROP SEQUENCE public.usuario_id_seq;

CREATE SEQUENCE public.usuario_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;-- public.categoria definition

-- Drop table

-- DROP TABLE public.categoria;

CREATE TABLE public.categoria (
	id int8 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1 NO CYCLE) NOT NULL,
	nombre varchar(80) NOT NULL,
	descripcion varchar(255) NULL,
	eliminado bool DEFAULT false NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT categoria_nombre_key UNIQUE (nombre),
	CONSTRAINT categoria_pkey PRIMARY KEY (id)
);


-- public.usuario definition

-- Drop table

-- DROP TABLE public.usuario;

CREATE TABLE public.usuario (
	id int8 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1 NO CYCLE) NOT NULL,
	nombre varchar(80) NOT NULL,
	apellido varchar(80) NOT NULL,
	mail varchar(120) NOT NULL,
	celular varchar(30) NULL,
	contrasena varchar(255) NOT NULL,
	rol public.rol DEFAULT 'USUARIO'::rol NOT NULL,
	eliminado bool DEFAULT false NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT usuario_mail_key UNIQUE (mail),
	CONSTRAINT usuario_pkey PRIMARY KEY (id)
);


-- public.pedido definition

-- Drop table

-- DROP TABLE public.pedido;

CREATE TABLE public.pedido (
	id int8 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1 NO CYCLE) NOT NULL,
	fecha date DEFAULT CURRENT_DATE NOT NULL,
	estado public.estado_pedido DEFAULT 'PENDIENTE'::estado_pedido NOT NULL,
	total numeric(12, 2) DEFAULT 0 NOT NULL,
	forma_pago public.forma_pago NOT NULL,
	usuario_id int8 NOT NULL,
	eliminado bool DEFAULT false NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT pedido_pkey PRIMARY KEY (id),
	CONSTRAINT pedido_total_check CHECK ((total >= (0)::numeric)),
	CONSTRAINT pedido_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id)
);
CREATE INDEX idx_pedido_usuario ON public.pedido USING btree (usuario_id);


-- public.producto definition

-- Drop table

-- DROP TABLE public.producto;

CREATE TABLE public.producto (
	id int8 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1 NO CYCLE) NOT NULL,
	nombre varchar(120) NOT NULL,
	precio numeric(10, 2) NOT NULL,
	descripcion varchar(255) NULL,
	stock int4 DEFAULT 0 NOT NULL,
	imagen varchar(255) NULL,
	disponible bool DEFAULT true NOT NULL,
	categoria_id int8 NOT NULL,
	eliminado bool DEFAULT false NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT producto_pkey PRIMARY KEY (id),
	CONSTRAINT producto_precio_check CHECK ((precio >= (0)::numeric)),
	CONSTRAINT producto_stock_check CHECK ((stock >= 0)),
	CONSTRAINT producto_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categoria(id)
);
CREATE INDEX idx_producto_categoria ON public.producto USING btree (categoria_id);
CREATE INDEX idx_producto_nombre_activo ON public.producto USING btree (nombre) WHERE (eliminado = false);


-- public.detalle_pedido definition

-- Drop table

-- DROP TABLE public.detalle_pedido;

CREATE TABLE public.detalle_pedido (
	id int8 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1 NO CYCLE) NOT NULL,
	cantidad int4 NOT NULL,
	precio_unitario numeric(10, 2) NOT NULL,
	subtotal numeric(12, 2) NOT NULL,
	pedido_id int8 NOT NULL,
	producto_id int8 NOT NULL,
	eliminado bool DEFAULT false NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT detalle_pedido_cantidad_check CHECK ((cantidad > 0)),
	CONSTRAINT detalle_pedido_pedido_id_producto_id_key UNIQUE (pedido_id, producto_id),
	CONSTRAINT detalle_pedido_pkey PRIMARY KEY (id),
	CONSTRAINT detalle_pedido_precio_unitario_check CHECK ((precio_unitario >= (0)::numeric)),
	CONSTRAINT detalle_pedido_subtotal_check CHECK ((subtotal >= (0)::numeric)),
	CONSTRAINT detalle_pedido_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedido(id) ON DELETE RESTRICT,
	CONSTRAINT detalle_pedido_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.producto(id)
);