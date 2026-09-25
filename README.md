# Gestión de parque de diversiones (PostgreSQL + PL/pgSQL + C con SQL embebido)

Base de datos y aplicación de consola para gestionar la venta de pases, el estacionamiento y los accesos de una empresa con cuatro parques de diversiones. Las reglas de negocio se implementan dentro de la base de datos, con triggers, un procedimiento almacenado y funciones en **PL/pgSQL**. Un programa en **C con SQL embebido (ECPG)** ofrece un menú para operar el sistema con transacciones.

Proyecto académico de la unidad curricular *Bases de Datos 2* (Tecnólogo en Informática, UTEC), 2025, realizado en **equipo de 4 integrantes**.

> Este repositorio es una copia personal del trabajo, publicada como parte de mi portafolio.

## Tecnologías

- PostgreSQL (probado en la versión 17)
- PL/pgSQL: triggers, procedimiento almacenado y funciones
- C con SQL embebido (ECPG) y transacciones (`COMMIT` / `ROLLBACK`)
- JSON en PostgreSQL (`json_array_elements`) para pasar varios pases en una sola llamada

## Qué hace

**Programa en C (menú):**

1. **Venta de entradas:** pide el parque, la fecha, la cantidad de entradas y la cédula de cada visitante, y si quiere estacionamiento. Antes de vender valida:
   - que haya cupo en el parque para esa fecha,
   - que el visitante no tenga ya un pase para ese día,
   - que haya lugar en el estacionamiento.

   La venta se registra con el procedimiento `realizar_venta` dentro de una transacción. Si algo falla, se hace `ROLLBACK`.
2. **Validar entrada:** con la cédula y la fecha indica si el pase es válido, si ya se usó o si no existe.
3. **Total recaudado** en un mes y año.

**Lógica en la base de datos:**

| Objeto | Tipo | Qué hace |
|---|---|---|
| `realizar_venta(...)` | Procedimiento | Registra la compra, los pases y el estacionamiento. Recibe los pases como un arreglo JSON y valida el cupo del parque, los pases duplicados y el precio vigente para la fecha. |
| `validar_entrada(ci, fecha)` | Función | Devuelve `Pase válido.`, `Pase ya utilizado` o `Pase no válido`. |
| `recaudo(anio, mes)` | Función | Total recaudado. Los parámetros son opcionales: se puede pedir por mes, por año o el total. |
| `trigger_actualizar_total` | Trigger (`pase`) | Recalcula el total de la compra cuando se agrega, modifica o elimina un pase. |
| `trigger_controlar_estacionamiento` | Trigger (`compra_estacionamiento`) | No deja superar la capacidad del estacionamiento por parque y día. |
| `trigger_verificar_capacidad` | Trigger (`acceso`) | No deja ingresar si el parque ya tiene la cantidad máxima de personas adentro. |

## Modelo de datos

`parque`, `juego`, `parque_juego`, `estacionamiento`, `persona`, `cliente`, `visitante`, `precio_pase` (precios con período de vigencia), `compra`, `compra_estacionamiento`, `pase`, `acceso`, `uso_juego` (con foto en `BYTEA`) y `tasa_cambio`.

## Cómo ejecutarlo

### 1. Crear la base y cargar los scripts (en este orden)

```bash
createdb lab02
psql -d lab02 -f sql/ddl.sql
psql -d lab02 -f sql/constraints.sql
psql -d lab02 -f sql/triggers.sql
psql -d lab02 -f sql/funciones_procedimientos.sql
psql -d lab02 -f sql/dml.sql          # datos de prueba (ficticios)
```

Algunas pruebas rápidas:

```sql
SELECT id_compra, total FROM compra;                     -- totales calculados por el trigger
SELECT validar_entrada('34567890', '2025-01-15');         -- 'Pase ya utilizado'
SELECT recaudo(2025, 1);                                  -- recaudado en enero de 2025
CALL realizar_venta('12345678', '12345678', 'credito', '0000',
     '[{"ci":"55555555","id_parque":2,"fecha":"2025-12-01"}]', false, 0);
```

### 2. Compilar y ejecutar el programa en C (Linux o Docker)

Se necesita el paquete de desarrollo de ECPG (en Debian/Ubuntu: `libecpg-dev`).

```bash
ecpg app/programa.pgc -o app/programa.c
gcc app/programa.c -I"$(pg_config --includedir)" -L"$(pg_config --libdir)" -lecpg -o programa

export PGUSER=tu_usuario PGPASSWORD=tu_password   # PGHOST y PGPORT son opcionales (por defecto: localhost:5432)
./programa
```

El programa se conecta a la base `lab02` y lee las credenciales de las variables de entorno, así no quedan escritas en el código.

## Estructura

```text
sql/
  ddl.sql                       tablas
  constraints.sql               claves foráneas y restricciones CHECK
  triggers.sql                  los 3 triggers y sus funciones
  funciones_procedimientos.sql  realizar_venta, validar_entrada, recaudo
  dml.sql                       datos de prueba
app/
  programa.pgc                  programa en C con SQL embebido (se preprocesa con ecpg)
```

## Limitaciones conocidas y posibles mejoras

- El número de tarjeta se guarda en texto plano. En un sistema real no debería guardarse, o se guardaría tokenizado a través de la pasarela de pago.
- `validar_entrada` controla la cédula y la fecha, pero no el parque.
- La venta desde el menú es para un solo parque y una sola fecha por compra. El procedimiento sí acepta varias combinaciones en el JSON.
