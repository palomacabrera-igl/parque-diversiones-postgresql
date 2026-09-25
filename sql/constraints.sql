-- CONSTRAINTS: Foreign Keys y Check Constraints

-- FK en parque_juego
ALTER TABLE parque_juego
ADD CONSTRAINT fk_parque_juego_parque FOREIGN KEY (id_parque) REFERENCES parque(id_parque);

ALTER TABLE parque_juego
ADD CONSTRAINT fk_parque_juego_juego FOREIGN KEY (id_juego) REFERENCES juego(id_juego);

-- FK en estacionamiento
ALTER TABLE estacionamiento
ADD CONSTRAINT fk_estacionamiento_parque FOREIGN KEY (id_parque) REFERENCES parque(id_parque);

-- FK en cliente y visitante
ALTER TABLE cliente
ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (ci) REFERENCES persona(ci);

ALTER TABLE visitante
ADD CONSTRAINT fk_visitante_persona FOREIGN KEY (ci) REFERENCES persona(ci);

-- FK en precio_pase
ALTER TABLE precio_pase
ADD CONSTRAINT fk_precio_pase_parque FOREIGN KEY (id_parque) REFERENCES parque(id_parque);

-- FK en compra
ALTER TABLE compra
ADD CONSTRAINT fk_compra_titular FOREIGN KEY (ci_titular) REFERENCES persona(ci);

ALTER TABLE compra
ADD CONSTRAINT fk_compra_comprador FOREIGN KEY (ci_comprador) REFERENCES persona(ci);

-- FK en compra_estacionamiento
ALTER TABLE compra_estacionamiento
ADD CONSTRAINT pk_compra_estacionamiento PRIMARY KEY (id_compra, id_parque, fecha);

ALTER TABLE compra_estacionamiento
ADD CONSTRAINT fk_ce_compra FOREIGN KEY (id_compra) REFERENCES compra(id_compra);

ALTER TABLE compra_estacionamiento
ADD CONSTRAINT fk_ce_parque FOREIGN KEY (id_parque) REFERENCES parque(id_parque);

-- FK en pase
ALTER TABLE pase
ADD CONSTRAINT fk_pase_compra FOREIGN KEY (id_compra) REFERENCES compra(id_compra);

ALTER TABLE pase
ADD CONSTRAINT fk_pase_visitante FOREIGN KEY (ci) REFERENCES visitante(ci);

ALTER TABLE pase
ADD CONSTRAINT fk_pase_parque FOREIGN KEY (id_parque) REFERENCES parque(id_parque);

ALTER TABLE pase
ADD CONSTRAINT fk_pase_precio FOREIGN KEY (id_precio_pase) REFERENCES precio_pase(id_precio_pase);

-- FK en acceso
ALTER TABLE acceso
ADD CONSTRAINT fk_acceso_pase FOREIGN KEY (id_pase) REFERENCES pase(id_pase);

-- FK en uso_juego
ALTER TABLE uso_juego
ADD CONSTRAINT fk_uso_juego_juego FOREIGN KEY (id_juego) REFERENCES juego(id_juego);

ALTER TABLE uso_juego
ADD CONSTRAINT fk_uso_juego_pase FOREIGN KEY (id_pase) REFERENCES pase(id_pase);

-- CHECK constraints
ALTER TABLE compra_estacionamiento
ADD CONSTRAINT chk_cantidad CHECK (cantidad >= 0);