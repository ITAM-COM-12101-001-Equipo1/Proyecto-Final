/*
================================================================================
 Script:      03_exploratory_analysis.sql
 Dataset:     1 - Remuneraciones del personal de la CDMX
 Etapa:       2 (Limpieza y staging)
 Propósito:   Análisis exploratorio en SQL sobre la tabla de staging para
              alimentar las decisiones de normalización (Etapa 3).
              Cada bloque responde a un punto del análisis pedido por la
              rúbrica:
                A. Atributos con valores únicos (candidatos a PK).
                B. Rangos de fechas (no aplica: ver README).
                C. Estadísticas numéricas (min/max/avg).
                D. Duplicados en atributos categóricos.
                E. Columnas redundantes.
                F. Distribución categórica.
                G. Valores nulos / vacíos por columna.
                H. Inconsistencias detectadas.
 Entrada:     `ds1.ds1_staging_remuneraciones` poblada (~246,821 filas).
 Salida:      Resultados de queries que se vuelcan en el README,
              sección "Resultados del análisis exploratorio".
 Uso:         Ejecutar cada bloque por separado y registrar el resultado.
================================================================================
*/

-- ---------------------------------------------------------------------------
-- A. Atributos con valores únicos (candidatos a PK natural)
-- ---------------------------------------------------------------------------
-- Pregunta clave: ¿alguna columna por sí sola identifica unívocamente la fila?
-- Si distinct = total → es candidata a PK.
SELECT
    COUNT(*)                                                  AS total_filas,
    COUNT(DISTINCT nombre)                                    AS distinct_nombre,
    COUNT(DISTINCT apellido_1)                                AS distinct_ap1,
    COUNT(DISTINCT apellido_2)                                AS distinct_ap2,
    COUNT(DISTINCT (nombre || '|' || apellido_1 || '|' || apellido_2))
                                                              AS distinct_nombre_completo,
    COUNT(DISTINCT n_puesto)                                  AS distinct_n_puesto,
    COUNT(DISTINCT id_tipo_nomina)                            AS distinct_id_tipo_nomina,
    COUNT(DISTINCT tipo_contratacion)                         AS distinct_tipo_contratacion,
    COUNT(DISTINCT tipo_personal)                             AS distinct_tipo_personal,
    COUNT(DISTINCT id_universo)                               AS distinct_id_universo,
    COUNT(DISTINCT n_universo)                                AS distinct_n_universo,
    COUNT(DISTINCT id_sector)                                 AS distinct_id_sector,
    COUNT(DISTINCT n_cabeza_sector)                           AS distinct_n_cabeza_sector,
    COUNT(DISTINCT id_nivel_salarial)                         AS distinct_id_nivel_salarial,
    COUNT(DISTINCT sueldo_tabular_bruto)                      AS distinct_sueldo_bruto,
    COUNT(DISTINCT sueldo_tabular_neto)                       AS distinct_sueldo_neto
FROM ds1.ds1_staging_remuneraciones;

-- ¿La fila completa es única? (¿hay duplicados exactos?)
SELECT COUNT(*) AS filas_duplicadas_exactas
FROM (
    SELECT nombre, apellido_1, apellido_2, sexo, edad, n_puesto,
           id_tipo_nomina, tipo_contratacion, tipo_personal,
           id_universo, n_universo, id_sector, n_cabeza_sector,
           id_nivel_salarial, sueldo_tabular_bruto, sueldo_tabular_neto,
           COUNT(*) AS c
      FROM ds1.ds1_staging_remuneraciones
     GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
    HAVING COUNT(*) > 1
) d;

-- ---------------------------------------------------------------------------
-- B. Rango de fechas / atributos temporales
-- ---------------------------------------------------------------------------
-- El CSV NO contiene columnas temporales por registro (ni fecha, ni año,
-- ni quincena). Esta query existe para documentar explícitamente la
-- ausencia y dejar evidencia en logs.
SELECT
    'Sin columnas temporales en el CSV oficial. '
    'El corte temporal es metadato del nombre de archivo y no se infiere '
    'a partir de los datos.' AS observacion_temporal;

-- ---------------------------------------------------------------------------
-- C. Estadísticas numéricas
-- ---------------------------------------------------------------------------
-- C.1 Edad
SELECT
    MIN(edad::INT)                  AS edad_min,
    MAX(edad::INT)                  AS edad_max,
    ROUND(AVG(edad::INT), 2)        AS edad_avg,
    COUNT(DISTINCT edad)            AS edad_distintos
FROM ds1.ds1_staging_remuneraciones;

-- C.2 Sueldo tabular bruto y neto
SELECT
    MIN(sueldo_tabular_bruto::NUMERIC)        AS bruto_min,
    MAX(sueldo_tabular_bruto::NUMERIC)        AS bruto_max,
    ROUND(AVG(sueldo_tabular_bruto::NUMERIC), 2) AS bruto_avg,
    MIN(sueldo_tabular_neto::NUMERIC)         AS neto_min,
    MAX(sueldo_tabular_neto::NUMERIC)         AS neto_max,
    ROUND(AVG(sueldo_tabular_neto::NUMERIC), 2)  AS neto_avg
FROM ds1.ds1_staging_remuneraciones;

-- C.3 ¿Hay filas donde el neto sea mayor que el bruto? (inconsistencia)
SELECT COUNT(*) AS filas_neto_mayor_que_bruto
FROM ds1.ds1_staging_remuneraciones
WHERE sueldo_tabular_neto::NUMERIC > sueldo_tabular_bruto::NUMERIC;

-- ---------------------------------------------------------------------------
-- D. Duplicados en atributos categóricos
-- ---------------------------------------------------------------------------
-- D.1 Personas con el mismo nombre completo (homonimias)
SELECT
    nombre, apellido_1, apellido_2,
    COUNT(*) AS apariciones
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY 1,2,3
HAVING COUNT(*) > 1
 ORDER BY apariciones DESC, nombre, apellido_1, apellido_2
 LIMIT 20;

-- D.2 ¿id_universo y n_universo siempre coinciden 1:1?
SELECT
    COUNT(DISTINCT id_universo)                               AS ids,
    COUNT(DISTINCT n_universo)                                AS nombres,
    COUNT(DISTINCT (id_universo || '|' || n_universo))        AS pares
FROM ds1.ds1_staging_remuneraciones;

-- D.3 ¿id_sector y n_cabeza_sector siempre coinciden 1:1?
SELECT
    COUNT(DISTINCT id_sector)                                 AS ids,
    COUNT(DISTINCT n_cabeza_sector)                           AS nombres,
    COUNT(DISTINCT (id_sector || '|' || n_cabeza_sector))     AS pares
FROM ds1.ds1_staging_remuneraciones;

-- D.4 ¿id_tipo_nomina determina tipo_contratacion?
SELECT id_tipo_nomina, COUNT(DISTINCT tipo_contratacion) AS contrataciones_distintas
FROM ds1.ds1_staging_remuneraciones
GROUP BY id_tipo_nomina
ORDER BY id_tipo_nomina;

-- ---------------------------------------------------------------------------
-- E. Columnas redundantes
-- ---------------------------------------------------------------------------
-- E.1 Pares (id_universo, n_universo) → si son 1:1 estricto, n_universo es
--     redundante respecto a id_universo (debe vivir en catálogo, no en cada fila).
SELECT id_universo, n_universo, COUNT(*) AS apariciones
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY id_universo, n_universo
 ORDER BY id_universo;

-- E.2 Pares (id_sector, n_cabeza_sector)
SELECT id_sector, n_cabeza_sector, COUNT(*) AS apariciones
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY id_sector, n_cabeza_sector
 ORDER BY id_sector
 LIMIT 50;

-- ---------------------------------------------------------------------------
-- F. Distribución categórica
-- ---------------------------------------------------------------------------
-- F.1 Sexo
SELECT sexo, COUNT(*) AS n
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY sexo
 ORDER BY n DESC;

-- F.2 Tipo de contratación
SELECT tipo_contratacion, COUNT(*) AS n
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY tipo_contratacion
 ORDER BY n DESC;

-- F.3 Tipo de personal
SELECT tipo_personal, COUNT(*) AS n
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY tipo_personal
 ORDER BY n DESC;

-- F.4 Top 15 sectores con más personal
SELECT id_sector, n_cabeza_sector, COUNT(*) AS n
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY id_sector, n_cabeza_sector
 ORDER BY n DESC
 LIMIT 15;

-- F.5 Distribución por universo
SELECT id_universo, n_universo, COUNT(*) AS n
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY id_universo, n_universo
 ORDER BY n DESC;

-- ---------------------------------------------------------------------------
-- G. Valores nulos / vacíos por columna
-- ---------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN nombre               IS NULL OR nombre               = '' THEN 1 ELSE 0 END) AS null_nombre,
    SUM(CASE WHEN apellido_1           IS NULL OR apellido_1           = '' THEN 1 ELSE 0 END) AS null_ap1,
    SUM(CASE WHEN apellido_2           IS NULL OR apellido_2           = '' THEN 1 ELSE 0 END) AS null_ap2,
    SUM(CASE WHEN sexo                 IS NULL OR sexo                 = '' THEN 1 ELSE 0 END) AS null_sexo,
    SUM(CASE WHEN edad                 IS NULL OR edad                 = '' THEN 1 ELSE 0 END) AS null_edad,
    SUM(CASE WHEN n_puesto             IS NULL OR n_puesto             = '' THEN 1 ELSE 0 END) AS null_n_puesto,
    SUM(CASE WHEN id_tipo_nomina       IS NULL OR id_tipo_nomina       = '' THEN 1 ELSE 0 END) AS null_id_tipo_nomina,
    SUM(CASE WHEN tipo_contratacion    IS NULL OR tipo_contratacion    = '' THEN 1 ELSE 0 END) AS null_tipo_contratacion,
    SUM(CASE WHEN tipo_personal        IS NULL OR tipo_personal        = '' THEN 1 ELSE 0 END) AS null_tipo_personal,
    SUM(CASE WHEN id_universo          IS NULL OR id_universo          = '' THEN 1 ELSE 0 END) AS null_id_universo,
    SUM(CASE WHEN n_universo           IS NULL OR n_universo           = '' THEN 1 ELSE 0 END) AS null_n_universo,
    SUM(CASE WHEN id_sector            IS NULL OR id_sector            = '' THEN 1 ELSE 0 END) AS null_id_sector,
    SUM(CASE WHEN n_cabeza_sector      IS NULL OR n_cabeza_sector      = '' THEN 1 ELSE 0 END) AS null_n_cabeza_sector,
    SUM(CASE WHEN id_nivel_salarial    IS NULL OR id_nivel_salarial    = '' THEN 1 ELSE 0 END) AS null_id_nivel_salarial,
    SUM(CASE WHEN sueldo_tabular_bruto IS NULL OR sueldo_tabular_bruto = '' THEN 1 ELSE 0 END) AS null_sueldo_bruto,
    SUM(CASE WHEN sueldo_tabular_neto  IS NULL OR sueldo_tabular_neto  = '' THEN 1 ELSE 0 END) AS null_sueldo_neto
FROM ds1.ds1_staging_remuneraciones;

-- ---------------------------------------------------------------------------
-- H. Inconsistencias detectadas
-- ---------------------------------------------------------------------------
-- H.1 Filas con sexo no estándar (ni MASCULINO ni FEMENINO).
SELECT sexo, COUNT(*) AS n
  FROM ds1.ds1_staging_remuneraciones
 WHERE sexo NOT IN ('MASCULINO','FEMENINO')
 GROUP BY sexo;

-- H.2 Filas anonimizadas (nombre, ap1, ap2 = 'RESERVADO')
SELECT COUNT(*) AS filas_reservado
  FROM ds1.ds1_staging_remuneraciones
 WHERE nombre = 'RESERVADO' AND apellido_1 = 'RESERVADO' AND apellido_2 = 'RESERVADO';

-- H.3 ¿Algún id_nivel_salarial mapea a >1 sueldo_tabular_bruto?
--     (esto demuestra que id_nivel_salarial NO determina funcionalmente
--     el sueldo en este corte → sueldo es atributo de la asignación).
SELECT id_nivel_salarial, COUNT(DISTINCT sueldo_tabular_bruto) AS sueldos_distintos
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY id_nivel_salarial
HAVING COUNT(DISTINCT sueldo_tabular_bruto) > 1
 ORDER BY sueldos_distintos DESC
 LIMIT 20;

-- H.4 ¿n_puesto mapea a >1 id_nivel_salarial? (puesto NO determina nivel)
SELECT n_puesto, COUNT(DISTINCT id_nivel_salarial) AS niveles_distintos
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY n_puesto
HAVING COUNT(DISTINCT id_nivel_salarial) > 1
 ORDER BY niveles_distintos DESC
 LIMIT 20;

-- H.5 ¿id_sector mapea a >1 id_universo? (sector NO determina universo)
SELECT id_sector, n_cabeza_sector, COUNT(DISTINCT id_universo) AS universos_distintos
  FROM ds1.ds1_staging_remuneraciones
 GROUP BY id_sector, n_cabeza_sector
HAVING COUNT(DISTINCT id_universo) > 1
 ORDER BY universos_distintos DESC
 LIMIT 20;
