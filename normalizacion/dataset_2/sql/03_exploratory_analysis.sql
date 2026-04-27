/*
================================================================================
 Script:      03_exploratory_analysis.sql
 Dataset:     2 - ENIGH 2024 NS (INEGI)
 Etapa:       2 (Limpieza y staging)
 Propósito:   Análisis exploratorio en SQL sobre las 5 tablas core del staging
              (viviendas, hogares, poblacion, ingresos, gastoshogar) +
              una visión transversal de las 17 tablas. Cada bloque responde a
              un punto de la rúbrica:
                A. Atributos con valores únicos (candidatos a PK).
                B. Rangos de fechas / atributos temporales.
                C. Estadísticas numéricas.
                D. Duplicados en atributos categóricos.
                E. Columnas redundantes.
                F. Distribución categórica.
                G. Valores nulos por columna.
                H. Inconsistencias detectadas.
 Entrada:     Tablas de staging pobladas.
 Salida:      Resultados que alimentan la sección "Resultados del análisis
              exploratorio" del README maestro de dataset_2.
================================================================================
*/

-- ---------------------------------------------------------------------------
-- Volumetría general (las 17 tablas + catálogos)
-- ---------------------------------------------------------------------------
SELECT 'viviendas'         AS tabla,  90324 AS esperado, COUNT(*) AS observado FROM ds2.ds2_staging_viviendas        UNION ALL
SELECT 'hogares',           91414, COUNT(*) FROM ds2.ds2_staging_hogares          UNION ALL
SELECT 'poblacion',        308598, COUNT(*) FROM ds2.ds2_staging_poblacion        UNION ALL
SELECT 'ingresos',         391563, COUNT(*) FROM ds2.ds2_staging_ingresos         UNION ALL
SELECT 'gastoshogar',     5311497, COUNT(*) FROM ds2.ds2_staging_gastoshogar      UNION ALL
SELECT 'concentradohogar',  91414, COUNT(*) FROM ds2.ds2_staging_concentradohogar UNION ALL
SELECT 'gastospersona',    377073, COUNT(*) FROM ds2.ds2_staging_gastospersona    UNION ALL
SELECT 'erogaciones',       69162, COUNT(*) FROM ds2.ds2_staging_erogaciones      UNION ALL
SELECT 'gastotarjetas',     19464, COUNT(*) FROM ds2.ds2_staging_gastotarjetas    UNION ALL
SELECT 'trabajos',         164325, COUNT(*) FROM ds2.ds2_staging_trabajos         UNION ALL
SELECT 'agro',              17442, COUNT(*) FROM ds2.ds2_staging_agro             UNION ALL
SELECT 'agroconsumo',       43992, COUNT(*) FROM ds2.ds2_staging_agroconsumo      UNION ALL
SELECT 'agrogasto',         61132, COUNT(*) FROM ds2.ds2_staging_agrogasto        UNION ALL
SELECT 'agroproductos',     69052, COUNT(*) FROM ds2.ds2_staging_agroproductos    UNION ALL
SELECT 'noagro',            23109, COUNT(*) FROM ds2.ds2_staging_noagro           UNION ALL
SELECT 'noagroimportes',   151276, COUNT(*) FROM ds2.ds2_staging_noagroimportes   UNION ALL
SELECT 'ingresos_jcf',        327, COUNT(*) FROM ds2.ds2_staging_ingresos_jcf;

-- ===========================================================================
-- A. Atributos con valores únicos (candidatos a PK)
-- ===========================================================================
SELECT
    COUNT(*)                                        AS total,
    COUNT(DISTINCT folioviv)                        AS distinct_folioviv
FROM ds2.ds2_staging_viviendas;
-- Esperado: total = distinct_folioviv = 90,324  → folioviv es PK natural.

SELECT
    COUNT(*)                                                     AS total,
    COUNT(DISTINCT (folioviv, foliohog))                         AS distinct_pk
FROM ds2.ds2_staging_hogares;
-- Esperado: total = distinct_pk = 91,414  → (folioviv, foliohog) es PK.

SELECT
    COUNT(*)                                                     AS total,
    COUNT(DISTINCT (folioviv, foliohog, numren))                 AS distinct_pk
FROM ds2.ds2_staging_poblacion;
-- Esperado: total = distinct_pk = 308,598

SELECT
    COUNT(*)                                                       AS total,
    COUNT(DISTINCT (folioviv, foliohog, numren, clave))            AS distinct_pk
FROM ds2.ds2_staging_ingresos;
-- Esperado: total = distinct_pk = 391,563

-- gastoshogar: la combinación natural NO es única.
SELECT
    COUNT(*)                                                                            AS total,
    COUNT(DISTINCT (folioviv, foliohog, clave, tipo_gasto, mes_dia, fecha_adqu))         AS distinct_natural,
    COUNT(*) - COUNT(DISTINCT (folioviv, foliohog, clave, tipo_gasto, mes_dia, fecha_adqu)) AS duplicados
FROM ds2.ds2_staging_gastoshogar;
-- Esperado: duplicados ≈ 6,300 (≈0.1%) → se requiere surrogate id_gasto_hogar.

-- ===========================================================================
-- B. Rango temporal / atributos de fecha
-- ===========================================================================
-- ENIGH se levanta entre agosto y noviembre del año del corte. Las únicas
-- columnas con fecha real están en gastoshogar (fecha_adqu, fecha_pago).

SELECT
    MIN(NULLIF(TRIM(fecha_adqu),'')) AS fecha_adqu_min,
    MAX(NULLIF(TRIM(fecha_adqu),'')) AS fecha_adqu_max,
    MIN(NULLIF(TRIM(fecha_pago),'')) AS fecha_pago_min,
    MAX(NULLIF(TRIM(fecha_pago),'')) AS fecha_pago_max
FROM ds2.ds2_staging_gastoshogar
WHERE fecha_adqu IS NOT NULL AND fecha_adqu <> '';

-- Mes del gasto (mes_dia) — distribución
SELECT SUBSTRING(mes_dia, 1, 2) AS mes, COUNT(*) AS n
FROM ds2.ds2_staging_gastoshogar
WHERE mes_dia IS NOT NULL AND mes_dia <> ''
GROUP BY 1 ORDER BY 1;

-- ingresos: ing_tri es el ingreso trimestralizado; mes_1..mes_6 son los meses
-- en que se reportó el ingreso (no son fechas absolutas).
SELECT mes_1, COUNT(*) FROM ds2.ds2_staging_ingresos GROUP BY 1 ORDER BY 1;

-- ===========================================================================
-- C. Estadísticas numéricas
-- ===========================================================================
-- C.1 Edad de la población
SELECT
    MIN(NULLIF(TRIM(edad),'')::INT) AS edad_min,
    MAX(NULLIF(TRIM(edad),'')::INT) AS edad_max,
    ROUND(AVG(NULLIF(TRIM(edad),'')::INT), 2) AS edad_avg
FROM ds2.ds2_staging_poblacion
WHERE NULLIF(TRIM(edad),'') IS NOT NULL;

-- C.2 Total de integrantes por hogar (tot_resid de viviendas)
SELECT
    MIN(NULLIF(TRIM(tot_resid),'')::INT) AS resid_min,
    MAX(NULLIF(TRIM(tot_resid),'')::INT) AS resid_max,
    ROUND(AVG(NULLIF(TRIM(tot_resid),'')::INT), 2) AS resid_avg
FROM ds2.ds2_staging_viviendas
WHERE NULLIF(TRIM(tot_resid),'') IS NOT NULL;

-- C.3 Sueldo bruto (ing_tri = ingreso trimestral por persona × clave)
SELECT
    MIN(NULLIF(TRIM(ing_tri),'')::NUMERIC) AS ing_min,
    MAX(NULLIF(TRIM(ing_tri),'')::NUMERIC) AS ing_max,
    ROUND(AVG(NULLIF(TRIM(ing_tri),'')::NUMERIC), 2) AS ing_avg,
    COUNT(*) AS registros
FROM ds2.ds2_staging_ingresos
WHERE NULLIF(TRIM(ing_tri),'') IS NOT NULL;

-- C.4 Gasto trimestralizado por hogar (gasto_tri)
SELECT
    MIN(NULLIF(TRIM(gasto_tri),'')::NUMERIC) AS gasto_min,
    MAX(NULLIF(TRIM(gasto_tri),'')::NUMERIC) AS gasto_max,
    ROUND(AVG(NULLIF(TRIM(gasto_tri),'')::NUMERIC), 2) AS gasto_avg
FROM ds2.ds2_staging_gastoshogar
WHERE NULLIF(TRIM(gasto_tri),'') IS NOT NULL;

-- ===========================================================================
-- D. Duplicados en atributos categóricos
-- ===========================================================================
-- D.1 Catálogo de entidades federativas (esperado: 32)
SELECT COUNT(DISTINCT entidad) AS entidades_distintas FROM ds2.ds2_staging_viviendas;
-- D.2 Catálogo de parentesco usado en la encuesta
SELECT parentesco, COUNT(*) AS n FROM ds2.ds2_staging_poblacion GROUP BY 1 ORDER BY 1;
-- D.3 Sexo
SELECT sexo, COUNT(*) AS n FROM ds2.ds2_staging_poblacion GROUP BY 1 ORDER BY 1;
-- D.4 Tipo de gasto
SELECT tipo_gasto, COUNT(*) AS n FROM ds2.ds2_staging_gastoshogar GROUP BY 1 ORDER BY 1;

-- ===========================================================================
-- E. Columnas redundantes
-- ===========================================================================
-- E.1 entidad, est_dis, upm aparecen REPLICADAS en muchas tablas (viviendas,
--     hogares, poblacion, ingresos, gastoshogar). Esto es la fuente del
--     "violación 3FN por dependencia transitiva":
--     (folioviv) → (entidad, est_dis, upm) en viviendas, y
--     (folioviv, foliohog, numren) → (entidad, ...) repetida en cada tabla.
SELECT 'viviendas'   AS tabla, COUNT(DISTINCT entidad) AS ent, COUNT(DISTINCT upm) AS upm FROM ds2.ds2_staging_viviendas    UNION ALL
SELECT 'hogares',    COUNT(DISTINCT entidad), COUNT(DISTINCT upm) FROM ds2.ds2_staging_hogares                              UNION ALL
SELECT 'poblacion',  COUNT(DISTINCT entidad), COUNT(DISTINCT upm) FROM ds2.ds2_staging_poblacion                            UNION ALL
SELECT 'ingresos',   COUNT(DISTINCT entidad), COUNT(DISTINCT upm) FROM ds2.ds2_staging_ingresos                             UNION ALL
SELECT 'gastoshogar',COUNT(DISTINCT entidad), COUNT(DISTINCT upm) FROM ds2.ds2_staging_gastoshogar;

-- E.2 Verificar que entidad, est_dis, upm son funcionalmente determinados
--     por folioviv (deberían serlo: una vivienda está en una sola entidad).
SELECT folioviv, COUNT(DISTINCT entidad) AS entidades
  FROM ds2.ds2_staging_viviendas
 GROUP BY folioviv
HAVING COUNT(DISTINCT entidad) > 1
 LIMIT 5;
-- Esperado: 0 filas → folioviv → entidad es DF estricta.

-- ===========================================================================
-- F. Distribución categórica
-- ===========================================================================
-- F.1 Distribución de hogares por entidad
SELECT entidad, COUNT(*) AS n_hogares
  FROM ds2.ds2_staging_hogares
 GROUP BY 1 ORDER BY n_hogares DESC LIMIT 15;

-- F.2 Distribución de tipo de vivienda (tipo_viv)
SELECT tipo_viv, COUNT(*) AS n
  FROM ds2.ds2_staging_viviendas
 GROUP BY 1 ORDER BY n DESC;

-- F.3 Distribución de tenencia de la vivienda
SELECT tenencia, COUNT(*) AS n
  FROM ds2.ds2_staging_viviendas
 GROUP BY 1 ORDER BY n DESC;

-- F.4 Hablantes de lengua indígena (poblacion.hablaind)
SELECT hablaind, COUNT(*) AS n
  FROM ds2.ds2_staging_poblacion
 GROUP BY 1 ORDER BY n DESC;

-- ===========================================================================
-- G. Valores nulos / vacíos en columnas críticas
-- ===========================================================================
-- En las tablas core, las columnas-clave NUNCA deben ser nulas/vacías.
SELECT 'viviendas.folioviv' AS col,
       SUM(CASE WHEN NULLIF(TRIM(folioviv),'') IS NULL THEN 1 ELSE 0 END) AS nulos
  FROM ds2.ds2_staging_viviendas UNION ALL
SELECT 'hogares.folioviv',
       SUM(CASE WHEN NULLIF(TRIM(folioviv),'') IS NULL THEN 1 ELSE 0 END)
  FROM ds2.ds2_staging_hogares UNION ALL
SELECT 'poblacion.numren',
       SUM(CASE WHEN NULLIF(TRIM(numren),'') IS NULL THEN 1 ELSE 0 END)
  FROM ds2.ds2_staging_poblacion UNION ALL
SELECT 'ingresos.clave',
       SUM(CASE WHEN NULLIF(TRIM(clave),'') IS NULL THEN 1 ELSE 0 END)
  FROM ds2.ds2_staging_ingresos UNION ALL
SELECT 'gastoshogar.clave',
       SUM(CASE WHEN NULLIF(TRIM(clave),'') IS NULL THEN 1 ELSE 0 END)
  FROM ds2.ds2_staging_gastoshogar;

-- ===========================================================================
-- H. Inconsistencias detectadas
-- ===========================================================================
-- H.1 Repeating groups: hogares trae alim17_1..12, num_auto..num_otro,
--     habito_1..6, etc. Esto es violación de 1FN.
--     Conteo de no-nulos por columna del grupo alim17_*:
SELECT
  COUNT(NULLIF(TRIM(alim17_1),'')) AS alim17_1,  COUNT(NULLIF(TRIM(alim17_2),'')) AS alim17_2,
  COUNT(NULLIF(TRIM(alim17_3),'')) AS alim17_3,  COUNT(NULLIF(TRIM(alim17_4),'')) AS alim17_4,
  COUNT(NULLIF(TRIM(alim17_5),'')) AS alim17_5,  COUNT(NULLIF(TRIM(alim17_6),'')) AS alim17_6,
  COUNT(NULLIF(TRIM(alim17_7),'')) AS alim17_7,  COUNT(NULLIF(TRIM(alim17_8),'')) AS alim17_8,
  COUNT(NULLIF(TRIM(alim17_9),'')) AS alim17_9,  COUNT(NULLIF(TRIM(alim17_10),'')) AS alim17_10,
  COUNT(NULLIF(TRIM(alim17_11),'')) AS alim17_11, COUNT(NULLIF(TRIM(alim17_12),'')) AS alim17_12
FROM ds2.ds2_staging_hogares;

-- H.2 Hogares cuyo número de huéspedes excede el total de residentes en su
--     vivienda → posible inconsistencia entre tablas.
SELECT v.folioviv, v.tot_resid, h.huespedes
  FROM ds2.ds2_staging_viviendas v
  JOIN ds2.ds2_staging_hogares  h USING (folioviv)
 WHERE NULLIF(TRIM(h.huespedes),'')::INT > NULLIF(TRIM(v.tot_resid),'')::INT
 LIMIT 10;

-- H.3 Ingresos negativos (no debería haber)
SELECT COUNT(*) AS ingresos_negativos
  FROM ds2.ds2_staging_ingresos
 WHERE NULLIF(TRIM(ing_tri),'')::NUMERIC < 0;

-- H.4 Personas con foliohog que no existe en hogares (huérfanos)
SELECT COUNT(*) AS personas_sin_hogar
  FROM ds2.ds2_staging_poblacion p
  LEFT JOIN ds2.ds2_staging_hogares h
         ON h.folioviv = p.folioviv AND h.foliohog = p.foliohog
 WHERE h.folioviv IS NULL;

-- H.5 Hogares cuyo folioviv no existe en viviendas
SELECT COUNT(*) AS hogares_sin_vivienda
  FROM ds2.ds2_staging_hogares h
  LEFT JOIN ds2.ds2_staging_viviendas v ON v.folioviv = h.folioviv
 WHERE v.folioviv IS NULL;
