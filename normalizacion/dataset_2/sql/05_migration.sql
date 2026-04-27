/*
================================================================================
 Script:      05_migration.sql
 Dataset:     2 - ENIGH 2024 NS (INEGI)
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   Migrar las 5 tablas core del staging al modelo normalizado en
              4FN (catálogos + entidades + tablas puente).
 Entrada:     Tablas de staging pobladas (script 02).
 Salida:      Modelo normalizado poblado. Conteos esperados:
                ds2_vivienda          90,324
                ds2_hogar             91,414
                ds2_persona          308,598
                ds2_persona_ingreso  391,563
                ds2_hogar_gasto    5,311,497
                + tablas puente con conteos derivados de los repeating groups.
 Estrategia:
   1. Cargar catálogos INEGI desde la tabla unificada de staging.
   2. Sembrar catálogos derivados (alimento, vehículo, aparato, pregunta
      de acceso alimentario, fenómeno, afectación, uso del tiempo).
   3. Insertar entidades en orden: vivienda → hogar → persona →
      persona_ingreso → hogar_gasto.
   4. Poblar las tablas puente desde los grupos repetidos del staging.
================================================================================
*/

BEGIN;

-- ===========================================================================
-- 1. Catálogos INEGI (desde tabla unificada de staging)
-- ===========================================================================
INSERT INTO ds2.ds2_cat_entidad (codigo, descripcion)
SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='entidad';

INSERT INTO ds2.ds2_cat_parentesco (codigo, descripcion)
SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='parentesco';

INSERT INTO ds2.ds2_cat_sexo (codigo, descripcion)
SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='sexo';

INSERT INTO ds2.ds2_cat_tipo_vivienda (codigo, descripcion)
SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='tipo_viv';

INSERT INTO ds2.ds2_cat_tenencia (codigo, descripcion)
SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='tenencia';

INSERT INTO ds2.ds2_cat_mat_pared  (codigo, descripcion) SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='mat_pared';
INSERT INTO ds2.ds2_cat_mat_techos (codigo, descripcion) SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='mat_techos';
INSERT INTO ds2.ds2_cat_mat_pisos  (codigo, descripcion) SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='mat_pisos';
INSERT INTO ds2.ds2_cat_agua_ent   (codigo, descripcion) SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='agua_ent';
INSERT INTO ds2.ds2_cat_ab_agua    (codigo, descripcion) SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='ab_agua';
INSERT INTO ds2.ds2_cat_drenaje    (codigo, descripcion) SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='drenaje';
INSERT INTO ds2.ds2_cat_combus     (codigo, descripcion) SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='combus';
INSERT INTO ds2.ds2_cat_si_no      (codigo, descripcion) SELECT codigo, descripcion FROM ds2.ds2_staging_catalogo_inegi WHERE catalogo_nombre='si_no';

-- ===========================================================================
-- 2. Catálogos derivados (sembrados manualmente desde el diccionario INEGI)
-- ===========================================================================
INSERT INTO ds2.ds2_cat_alimento (sufijo_csv, descripcion) VALUES
  ('alim17_1',  'Cereales'),
  ('alim17_2',  'Tubérculos'),
  ('alim17_3',  'Verduras'),
  ('alim17_4',  'Frutas'),
  ('alim17_5',  'Carne'),
  ('alim17_6',  'Huevo'),
  ('alim17_7',  'Pescado'),
  ('alim17_8',  'Leguminosas'),
  ('alim17_9',  'Lácteos'),
  ('alim17_10', 'Aceites'),
  ('alim17_11', 'Azúcar'),
  ('alim17_12', 'Otros alimentos');

INSERT INTO ds2.ds2_cat_vehiculo (sufijo_csv, descripcion) VALUES
  ('auto',  'Automóvil'),
  ('van',   'Camioneta'),
  ('pick',  'Pickup'),
  ('moto',  'Motocicleta'),
  ('bici',  'Bicicleta'),
  ('trici', 'Triciclo'),
  ('carre', 'Carreta'),
  ('canoa', 'Canoa'),
  ('otro',  'Otro vehículo');

INSERT INTO ds2.ds2_cat_aparato (sufijo_csv, descripcion) VALUES
  ('ester', 'Estéreo / equipo de sonido'),
  ('radio', 'Radio'),
  ('tva',   'Televisor analógico'),
  ('tvd',   'Televisor digital'),
  ('dvd',   'DVD / Blu-Ray'),
  ('licua', 'Licuadora'),
  ('tosta', 'Tostador'),
  ('micro', 'Horno de microondas'),
  ('refri', 'Refrigerador'),
  ('estuf', 'Estufa'),
  ('lavad', 'Lavadora'),
  ('planc', 'Plancha'),
  ('maqui', 'Máquina de coser'),
  ('venti', 'Ventilador'),
  ('aspir', 'Aspiradora'),
  ('compu', 'Computadora de escritorio'),
  ('lap',   'Laptop'),
  ('table', 'Tablet'),
  ('impre', 'Impresora'),
  ('juego', 'Consola de videojuegos');

INSERT INTO ds2.ds2_cat_pregunta_acc_alim (sufijo_csv, descripcion) VALUES
  ('acc_alim1',  'Preocupación porque la comida se acabe'),
  ('acc_alim2',  'Sin comida'),
  ('acc_alim3',  'Poca variedad de alimentos'),
  ('acc_alim4',  'Adulto poca variedad de alimentos'),
  ('acc_alim5',  'Dejó algún alimento'),
  ('acc_alim6',  'Comió menos'),
  ('acc_alim7',  'Sintió hambre y no comió'),
  ('acc_alim8',  'Una o menos comidas'),
  ('acc_alim9',  'Mendigar por comida'),
  ('acc_alim10', 'Menor con alimentos no sanos'),
  ('acc_alim11', 'Menor con poca variedad de alimentos'),
  ('acc_alim12', 'Menor comió menos'),
  ('acc_alim13', 'Disminuyó comida para menor'),
  ('acc_alim14', 'Menor sintió hambre y no comió'),
  ('acc_alim15', 'Menor se acostó con hambre'),
  ('acc_alim16', 'Menor con una o menos comidas'),
  ('acc_alim18', 'Relación con el consumo regular');

INSERT INTO ds2.ds2_cat_fenomeno_climatico (sufijo_csv, descripcion) VALUES
  ('f_sequia',   'Sequía'),
  ('f_inunda',   'Inundación'),
  ('f_helada',   'Helada'),
  ('f_incendio', 'Incendio'),
  ('f_huracan',  'Huracán'),
  ('f_desliza',  'Deslizamiento'),
  ('f_otro',     'Otro fenómeno');

INSERT INTO ds2.ds2_cat_afectacion (sufijo_csv, descripcion) VALUES
  ('af_viv',     'Vivienda'),
  ('af_empleo',  'Empleo'),
  ('af_negocio', 'Negocio'),
  ('af_cultivo', 'Cultivo'),
  ('af_trabajo', 'Trabajo'),
  ('af_salud',   'Salud'),
  ('af_otro',    'Otro');

INSERT INTO ds2.ds2_cat_actividad_uso_tiempo (id_actividad, descripcion) VALUES
  (1, 'Actividad 1 (ver diccionario INEGI usotiempo1)'),
  (2, 'Actividad 2 (usotiempo2)'),
  (3, 'Actividad 3 (usotiempo3)'),
  (4, 'Actividad 4 (usotiempo4)'),
  (5, 'Actividad 5 (usotiempo5)'),
  (6, 'Actividad 6 (usotiempo6)'),
  (7, 'Actividad 7 (usotiempo7)'),
  (8, 'Actividad 8 (usotiempo8)');

-- Claves de ingreso y gasto: poblar a partir de los códigos observados.
INSERT INTO ds2.ds2_cat_clave_ingreso (clave)
SELECT DISTINCT TRIM(clave) FROM ds2.ds2_staging_ingresos WHERE NULLIF(TRIM(clave),'') IS NOT NULL;

INSERT INTO ds2.ds2_cat_clave_gasto (clave)
SELECT DISTINCT TRIM(clave) FROM ds2.ds2_staging_gastoshogar WHERE NULLIF(TRIM(clave),'') IS NOT NULL;

-- ===========================================================================
-- 3. Entidades core
-- ===========================================================================

INSERT INTO ds2.ds2_vivienda (
    folioviv, cod_entidad, cod_tipo_vivienda, cod_mat_pared, cod_mat_techos,
    cod_mat_pisos, cod_agua_ent, cod_ab_agua, cod_drenaje, cod_combus,
    cod_tenencia, antiguedad, cuart_dorm, num_cuarto, tot_resid, tot_hom,
    tot_muj, tot_hog, ubica_geo, tam_loc, est_socio, est_dis, upm, factor
)
SELECT
    s.folioviv,
    SUBSTRING(s.ubica_geo, 1, 2)               AS cod_entidad,  -- entidad = 2 primeros chars del ubica_geo
    NULLIF(TRIM(s.tipo_viv),''),
    NULLIF(TRIM(s.mat_pared),''),
    NULLIF(TRIM(s.mat_techos),''),
    NULLIF(TRIM(s.mat_pisos),''),
    NULLIF(TRIM(s.agua_ent),''),
    NULLIF(TRIM(s.ab_agua),''),
    NULLIF(TRIM(s.drenaje),''),
    NULLIF(TRIM(s.combus),''),
    NULLIF(TRIM(s.tenencia),''),
    NULLIF(TRIM(s.antiguedad),'')::SMALLINT,
    NULLIF(TRIM(s.cuart_dorm),'')::SMALLINT,
    NULLIF(TRIM(s.num_cuarto),'')::SMALLINT,
    NULLIF(TRIM(s.tot_resid),'')::SMALLINT,
    NULLIF(TRIM(s.tot_hom),'')::SMALLINT,
    NULLIF(TRIM(s.tot_muj),'')::SMALLINT,
    NULLIF(TRIM(s.tot_hog),'')::SMALLINT,
    s.ubica_geo, s.tam_loc, s.est_socio, s.est_dis, s.upm,
    NULLIF(TRIM(s.factor),'')::INT
FROM ds2.ds2_staging_viviendas s;

INSERT INTO ds2.ds2_hogar (
    folioviv, foliohog, huespedes, huesp_come, num_trab_d, trab_come,
    telefono, celular, conex_inte, tv_paga, peliculas, camb_clim,
    consumo, autocons, regalos, remunera, transferen
)
SELECT
    s.folioviv, s.foliohog,
    NULLIF(TRIM(s.huespedes),'')::SMALLINT,
    NULLIF(TRIM(s.huesp_come),'')::SMALLINT,
    NULLIF(TRIM(s.num_trab_d),'')::SMALLINT,
    NULLIF(TRIM(s.trab_come),'')::SMALLINT,
    NULLIF(TRIM(s.telefono),''),
    NULLIF(TRIM(s.celular),''),
    NULLIF(TRIM(s.conex_inte),''),
    NULLIF(TRIM(s.tv_paga),''),
    NULLIF(TRIM(s.peliculas),''),
    NULLIF(TRIM(s.camb_clim),''),
    NULLIF(TRIM(s.consumo),''),
    NULLIF(TRIM(s.autocons),''),
    NULLIF(TRIM(s.regalos),''),
    NULLIF(TRIM(s.remunera),''),
    NULLIF(TRIM(s.transferen),'')
FROM ds2.ds2_staging_hogares s;

INSERT INTO ds2.ds2_persona (
    folioviv, foliohog, numren, cod_parentesco, cod_sexo, edad, pais_nac,
    hablaind, hablaesp, alfabetism, asis_esc, nivelaprob, edo_conyug,
    diabetes, pres_alta
)
SELECT
    s.folioviv, s.foliohog, s.numren,
    NULLIF(TRIM(s.parentesco),''),
    NULLIF(TRIM(s.sexo),''),
    NULLIF(TRIM(s.edad),'')::SMALLINT,
    NULLIF(TRIM(s.pais_nac),''),
    NULLIF(TRIM(s.hablaind),''),
    NULLIF(TRIM(s.hablaesp),''),
    NULLIF(TRIM(s.alfabetism),''),
    NULLIF(TRIM(s.asis_esc),''),
    NULLIF(TRIM(s.nivelaprob),''),
    NULLIF(TRIM(s.edo_conyug),''),
    NULLIF(TRIM(s.diabetes),''),
    NULLIF(TRIM(s.pres_alta),'')
FROM ds2.ds2_staging_poblacion s;

INSERT INTO ds2.ds2_persona_ingreso (
    folioviv, foliohog, numren, clave, mes_1, mes_2, mes_3, mes_4, mes_5, mes_6,
    ing_1, ing_2, ing_3, ing_4, ing_5, ing_6, ing_tri
)
SELECT
    s.folioviv, s.foliohog, s.numren, TRIM(s.clave),
    NULLIF(TRIM(s.mes_1),''), NULLIF(TRIM(s.mes_2),''), NULLIF(TRIM(s.mes_3),''),
    NULLIF(TRIM(s.mes_4),''), NULLIF(TRIM(s.mes_5),''), NULLIF(TRIM(s.mes_6),''),
    NULLIF(TRIM(s.ing_1),'')::NUMERIC(14,2), NULLIF(TRIM(s.ing_2),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.ing_3),'')::NUMERIC(14,2), NULLIF(TRIM(s.ing_4),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.ing_5),'')::NUMERIC(14,2), NULLIF(TRIM(s.ing_6),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.ing_tri),'')::NUMERIC(14,2)
FROM ds2.ds2_staging_ingresos s;

INSERT INTO ds2.ds2_hogar_gasto (
    folioviv, foliohog, clave, tipo_gasto, mes_dia, forma_pag1, forma_pag2,
    forma_pag3, lugar_comp, orga_inst, frecuencia, fecha_adqu, fecha_pago,
    cantidad, gasto, pago_mp, costo, inmujer, num_meses, num_pagos,
    ultim_pago, gasto_tri, gasto_nm, gas_nm_tri, imujer_tri
)
SELECT
    s.folioviv, s.foliohog, TRIM(s.clave),
    NULLIF(TRIM(s.tipo_gasto),''),
    NULLIF(TRIM(s.mes_dia),''),
    NULLIF(TRIM(s.forma_pag1),''),
    NULLIF(TRIM(s.forma_pag2),''),
    NULLIF(TRIM(s.forma_pag3),''),
    NULLIF(TRIM(s.lugar_comp),''),
    NULLIF(TRIM(s.orga_inst),''),
    NULLIF(TRIM(s.frecuencia),''),
    NULLIF(TRIM(s.fecha_adqu),''),
    NULLIF(TRIM(s.fecha_pago),''),
    NULLIF(TRIM(s.cantidad),'')::NUMERIC(14,4),
    NULLIF(TRIM(s.gasto),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.pago_mp),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.costo),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.inmujer),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.num_meses),'')::SMALLINT,
    NULLIF(TRIM(s.num_pagos),'')::SMALLINT,
    NULLIF(TRIM(s.ultim_pago),''),
    NULLIF(TRIM(s.gasto_tri),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.gasto_nm),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.gas_nm_tri),'')::NUMERIC(14,2),
    NULLIF(TRIM(s.imujer_tri),'')::NUMERIC(14,2)
FROM ds2.ds2_staging_gastoshogar s;

-- ===========================================================================
-- 4. Tablas puente (1FN — repeating groups → filas)
-- ===========================================================================

-- 4.1 Hogar × consumo de alimento
INSERT INTO ds2.ds2_hogar_consumo_alim (folioviv, foliohog, id_alimento, dias_consumo)
SELECT s.folioviv, s.foliohog, c.id_alimento, NULLIF(TRIM(v.valor),'')::SMALLINT
FROM ds2.ds2_staging_hogares s
CROSS JOIN LATERAL (
    VALUES
      ('alim17_1',  s.alim17_1),  ('alim17_2',  s.alim17_2),
      ('alim17_3',  s.alim17_3),  ('alim17_4',  s.alim17_4),
      ('alim17_5',  s.alim17_5),  ('alim17_6',  s.alim17_6),
      ('alim17_7',  s.alim17_7),  ('alim17_8',  s.alim17_8),
      ('alim17_9',  s.alim17_9),  ('alim17_10', s.alim17_10),
      ('alim17_11', s.alim17_11), ('alim17_12', s.alim17_12)
) AS v(sufijo_csv, valor)
JOIN ds2.ds2_cat_alimento c ON c.sufijo_csv = v.sufijo_csv
WHERE NULLIF(TRIM(v.valor),'') IS NOT NULL;

-- 4.2 Hogar × vehículo
INSERT INTO ds2.ds2_hogar_vehiculo (folioviv, foliohog, id_vehiculo, cantidad, anio_ultimo)
SELECT s.folioviv, s.foliohog, c.id_vehiculo,
       NULLIF(TRIM(v.cantidad),'')::SMALLINT,
       NULLIF(TRIM(v.anio),'')
FROM ds2.ds2_staging_hogares s
CROSS JOIN LATERAL (
    VALUES
      ('auto',  s.num_auto,  s.anio_auto),
      ('van',   s.num_van,   s.anio_van),
      ('pick',  s.num_pick,  s.anio_pick),
      ('moto',  s.num_moto,  s.anio_moto),
      ('bici',  s.num_bici,  s.anio_bici),
      ('trici', s.num_trici, s.anio_trici),
      ('carre', s.num_carre, s.anio_carre),
      ('canoa', s.num_canoa, s.anio_canoa),
      ('otro',  s.num_otro,  s.anio_otro)
) AS v(sufijo_csv, cantidad, anio)
JOIN ds2.ds2_cat_vehiculo c ON c.sufijo_csv = v.sufijo_csv
WHERE NULLIF(TRIM(v.cantidad),'') IS NOT NULL
  AND TRIM(v.cantidad)::SMALLINT > 0;   -- solo registramos los que el hogar tiene

-- 4.3 Hogar × aparato (electrodoméstico/electrónico)
INSERT INTO ds2.ds2_hogar_aparato (folioviv, foliohog, id_aparato, cantidad, anio_ultimo)
SELECT s.folioviv, s.foliohog, c.id_aparato,
       NULLIF(TRIM(v.cantidad),'')::SMALLINT,
       NULLIF(TRIM(v.anio),'')
FROM ds2.ds2_staging_hogares s
CROSS JOIN LATERAL (
    VALUES
      ('ester', s.num_ester, s.anio_ester),
      ('radio', s.num_radio, s.anio_radio),
      ('tva',   s.num_tva,   s.anio_tva),
      ('tvd',   s.num_tvd,   s.anio_tvd),
      ('dvd',   s.num_dvd,   s.anio_dvd),
      ('licua', s.num_licua, s.anio_licua),
      ('tosta', s.num_tosta, s.anio_tosta),
      ('micro', s.num_micro, s.anio_micro),
      ('refri', s.num_refri, s.anio_refri),
      ('estuf', s.num_estuf, s.anio_estuf),
      ('lavad', s.num_lavad, s.anio_lavad),
      ('planc', s.num_planc, s.anio_planc),
      ('maqui', s.num_maqui, s.anio_maqui),
      ('venti', s.num_venti, s.anio_venti),
      ('aspir', s.num_aspir, s.anio_aspir),
      ('compu', s.num_compu, s.anio_compu),
      ('lap',   s.num_lap,   s.anio_lap),
      ('table', s.num_table, s.anio_table),
      ('impre', s.num_impre, s.anio_impre),
      ('juego', s.num_juego, s.anio_juego)
) AS v(sufijo_csv, cantidad, anio)
JOIN ds2.ds2_cat_aparato c ON c.sufijo_csv = v.sufijo_csv
WHERE NULLIF(TRIM(v.cantidad),'') IS NOT NULL
  AND TRIM(v.cantidad)::SMALLINT > 0;

-- 4.4 Hogar × pregunta acceso alimentario (acc_alim1..16, 18)
INSERT INTO ds2.ds2_hogar_acceso_alim (folioviv, foliohog, id_pregunta, respuesta)
SELECT s.folioviv, s.foliohog, c.id_pregunta, TRIM(v.valor)
FROM ds2.ds2_staging_hogares s
CROSS JOIN LATERAL (
    VALUES
      ('acc_alim1',  s.acc_alim1),  ('acc_alim2',  s.acc_alim2),
      ('acc_alim3',  s.acc_alim3),  ('acc_alim4',  s.acc_alim4),
      ('acc_alim5',  s.acc_alim5),  ('acc_alim6',  s.acc_alim6),
      ('acc_alim7',  s.acc_alim7),  ('acc_alim8',  s.acc_alim8),
      ('acc_alim9',  s.acc_alim9),  ('acc_alim10', s.acc_alim10),
      ('acc_alim11', s.acc_alim11), ('acc_alim12', s.acc_alim12),
      ('acc_alim13', s.acc_alim13), ('acc_alim14', s.acc_alim14),
      ('acc_alim15', s.acc_alim15), ('acc_alim16', s.acc_alim16),
      ('acc_alim18', s.acc_alim18)
) AS v(sufijo_csv, valor)
JOIN ds2.ds2_cat_pregunta_acc_alim c ON c.sufijo_csv = v.sufijo_csv
WHERE NULLIF(TRIM(v.valor),'') IS NOT NULL;

-- 4.5 Hogar × fenómeno climático
INSERT INTO ds2.ds2_hogar_fenomeno (folioviv, foliohog, id_fenomeno, presencio)
SELECT s.folioviv, s.foliohog, c.id_fenomeno, TRIM(v.valor)
FROM ds2.ds2_staging_hogares s
CROSS JOIN LATERAL (
    VALUES
      ('f_sequia',   s.f_sequia),   ('f_inunda', s.f_inunda),
      ('f_helada',   s.f_helada),   ('f_incendio', s.f_incendio),
      ('f_huracan',  s.f_huracan),  ('f_desliza', s.f_desliza),
      ('f_otro',     s.f_otro)
) AS v(sufijo_csv, valor)
JOIN ds2.ds2_cat_fenomeno_climatico c ON c.sufijo_csv = v.sufijo_csv
WHERE NULLIF(TRIM(v.valor),'') IS NOT NULL;

-- 4.6 Hogar × afectación
INSERT INTO ds2.ds2_hogar_afectacion (folioviv, foliohog, id_afectacion, afecto)
SELECT s.folioviv, s.foliohog, c.id_afectacion, TRIM(v.valor)
FROM ds2.ds2_staging_hogares s
CROSS JOIN LATERAL (
    VALUES
      ('af_viv',     s.af_viv),     ('af_empleo',  s.af_empleo),
      ('af_negocio', s.af_negocio), ('af_cultivo', s.af_cultivo),
      ('af_trabajo', s.af_trabajo), ('af_salud',   s.af_salud),
      ('af_otro',    s.af_otro)
) AS v(sufijo_csv, valor)
JOIN ds2.ds2_cat_afectacion c ON c.sufijo_csv = v.sufijo_csv
WHERE NULLIF(TRIM(v.valor),'') IS NOT NULL;

-- 4.7 Persona × actividad de uso del tiempo (8 actividades)
INSERT INTO ds2.ds2_persona_uso_tiempo
       (folioviv, foliohog, numren, id_actividad, horas, minutos, clave_uso)
SELECT s.folioviv, s.foliohog, s.numren, v.id_actividad,
       NULLIF(TRIM(v.h),'')::SMALLINT,
       NULLIF(TRIM(v.m),'')::SMALLINT,
       NULLIF(TRIM(v.k),'')
FROM ds2.ds2_staging_poblacion s
CROSS JOIN LATERAL (
    VALUES
      (1::SMALLINT, s.hor_1, s.min_1, s.usotiempo1),
      (2,           s.hor_2, s.min_2, s.usotiempo2),
      (3,           s.hor_3, s.min_3, s.usotiempo3),
      (4,           s.hor_4, s.min_4, s.usotiempo4),
      (5,           s.hor_5, s.min_5, s.usotiempo5),
      (6,           s.hor_6, s.min_6, s.usotiempo6),
      (7,           s.hor_7, s.min_7, s.usotiempo7),
      (8,           s.hor_8, s.min_8, s.usotiempo8)
) AS v(id_actividad, h, m, k)
WHERE NULLIF(TRIM(v.h),'') IS NOT NULL
   OR NULLIF(TRIM(v.m),'') IS NOT NULL
   OR NULLIF(TRIM(v.k),'') IS NOT NULL;

COMMIT;

-- Conteos rápidos.
SELECT 'ds2_vivienda'         AS tabla, COUNT(*) AS filas FROM ds2.ds2_vivienda          UNION ALL
SELECT 'ds2_hogar',                 COUNT(*) FROM ds2.ds2_hogar                            UNION ALL
SELECT 'ds2_persona',               COUNT(*) FROM ds2.ds2_persona                          UNION ALL
SELECT 'ds2_persona_ingreso',       COUNT(*) FROM ds2.ds2_persona_ingreso                  UNION ALL
SELECT 'ds2_hogar_gasto',           COUNT(*) FROM ds2.ds2_hogar_gasto                      UNION ALL
SELECT 'ds2_hogar_consumo_alim',    COUNT(*) FROM ds2.ds2_hogar_consumo_alim               UNION ALL
SELECT 'ds2_hogar_vehiculo',        COUNT(*) FROM ds2.ds2_hogar_vehiculo                   UNION ALL
SELECT 'ds2_hogar_aparato',         COUNT(*) FROM ds2.ds2_hogar_aparato                    UNION ALL
SELECT 'ds2_hogar_acceso_alim',     COUNT(*) FROM ds2.ds2_hogar_acceso_alim                UNION ALL
SELECT 'ds2_hogar_fenomeno',        COUNT(*) FROM ds2.ds2_hogar_fenomeno                   UNION ALL
SELECT 'ds2_hogar_afectacion',      COUNT(*) FROM ds2.ds2_hogar_afectacion                 UNION ALL
SELECT 'ds2_persona_uso_tiempo',    COUNT(*) FROM ds2.ds2_persona_uso_tiempo;
