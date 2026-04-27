/*
================================================================================
 Script:      05_migration.sql
 Dataset:     3 - CONSAR
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   Migrar las 11 tablas de staging al modelo normalizado en 4FN.
              Incluye los pivots wide→long para #03, #05 y #09.
 Estrategia:
   1. Sembrar los 4 catálogos primarios (afore, siefore, tipo_recurso, plazo)
      curando los sentinels (es_agregado=TRUE) para los valores que no son
      AFOREs comerciales.
   2. Sembrar los 2 catálogos derivados (metrica_sensibilidad, metrica_cuenta)
      con los nombres de columna oficiales del CSV.
   3. Volcar las 11 tablas de hechos. Los datasets anchos (#03, #05, #09) se
      pivotean usando UNION ALL / VALUES.
   4. Las filas con `afore` agregada se almacenan en `ds3_agregado_observado`
      (no en el fact), preservando el dato del CSV sin contaminar el modelo.
================================================================================
*/

BEGIN;

-- ===========================================================================
-- 1. Catálogo AFORE
-- ===========================================================================
-- Conjunto canónico de slugs observados en los 11 staging tables.
WITH all_afores AS (
    SELECT DISTINCT TRIM(afore) AS slug FROM ds3.ds3_staging_precios_bolsa     WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_medidas           WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_entradas_salidas  WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_cuentas           WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_comisiones        WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_activos_netos     WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_traspasos         WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_recursos          WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_rendimientos      WHERE NULLIF(TRIM(afore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(afore)         FROM ds3.ds3_staging_precios_gestion   WHERE NULLIF(TRIM(afore),'') IS NOT NULL
)
INSERT INTO ds3.ds3_cat_afore (slug, nombre_display, es_agregado)
SELECT slug,
       INITCAP(slug)                            AS nombre_display,
       (
         slug ILIKE '%promedio ponderado%'
         OR slug ILIKE 'total %'
         OR slug ILIKE 'prestadora%'
         OR slug ILIKE 'cuentas resguardadas%'
         OR slug ILIKE 'adicionales promedio%'
       )                                        AS es_agregado
FROM all_afores
ORDER BY slug;

-- ===========================================================================
-- 2. Catálogo SIEFORE
-- ===========================================================================
WITH all_sf AS (
    SELECT DISTINCT TRIM(siefore) AS slug FROM ds3.ds3_staging_precios_bolsa   WHERE NULLIF(TRIM(siefore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(siefore)         FROM ds3.ds3_staging_medidas         WHERE NULLIF(TRIM(siefore),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(siefore)         FROM ds3.ds3_staging_precios_gestion WHERE NULLIF(TRIM(siefore),'') IS NOT NULL
)
INSERT INTO ds3.ds3_cat_siefore (slug, nombre_display)
SELECT slug, INITCAP(slug)
FROM all_sf
ORDER BY slug;

-- ===========================================================================
-- 3. Catálogo TIPO_RECURSO
-- ===========================================================================
WITH all_tr AS (
    SELECT DISTINCT TRIM(tipo_recurso) AS slug FROM ds3.ds3_staging_activos_netos WHERE NULLIF(TRIM(tipo_recurso),'') IS NOT NULL UNION
    SELECT DISTINCT TRIM(tipo_recurso)         FROM ds3.ds3_staging_rendimientos  WHERE NULLIF(TRIM(tipo_recurso),'') IS NOT NULL UNION
    -- Para #09 las "métricas" son tipos de recurso codificados como columnas;
    -- se siembran explícitamente abajo en el bloque de pivot.
    SELECT v FROM (VALUES
        ('ahorro solidario'),
        ('ahorro voluntario'),
        ('ahorro voluntario y solidario'),
        ('bono de pension issste'),
        ('capital de las afores'),
        ('fondos de prevision social'),
        ('fovissste'),
        ('infonavit'),
        ('rcv - imss'),
        ('rcv - issste'),
        ('recursos administrados por las afores'),
        ('recursos de los trabajadores'),
        ('recursos depositados en banco de méxico'),
        ('recursos registrados en el sar'),
        ('vivienda')
    ) AS x(v)
)
INSERT INTO ds3.ds3_cat_tipo_recurso (slug, nombre_display)
SELECT slug, INITCAP(slug)
FROM all_tr
ORDER BY slug;

-- ===========================================================================
-- 4. Catálogo PLAZO
-- ===========================================================================
INSERT INTO ds3.ds3_cat_plazo (slug, nombre_display, orden) VALUES
  ('12 meses',  '12 meses', 1),
  ('24 meses',  '24 meses', 2),
  ('36 meses',  '36 meses', 3),
  ('5 años',    '5 años',   4),
  ('historico', 'Histórico', 5);

-- ===========================================================================
-- 5. Catálogos derivados (métricas)
-- ===========================================================================
INSERT INTO ds3.ds3_cat_metrica_sensibilidad (columna_csv, descripcion, unidad) VALUES
  ('coeficiente_liquidez',                            'Coeficiente de liquidez',                                  'ratio'),
  ('diferencial_valor_riesgo_condicional_dcvar',      'Diferencial del valor en riesgo condicional (DCVaR)',      'pct'),
  ('error_seguimiento',                               'Error de seguimiento (tracking error)',                    'pct'),
  ('escenarios_valor_riesgo_var',                     'Escenarios de valor en riesgo (VaR)',                      'count'),
  ('plazo_promedio_ponderado_ppp',                    'Plazo promedio ponderado del portafolio',                  'dias'),
  ('provision_exposicion_instrumentos_derivados_pid', 'Provisión por exposición a instrumentos derivados (PID)',  'monto'),
  ('valor_riesgo_var',                                'Valor en riesgo (VaR)',                                    'pct');

INSERT INTO ds3.ds3_cat_metrica_cuenta (columna_csv, descripcion) VALUES
  ('cuentas_inhabilitadas',                                     'Cuentas inhabilitadas'),
  ('cuentas_resguardadas_fondo_pensiones_para_bienestar_010',   'Cuentas resguardadas en el Fondo de Pensiones para el Bienestar 010'),
  ('total_cuentas_administradas_sar',                           'Total de cuentas administradas SAR'),
  ('total_cuentas_administradas_afores',                        'Total de cuentas administradas por las AFOREs'),
  ('trabajadores_asignados',                                    'Trabajadores asignados'),
  ('trabajadores_asignados_recursos_depositados_banco_mexico',  'Trabajadores asignados con recursos depositados en Banco de México'),
  ('trabajadores_asignados_recursos_depositados_siefores',      'Trabajadores asignados con recursos depositados en SIEFOREs'),
  ('trabajadores_imss',                                         'Trabajadores IMSS'),
  ('trabajadores_independientes',                               'Trabajadores independientes'),
  ('trabajadores_issste',                                       'Trabajadores ISSSTE'),
  ('trabajadores_registrados',                                  'Trabajadores registrados');

-- ===========================================================================
-- 6. Hechos
-- ===========================================================================

-- Helper view: solo afores comerciales (no agregadas)
CREATE OR REPLACE VIEW ds3._v_afore_real AS
SELECT id_afore, slug FROM ds3.ds3_cat_afore WHERE es_agregado = FALSE;

-- ---- #01 precio bolsa ----
INSERT INTO ds3.ds3_precio_bolsa (fecha, id_afore, id_siefore, precio)
SELECT TRIM(s.fecha)::DATE, a.id_afore, sf.id_siefore,
       NULLIF(TRIM(s.precio),'')::NUMERIC(20,8)
  FROM ds3.ds3_staging_precios_bolsa s
  JOIN ds3._v_afore_real      a  ON a.slug  = TRIM(s.afore)
  JOIN ds3.ds3_cat_siefore    sf ON sf.slug = TRIM(s.siefore)
 WHERE NULLIF(TRIM(s.precio),'') IS NOT NULL;

-- ---- #02 PEA cotizantes ----
INSERT INTO ds3.ds3_pea_cotizantes (anio, cotizantes, pea, porcentaje_pea_afore)
SELECT TRIM(anio)::SMALLINT,
       NULLIF(TRIM(cotizantes),'')::BIGINT,
       NULLIF(TRIM(pea),'')::BIGINT,
       NULLIF(TRIM(porcentaje_pea_afore),'')::NUMERIC(6,2)
  FROM ds3.ds3_staging_pea_cotizantes
 WHERE NULLIF(TRIM(anio),'') IS NOT NULL;

-- ---- #03 medidas (PIVOT wide→long, 7 métricas) ----
INSERT INTO ds3.ds3_medida_sensibilidad (fecha, id_siefore, id_afore, id_metrica, valor)
SELECT TRIM(s.fecha)::DATE, sf.id_siefore, a.id_afore, m.id_metrica,
       NULLIF(TRIM(v.valor),'')::NUMERIC(20,6)
  FROM ds3.ds3_staging_medidas s
  JOIN ds3._v_afore_real   a  ON a.slug  = TRIM(s.afore)
  JOIN ds3.ds3_cat_siefore sf ON sf.slug = TRIM(s.siefore)
  CROSS JOIN LATERAL (VALUES
     ('coeficiente_liquidez',                            s.coeficiente_liquidez),
     ('diferencial_valor_riesgo_condicional_dcvar',      s.diferencial_valor_riesgo_condicional_dcvar),
     ('error_seguimiento',                               s.error_seguimiento),
     ('escenarios_valor_riesgo_var',                     s.escenarios_valor_riesgo_var),
     ('plazo_promedio_ponderado_ppp',                    s.plazo_promedio_ponderado_ppp),
     ('provision_exposicion_instrumentos_derivados_pid', s.provision_exposicion_instrumentos_derivados_pid),
     ('valor_riesgo_var',                                s.valor_riesgo_var)
  ) AS v(columna_csv, valor)
  JOIN ds3.ds3_cat_metrica_sensibilidad m ON m.columna_csv = v.columna_csv
 WHERE NULLIF(TRIM(v.valor),'') IS NOT NULL;

-- ---- #04 entradas / salidas ----
INSERT INTO ds3.ds3_flujo_recurso (fecha, id_afore, montos_entradas, montos_salidas)
SELECT TRIM(s.fecha)::DATE, a.id_afore,
       NULLIF(TRIM(s.montos_entradas),'')::NUMERIC(20,4),
       NULLIF(TRIM(s.montos_salidas),'')::NUMERIC(20,4)
  FROM ds3.ds3_staging_entradas_salidas s
  JOIN ds3._v_afore_real a ON a.slug = TRIM(s.afore);

-- ---- #05 cuentas (PIVOT wide→long, 11 métricas) ----
INSERT INTO ds3.ds3_cuenta_administrada (fecha, id_afore, id_metrica, valor)
SELECT TRIM(s.fecha)::DATE, a.id_afore, m.id_metrica,
       NULLIF(TRIM(v.valor),'')::NUMERIC(20,2)
  FROM ds3.ds3_staging_cuentas s
  JOIN ds3._v_afore_real a ON a.slug = TRIM(s.afore)
  CROSS JOIN LATERAL (VALUES
     ('cuentas_inhabilitadas',                                    s.cuentas_inhabilitadas),
     ('cuentas_resguardadas_fondo_pensiones_para_bienestar_010',  s.cuentas_resguardadas_fondo_pensiones_para_bienestar_010),
     ('total_cuentas_administradas_sar',                          s.total_cuentas_administradas_sar),
     ('total_cuentas_administradas_afores',                       s.total_cuentas_administradas_afores),
     ('trabajadores_asignados',                                   s.trabajadores_asignados),
     ('trabajadores_asignados_recursos_depositados_banco_mexico', s.trabajadores_asignados_recursos_depositados_banco_mexico),
     ('trabajadores_asignados_recursos_depositados_siefores',     s.trabajadores_asignados_recursos_depositados_siefores),
     ('trabajadores_imss',                                        s.trabajadores_imss),
     ('trabajadores_independientes',                              s.trabajadores_independientes),
     ('trabajadores_issste',                                      s.trabajadores_issste),
     ('trabajadores_registrados',                                 s.trabajadores_registrados)
  ) AS v(columna_csv, valor)
  JOIN ds3.ds3_cat_metrica_cuenta m ON m.columna_csv = v.columna_csv
 WHERE NULLIF(TRIM(v.valor),'') IS NOT NULL;

-- ---- #06 comisiones ----
INSERT INTO ds3.ds3_comision (fecha, id_afore, comision)
SELECT TRIM(s.fecha)::DATE, a.id_afore, NULLIF(TRIM(s.comision),'')::NUMERIC(7,4)
  FROM ds3.ds3_staging_comisiones s
  JOIN ds3._v_afore_real a ON a.slug = TRIM(s.afore)
 WHERE NULLIF(TRIM(s.comision),'') IS NOT NULL;

-- ---- #07 activos netos ----
INSERT INTO ds3.ds3_activo_neto (fecha, id_tipo_recurso, id_afore, monto)
SELECT TRIM(s.fecha)::DATE, tr.id_tipo_recurso, a.id_afore,
       NULLIF(TRIM(s.monto),'')::NUMERIC(20,4)
  FROM ds3.ds3_staging_activos_netos s
  JOIN ds3._v_afore_real        a  ON a.slug  = TRIM(s.afore)
  JOIN ds3.ds3_cat_tipo_recurso tr ON tr.slug = TRIM(s.tipo_recurso)
 WHERE NULLIF(TRIM(s.monto),'') IS NOT NULL;

-- ---- #08 traspasos ----
INSERT INTO ds3.ds3_traspaso (fecha, id_afore, num_tras_cedido, num_tras_recibido)
SELECT TRIM(s.fecha)::DATE, a.id_afore,
       NULLIF(TRIM(s.num_tras_cedido),'')::NUMERIC::INT,
       NULLIF(TRIM(s.num_tras_recibido),'')::NUMERIC::INT
  FROM ds3.ds3_staging_traspasos s
  JOIN ds3._v_afore_real a ON a.slug = TRIM(s.afore);

-- ---- #09 recursos por afore (PIVOT wide→long, 15 tipos de recurso) ----
INSERT INTO ds3.ds3_recurso_afore (fecha, id_afore, id_tipo_recurso, monto)
SELECT TRIM(s.fecha)::DATE, a.id_afore, tr.id_tipo_recurso,
       NULLIF(TRIM(v.valor),'')::NUMERIC(20,4)
  FROM ds3.ds3_staging_recursos s
  JOIN ds3._v_afore_real a ON a.slug = TRIM(s.afore)
  CROSS JOIN LATERAL (VALUES
     ('ahorro solidario',                            s."monto_ahorro solidario"),
     ('ahorro voluntario',                           s."monto_ahorro voluntario"),
     ('ahorro voluntario y solidario',               s."monto_ahorro voluntario y solidario"),
     ('bono de pension issste',                      s."monto_bono de pension issste"),
     ('capital de las afores',                       s."monto_capital de las afores"),
     ('fondos de prevision social',                  s."monto_fondos de prevision social"),
     ('fovissste',                                   s.monto_fovissste),
     ('infonavit',                                   s.monto_infonavit),
     ('rcv - imss',                                  s."monto_rcv - imss"),
     ('rcv - issste',                                s."monto_rcv - issste"),
     ('recursos administrados por las afores',       s."monto_recursos administrados por las afores"),
     ('recursos de los trabajadores',                s."monto_recursos de los trabajadores"),
     ('recursos depositados en banco de méxico',     s."monto_recursos depositados en banco de méxico"),
     ('recursos registrados en el sar',              s."monto_recursos registrados en el sar"),
     ('vivienda',                                    s.monto_vivienda)
  ) AS v(slug_tr, valor)
  JOIN ds3.ds3_cat_tipo_recurso tr ON tr.slug = v.slug_tr
 WHERE NULLIF(TRIM(v.valor),'') IS NOT NULL;

-- ---- #10 rendimientos ----
INSERT INTO ds3.ds3_rendimiento (fecha, id_tipo_recurso, id_plazo, id_afore, monto)
SELECT TRIM(s.fecha)::DATE, tr.id_tipo_recurso, p.id_plazo, a.id_afore,
       NULLIF(TRIM(s.monto),'')::NUMERIC(20,6)
  FROM ds3.ds3_staging_rendimientos s
  JOIN ds3._v_afore_real        a  ON a.slug = TRIM(s.afore)
  JOIN ds3.ds3_cat_tipo_recurso tr ON tr.slug = TRIM(s.tipo_recurso)
  JOIN ds3.ds3_cat_plazo        p  ON p.slug  = TRIM(s.plazo)
 WHERE NULLIF(TRIM(s.monto),'') IS NOT NULL;

-- ---- #11 precios de gestión ----
INSERT INTO ds3.ds3_precio_gestion (fecha, id_afore, id_siefore, precio)
SELECT TRIM(s.fecha)::DATE, a.id_afore, sf.id_siefore,
       NULLIF(TRIM(s.precio),'')::NUMERIC(20,8)
  FROM ds3.ds3_staging_precios_gestion s
  JOIN ds3._v_afore_real   a  ON a.slug = TRIM(s.afore)
  JOIN ds3.ds3_cat_siefore sf ON sf.slug = TRIM(s.siefore)
 WHERE NULLIF(TRIM(s.precio),'') IS NOT NULL;

-- ===========================================================================
-- 7. Agregados observados (sentinels) — preservar el bit del CSV original
-- ===========================================================================
-- Filas con etiqueta_afore agregada se guardan acá para reproducibilidad.
-- Ejemplo: #05 con afore='total de cuentas administradas en el sar'.
INSERT INTO ds3.ds3_agregado_observado
       (archivo_csv, fecha, etiqueta_afore, valor)
SELECT '05_cuentas',
       TRIM(s.fecha)::DATE,
       TRIM(s.afore),
       NULLIF(TRIM(s.total_cuentas_administradas_sar),'')::NUMERIC
  FROM ds3.ds3_staging_cuentas s
  JOIN ds3.ds3_cat_afore a ON a.slug = TRIM(s.afore) AND a.es_agregado = TRUE
 WHERE NULLIF(TRIM(s.total_cuentas_administradas_sar),'') IS NOT NULL;

INSERT INTO ds3.ds3_agregado_observado
       (archivo_csv, fecha, etiqueta_afore, plazo, valor)
SELECT '10_rendimientos',
       TRIM(s.fecha)::DATE,
       TRIM(s.afore),
       TRIM(s.plazo),
       NULLIF(TRIM(s.monto),'')::NUMERIC
  FROM ds3.ds3_staging_rendimientos s
  JOIN ds3.ds3_cat_afore a ON a.slug = TRIM(s.afore) AND a.es_agregado = TRUE
 WHERE NULLIF(TRIM(s.monto),'') IS NOT NULL;

COMMIT;

-- Conteos rápidos.
SELECT 'cat_afore'         AS tabla, COUNT(*) AS filas FROM ds3.ds3_cat_afore                  UNION ALL
SELECT 'cat_siefore',           COUNT(*)                  FROM ds3.ds3_cat_siefore             UNION ALL
SELECT 'cat_tipo_recurso',      COUNT(*)                  FROM ds3.ds3_cat_tipo_recurso        UNION ALL
SELECT 'cat_plazo',             COUNT(*)                  FROM ds3.ds3_cat_plazo               UNION ALL
SELECT 'cat_metrica_sens',      COUNT(*)                  FROM ds3.ds3_cat_metrica_sensibilidad UNION ALL
SELECT 'cat_metrica_cuenta',    COUNT(*)                  FROM ds3.ds3_cat_metrica_cuenta      UNION ALL
SELECT 'precio_bolsa',          COUNT(*)                  FROM ds3.ds3_precio_bolsa            UNION ALL
SELECT 'pea_cotizantes',        COUNT(*)                  FROM ds3.ds3_pea_cotizantes          UNION ALL
SELECT 'medida_sensibilidad',   COUNT(*)                  FROM ds3.ds3_medida_sensibilidad     UNION ALL
SELECT 'flujo_recurso',         COUNT(*)                  FROM ds3.ds3_flujo_recurso           UNION ALL
SELECT 'cuenta_administrada',   COUNT(*)                  FROM ds3.ds3_cuenta_administrada     UNION ALL
SELECT 'comision',              COUNT(*)                  FROM ds3.ds3_comision                UNION ALL
SELECT 'activo_neto',           COUNT(*)                  FROM ds3.ds3_activo_neto             UNION ALL
SELECT 'traspaso',              COUNT(*)                  FROM ds3.ds3_traspaso                UNION ALL
SELECT 'recurso_afore',         COUNT(*)                  FROM ds3.ds3_recurso_afore           UNION ALL
SELECT 'rendimiento',           COUNT(*)                  FROM ds3.ds3_rendimiento             UNION ALL
SELECT 'precio_gestion',        COUNT(*)                  FROM ds3.ds3_precio_gestion          UNION ALL
SELECT 'agregado_observado',    COUNT(*)                  FROM ds3.ds3_agregado_observado;
