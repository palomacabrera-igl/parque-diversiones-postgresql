-- FUNCIONES Y PROCEDIMIENTOS DE ALMACENADO

-- Procedimiento: realizar_venta
-- Permite registrar la venta de entradas y estacionamiento, con validaciones de capacidad.
CREATE OR REPLACE PROCEDURE realizar_venta(
    p_comprador CHAR(8),
    p_titular CHAR(8),
    p_tipo VARCHAR,
    p_numero_tarjeta VARCHAR,
    p_pases JSON,
    p_usar_estacionamiento BOOLEAN,
    p_cantidad_est INT DEFAULT 0
)
LANGUAGE plpgsql
AS $$
DECLARE
    r JSON;
    v_ci CHAR(8);
    v_fecha DATE;
    v_id_parque INT;
    v_precio NUMERIC;
    v_id_precio INT;
    v_id_compra INT;
    cupo_parque INT;
    usados_parque INT;
    cupo_est INT;
    usados_est INT;
    fecha_loop DATE;
    parque_loop INT;
BEGIN
    -- Verificar y crear comprador si no existe (persona)
    -- Se insertan con valores genéricos 'Desconocido' si el CI no existe.
    IF NOT EXISTS (SELECT 1 FROM persona WHERE ci = p_comprador) THEN
        INSERT INTO persona(ci, nombre1, apellido1) VALUES (p_comprador, 'Desconocido', 'Desconocido');
    END IF;

    -- Verificar y crear titular si no existe (persona) y registrarlo como cliente
    IF NOT EXISTS (SELECT 1 FROM persona WHERE ci = p_titular) THEN
        INSERT INTO persona(ci, nombre1, apellido1) VALUES (p_titular, 'Desconocido', 'Desconocido');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE ci = p_titular) THEN
        INSERT INTO cliente(ci) VALUES (p_titular);
    END IF;

    -- Insertar la compra
    INSERT INTO compra(fecha, tipo, numero, ci_titular, ci_comprador)
    VALUES (current_date, p_tipo, p_numero_tarjeta, p_titular, p_comprador)
    RETURNING id_compra INTO v_id_compra;

    -- Recorrer cada pase (visitantes) del array JSON
    FOR r IN SELECT * FROM json_array_elements(p_pases)
    LOOP
        v_ci := r ->> 'ci';
        v_id_parque := (r ->> 'id_parque')::INT;
        v_fecha := (r ->> 'fecha')::DATE;

        -- Verificar y agregar visitante si no existe (persona)
        IF NOT EXISTS (SELECT 1 FROM persona WHERE ci = v_ci) THEN
            INSERT INTO persona(ci, nombre1, apellido1) VALUES (v_ci, 'Desconocido', 'Desconocido');
        END IF;
        -- Registrar como visitante
        IF NOT EXISTS (SELECT 1 FROM visitante WHERE ci = v_ci) THEN
            INSERT INTO visitante(ci) VALUES (v_ci);
        END IF;

        -- Verificar que la persona no tenga ya pase en esa fecha y parque
        IF EXISTS (
            SELECT 1 FROM pase
            WHERE ci = v_ci AND id_parque = v_id_parque AND fecha = v_fecha
        ) THEN
            RAISE EXCEPTION 'La persona con CI % ya tiene un pase para el parque % en la fecha %', v_ci, v_id_parque, v_fecha;
        END IF;

        -- Validar cupo en parque
        SELECT capacidad_max INTO cupo_parque FROM parque WHERE id_parque = v_id_parque;
        SELECT COUNT(*) INTO usados_parque FROM pase
        WHERE id_parque = v_id_parque AND fecha = v_fecha;

        IF usados_parque >= cupo_parque THEN
            RAISE EXCEPTION 'No hay cupo en el parque % para la fecha % (actual: % / max: %)', v_id_parque, v_fecha, usados_parque, cupo_parque;
        END IF;

        -- Obtener id_precio_pase y precio para el pase
        SELECT id_precio_pase, precio INTO v_id_precio, v_precio
        FROM precio_pase
        WHERE id_parque = v_id_parque
          AND v_fecha BETWEEN fecha_desde AND fecha_hasta
        ORDER BY fecha_desde DESC
        LIMIT 1;

        IF v_id_precio IS NULL THEN
            RAISE EXCEPTION 'No hay precio definido para el parque % en la fecha %', v_id_parque, v_fecha;
        END IF;

        -- Insertar el pase
        INSERT INTO pase(ci, id_parque, fecha, id_precio_pase, id_compra)
        VALUES (v_ci, v_id_parque, v_fecha, v_id_precio, v_id_compra);
    END LOOP;

    -- Registrar estacionamiento si corresponde
    IF p_usar_estacionamiento THEN
        -- Extraer el primer parque y fecha de los pases para el registro de estacionamiento
        -- Asumimos que todos los pases son para el mismo parque y fecha, como se maneja en C
        SELECT DISTINCT (j->>'fecha')::DATE, (j->>'id_parque')::INT
        INTO fecha_loop, parque_loop
        FROM json_array_elements(p_pases) AS j
        LIMIT 1;

        -- Este insert activará el trigger de control de estacionamiento.
        INSERT INTO compra_estacionamiento(id_compra, id_parque, fecha, cantidad)
        VALUES (v_id_compra, parque_loop, fecha_loop, p_cantidad_est);
    END IF;

    -- Calcular total de la compra
    UPDATE compra SET total = (
        SELECT COALESCE(SUM(pp.precio), 0)
        FROM pase p
        JOIN precio_pase pp ON pp.id_precio_pase = p.id_precio_pase
        WHERE p.id_compra = v_id_compra
    )
    WHERE id_compra = v_id_compra;

END;
$$;


-- Función: validar_entrada
-- Verifica si un pase es válido para una persona en una fecha específica.
CREATE OR REPLACE FUNCTION validar_entrada(p_ci CHAR(8), p_fecha DATE)
RETURNS VARCHAR AS $$
DECLARE
    fecha_pase DATE;
BEGIN
    -- Verificar si existe el pase
    SELECT fecha INTO fecha_pase
    FROM pase
    WHERE ci = p_ci AND fecha = p_fecha
    LIMIT 1;

    -- Si NOT FOUND (no se encontró ningún pase)
    IF NOT FOUND THEN
        RETURN 'Pase no válido';
    END IF;

    -- Si la fecha del pase es anterior a hoy (ya fue utilizado o es para el pasado)
    IF fecha_pase < CURRENT_DATE THEN
        RETURN 'Pase ya utilizado';
    ELSE
        -- Si la fecha del pase es hoy o en el futuro
        RETURN 'Pase válido.';
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Función: recaudo
-- Calcula el total recaudado por las compras en un mes/año específico o en total.
CREATE OR REPLACE FUNCTION recaudo(IN p_anio INT DEFAULT NULL, IN p_mes INT DEFAULT NULL) RETURNS NUMERIC
LANGUAGE sql
AS $$
    SELECT COALESCE(SUM(total), 0)
    FROM compra
    WHERE (p_anio IS NULL OR EXTRACT(YEAR FROM fecha) = p_anio)
    AND (p_mes IS NULL OR EXTRACT(MONTH FROM fecha) = p_mes);
$$;