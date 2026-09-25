-- Triggers: Lógica de control y automatización de la base de datos.

-- Trigger 1: Evitar que ingresen más personas de las permitidas (Capacidad del Parque)
CREATE OR REPLACE FUNCTION verificar_capacidad()
RETURNS TRIGGER AS $$
DECLARE
    id_parque_acceso INT;
    capacidad_maxima INT;
    cantidad_actual INT;
BEGIN
    SELECT id_parque INTO id_parque_acceso
    FROM pase
    WHERE id_pase = NEW.id_pase;

    SELECT COUNT(*) INTO cantidad_actual
    FROM acceso a
    JOIN pase p ON a.id_pase = p.id_pase
    WHERE p.id_parque = id_parque_acceso
    AND a.fecha = NEW.fecha
    AND a.hora_salida IS NULL; -- Solo contar personas que aún están en el parque

    SELECT capacidad_max INTO capacidad_maxima
    FROM parque
    WHERE id_parque = id_parque_acceso;

    IF cantidad_actual >= capacidad_maxima THEN
        RAISE EXCEPTION 'Capacidad máxima alcanzada en el parque %', id_parque_acceso;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Elimina el trigger si ya existe para evitar errores al recrearlo
DROP TRIGGER IF EXISTS trigger_verificar_capacidad ON acceso;

-- Crea el trigger para ejecutarse ANTES de cada inserción en la tabla acceso
CREATE TRIGGER trigger_verificar_capacidad
BEFORE INSERT ON acceso
FOR EACH ROW
EXECUTE FUNCTION verificar_capacidad();


-- Trigger 2: Actualizar el total de la compra automáticamente al insertar/actualizar/eliminar pases
CREATE OR REPLACE FUNCTION actualizar_total_compra()
RETURNS TRIGGER AS $$
DECLARE
    total_suma NUMERIC;
    compra_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        compra_id := OLD.id_compra;
    ELSE
        compra_id := NEW.id_compra;
    END IF;

    SELECT COALESCE(SUM(pp.precio), 0)
    INTO total_suma
    FROM pase ps
    JOIN precio_pase pp ON ps.id_precio_pase = pp.id_precio_pase
    WHERE ps.id_compra = compra_id;

    UPDATE compra SET total = total_suma
    WHERE id_compra = compra_id;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Elimina el trigger si ya existe
DROP TRIGGER IF EXISTS trigger_actualizar_total ON pase;

-- Crea el trigger para ejecutarse DESPUÉS de cada inserción, actualización o eliminación en la tabla pase
CREATE TRIGGER trigger_actualizar_total
AFTER INSERT OR UPDATE OR DELETE ON pase
FOR EACH ROW
EXECUTE FUNCTION actualizar_total_compra();


-- Trigger 3: Verificar que no se exceda la capacidad de estacionamiento por parque y día
CREATE OR REPLACE FUNCTION controlar_estacionamiento()
RETURNS TRIGGER AS $$
DECLARE
    total_actual INT := 0;
    capacidad_max_parque INT;
BEGIN
    -- Calcular la suma de autos ya comprados para ese parque y fecha, excluyendo si se trata de una UPDATE sobre la misma fila
    SELECT COALESCE(SUM(cantidad), 0)
    INTO total_actual
    FROM compra_estacionamiento
    WHERE id_parque = NEW.id_parque
    AND fecha = NEW.fecha
    AND (TG_OP = 'INSERT' OR id_compra <> NEW.id_compra);

    -- Obtener la capacidad máxima del parque
    SELECT capacidad_max INTO capacidad_max_parque
    FROM estacionamiento
    WHERE id_parque = NEW.id_parque;

    -- Verificar si se excede
    IF total_actual + NEW.cantidad > capacidad_max_parque THEN
        RAISE EXCEPTION 'Capacidad de estacionamiento superada para el parque % en la fecha % (disponibles: %)', NEW.id_parque, NEW.fecha, capacidad_max_parque - total_actual;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Elimina el trigger si ya existe
DROP TRIGGER IF EXISTS trigger_controlar_estacionamiento ON compra_estacionamiento;

-- Crea el trigger para ejecutarse ANTES de cada inserción o actualización en la tabla compra_estacionamiento
CREATE TRIGGER trigger_controlar_estacionamiento
BEFORE INSERT OR UPDATE ON compra_estacionamiento
FOR EACH ROW
EXECUTE FUNCTION controlar_estacionamiento();