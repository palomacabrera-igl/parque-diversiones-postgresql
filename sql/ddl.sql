-- DDL: Data Definition Language
-- Creación de tablas para el sistema de gestión de parques de diversiones.

-- La base se crea aparte, antes de ejecutar este script (ver README):
-- CREATE DATABASE lab02;

CREATE TABLE parque (
    id_parque SERIAL PRIMARY KEY,
    capacidad_max INT NOT NULL,
    ubicacion VARCHAR(100) NOT NULL
);

CREATE TABLE juego (
    id_juego SERIAL PRIMARY KEY
);

CREATE TABLE parque_juego (
    id_parque INT,
    id_juego INT,
    PRIMARY KEY (id_parque, id_juego)
);

CREATE TABLE estacionamiento (
    id_estacionamiento SERIAL PRIMARY KEY,
    capacidad_max INT NOT NULL,
    id_parque INT UNIQUE NOT NULL
);

CREATE TABLE persona (
    ci CHAR(8) PRIMARY KEY,
    nombre1 VARCHAR(50) NOT NULL,
    nombre2 VARCHAR(50),
    apellido1 VARCHAR(50) NOT NULL,
    apellido2 VARCHAR(50)
);

CREATE TABLE cliente (
    ci CHAR(8) PRIMARY KEY
);

CREATE TABLE visitante (
    ci CHAR(8) PRIMARY KEY
);

CREATE TABLE precio_pase (
    id_precio_pase SERIAL UNIQUE,
    id_parque INT,
    precio NUMERIC NOT NULL,
    fecha_desde DATE NOT NULL,
    fecha_hasta DATE NOT NULL,
    PRIMARY KEY (id_parque, id_precio_pase)
);

CREATE TABLE compra (
    id_compra SERIAL PRIMARY KEY,
    fecha DATE NOT NULL DEFAULT now(),
    tipo VARCHAR(50) NOT NULL,
    numero VARCHAR(50) NOT NULL,
    ci_titular CHAR(8) NOT NULL,
    ci_comprador CHAR(8) NOT NULL,
    total NUMERIC
);

CREATE TABLE compra_estacionamiento (
    id_compra INT,
    id_parque INT,
    fecha DATE,
    cantidad INT
);

CREATE TABLE pase (
    id_pase SERIAL PRIMARY KEY,
    id_compra INT,
    ci CHAR(8),
    id_parque INT,
    fecha DATE NOT NULL,
    id_precio_pase INT
);

CREATE TABLE acceso (
    id_acceso SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    hora_entrada TIME NOT NULL,
    hora_salida TIME,
    id_pase INT NOT NULL
);

CREATE TABLE uso_juego (
    id_usojuego SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    foto BYTEA,
    id_juego INT NOT NULL,
    id_pase INT NOT NULL
);

CREATE TABLE tasa_cambio (
    fecha_desde DATE NOT NULL,
    fecha_hasta DATE NOT NULL,
    valor_usd NUMERIC NOT NULL,
    PRIMARY KEY (fecha_desde, fecha_hasta)
);