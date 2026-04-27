/*
================================================================================
 Script:      06_verification.sql
 Dataset:     3 - CONSAR
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   Verificar la integridad de la migración + validar las
              identidades contables relevantes.
 Criterios de aceptación:
   V1. Conteos staging vs (fact + agregados) coinciden.
   V2. Cardinalidad de catálogos.
   V3. Pivots wide→long preservan la suma de valores no nulos.
   V4. FKs íntegras.
   V5. Identidad contable #08: SUM(cedidos) = SUM(recibidos) por mes.
   V6. Identidad contable #04: comparación entradas vs salidas por afore/anio.
================================================================================
*/

-- ===========================================================================
-- V1. Conteos staging vs normalizado
-- ===========================================================================
-- Helper: las filas del fact + agregados deben sumar las filas no nulas del staging.

-- #01
SELECT '01_precios_bolsa' AS dataset,
       (SELECT COUNT(*) FROM ds3.ds3_staging_precios_bolsa WHERE NULLIF(TRIM(precio),'') IS NOT NULL) AS staging_no_null,
       (SELECT COUNT(*) FROM ds3.ds3_precio_bolsa)                                                    AS fact;

-- #03 (medidas): cada fila del staging genera HASTA 7 filas en el fact (una por
-- métrica no nula). Conteo de medidas no nulas en staging:
SELECT '03_medidas' AS dataset,
       (SELECT
            SUM((NULLIF(TRIM(coeficiente_liquidez),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(diferencial_valor_riesgo_condicional_dcvar),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(error_seguimiento),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(escenarios_valor_riesgo_var),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(plazo_promedio_ponderado_ppp),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(provision_exposicion_instrumentos_derivados_pid),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(valor_riesgo_var),'') IS NOT NULL)::INT)
        FROM ds3.ds3_staging_medidas) AS staging_medidas_no_nulas,
       (SELECT COUNT(*) FROM ds3.ds3_medida_sensibilidad) AS fact;

-- #05 (cuentas): cada fila genera hasta 11 filas
SELECT '05_cuentas' AS dataset,
       (SELECT
            SUM((NULLIF(TRIM(cuentas_inhabilitadas),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(cuentas_resguardadas_fondo_pensiones_para_bienestar_010),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(total_cuentas_administradas_sar),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(total_cuentas_administradas_afores),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(trabajadores_asignados),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(trabajadores_asignados_recursos_depositados_banco_mexico),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(trabajadores_asignados_recursos_depositados_siefores),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(trabajadores_imss),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(trabajadores_independientes),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(trabajadores_issste),'') IS NOT NULL)::INT) +
            SUM((NULLIF(TRIM(trabajadores_registrados),'') IS NOT NULL)::INT)
        FROM ds3.ds3_staging_cuentas
        JOIN ds3.ds3_cat_afore a ON a.slug = TRIM(ds3.ds3_staging_cuentas.afore) AND a.es_agregado = FALSE
       ) AS staging_cuentas_real_no_nulas,
       (SELECT COUNT(*) FROM ds3.ds3_cuenta_administrada) AS fact;

-- ===========================================================================
-- V2. Cardinalidad de catálogos
-- ===========================================================================
SELECT 'cat_afore_total'    AS k, COUNT(*) FROM ds3.ds3_cat_afore                                        UNION ALL
SELECT 'cat_afore_real',          COUNT(*) FROM ds3.ds3_cat_afore WHERE es_agregado = FALSE              UNION ALL
SELECT 'cat_afore_agregado',      COUNT(*) FROM ds3.ds3_cat_afore WHERE es_agregado = TRUE               UNION ALL
SELECT 'cat_siefore',             COUNT(*) FROM ds3.ds3_cat_siefore                                      UNION ALL
SELECT 'cat_tipo_recurso',        COUNT(*) FROM ds3.ds3_cat_tipo_recurso                                 UNION ALL
SELECT 'cat_plazo',               COUNT(*) FROM ds3.ds3_cat_plazo                                        UNION ALL
SELECT 'cat_metrica_sens',        COUNT(*) FROM ds3.ds3_cat_metrica_sensibilidad                         UNION ALL
SELECT 'cat_metrica_cuenta',      COUNT(*) FROM ds3.ds3_cat_metrica_cuenta;

-- ===========================================================================
-- V3. Pivots: suma de valores conservada
-- ===========================================================================
-- #03 medidas: la suma de UNA columna del staging (ej. valor_riesgo_var) debe
-- coincidir con la suma de esa misma métrica en el fact filtrado.
SELECT
    'staging coeficiente_liquidez' AS k,
    SUM(NULLIF(TRIM(coeficiente_liquidez),'')::NUMERIC) AS total
  FROM ds3.ds3_staging_medidas s
  JOIN ds3.ds3_cat_afore a ON a.slug = TRIM(s.afore) AND a.es_agregado = FALSE
UNION ALL
SELECT 'fact coeficiente_liquidez',
    SUM(valor)
  FROM ds3.ds3_medida_sensibilidad ms
  JOIN ds3.ds3_cat_metrica_sensibilidad m ON m.id_metrica = ms.id_metrica
 WHERE m.columna_csv = 'coeficiente_liquidez';
-- Esperado: ambas sumas iguales.

-- #09 recursos: suma de monto_vivienda en staging vs fact
SELECT 'staging vivienda' AS k,
       SUM(NULLIF(TRIM(monto_vivienda),'')::NUMERIC) AS total
  FROM ds3.ds3_staging_recursos s
  JOIN ds3.ds3_cat_afore a ON a.slug = TRIM(s.afore) AND a.es_agregado = FALSE
UNION ALL
SELECT 'fact vivienda',
       SUM(ra.monto)
  FROM ds3.ds3_recurso_afore ra
  JOIN ds3.ds3_cat_tipo_recurso tr ON tr.id_tipo_recurso = ra.id_tipo_recurso
 WHERE tr.slug = 'vivienda';

-- ===========================================================================
-- V4. FKs íntegras
-- ===========================================================================
SELECT 'fk_pb_afore'          AS fk, COUNT(*) AS rotas
  FROM ds3.ds3_precio_bolsa pb LEFT JOIN ds3.ds3_cat_afore a ON a.id_afore = pb.id_afore WHERE a.id_afore IS NULL UNION ALL
SELECT 'fk_pb_siefore',           COUNT(*)
  FROM ds3.ds3_precio_bolsa pb LEFT JOIN ds3.ds3_cat_siefore s ON s.id_siefore = pb.id_siefore WHERE s.id_siefore IS NULL UNION ALL
SELECT 'fk_medida_metrica',       COUNT(*)
  FROM ds3.ds3_medida_sensibilidad m LEFT JOIN ds3.ds3_cat_metrica_sensibilidad x ON x.id_metrica = m.id_metrica WHERE x.id_metrica IS NULL UNION ALL
SELECT 'fk_cuenta_metrica',       COUNT(*)
  FROM ds3.ds3_cuenta_administrada c LEFT JOIN ds3.ds3_cat_metrica_cuenta x ON x.id_metrica = c.id_metrica WHERE x.id_metrica IS NULL UNION ALL
SELECT 'fk_recurso_tipo',         COUNT(*)
  FROM ds3.ds3_recurso_afore r LEFT JOIN ds3.ds3_cat_tipo_recurso tr ON tr.id_tipo_recurso = r.id_tipo_recurso WHERE tr.id_tipo_recurso IS NULL UNION ALL
SELECT 'fk_rendimiento_plazo',    COUNT(*)
  FROM ds3.ds3_rendimiento r LEFT JOIN ds3.ds3_cat_plazo p ON p.id_plazo = r.id_plazo WHERE p.id_plazo IS NULL;
-- Esperado: 0 en todas.

-- ===========================================================================
-- V5. Identidad contable #08: SUM(cedidos) = SUM(recibidos) por mes
-- ===========================================================================
WITH agg AS (
    SELECT DATE_TRUNC('month', fecha)::DATE   AS mes,
           SUM(num_tras_cedido)               AS cedidos,
           SUM(num_tras_recibido)             AS recibidos
      FROM ds3.ds3_traspaso
     GROUP BY 1
)
SELECT
    COUNT(*)                                                            AS meses_total,
    SUM(CASE WHEN cedidos = recibidos THEN 1 ELSE 0 END)                AS meses_cuadran,
    SUM(CASE WHEN cedidos <> recibidos THEN 1 ELSE 0 END)               AS meses_no_cuadran,
    MIN(CASE WHEN cedidos <> recibidos THEN ABS(cedidos - recibidos) END) AS min_diff,
    MAX(CASE WHEN cedidos <> recibidos THEN ABS(cedidos - recibidos) END) AS max_diff
FROM agg;
-- Esperado: meses_no_cuadran=0 a nivel sistema. Si hay diferencias, suelen
-- corresponder a traspasos hacia/desde afores que ya no operan (capturados
-- como agregados). Documentar caso por caso.

-- ===========================================================================
-- V6. Identidad contable #04: balance entradas - salidas por anio
-- ===========================================================================
SELECT EXTRACT(YEAR FROM fecha)::INT AS anio,
       SUM(montos_entradas) AS entradas,
       SUM(montos_salidas)  AS salidas,
       SUM(montos_entradas) - SUM(montos_salidas) AS neto
  FROM ds3.ds3_flujo_recurso
 GROUP BY 1
 ORDER BY 1;
-- Esperado: el "neto" es el flujo neto del sistema. No es identidad
-- estricta como #08 — es una métrica derivada (flujo = entradas - salidas).
