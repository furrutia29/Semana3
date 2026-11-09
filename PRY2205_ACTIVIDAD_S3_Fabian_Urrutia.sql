-- FORMATO GENERAL DE SALIDA
SET LINESIZE 180
SET PAGESIZE 100

-- CASO 1: ANALISIS DE PROPIEDADES

SELECT
    p.id_tipo_propiedad AS TIPO,
    COUNT(*) AS TOTAL_PROPIEDADES,
    '$' || TO_CHAR(MAX(p.valor_arriendo),
        'FM999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.''') AS MAX_ARRIENDO,
    '$' || TO_CHAR(ROUND(AVG(p.valor_arriendo)),
        'FM999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.''') AS PROMEDIO_ARRIENDO,
    '$' || TO_CHAR(MIN(p.valor_arriendo),
        'FM999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.''') AS MIN_ARRIENDO,
    CASE
        WHEN MAX(p.valor_arriendo) > 1000000
        THEN 'PREMIUM'
        ELSE 'ESTÁNDAR'
    END AS CLASIFICACION,
    '$' || TO_CHAR(SUM(NVL(p.valor_gasto_comun, 0)),
        'FM999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.''') AS TOTAL_GASTOS_COMUNES
FROM propiedad p
GROUP BY p.id_tipo_propiedad
HAVING SUM(NVL(p.valor_gasto_comun, 0))
       > &VALOR_TOTAL_GASTO_COMUN
ORDER BY SUM(NVL(p.valor_gasto_comun, 0)) DESC;


-- CASO 2: ANTIGUEDAD DE EMPLEADOS

SELECT
    UPPER(e.nombre_emp || ' ' || e.appaterno_emp)
        AS "Nombre Empleado",

    '$' || TO_CHAR(e.sueldo_emp,
        'FM999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.''')
        AS "Sueldo con Formato",

    CASE
        WHEN e.sueldo_emp > 2000000 THEN 'ALTO'
        ELSE 'MEDIO'
    END AS "Clasificación Sueldo",

    e.anios_antiguedad AS "Años Antigüedad",

    'Corresponde bono ' ||
    CASE
        WHEN e.anios_antiguedad > 20 THEN '15'
        WHEN e.anios_antiguedad > 10 THEN '10'
        ELSE '5'
    END || '%:  $' ||

    TO_CHAR(
        ROUND(e.sueldo_emp *
            CASE
                WHEN e.anios_antiguedad > 20 THEN 0.15
                WHEN e.anios_antiguedad > 10 THEN 0.10
                ELSE 0.05
            END
        ),
        'FM999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.''')
        AS "BONO"

FROM (
    SELECT
        nombre_emp,
        appaterno_emp,
        NVL(sueldo_emp, 0) AS sueldo_emp,
        TRUNC(
            MONTHS_BETWEEN(TRUNC(SYSDATE), fecing_emp) / 12
        ) AS anios_antiguedad
    FROM empleado
    WHERE id_categoria_emp = 3
      AND id_sucursal <> &CODIGO_SUCURSAL
) e

WHERE e.anios_antiguedad > 5
ORDER BY e.sueldo_emp DESC;


COLUMN CLASIFICACION_RENTA FORMAT A20
COLUMN CANTIDAD_CLIENTES FORMAT 9999
COLUMN RENTA_PROMEDIO FORMAT A18
COLUMN ESTADO_TELEFONO FORMAT A26

-- CASO 3: LISTADO DE CLIENTES

SELECT
    c.clasificacion_renta AS CLASIFICACION_RENTA,
    COUNT(*) AS CANTIDAD_CLIENTES,

    '$' || TO_CHAR(
        ROUND(AVG(c.renta_cli)),
        'FM999G999G990',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS RENTA_PROMEDIO,

    CASE
        WHEN COUNT(c.celular_cli) = 0
        THEN 'Clientes sin Teléfono'
        ELSE 'Clientes con Teléfono'
    END AS ESTADO_TELEFONO

FROM (
    SELECT
        renta_cli,
        celular_cli,
        CASE
            WHEN renta_cli >= 1000000 THEN 'PREMIUM'
            WHEN renta_cli >= 600000 THEN 'ALTA'
            WHEN renta_cli >= 300000 THEN 'MEDIA'
            ELSE 'BAJA'
        END AS clasificacion_renta
    FROM cliente
) c

GROUP BY c.clasificacion_renta
HAVING AVG(c.renta_cli) > 200000

ORDER BY
    CASE c.clasificacion_renta
        WHEN 'ALTA' THEN 1
        WHEN 'MEDIA' THEN 2
        WHEN 'BAJA' THEN 3
        WHEN 'PREMIUM' THEN 4
    END;
