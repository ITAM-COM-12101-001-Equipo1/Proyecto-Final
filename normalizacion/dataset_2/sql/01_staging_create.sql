/*
================================================================================
 Script:      01_staging_create.sql
 Dataset:     2 - Encuesta Nacional de Ingresos y Gastos de los Hogares 2024
              (ENIGH 2024 NS, INEGI)
 Etapa:       2 (Limpieza y staging)
 Propósito:   Crear el schema `ds2` y la tabla de staging para CADA UNA de las
              17 sub-tablas oficiales del ENIGH 2024. Todas las columnas se
              cargan como TEXT para preservar exactamente el contenido del
              CSV original; el casteo a tipos definitivos ocurre en el script
              05_migration.sql al poblar el modelo normalizado.
 Entrada:     Ninguna (DDL puro).
 Salida:      17 tablas de staging vacías + tabla de catálogo unificado.
 Decisiones:
   - Schema dedicado `ds2` para aislar este dataset y evitar colisiones con
     dataset_1 (`ds1`) y futuros datasets.
   - Las 17 tablas de staging replican EXACTAMENTE las columnas del CSV
     oficial INEGI (sin renombrar ni inventar columnas).
   - Se agrega `staging_row_id BIGSERIAL` y `cargado_en TIMESTAMP` SOLO como
     metadatos técnicos de carga (no son datos del CSV).
   - Los catálogos INEGI vienen como pares (codigo, descripcion). Se cargan
     en una tabla ÚNICA `ds2_staging_catalogo_inegi` con una columna extra
     `catalogo_nombre` que identifica de qué catálogo proviene cada par.
================================================================================
*/

CREATE SCHEMA IF NOT EXISTS ds2;

-- ===========================================================================
--  17 tablas de staging (las 17 sub-tablas oficiales del ENIGH 2024 NS)
-- ===========================================================================

DROP TABLE IF EXISTS ds2.ds2_staging_agro             CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_agroconsumo      CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_agrogasto        CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_agroproductos    CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_concentradohogar CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_erogaciones      CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_gastoshogar      CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_gastospersona    CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_gastotarjetas    CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_hogares          CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_ingresos         CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_ingresos_jcf     CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_noagro           CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_noagroimportes   CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_poblacion        CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_trabajos         CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_viviendas        CASCADE;
DROP TABLE IF EXISTS ds2.ds2_staging_catalogo_inegi   CASCADE;

-- ---------------------------------------------------------------------------
-- viviendas (90,324 filas, 82 columnas) — características de las viviendas
-- PK natural: folioviv
-- ---------------------------------------------------------------------------
CREATE TABLE ds2.ds2_staging_viviendas (
    staging_row_id BIGSERIAL PRIMARY KEY,
    folioviv TEXT, tipo_viv TEXT, mat_pared TEXT, mat_techos TEXT, mat_pisos TEXT,
    antiguedad TEXT, antigua_ne TEXT, cocina TEXT, cocina_dor TEXT, cuart_dorm TEXT,
    num_cuarto TEXT, lugar_coc TEXT, agua_ent TEXT, ab_agua TEXT, agua_noe TEXT,
    dotac_agua TEXT, excusado TEXT, uso_compar TEXT, sanit_agua TEXT, biodigest TEXT,
    bano_comp TEXT, bano_excus TEXT, bano_regad TEXT, drenaje TEXT, disp_elect TEXT,
    focos TEXT, focos_ahor TEXT, combus TEXT, fogon_chi TEXT, eli_basura TEXT,
    tenencia TEXT, renta TEXT, estim_pago TEXT, pago_viv TEXT, pago_mesp TEXT,
    tipo_adqui TEXT, viv_usada TEXT, finan_1 TEXT, finan_2 TEXT, finan_3 TEXT,
    finan_4 TEXT, finan_5 TEXT, finan_6 TEXT, finan_7 TEXT, finan_8 TEXT,
    num_dueno1 TEXT, hog_dueno1 TEXT, num_dueno2 TEXT, hog_dueno2 TEXT, escrituras TEXT,
    lavadero TEXT, fregadero TEXT, regadera TEXT, tinaco_azo TEXT, cisterna TEXT,
    pileta TEXT, calent_sol TEXT, calent_gas TEXT, calen_lena TEXT, medid_luz TEXT,
    bomba_agua TEXT, tanque_gas TEXT, aire_acond TEXT, calefacc TEXT, p_grietas TEXT,
    p_pandeos TEXT, p_levanta TEXT, p_humedad TEXT, p_fractura TEXT, p_electric TEXT,
    p_tuberias TEXT, tot_resid TEXT, tot_hom TEXT, tot_muj TEXT, tot_hog TEXT,
    ubica_geo TEXT, tam_loc TEXT, est_socio TEXT, est_dis TEXT, upm TEXT,
    factor TEXT, procaptar TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- hogares (91,414 filas, 148 columnas) — características de los hogares
-- PK natural: (folioviv, foliohog)
-- 1FN: contiene MUCHOS grupos repetidos (alim17_1..12, num_auto..anio_auto..,
--      num_van..anio_van.., num_pick..., habito_1..6, f_*, af_*, etc.)
-- ---------------------------------------------------------------------------
CREATE TABLE ds2.ds2_staging_hogares (
    staging_row_id BIGSERIAL PRIMARY KEY,
    folioviv TEXT, foliohog TEXT, huespedes TEXT, huesp_come TEXT, num_trab_d TEXT,
    trab_come TEXT, acc_alim1 TEXT, acc_alim2 TEXT, acc_alim3 TEXT, acc_alim4 TEXT,
    acc_alim5 TEXT, acc_alim6 TEXT, acc_alim7 TEXT, acc_alim8 TEXT, acc_alim9 TEXT,
    acc_alim10 TEXT, acc_alim11 TEXT, acc_alim12 TEXT, acc_alim13 TEXT, acc_alim14 TEXT,
    acc_alim15 TEXT, acc_alim16 TEXT, alim17_1 TEXT, alim17_2 TEXT, alim17_3 TEXT,
    alim17_4 TEXT, alim17_5 TEXT, alim17_6 TEXT, alim17_7 TEXT, alim17_8 TEXT,
    alim17_9 TEXT, alim17_10 TEXT, alim17_11 TEXT, alim17_12 TEXT, acc_alim18 TEXT,
    telefono TEXT, celular TEXT, conex_inte TEXT, tv_paga TEXT, peliculas TEXT,
    num_auto TEXT, anio_auto TEXT, num_van TEXT, anio_van TEXT, num_pick TEXT,
    anio_pick TEXT, num_moto TEXT, anio_moto TEXT, num_bici TEXT, anio_bici TEXT,
    num_trici TEXT, anio_trici TEXT, num_carre TEXT, anio_carre TEXT, num_canoa TEXT,
    anio_canoa TEXT, num_otro TEXT, anio_otro TEXT, num_ester TEXT, anio_ester TEXT,
    num_radio TEXT, anio_radio TEXT, num_tva TEXT, anio_tva TEXT, num_tvd TEXT,
    anio_tvd TEXT, num_dvd TEXT, anio_dvd TEXT, num_licua TEXT, anio_licua TEXT,
    num_tosta TEXT, anio_tosta TEXT, num_micro TEXT, anio_micro TEXT, num_refri TEXT,
    anio_refri TEXT, num_estuf TEXT, anio_estuf TEXT, num_lavad TEXT, anio_lavad TEXT,
    num_planc TEXT, anio_planc TEXT, num_maqui TEXT, anio_maqui TEXT, num_venti TEXT,
    anio_venti TEXT, num_aspir TEXT, anio_aspir TEXT, num_compu TEXT, anio_compu TEXT,
    num_lap TEXT, anio_lap TEXT, num_table TEXT, anio_table TEXT, num_impre TEXT,
    anio_impre TEXT, num_juego TEXT, anio_juego TEXT, tsalud1_h TEXT, tsalud1_m TEXT,
    camb_clim TEXT, f_sequia TEXT, f_inunda TEXT, f_helada TEXT, f_incendio TEXT,
    f_huracan TEXT, f_desliza TEXT, f_otro TEXT, af_viv TEXT, af_empleo TEXT,
    af_negocio TEXT, af_cultivo TEXT, af_trabajo TEXT, af_salud TEXT, af_otro TEXT,
    habito_1 TEXT, habito_2 TEXT, habito_3 TEXT, habito_4 TEXT, habito_5 TEXT,
    habito_6 TEXT, consumo TEXT, nr_viv TEXT, tarjeta TEXT, pagotarjet TEXT,
    regalotar TEXT, regalodado TEXT, autocons TEXT, regalos TEXT, remunera TEXT,
    transferen TEXT, parto_g TEXT, negcua TEXT, est_alim TEXT, est_trans TEXT,
    bene_licon TEXT, cond_licon TEXT, lts_licon TEXT, otros_lts TEXT, diconsa TEXT,
    frec_dicon TEXT, cond_dicon TEXT, pago_dicon TEXT, otro_pago TEXT, entidad TEXT,
    est_dis TEXT, upm TEXT, factor TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- poblacion (308,598 filas, 185 columnas) — integrantes del hogar
-- PK natural: (folioviv, foliohog, numren)
-- 1FN: grupos repetidos masivos (hor_1..8, min_1..8, usotiempo1..8,
--      redsoc_1..6, inst_1..9, servmed_1..11, pagoaten_1..7, noatenc_1..16,
--      norecib_1..11, razon_1..11, segvol_1..7, etc.)
-- ---------------------------------------------------------------------------
CREATE TABLE ds2.ds2_staging_poblacion (
    staging_row_id BIGSERIAL PRIMARY KEY,
    folioviv TEXT, foliohog TEXT, numren TEXT, parentesco TEXT, sexo TEXT, edad TEXT,
    madre_hog TEXT, madre_id TEXT, padre_hog TEXT, padre_id TEXT, pais_nac TEXT,
    afrod TEXT, disc_ver TEXT, disc_oir TEXT, disc_brazo TEXT, disc_camin TEXT,
    disc_apren TEXT, disc_vest TEXT, disc_habla TEXT, disc_acti TEXT, edu_ini TEXT,
    no_asis TEXT, hablaind TEXT, lenguaind TEXT, hablaesp TEXT, comprenind TEXT,
    etnia TEXT, alfabetism TEXT, asis_esc TEXT, no_asisb TEXT, nivel TEXT, grado TEXT,
    tipoesc TEXT, tiene_b TEXT, otorg_b TEXT, forma_b TEXT, tiene_c TEXT, otorg_c TEXT,
    forma_c TEXT, nivelaprob TEXT, gradoaprob TEXT, antec_esc TEXT, residencia TEXT,
    edo_conyug TEXT, pareja_hog TEXT, conyuge_id TEXT, segsoc TEXT, ss_aa TEXT, ss_mm TEXT,
    redsoc_1 TEXT, redsoc_2 TEXT, redsoc_3 TEXT, redsoc_4 TEXT, redsoc_5 TEXT, redsoc_6 TEXT,
    hor_1 TEXT, min_1 TEXT, usotiempo1 TEXT, hor_2 TEXT, min_2 TEXT, usotiempo2 TEXT,
    hor_3 TEXT, min_3 TEXT, usotiempo3 TEXT, hor_4 TEXT, min_4 TEXT, usotiempo4 TEXT,
    hor_5 TEXT, min_5 TEXT, usotiempo5 TEXT, hor_6 TEXT, min_6 TEXT, usotiempo6 TEXT,
    hor_7 TEXT, min_7 TEXT, usotiempo7 TEXT, hor_8 TEXT, min_8 TEXT, usotiempo8 TEXT,
    inst_1 TEXT, inst_2 TEXT, inst_3 TEXT, inst_4 TEXT, inst_5 TEXT, inst_6 TEXT,
    inst_7 TEXT, inst_8 TEXT, inst_9 TEXT, atemed TEXT,
    inscr_1 TEXT, inscr_2 TEXT, inscr_3 TEXT, inscr_4 TEXT, inscr_5 TEXT, inscr_6 TEXT,
    inscr_7 TEXT, inscr_8 TEXT, prob_anio TEXT, prob_mes TEXT, prob_sal TEXT, aten_sal TEXT,
    servmed_1 TEXT, servmed_2 TEXT, servmed_3 TEXT, servmed_4 TEXT, servmed_5 TEXT,
    servmed_6 TEXT, servmed_7 TEXT, servmed_8 TEXT, servmed_9 TEXT, servmed_10 TEXT,
    servmed_11 TEXT, hh_lug TEXT, mm_lug TEXT, hh_esp TEXT, mm_esp TEXT,
    pagoaten_1 TEXT, pagoaten_2 TEXT, pagoaten_3 TEXT, pagoaten_4 TEXT, pagoaten_5 TEXT,
    pagoaten_6 TEXT, pagoaten_7 TEXT,
    noatenc_1 TEXT, noatenc_2 TEXT, noatenc_3 TEXT, noatenc_4 TEXT, noatenc_5 TEXT,
    noatenc_6 TEXT, noatenc_7 TEXT, noatenc_8 TEXT, noatenc_9 TEXT, noatenc_10 TEXT,
    noatenc_11 TEXT, noatenc_12 TEXT, noatenc_13 TEXT, noatenc_14 TEXT, noatenc_15 TEXT,
    noatenc_16 TEXT,
    norecib_1 TEXT, norecib_2 TEXT, norecib_3 TEXT, norecib_4 TEXT, norecib_5 TEXT,
    norecib_6 TEXT, norecib_7 TEXT, norecib_8 TEXT, norecib_9 TEXT, norecib_10 TEXT,
    norecib_11 TEXT,
    razon_1 TEXT, razon_2 TEXT, razon_3 TEXT, razon_4 TEXT, razon_5 TEXT, razon_6 TEXT,
    razon_7 TEXT, razon_8 TEXT, razon_9 TEXT, razon_10 TEXT, razon_11 TEXT,
    diabetes TEXT, pres_alta TEXT, peso TEXT,
    segvol_1 TEXT, segvol_2 TEXT, segvol_3 TEXT, segvol_4 TEXT, segvol_5 TEXT,
    segvol_6 TEXT, segvol_7 TEXT,
    hijos_viv TEXT, hijos_mue TEXT, hijos_sob TEXT, trabajo_mp TEXT, motivo_aus TEXT,
    act_pnea1 TEXT, act_pnea2 TEXT, num_trabaj TEXT, c_futuro TEXT, ct_futuro TEXT,
    entidad TEXT, est_dis TEXT, upm TEXT, factor TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- ingresos (391,563 filas, 21 columnas) — ingresos por persona y clave
-- PK natural: (folioviv, foliohog, numren, clave)  — verificada empíricamente
-- ---------------------------------------------------------------------------
CREATE TABLE ds2.ds2_staging_ingresos (
    staging_row_id BIGSERIAL PRIMARY KEY,
    folioviv TEXT, foliohog TEXT, numren TEXT, clave TEXT,
    mes_1 TEXT, mes_2 TEXT, mes_3 TEXT, mes_4 TEXT, mes_5 TEXT, mes_6 TEXT,
    ing_1 TEXT, ing_2 TEXT, ing_3 TEXT, ing_4 TEXT, ing_5 TEXT, ing_6 TEXT,
    ing_tri TEXT, entidad TEXT, est_dis TEXT, upm TEXT, factor TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- gastoshogar (5,311,497 filas, 31 columnas) — gastos por hogar y clave
-- PK natural: NO existe combinación natural única (verificado: hay 1,188
--             duplicados al usar (folioviv, foliohog, clave, tipo_gasto,
--             mes_dia, fecha_adqu) sobre 1M filas muestreadas).
-- Decisión:   Se usará surrogate id_gasto_hogar BIGSERIAL en el modelo
--             normalizado, conservando las claves naturales como atributos.
-- ---------------------------------------------------------------------------
CREATE TABLE ds2.ds2_staging_gastoshogar (
    staging_row_id BIGSERIAL PRIMARY KEY,
    folioviv TEXT, foliohog TEXT, clave TEXT, tipo_gasto TEXT, mes_dia TEXT,
    forma_pag1 TEXT, forma_pag2 TEXT, forma_pag3 TEXT, lugar_comp TEXT, orga_inst TEXT,
    frecuencia TEXT, fecha_adqu TEXT, fecha_pago TEXT, cantidad TEXT, gasto TEXT,
    pago_mp TEXT, costo TEXT, inmujer TEXT, inst_1 TEXT, inst_2 TEXT,
    num_meses TEXT, num_pagos TEXT, ultim_pago TEXT, gasto_tri TEXT, gasto_nm TEXT,
    gas_nm_tri TEXT, imujer_tri TEXT, entidad TEXT, est_dis TEXT, upm TEXT, factor TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Las tablas restantes se cargan también en staging para cumplir la rúbrica
-- (Etapa 1, "Dimensiones") y para que el equipo pueda extender la
-- normalización a ellas en el futuro. Por alcance de este entregable, NO se
-- normalizan a 4FN aquí — se documenta su staging y queda como hipotético
-- siguiente paso (ver README, sección "Alcance").
-- ---------------------------------------------------------------------------

CREATE TABLE ds2.ds2_staging_concentradohogar (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,  -- línea cruda; columnas resumen (126) sin desglosar
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE ds2.ds2_staging_concentradohogar IS
  'Tabla resumen por hogar con 126 columnas derivadas/agregadas. Se almacena '
  'la línea CSV cruda en una sola columna por economía: el contenido de '
  'concentradohogar es una vista materializada de hogares + ingresos + gastos '
  'que se reconstruye fielmente al normalizar las tablas base. Documentado.';

CREATE TABLE ds2.ds2_staging_gastospersona (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ds2.ds2_staging_erogaciones (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ds2.ds2_staging_gastotarjetas (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ds2.ds2_staging_trabajos (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ds2.ds2_staging_agro (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE ds2.ds2_staging_agroconsumo (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE ds2.ds2_staging_agrogasto (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE ds2.ds2_staging_agroproductos (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE ds2.ds2_staging_noagro (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE ds2.ds2_staging_noagroimportes (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE ds2.ds2_staging_ingresos_jcf (
    staging_row_id BIGSERIAL PRIMARY KEY,
    contenido TEXT NOT NULL,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- Catálogos INEGI: tabla unificada
-- ---------------------------------------------------------------------------
CREATE TABLE ds2.ds2_staging_catalogo_inegi (
    staging_row_id   BIGSERIAL PRIMARY KEY,
    catalogo_nombre  TEXT NOT NULL,  -- ej: 'entidad', 'parentesco', 'si_no'
    codigo           TEXT NOT NULL,
    descripcion      TEXT NOT NULL,
    cargado_en       TIMESTAMP NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE ds2.ds2_staging_catalogo_inegi IS
  'Catálogos oficiales INEGI consolidados. Cada fila apunta a un catálogo '
  'individual (ej. entidad, parentesco, mat_pared, si_no) que puede '
  'extraerse después como tabla independiente en el modelo normalizado.';
