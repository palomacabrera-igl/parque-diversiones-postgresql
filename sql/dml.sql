-- DML: Data Manipulation Language
-- Inserción de datos de ejemplo para pruebas.

-- Insert parques
INSERT INTO parque (capacidad_max, ubicacion) VALUES
(3, 'Montevideo'),
(2, 'San José'),
(1, 'Salto'),              -- Mínima capacidad
(5, 'Rivera'),             -- Más capacidad para tests
(0, 'Parque Fantasma');   -- Para probar validaciones de capacidad 0

-- Insert juegos
INSERT INTO juego DEFAULT VALUES;
INSERT INTO juego DEFAULT VALUES;
INSERT INTO juego DEFAULT VALUES;
INSERT INTO juego DEFAULT VALUES;
INSERT INTO juego DEFAULT VALUES;


-- Relación parque-juego
INSERT INTO parque_juego VALUES
(1, 1), (1, 2),
(2, 3), (2, 4),
(3, 5),
(4, 2), (4, 3);  -- Parque con juegos mixtos

-- Estacionamientos
INSERT INTO estacionamiento (capacidad_max, id_parque) VALUES
(2, 1),   -- Parque 1 con 2 espacios
(150, 2), -- Parque 2 con 150 espacios
(250, 3), -- Parque 3 con 250 espacios
(1, 4);   -- Parque 4 con 1 espacio (mínima capacidad para saturar)

-- Personas
-- Nota: 'nombre1' y 'apellido1' son NOT NULL, por lo que se proveen valores.
INSERT INTO persona (ci, nombre1, nombre2, apellido1, apellido2) VALUES
('12345678', 'Ana', NULL, 'Pérez', NULL),
('23456789', 'Luis', 'Miguel', 'Rodríguez', 'López'),
('34567890', 'Carla', NULL, 'Suárez', NULL),
('45678901', 'Martín', 'Andrés', 'Gómez', NULL),
('87654321', 'Lucía', NULL, 'Fernández', 'Pérez'),
('88888888', 'Visitante', NULL, 'Duplicado', NULL),
('99999999', 'Visitante', NULL, 'Saturación', NULL);

-- Clientes
INSERT INTO cliente VALUES ('12345678');
INSERT INTO cliente VALUES ('23456789');

-- Visitantes
INSERT INTO visitante VALUES
('12345678'),
('45678901'),
('87654321'),
('99999999'),
('88888888'),
('34567890');


-- Precios de pase
INSERT INTO precio_pase (id_parque, precio, fecha_desde, fecha_hasta) VALUES
(1, 500, '2025-01-01', '2025-12-31'),
(1, 400, '2024-01-01', '2024-12-31'), -- Ejemplo de precio anterior
(2, 400, '2024-01-01', '2024-12-31'),
(2, 450, '2025-01-01', '2025-12-31'),
(3, 550, '2025-01-01', '2025-12-31'),
(4, 550, '2025-01-01', '2025-12-31');

-- Compras
-- Nota: el total se actualizará por trigger al insertar los pases.
-- Se usa 'current_date' para la fecha de compra si no se especifica.
INSERT INTO compra (fecha, tipo, numero, ci_titular, ci_comprador) VALUES
('2025-01-10', 'Credito', '1111222233334444', '12345678', '12345678'),
('2025-01-15', 'Debito', '9999888877776666', '23456789', '23456789'),
('2025-01-20', 'Credito', '1234432112344321', '12345678', '34567890'),
('2025-01-25', 'Debito', '8888777766665555', '45678901', '87654321'),
('2025-02-01', 'Mastercard', '4444333322221111', '87654321', '12345678');


-- Compra estacionamiento
-- Estos inserts activarán el trigger 'trigger_controlar_estacionamiento'
INSERT INTO compra_estacionamiento VALUES
(1, 1, '2025-01-15', 2),  -- Parque 1, 2 lugares (capacidad máxima)
(2, 2, '2025-01-20', 1),
(4, 4, '2025-01-25', 1);  -- Parque 4, 1 lugar (capacidad mínima, para saturar)

-- Pases (se asume uso del id_precio_pase correcto según fecha)
-- Estos inserts activarán el trigger 'trigger_actualizar_total' en la tabla 'compra'.
INSERT INTO pase (id_compra, ci, id_parque, fecha, id_precio_pase) VALUES
(1, '34567890', 1, '2025-01-15', 1), -- compra 1, ci 34567890, parque 1, fecha 2025-01-15, precio_pase 1 (500)
(1, '45678901', 1, '2025-01-15', 1), -- compra 1, ci 45678901, parque 1, fecha 2025-01-15, precio_pase 1 (500)
-- Total compra 1 debería ser 1000
(2, '87654321', 2, '2025-01-20', 3), -- compra 2, ci 87654321, parque 2, fecha 2025-01-20, precio_pase 3 (400)
-- Total compra 2 debería ser 400
(3, '88888888', 3, '2025-01-20', 5), -- compra 3, ci 88888888, parque 3, fecha 2025-01-20, precio_pase 5 (550)
-- El siguiente pase intentaría saturar el parque 3 (capacidad 1), si el trigger de capacidad de parque estuviera en 'pase'
-- Pero está en 'acceso', y el C program ya valida la capacidad del parque.
-- (3, '99999999', 3, '2025-01-20', 5), -- Este pase fallaría si el parque 3 tuviera capacidad 1 y ya hubiera 1 pase para esa fecha
(4, '88888888', 3, '2025-01-21', 5);      -- Mismo visitante pero otro día, debería ser válido

-- Accesos
-- Estos inserts activarán el trigger 'trigger_verificar_capacidad'
INSERT INTO acceso (fecha, hora_entrada, hora_salida, id_pase) VALUES
('2025-01-15', '10:00', '18:00', 1), -- Pase 1
('2025-01-15', '10:30', NULL, 2),   -- Pase 2, aún en el parque. (Parque 1, capacidad 3. 2 personas en este punto.)
('2025-01-20', '11:00', '17:00', 3), -- Pase 3
('2025-01-20', '12:00', NULL, 4);   -- Pase 4. (Parque 3, capacidad 1. 1 persona dentro. Este pase debería pasar si el pase 4 es para un parque con capacidad suficiente.)

-- Uso de juegos
INSERT INTO uso_juego (fecha, hora, foto, id_juego, id_pase) VALUES
('2025-01-15', '11:00', NULL, 1, 1),
('2025-01-15', '12:00', NULL, 2, 1),
('2025-01-15', '11:30', NULL, 1, 2),
('2025-01-20', '13:00', NULL, 3, 3),
('2025-01-16', '14:00', NULL, 1, 1),  -- mismo pase que ya usó el 15
('2025-01-17', '15:00', NULL, 1, 2),  -- otro visitante usando el mismo juego
('2025-01-20', '12:00', NULL, 1, 3),  -- tercer visitante, otro día
('2025-02-01', '13:00', NULL, 1, 1),  -- mismo visitante repite en otro mes
('2025-02-02', '14:30', NULL, 1, 2);  -- otro visitante repite

-- Tasa de cambio
INSERT INTO tasa_cambio (fecha_desde, fecha_hasta, valor_usd) VALUES
('2025-01-01', '2025-12-31', 40),
('2024-01-01', '2024-12-31', 39.5);