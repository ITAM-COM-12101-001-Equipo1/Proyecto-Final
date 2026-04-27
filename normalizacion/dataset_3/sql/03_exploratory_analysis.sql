/*
================================================================================
 Script:      03_exploratory_analysis.sql
 Dataset:     3 - CONSAR
 Etapa:       2 (Limpieza y staging)
 Propósito:   Análisis exploratorio sobre los 11 staging tables.
              Bloques A–H tal como en dataset_1 y dataset_2.
================================================================================
*/

-- ===========================================================================
-- Volumetría general
-- ===========================================================================
SELECT '01_precios_bolsa'    AS dataset, 635167 AS esperado, COUNT(*) AS observado FROM ds3.ds3_staging_precios_bolsa     UNION ALL
SELECT '02_pea_cotizantes',         15, COUNT(*) FROM ds3.ds3_staging_pea_cotizantes                                       UNION ALL
SELECT '03_medidas',              7840, COUNT(*) FROM ds3.ds3_staging_medidas                                              UNION ALL
SELECT '04_entradas_salidas',     1980, COUNT(*) FROM ds3.ds3_staging_entradas_salidas                                     UNION ALL
SELECT '05_cuentas',              4303, COUNT(*) FROM ds3.ds3_staging_cuentas                                              UNION ALL
SELECT '06_comisiones',           2080, COUNT(*) FROM ds3.ds3_staging_comisiones                                           UNION ALL
SELECT '07_activos_netos',        9849, COUNT(*) FROM ds3.ds3_staging_activos_netos                                        UNION ALL
SELECT '08_traspasos',            3200, COUNT(*) FROM ds3.ds3_staging_traspasos                                            UNION ALL
SELECT '09_recursos',             3586, COUNT(*) FROM ds3.ds3_staging_recursos                                             UNION ALL
SELECT '10_rendimientos',        35041, COUNT(*) FROM ds3.ds3_staging_rendimientos                                         UNION ALL
SELECT '11_precios_gestion',    588318, COUNT(*) FROM ds3.ds3_staging_precios_gestion;

-- ===========================================================================
-- A. Atributos con valores únicos / candidatos a PK
-- ===========================================================================
-- A.1 #01 precios_bolsa: ¿(fecha, afore, siefore) es PK?
SELECT
    COUNT(*)                                                       AS total,
    COUNT(DISTINCT (fecha, afore, siefore))                        AS distinct_pk
  FROM ds3.ds3_staging_precios_bolsa;

-- A.2 #02 pea_cotizantes: ¿anio es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT anio) AS distinct_anio
  FROM ds3.ds3_staging_pea_cotizantes;

-- A.3 #03 medidas: ¿(fecha, siefore, afore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, siefore, afore)) AS distinct_pk
  FROM ds3.ds3_staging_medidas;

-- A.4 #04 entradas_salidas: ¿(fecha, afore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, afore)) AS distinct_pk
  FROM ds3.ds3_staging_entradas_salidas;

-- A.5 #05 cuentas: ¿(fecha, afore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, afore)) AS distinct_pk
  FROM ds3.ds3_staging_cuentas;

-- A.6 #06 comisiones: ¿(fecha, afore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, afore)) AS distinct_pk
  FROM ds3.ds3_staging_comisiones;

-- A.7 #07 activos_netos: ¿(fecha, tipo_recurso, afore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, tipo_recurso, afore)) AS distinct_pk
  FROM ds3.ds3_staging_activos_netos;

-- A.8 #08 traspasos: ¿(fecha, afore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, afore)) AS distinct_pk
  FROM ds3.ds3_staging_traspasos;

-- A.9 #09 recursos: ¿(fecha, afore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, afore)) AS distinct_pk
  FROM ds3.ds3_staging_recursos;

-- A.10 #10 rendimientos: ¿(fecha, tipo_recurso, plazo, afore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, tipo_recurso, plazo, afore)) AS distinct_pk
  FROM ds3.ds3_staging_rendimientos;

-- A.11 #11 precios_gestion: ¿(fecha, afore, siefore) es PK?
SELECT COUNT(*) AS total, COUNT(DISTINCT (fecha, afore, siefore)) AS distinct_pk
  FROM ds3.ds3_staging_precios_gestion;

-- ===========================================================================
-- B. Rango temporal por dataset
-- ===========================================================================
SELECT '01' AS ds, MIN(fecha) AS desde, MAX(fecha) AS hasta FROM ds3.ds3_staging_precios_bolsa     UNION ALL
SELECT '02', MIN(anio), MAX(anio)  FROM ds3.ds3_staging_pea_cotizantes                              UNION ALL
SELECT '03', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_medidas                                    UNION ALL
SELECT '04', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_entradas_salidas                           UNION ALL
SELECT '05', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_cuentas                                    UNION ALL
SELECT '06', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_comisiones                                 UNION ALL
SELECT '07', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_activos_netos                              UNION ALL
SELECT '08', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_traspasos                                  UNION ALL
SELECT '09', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_recursos                                   UNION ALL
SELECT '10', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_rendimientos                               UNION ALL
SELECT '11', MIN(fecha), MAX(fecha) FROM ds3.ds3_staging_precios_gestion;

-- ===========================================================================
-- C. Estadísticas numéricas
-- ===========================================================================
SELECT 'precio bolsa'        AS metrica,
       MIN(NULLIF(TRIM(precio),'')::NUMERIC),
       MAX(NULLIF(TRIM(precio),'')::NUMERIC),
       ROUND(AVG(NULLIF(TRIM(precio),'')::NUMERIC), 4)
  FROM ds3.ds3_staging_precios_bolsa
 WHERE NULLIF(TRIM(precio),'') IS NOT NULL UNION ALL
SELECT 'comision %',
       MIN(NULLIF(TRIM(comision),'')::NUMERIC),
       MAX(NULLIF(TRIM(comision),'')::NUMERIC),
       ROUND(AVG(NULLIF(TRIM(comision),'')::NUMERIC), 4)
  FROM ds3.ds3_staging_comisiones
 WHERE NULLIF(TRIM(comision),'') IS NOT NULL UNION ALL
SELECT 'monto activos netos',
       MIN(NULLIF(TRIM(monto),'')::NUMERIC),
       MAX(NULLIF(TRIM(monto),'')::NUMERIC),
       ROUND(AVG(NULLIF(TRIM(monto),'')::NUMERIC), 2)
  FROM ds3.ds3_staging_activos_netos
 WHERE NULLIF(TRIM(monto),'') IS NOT NULL;

-- ===========================================================================
-- D. Catálogos detectados (afore, siefore, tipo_recurso, plazo)
-- ===========================================================================
-- D.1 AFORE
SELECT DISTINCT afore FROM (
  SELECT afore FROM ds3.ds3_staging_precios_bolsa     UNION ALL
  SELECT afore FROM ds3.ds3_staging_medidas           UNION ALL
  SELECT afore FROM ds3.ds3_staging_entradas_salidas  UNION ALL
  SELECT afore FROM ds3.ds3_staging_cuentas           UNION ALL
  SELECT afore FROM ds3.ds3_staging_comisiones        UNION ALL
  SELECT afore FROM ds3.ds3_staging_activos_netos     UNION ALL
  SELECT afore FROM ds3.ds3_staging_traspasos         UNION ALL
  SELECT afore FROM ds3.ds3_staging_recursos          UNION ALL
  SELECT afore FROM ds3.ds3_staging_rendimientos      UNION ALL
  SELECT afore FROM ds3.ds3_staging_precios_gestion
) u
WHERE afore IS NOT NULL AND TRIM(afore) <> ''
ORDER BY 1;
-- Esperado: ~63 valores distintos. NO TODOS son afores reales — algunos son
-- agregados/sub-portfolios (ver H.1 abajo y bloque de curaduría en 05_migration).

-- D.2 SIEFORE
SELECT DISTINCT siefore FROM (
  SELECT siefore FROM ds3.ds3_staging_precios_bolsa   UNION ALL
  SELECT siefore FROM ds3.ds3_staging_medidas         UNION ALL
  SELECT siefore FROM ds3.ds3_staging_precios_gestion
) u
WHERE siefore IS NOT NULL AND TRIM(siefore) <> ''
ORDER BY 1;
-- Esperado: ~38 valores. Hay variantes históricas: "sb 55-59" vs
-- "siefore básica 55-59" para el mismo concepto.

-- D.3 TIPO_RECURSO
SELECT DISTINCT tipo_recurso FROM (
  SELECT tipo_recurso FROM ds3.ds3_staging_activos_netos UNION ALL
  SELECT tipo_recurso FROM ds3.ds3_staging_rendimientos
) u
ORDER BY 1;

-- D.4 PLAZO
SELECT DISTINCT plazo FROM ds3.ds3_staging_rendimientos ORDER BY 1;

-- ===========================================================================
-- E. Columnas redundantes / repeating groups (1FN)
-- ===========================================================================
-- Los datasets #03, #05 y #09 vienen ANCHOS: una fila con múltiples columnas
-- de medida. Esto viola 1FN (los nombres de columna codifican una dimensión).
-- En el modelo normalizado se descomponen vía un catálogo de métrica + tabla
-- de medida (fecha, afore, [siefore], id_metrica, valor).
SELECT '03_medidas       (7 métricas/fila)'  AS caso UNION ALL
SELECT '05_cuentas       (11 métricas/fila)'           UNION ALL
SELECT '09_recursos      (15 métricas/fila)';

-- ===========================================================================
-- F. Distribución categórica
-- ===========================================================================
SELECT afore, COUNT(*) AS apariciones
  FROM ds3.ds3_staging_precios_bolsa
 GROUP BY afore ORDER BY apariciones DESC LIMIT 15;

SELECT siefore, COUNT(*) AS apariciones
  FROM ds3.ds3_staging_precios_bolsa
 GROUP BY siefore ORDER BY apariciones DESC LIMIT 15;

-- ===========================================================================
-- G. Valores nulos / vacíos
-- ===========================================================================
SELECT '03_medidas.coef_liquidez NULL' AS check,
       SUM(CASE WHEN NULLIF(TRIM(coeficiente_liquidez),'') IS NULL THEN 1 ELSE 0 END) AS nulos
  FROM ds3.ds3_staging_medidas UNION ALL
SELECT '05_cuentas.tot_administradas NULL',
       SUM(CASE WHEN NULLIF(TRIM(total_cuentas_administradas_afores),'') IS NULL THEN 1 ELSE 0 END)
  FROM ds3.ds3_staging_cuentas UNION ALL
SELECT '09_recursos.rcv_imss NULL',
       SUM(CASE WHEN NULLIF(TRIM("monto_rcv - imss"),'') IS NULL THEN 1 ELSE 0 END)
  FROM ds3.ds3_staging_recursos;
-- Esperado: alta tasa de nulos en los datasets anchos (no toda métrica aplica
-- a toda afore en toda fecha). El pivot wide→long los descarta naturalmente.

-- ===========================================================================
-- H. Inconsistencias / sentinels detectados
-- ===========================================================================
-- H.1 Valores en columna `afore` que NO son afores reales (agregados,
-- sub-portfolios, columnas de promedio ponderado). Estos NO deben formar
-- parte del catálogo de afores comerciales; se documentan como sentinels.
SELECT DISTINCT afore
  FROM (
    SELECT afore FROM ds3.ds3_staging_precios_bolsa     UNION
    SELECT afore FROM ds3.ds3_staging_cuentas           UNION
    SELECT afore FROM ds3.ds3_staging_recursos          UNION
    SELECT afore FROM ds3.ds3_staging_rendimientos
  ) u
 WHERE LOWER(TRIM(afore)) LIKE '%promedio ponderado%'
    OR LOWER(TRIM(afore)) LIKE 'total %'
    OR LOWER(TRIM(afore)) LIKE 'prestadora%'
    OR LOWER(TRIM(afore)) LIKE 'cuentas resguardadas%'
 ORDER BY 1;

-- H.2 Identidad contable preliminar #08: SUM(cedidos) ≈ SUM(recibidos)
-- por mes a nivel sistema. Se valida formalmente en 06_verification.
SELECT
    DATE_TRUNC('month', NULLIF(TRIM(fecha),'')::DATE) AS mes,
    SUM(NULLIF(TRIM(num_tras_cedido),'')::NUMERIC)    AS cedidos,
    SUM(NULLIF(TRIM(num_tras_recibido),'')::NUMERIC)  AS recibidos
  FROM ds3.ds3_staging_traspasos
 GROUP BY 1
 ORDER BY 1
 LIMIT 12;

-- H.3 Identidad contable preliminar #04: comparación entradas vs salidas
SELECT
    DATE_TRUNC('year', NULLIF(TRIM(fecha),'')::DATE) AS anio,
    SUM(NULLIF(TRIM(montos_entradas),'')::NUMERIC)   AS entradas_total,
    SUM(NULLIF(TRIM(montos_salidas),'')::NUMERIC)    AS salidas_total
  FROM ds3.ds3_staging_entradas_salidas
 GROUP BY 1
 ORDER BY 1
 LIMIT 5;
