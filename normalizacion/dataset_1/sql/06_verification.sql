/*
================================================================================
 Script:      06_verification.sql
 Dataset:     1 - Remuneraciones del personal de la CDMX
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   Verificar que la migración del staging al esquema normalizado
              fue íntegra (sin pérdida ni duplicación de datos).
 Entrada:     ds1_staging_remuneraciones + esquema normalizado poblado.
 Salida:      Resultados booleanos / numéricos por verificación. Cada
              query devuelve un valor que el equipo puede contrastar.
 Criterio de aceptación:
   - V1: COUNT(staging) == COUNT(remuneracion) == COUNT(persona).
   - V2: cardinalidades de catálogos (27 / 73 / 7 / 11 / 1772).
   - V3: SUM(sueldos staging) == SUM(sueldos remuneración).
   - V4: cada fila del staging tiene exactamente una contraparte
         en remuneración (0 huérfanas).
   - V5: integridad referencial recíproca (no hay FKs colgando).
   - V6: la "tabla pivote" reconstruida desde el normalizado coincide
         fila a fila con el staging en muestras aleatorias.
================================================================================
*/

-- ===========================================================================
-- V1. Conteos generales
-- ===========================================================================
SELECT 'staging'           AS tabla, COUNT(*) AS filas FROM ds1.ds1_staging_remuneraciones UNION ALL
SELECT 'remuneracion',         COUNT(*) FROM ds1.ds1_remuneracion UNION ALL
SELECT 'persona',              COUNT(*) FROM ds1.ds1_persona;
-- Esperado: las tres con el mismo valor (246,821).

-- ===========================================================================
-- V2. Cardinalidad de catálogos
-- ===========================================================================
SELECT 'ds1_universo'      AS tabla, COUNT(*) AS filas, 27   AS esperado FROM ds1.ds1_universo      UNION ALL
SELECT 'ds1_sector',           COUNT(*),                73       FROM ds1.ds1_sector          UNION ALL
SELECT 'ds1_tipo_nomina',      COUNT(*),                7        FROM ds1.ds1_tipo_nomina     UNION ALL
SELECT 'ds1_tipo_personal',    COUNT(*),                11       FROM ds1.ds1_tipo_personal   UNION ALL
SELECT 'ds1_puesto',           COUNT(*),                1772     FROM ds1.ds1_puesto;

-- ===========================================================================
-- V3. Suma agregada de sueldos (ningún sueldo perdido o duplicado)
-- ===========================================================================
WITH s AS (
    SELECT SUM(sueldo_tabular_bruto::NUMERIC) AS bruto,
           SUM(sueldo_tabular_neto::NUMERIC)  AS neto
      FROM ds1.ds1_staging_remuneraciones
), n AS (
    SELECT SUM(sueldo_tabular_bruto)          AS bruto,
           SUM(sueldo_tabular_neto)           AS neto
      FROM ds1.ds1_remuneracion
)
SELECT
    s.bruto AS bruto_staging, n.bruto AS bruto_normalizado,
    (s.bruto = n.bruto) AS bruto_ok,
    s.neto  AS neto_staging,  n.neto  AS neto_normalizado,
    (s.neto = n.neto) AS neto_ok
FROM s, n;

-- ===========================================================================
-- V4. Cada fila del staging tiene exactamente una en remuneración
-- ===========================================================================
SELECT COUNT(*) AS filas_staging_sin_contraparte
  FROM ds1.ds1_staging_remuneraciones s
  LEFT JOIN ds1.ds1_remuneracion r ON r.id_remuneracion = s.staging_row_id
 WHERE r.id_remuneracion IS NULL;
-- Esperado: 0.

SELECT COUNT(*) AS filas_remuneracion_sin_staging
  FROM ds1.ds1_remuneracion r
  LEFT JOIN ds1.ds1_staging_remuneraciones s ON s.staging_row_id = r.id_remuneracion
 WHERE s.staging_row_id IS NULL;
-- Esperado: 0.

-- ===========================================================================
-- V5. Integridad referencial: ninguna FK rota
-- ===========================================================================
SELECT 'fk_persona'         AS fk, COUNT(*) AS rotas FROM ds1.ds1_remuneracion r
   LEFT JOIN ds1.ds1_persona       x ON x.id_persona       = r.id_persona       WHERE x.id_persona       IS NULL UNION ALL
SELECT 'fk_puesto',                COUNT(*)               FROM ds1.ds1_remuneracion r
   LEFT JOIN ds1.ds1_puesto        x ON x.id_puesto        = r.id_puesto        WHERE x.id_puesto        IS NULL UNION ALL
SELECT 'fk_tipo_nomina',           COUNT(*)               FROM ds1.ds1_remuneracion r
   LEFT JOIN ds1.ds1_tipo_nomina   x ON x.id_tipo_nomina   = r.id_tipo_nomina   WHERE x.id_tipo_nomina   IS NULL UNION ALL
SELECT 'fk_tipo_personal',         COUNT(*)               FROM ds1.ds1_remuneracion r
   LEFT JOIN ds1.ds1_tipo_personal x ON x.id_tipo_personal = r.id_tipo_personal WHERE x.id_tipo_personal IS NULL UNION ALL
SELECT 'fk_universo',              COUNT(*)               FROM ds1.ds1_remuneracion r
   LEFT JOIN ds1.ds1_universo      x ON x.id_universo      = r.id_universo      WHERE x.id_universo      IS NULL UNION ALL
SELECT 'fk_sector',                COUNT(*)               FROM ds1.ds1_remuneracion r
   LEFT JOIN ds1.ds1_sector        x ON x.id_sector        = r.id_sector        WHERE x.id_sector        IS NULL;
-- Esperado: todas con rotas = 0.

-- ===========================================================================
-- V6. Reconstrucción del staging desde el normalizado
-- ===========================================================================
-- Construye una vista "ancha" desde el modelo normalizado y la compara
-- contra el staging fila por fila. Devuelve el número de discrepancias.

WITH ancha AS (
    SELECT
        r.id_remuneracion                                              AS staging_row_id,
        per.nombre, per.apellido_1, per.apellido_2,
        per.sexo, per.edad::TEXT                                       AS edad,
        pu.n_puesto,
        r.id_tipo_nomina::TEXT                                         AS id_tipo_nomina,
        tn.tipo_contratacion,
        tp.tipo_personal,
        r.id_universo,  u.n_universo,
        r.id_sector,    se.n_cabeza_sector,
        r.id_nivel_salarial,
        r.sueldo_tabular_bruto::TEXT                                   AS sueldo_tabular_bruto,
        r.sueldo_tabular_neto::TEXT                                    AS sueldo_tabular_neto
      FROM ds1.ds1_remuneracion r
      JOIN ds1.ds1_persona       per ON per.id_persona       = r.id_persona
      JOIN ds1.ds1_puesto        pu  ON pu.id_puesto         = r.id_puesto
      JOIN ds1.ds1_tipo_nomina   tn  ON tn.id_tipo_nomina    = r.id_tipo_nomina
      JOIN ds1.ds1_tipo_personal tp  ON tp.id_tipo_personal  = r.id_tipo_personal
      JOIN ds1.ds1_universo      u   ON u.id_universo        = r.id_universo
      JOIN ds1.ds1_sector        se  ON se.id_sector         = r.id_sector
)
SELECT COUNT(*) AS discrepancias_normalizado_vs_staging
  FROM ancha a
  JOIN ds1.ds1_staging_remuneraciones s ON s.staging_row_id = a.staging_row_id
 WHERE TRIM(s.nombre)              IS DISTINCT FROM a.nombre
    OR TRIM(s.apellido_1)          IS DISTINCT FROM a.apellido_1
    OR TRIM(s.apellido_2)          IS DISTINCT FROM a.apellido_2
    OR TRIM(s.sexo)                IS DISTINCT FROM a.sexo
    OR TRIM(s.edad)                IS DISTINCT FROM a.edad
    OR TRIM(s.n_puesto)            IS DISTINCT FROM a.n_puesto
    OR TRIM(s.id_tipo_nomina)      IS DISTINCT FROM a.id_tipo_nomina
    OR TRIM(s.tipo_contratacion)   IS DISTINCT FROM a.tipo_contratacion
    OR TRIM(s.tipo_personal)       IS DISTINCT FROM a.tipo_personal
    OR TRIM(s.id_universo)         IS DISTINCT FROM a.id_universo
    OR TRIM(s.n_universo)          IS DISTINCT FROM a.n_universo
    OR TRIM(s.id_sector)           IS DISTINCT FROM a.id_sector
    OR TRIM(s.n_cabeza_sector)     IS DISTINCT FROM a.n_cabeza_sector
    OR TRIM(s.id_nivel_salarial)   IS DISTINCT FROM a.id_nivel_salarial
    OR TRIM(s.sueldo_tabular_bruto)::NUMERIC IS DISTINCT FROM a.sueldo_tabular_bruto::NUMERIC
    OR TRIM(s.sueldo_tabular_neto)::NUMERIC  IS DISTINCT FROM a.sueldo_tabular_neto::NUMERIC;
-- Esperado: 0.
