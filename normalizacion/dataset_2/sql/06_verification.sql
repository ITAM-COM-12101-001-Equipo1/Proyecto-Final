/*
================================================================================
 Script:      06_verification.sql
 Dataset:     2 - ENIGH 2024 NS (INEGI)
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   Verificar la integridad de la migración del staging al modelo
              normalizado. Mismo patrón que dataset_1 (V1..V6).
 Criterios de aceptación:
   V1: COUNT(staging) == COUNT(entidad normalizada) en las 5 core.
   V2: cardinalidad de catálogos coherente con los códigos del staging.
   V3: SUM agregado de ingresos y gastos coincide entre staging y modelo.
   V4: integridad referencial (cero FKs rotas).
   V5: tablas puente con suma de filas == nº de no-nulos en grupos repetidos
       del staging.
   V6: reconstrucción "ancha" de algunas filas para validar fidelidad.
================================================================================
*/

-- ===========================================================================
-- V1. Conteos por entidad core
-- ===========================================================================
SELECT 'staging_viviendas'  AS tabla, COUNT(*) FROM ds2.ds2_staging_viviendas    UNION ALL
SELECT 'ds2_vivienda',           COUNT(*) FROM ds2.ds2_vivienda                  UNION ALL
SELECT 'staging_hogares',         COUNT(*) FROM ds2.ds2_staging_hogares           UNION ALL
SELECT 'ds2_hogar',                COUNT(*) FROM ds2.ds2_hogar                    UNION ALL
SELECT 'staging_poblacion',        COUNT(*) FROM ds2.ds2_staging_poblacion        UNION ALL
SELECT 'ds2_persona',              COUNT(*) FROM ds2.ds2_persona                  UNION ALL
SELECT 'staging_ingresos',         COUNT(*) FROM ds2.ds2_staging_ingresos         UNION ALL
SELECT 'ds2_persona_ingreso',      COUNT(*) FROM ds2.ds2_persona_ingreso          UNION ALL
SELECT 'staging_gastoshogar',      COUNT(*) FROM ds2.ds2_staging_gastoshogar      UNION ALL
SELECT 'ds2_hogar_gasto',          COUNT(*) FROM ds2.ds2_hogar_gasto;

-- ===========================================================================
-- V2. Cardinalidad de catálogos
-- ===========================================================================
SELECT 'cat_entidad'        AS catalogo, COUNT(*) AS filas, 32 AS esperado_aprox FROM ds2.ds2_cat_entidad        UNION ALL
SELECT 'cat_parentesco',         COUNT(*),  60 FROM ds2.ds2_cat_parentesco                                 UNION ALL
SELECT 'cat_sexo',                COUNT(*),   2 FROM ds2.ds2_cat_sexo                                      UNION ALL
SELECT 'cat_tipo_vivienda',       COUNT(*),  10 FROM ds2.ds2_cat_tipo_vivienda                             UNION ALL
SELECT 'cat_tenencia',            COUNT(*),   6 FROM ds2.ds2_cat_tenencia                                  UNION ALL
SELECT 'cat_alimento',            COUNT(*),  12 FROM ds2.ds2_cat_alimento                                  UNION ALL
SELECT 'cat_vehiculo',            COUNT(*),   9 FROM ds2.ds2_cat_vehiculo                                  UNION ALL
SELECT 'cat_aparato',             COUNT(*),  20 FROM ds2.ds2_cat_aparato                                   UNION ALL
SELECT 'cat_pregunta_acc_alim',   COUNT(*),  17 FROM ds2.ds2_cat_pregunta_acc_alim                         UNION ALL
SELECT 'cat_fenomeno_climatico',  COUNT(*),   7 FROM ds2.ds2_cat_fenomeno_climatico                        UNION ALL
SELECT 'cat_afectacion',          COUNT(*),   7 FROM ds2.ds2_cat_afectacion                                UNION ALL
SELECT 'cat_actividad_uso_tiempo',COUNT(*),   8 FROM ds2.ds2_cat_actividad_uso_tiempo                      UNION ALL
SELECT 'cat_clave_ingreso',       COUNT(*),  -1 FROM ds2.ds2_cat_clave_ingreso                             UNION ALL
SELECT 'cat_clave_gasto',         COUNT(*),  -1 FROM ds2.ds2_cat_clave_gasto;

-- ===========================================================================
-- V3. Sumas agregadas
-- ===========================================================================
WITH s AS (
    SELECT SUM(NULLIF(TRIM(ing_tri),'')::NUMERIC)   AS ing_total
      FROM ds2.ds2_staging_ingresos
), n AS (
    SELECT SUM(ing_tri) AS ing_total FROM ds2.ds2_persona_ingreso
)
SELECT s.ing_total AS ing_staging, n.ing_total AS ing_normalizado,
       (s.ing_total = n.ing_total) AS ok
FROM s, n;

WITH s AS (
    SELECT SUM(NULLIF(TRIM(gasto),'')::NUMERIC) AS gasto_total
      FROM ds2.ds2_staging_gastoshogar
), n AS (
    SELECT SUM(gasto) AS gasto_total FROM ds2.ds2_hogar_gasto
)
SELECT s.gasto_total AS gasto_staging, n.gasto_total AS gasto_normalizado,
       (s.gasto_total = n.gasto_total) AS ok
FROM s, n;

-- ===========================================================================
-- V4. Integridad referencial (FKs rotas)
-- ===========================================================================
SELECT 'fk_hogar_vivienda'  AS fk, COUNT(*) AS rotas FROM ds2.ds2_hogar h
   LEFT JOIN ds2.ds2_vivienda v ON v.folioviv = h.folioviv WHERE v.folioviv IS NULL UNION ALL
SELECT 'fk_persona_hogar',          COUNT(*) FROM ds2.ds2_persona p
   LEFT JOIN ds2.ds2_hogar h ON h.folioviv = p.folioviv AND h.foliohog = p.foliohog WHERE h.folioviv IS NULL UNION ALL
SELECT 'fk_ingreso_persona',         COUNT(*) FROM ds2.ds2_persona_ingreso pi
   LEFT JOIN ds2.ds2_persona p ON p.folioviv = pi.folioviv AND p.foliohog = pi.foliohog AND p.numren = pi.numren WHERE p.folioviv IS NULL UNION ALL
SELECT 'fk_gasto_hogar',             COUNT(*) FROM ds2.ds2_hogar_gasto g
   LEFT JOIN ds2.ds2_hogar h ON h.folioviv = g.folioviv AND h.foliohog = g.foliohog WHERE h.folioviv IS NULL UNION ALL
SELECT 'fk_consumo_alim_hogar',      COUNT(*) FROM ds2.ds2_hogar_consumo_alim c
   LEFT JOIN ds2.ds2_hogar h ON h.folioviv = c.folioviv AND h.foliohog = c.foliohog WHERE h.folioviv IS NULL UNION ALL
SELECT 'fk_uso_tiempo_persona',      COUNT(*) FROM ds2.ds2_persona_uso_tiempo u
   LEFT JOIN ds2.ds2_persona p ON p.folioviv = u.folioviv AND p.foliohog = u.foliohog AND p.numren = u.numren WHERE p.folioviv IS NULL;
-- Esperado: todas con rotas = 0.

-- ===========================================================================
-- V5. Tablas puente: filas == nº de no-nulos en grupos repetidos del staging
-- ===========================================================================
-- Consumo alimento: 12 columnas alim17_* en hogares con valor no nulo deben
-- generar igual número de filas en ds2_hogar_consumo_alim.
WITH staging_count AS (
    SELECT
      SUM((NULLIF(TRIM(alim17_1),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_2),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_3),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_4),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_5),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_6),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_7),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_8),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_9),'')  IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_10),'') IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_11),'') IS NOT NULL)::INT) +
      SUM((NULLIF(TRIM(alim17_12),'') IS NOT NULL)::INT) AS no_nulos
    FROM ds2.ds2_staging_hogares
), normalized_count AS (
    SELECT COUNT(*) AS filas FROM ds2.ds2_hogar_consumo_alim
)
SELECT s.no_nulos, n.filas, (s.no_nulos = n.filas) AS ok
FROM staging_count s, normalized_count n;

-- ===========================================================================
-- V6. Reconstrucción ancha de muestra: una fila aleatoria de hogares
-- ===========================================================================
SELECT v.folioviv, h.foliohog, ce.descripcion AS entidad,
       ct.descripcion AS tipo_vivienda,
       cten.descripcion AS tenencia,
       v.tot_resid, h.huespedes
  FROM ds2.ds2_hogar h
  JOIN ds2.ds2_vivienda v ON v.folioviv = h.folioviv
  LEFT JOIN ds2.ds2_cat_entidad       ce  ON ce.codigo  = v.cod_entidad
  LEFT JOIN ds2.ds2_cat_tipo_vivienda ct  ON ct.codigo  = v.cod_tipo_vivienda
  LEFT JOIN ds2.ds2_cat_tenencia      cten ON cten.codigo = v.cod_tenencia
 LIMIT 5;
