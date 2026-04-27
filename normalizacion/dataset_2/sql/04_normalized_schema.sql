/*
================================================================================
 Script:      04_normalized_schema.sql
 Dataset:     2 - ENIGH 2024 NS (INEGI)
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   DDL del modelo normalizado en 4FN para las 5 tablas core
              (viviendas, hogares, poblacion, ingresos, gastoshogar) +
              catálogos INEGI + tablas puente para los grupos repetidos
              (eliminación de violaciones 1FN).
 Entrada:     Ninguna.
 Salida:      Tablas vacías en schema `ds2`, con PKs, FKs, CHECKs e índices.
 Decisiones (resumidas — la justificación completa vive en docs/):
   - 5 entidades core con sus PKs naturales:
       vivienda(folioviv) / hogar(folioviv,foliohog) / persona(folioviv,
       foliohog,numren) / persona_ingreso(folioviv,foliohog,numren,clave) /
       hogar_gasto(id_hogar_gasto SERIAL, surrogate por la no-unicidad
       observada en gastoshogar).
   - Catálogos INEGI nominales: entidad, tipo_vivienda, tenencia,
     parentesco, sexo, mat_pared, mat_techos, mat_pisos, agua_ent,
     ab_agua, drenaje, combus, eli_basura, si_no, etc. Se cargan desde
     la tabla unificada `ds2_staging_catalogo_inegi`.
   - Tablas puente (1FN) para los repeating groups MÁS significativos
     (resto pendiente como follow-up):
       hogar_consumo_alimento (alim17_1..12)
       hogar_vehiculo (num_/anio_ × {auto, van, pick, moto, bici, trici,
                                     carre, canoa, otro})
       hogar_aparato (num_/anio_ × {ester, radio, tva, tvd, dvd, licua,
                                    tosta, micro, refri, estuf, lavad, planc,
                                    maqui, venti, aspir, compu, lap, table,
                                    impre, juego})
       hogar_acceso_alimentario (acc_alim1..16, acc_alim18)
       hogar_fenomeno (f_sequia .. f_otro)
       hogar_afectacion (af_viv .. af_otro)
       persona_uso_tiempo (8 actividades × hor/min/usotiempo) — ejemplo MVD
   - Las DFs (entidad,est_dis,upm) repetidas en ingresos/gastoshogar/poblacion
     se EXTRAEN a vivienda (DF: folioviv → entidad,est_dis,upm) y se eliminan
     de las tablas hijas.
   - sueldo_tabular_bruto/neto NO existen en ENIGH; el equivalente es
     ing_tri (trimestre) en ingresos. Se conserva como atributo de
     persona_ingreso con NUMERIC(14,2).
================================================================================
*/

-- Limpieza idempotente. Orden: hijas → padres → catálogos.
DROP TABLE IF EXISTS ds2.ds2_persona_uso_tiempo       CASCADE;
DROP TABLE IF EXISTS ds2.ds2_hogar_afectacion         CASCADE;
DROP TABLE IF EXISTS ds2.ds2_hogar_fenomeno           CASCADE;
DROP TABLE IF EXISTS ds2.ds2_hogar_acceso_alim        CASCADE;
DROP TABLE IF EXISTS ds2.ds2_hogar_aparato            CASCADE;
DROP TABLE IF EXISTS ds2.ds2_hogar_vehiculo           CASCADE;
DROP TABLE IF EXISTS ds2.ds2_hogar_consumo_alim       CASCADE;
DROP TABLE IF EXISTS ds2.ds2_hogar_gasto              CASCADE;
DROP TABLE IF EXISTS ds2.ds2_persona_ingreso          CASCADE;
DROP TABLE IF EXISTS ds2.ds2_persona                  CASCADE;
DROP TABLE IF EXISTS ds2.ds2_hogar                    CASCADE;
DROP TABLE IF EXISTS ds2.ds2_vivienda                 CASCADE;

DROP TABLE IF EXISTS ds2.ds2_cat_actividad_uso_tiempo CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_afectacion           CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_fenomeno_climatico   CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_pregunta_acc_alim    CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_aparato              CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_vehiculo             CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_alimento             CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_clave_gasto          CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_clave_ingreso        CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_si_no                CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_combus               CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_drenaje              CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_ab_agua              CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_agua_ent             CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_mat_pisos            CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_mat_techos           CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_mat_pared            CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_tenencia             CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_tipo_vivienda        CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_sexo                 CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_parentesco           CASCADE;
DROP TABLE IF EXISTS ds2.ds2_cat_entidad              CASCADE;

-- ===========================================================================
-- Catálogos INEGI (todos con la forma oficial: codigo + descripcion)
-- ===========================================================================
CREATE TABLE ds2.ds2_cat_entidad (
    codigo VARCHAR(2) PRIMARY KEY,
    descripcion VARCHAR(60) NOT NULL UNIQUE
);
CREATE TABLE ds2.ds2_cat_parentesco (
    codigo VARCHAR(4) PRIMARY KEY,
    descripcion VARCHAR(200) NOT NULL UNIQUE
);
CREATE TABLE ds2.ds2_cat_sexo (
    codigo VARCHAR(2) PRIMARY KEY,
    descripcion VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE ds2.ds2_cat_tipo_vivienda (
    codigo VARCHAR(2) PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL UNIQUE
);
CREATE TABLE ds2.ds2_cat_tenencia (
    codigo VARCHAR(2) PRIMARY KEY,
    descripcion VARCHAR(150) NOT NULL UNIQUE
);
CREATE TABLE ds2.ds2_cat_mat_pared  (codigo VARCHAR(2) PRIMARY KEY, descripcion VARCHAR(100) NOT NULL UNIQUE);
CREATE TABLE ds2.ds2_cat_mat_techos (codigo VARCHAR(2) PRIMARY KEY, descripcion VARCHAR(100) NOT NULL UNIQUE);
CREATE TABLE ds2.ds2_cat_mat_pisos  (codigo VARCHAR(2) PRIMARY KEY, descripcion VARCHAR(100) NOT NULL UNIQUE);
CREATE TABLE ds2.ds2_cat_agua_ent   (codigo VARCHAR(2) PRIMARY KEY, descripcion VARCHAR(150) NOT NULL UNIQUE);
CREATE TABLE ds2.ds2_cat_ab_agua    (codigo VARCHAR(2) PRIMARY KEY, descripcion VARCHAR(150) NOT NULL UNIQUE);
CREATE TABLE ds2.ds2_cat_drenaje    (codigo VARCHAR(2) PRIMARY KEY, descripcion VARCHAR(150) NOT NULL UNIQUE);
CREATE TABLE ds2.ds2_cat_combus     (codigo VARCHAR(2) PRIMARY KEY, descripcion VARCHAR(100) NOT NULL UNIQUE);
CREATE TABLE ds2.ds2_cat_si_no      (codigo VARCHAR(2) PRIMARY KEY, descripcion VARCHAR(20)  NOT NULL UNIQUE);

-- Catálogos derivados (no vienen como CSV en INEGI; los construimos nosotros
-- a partir de los grupos repetidos del esquema flat).

CREATE TABLE ds2.ds2_cat_clave_ingreso (
    clave VARCHAR(6) PRIMARY KEY,
    descripcion VARCHAR(255)
);
COMMENT ON TABLE ds2.ds2_cat_clave_ingreso IS
  'Catálogo de claves de fuentes de ingreso. La descripción se importa del '
  'diccionario oficial INEGI; aquí solo se almacena el código.';

CREATE TABLE ds2.ds2_cat_clave_gasto (
    clave VARCHAR(6) PRIMARY KEY,
    descripcion VARCHAR(255)
);

CREATE TABLE ds2.ds2_cat_alimento (
    id_alimento  SMALLSERIAL PRIMARY KEY,
    sufijo_csv   VARCHAR(10) NOT NULL UNIQUE,  -- 'alim17_1' .. 'alim17_12'
    descripcion  VARCHAR(60) NOT NULL UNIQUE   -- 'Cereales', 'Tubérculos', etc.
);

CREATE TABLE ds2.ds2_cat_vehiculo (
    id_vehiculo  SMALLSERIAL PRIMARY KEY,
    sufijo_csv   VARCHAR(10) NOT NULL UNIQUE,  -- 'auto', 'van', ...
    descripcion  VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE ds2.ds2_cat_aparato (
    id_aparato   SMALLSERIAL PRIMARY KEY,
    sufijo_csv   VARCHAR(10) NOT NULL UNIQUE,  -- 'radio', 'micro', ...
    descripcion  VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE ds2.ds2_cat_pregunta_acc_alim (
    id_pregunta  SMALLSERIAL PRIMARY KEY,
    sufijo_csv   VARCHAR(12) NOT NULL UNIQUE,  -- 'acc_alim1' .. 'acc_alim16', 'acc_alim18'
    descripcion  VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE ds2.ds2_cat_fenomeno_climatico (
    id_fenomeno  SMALLSERIAL PRIMARY KEY,
    sufijo_csv   VARCHAR(12) NOT NULL UNIQUE,
    descripcion  VARCHAR(60)  NOT NULL UNIQUE
);

CREATE TABLE ds2.ds2_cat_afectacion (
    id_afectacion SMALLSERIAL PRIMARY KEY,
    sufijo_csv    VARCHAR(12) NOT NULL UNIQUE,
    descripcion   VARCHAR(60)  NOT NULL UNIQUE
);

CREATE TABLE ds2.ds2_cat_actividad_uso_tiempo (
    id_actividad  SMALLINT PRIMARY KEY,    -- 1..8 corresponde a usotiempo1..8
    descripcion   VARCHAR(80) NOT NULL UNIQUE
);

-- ===========================================================================
-- Entidad raíz: VIVIENDA
-- PK: folioviv (10 caracteres, identificador INEGI estable)
-- DF: folioviv → todos los demás atributos de la vivienda
--                + entidad, est_dis, upm, ubica_geo, tam_loc, est_socio,
--                  factor (atributos del marco muestral)
-- ===========================================================================
CREATE TABLE ds2.ds2_vivienda (
    folioviv          VARCHAR(10) PRIMARY KEY,
    cod_entidad       VARCHAR(2)  NOT NULL,
    cod_tipo_vivienda VARCHAR(2),
    cod_mat_pared     VARCHAR(2),
    cod_mat_techos    VARCHAR(2),
    cod_mat_pisos     VARCHAR(2),
    cod_agua_ent      VARCHAR(2),
    cod_ab_agua       VARCHAR(2),
    cod_drenaje       VARCHAR(2),
    cod_combus        VARCHAR(2),
    cod_tenencia      VARCHAR(2),
    antiguedad        SMALLINT,
    cuart_dorm        SMALLINT,
    num_cuarto        SMALLINT,
    tot_resid         SMALLINT,
    tot_hom           SMALLINT,
    tot_muj           SMALLINT,
    tot_hog           SMALLINT,
    ubica_geo         VARCHAR(10),
    tam_loc           VARCHAR(2),
    est_socio         VARCHAR(2),
    est_dis           VARCHAR(4),
    upm               VARCHAR(8),
    factor            INTEGER,
    CONSTRAINT fk_viv_entidad       FOREIGN KEY (cod_entidad)        REFERENCES ds2.ds2_cat_entidad(codigo),
    CONSTRAINT fk_viv_tipo_viv      FOREIGN KEY (cod_tipo_vivienda)  REFERENCES ds2.ds2_cat_tipo_vivienda(codigo),
    CONSTRAINT fk_viv_mat_pared     FOREIGN KEY (cod_mat_pared)      REFERENCES ds2.ds2_cat_mat_pared(codigo),
    CONSTRAINT fk_viv_mat_techos    FOREIGN KEY (cod_mat_techos)     REFERENCES ds2.ds2_cat_mat_techos(codigo),
    CONSTRAINT fk_viv_mat_pisos     FOREIGN KEY (cod_mat_pisos)      REFERENCES ds2.ds2_cat_mat_pisos(codigo),
    CONSTRAINT fk_viv_agua_ent      FOREIGN KEY (cod_agua_ent)       REFERENCES ds2.ds2_cat_agua_ent(codigo),
    CONSTRAINT fk_viv_ab_agua       FOREIGN KEY (cod_ab_agua)        REFERENCES ds2.ds2_cat_ab_agua(codigo),
    CONSTRAINT fk_viv_drenaje       FOREIGN KEY (cod_drenaje)        REFERENCES ds2.ds2_cat_drenaje(codigo),
    CONSTRAINT fk_viv_combus        FOREIGN KEY (cod_combus)         REFERENCES ds2.ds2_cat_combus(codigo),
    CONSTRAINT fk_viv_tenencia      FOREIGN KEY (cod_tenencia)       REFERENCES ds2.ds2_cat_tenencia(codigo),
    CONSTRAINT chk_viv_resid_consist
        CHECK (tot_resid IS NULL OR (tot_hom + tot_muj) = tot_resid)
);
COMMENT ON TABLE ds2.ds2_vivienda IS
  'Entidad raíz del modelo. PK natural folioviv (10 caracteres, identificador '
  'INEGI). entidad/est_dis/upm viven aquí porque son funcionalmente '
  'determinados por folioviv (verificado: 0 violaciones).';

-- ===========================================================================
-- HOGAR (un hogar habita una vivienda; varios hogares pueden compartir
-- vivienda — verificado: 91,414 hogares en 90,324 viviendas).
-- PK: (folioviv, foliohog)
-- ===========================================================================
CREATE TABLE ds2.ds2_hogar (
    folioviv     VARCHAR(10) NOT NULL,
    foliohog     VARCHAR(2)  NOT NULL,
    huespedes    SMALLINT,
    huesp_come   SMALLINT,
    num_trab_d   SMALLINT,
    trab_come    SMALLINT,
    -- atributos individuales del hogar (no repeating groups)
    telefono     VARCHAR(2),
    celular      VARCHAR(2),
    conex_inte   VARCHAR(2),
    tv_paga      VARCHAR(2),
    peliculas    VARCHAR(2),
    camb_clim    VARCHAR(2),
    consumo      VARCHAR(2),
    autocons     VARCHAR(2),
    regalos      VARCHAR(2),
    remunera     VARCHAR(2),
    transferen   VARCHAR(2),
    PRIMARY KEY (folioviv, foliohog),
    CONSTRAINT fk_hog_vivienda FOREIGN KEY (folioviv)
      REFERENCES ds2.ds2_vivienda(folioviv) ON DELETE CASCADE
);
COMMENT ON TABLE ds2.ds2_hogar IS
  'Hogar (unidad de gasto). Su PK es compuesta (folioviv, foliohog). Los '
  'atributos que eran "repeating groups" en el CSV (alim17_*, num_*, anio_*, '
  'habito_*, f_*, af_*, acc_alim*) se extrajeron a tablas puente para '
  'satisfacer 1FN.';

-- ===========================================================================
-- PERSONA (integrante del hogar)
-- PK: (folioviv, foliohog, numren)
-- ===========================================================================
CREATE TABLE ds2.ds2_persona (
    folioviv      VARCHAR(10) NOT NULL,
    foliohog      VARCHAR(2)  NOT NULL,
    numren        VARCHAR(2)  NOT NULL,
    cod_parentesco VARCHAR(4),
    cod_sexo       VARCHAR(2) NOT NULL,
    edad          SMALLINT,
    pais_nac      VARCHAR(3),
    hablaind      VARCHAR(2),
    hablaesp      VARCHAR(2),
    alfabetism    VARCHAR(2),
    asis_esc      VARCHAR(2),
    nivelaprob    VARCHAR(2),
    edo_conyug    VARCHAR(2),
    diabetes      VARCHAR(2),
    pres_alta     VARCHAR(2),
    PRIMARY KEY (folioviv, foliohog, numren),
    CONSTRAINT fk_persona_hogar
      FOREIGN KEY (folioviv, foliohog)
      REFERENCES ds2.ds2_hogar(folioviv, foliohog) ON DELETE CASCADE,
    CONSTRAINT fk_persona_parentesco
      FOREIGN KEY (cod_parentesco) REFERENCES ds2.ds2_cat_parentesco(codigo),
    CONSTRAINT fk_persona_sexo
      FOREIGN KEY (cod_sexo) REFERENCES ds2.ds2_cat_sexo(codigo),
    CONSTRAINT chk_persona_edad CHECK (edad IS NULL OR edad BETWEEN 0 AND 120)
);

-- ===========================================================================
-- INGRESO (por persona × clave de fuente de ingreso)
-- PK: (folioviv, foliohog, numren, clave) — verificada empíricamente.
-- ===========================================================================
CREATE TABLE ds2.ds2_persona_ingreso (
    folioviv     VARCHAR(10) NOT NULL,
    foliohog     VARCHAR(2)  NOT NULL,
    numren       VARCHAR(2)  NOT NULL,
    clave        VARCHAR(6)  NOT NULL,
    mes_1        VARCHAR(2),  mes_2 VARCHAR(2), mes_3 VARCHAR(2),
    mes_4        VARCHAR(2),  mes_5 VARCHAR(2), mes_6 VARCHAR(2),
    ing_1        NUMERIC(14,2), ing_2 NUMERIC(14,2), ing_3 NUMERIC(14,2),
    ing_4        NUMERIC(14,2), ing_5 NUMERIC(14,2), ing_6 NUMERIC(14,2),
    ing_tri      NUMERIC(14,2),
    PRIMARY KEY (folioviv, foliohog, numren, clave),
    CONSTRAINT fk_ingreso_persona
      FOREIGN KEY (folioviv, foliohog, numren)
      REFERENCES ds2.ds2_persona(folioviv, foliohog, numren) ON DELETE CASCADE,
    CONSTRAINT fk_ingreso_clave
      FOREIGN KEY (clave) REFERENCES ds2.ds2_cat_clave_ingreso(clave),
    CONSTRAINT chk_ingreso_no_negativo
      CHECK (ing_tri IS NULL OR ing_tri >= 0)
);

-- ===========================================================================
-- GASTO DEL HOGAR (por hogar × clave × tipo_gasto, sin PK natural única)
-- PK: surrogate id_hogar_gasto BIGSERIAL (verificado: 1,188 duplicados en 1M
--     filas usando todas las columnas naturales).
-- ===========================================================================
CREATE TABLE ds2.ds2_hogar_gasto (
    id_hogar_gasto BIGSERIAL PRIMARY KEY,
    folioviv     VARCHAR(10) NOT NULL,
    foliohog     VARCHAR(2)  NOT NULL,
    clave        VARCHAR(6)  NOT NULL,
    tipo_gasto   VARCHAR(2),
    mes_dia      VARCHAR(8),
    forma_pag1   VARCHAR(2), forma_pag2 VARCHAR(2), forma_pag3 VARCHAR(2),
    lugar_comp   VARCHAR(2),
    orga_inst    VARCHAR(2),
    frecuencia   VARCHAR(2),
    fecha_adqu   VARCHAR(8),
    fecha_pago   VARCHAR(8),
    cantidad     NUMERIC(14,4),
    gasto        NUMERIC(14,2),
    pago_mp      NUMERIC(14,2),
    costo        NUMERIC(14,2),
    inmujer      NUMERIC(14,2),
    num_meses    SMALLINT,
    num_pagos    SMALLINT,
    ultim_pago   VARCHAR(8),
    gasto_tri    NUMERIC(14,2),
    gasto_nm     NUMERIC(14,2),
    gas_nm_tri   NUMERIC(14,2),
    imujer_tri   NUMERIC(14,2),
    CONSTRAINT fk_gasto_hogar
      FOREIGN KEY (folioviv, foliohog)
      REFERENCES ds2.ds2_hogar(folioviv, foliohog) ON DELETE CASCADE,
    CONSTRAINT fk_gasto_clave
      FOREIGN KEY (clave) REFERENCES ds2.ds2_cat_clave_gasto(clave),
    CONSTRAINT chk_gasto_no_negativo
      CHECK (gasto IS NULL OR gasto >= 0)
);

-- ===========================================================================
-- PUENTES 1FN — extracción de los repeating groups del CSV original
-- ===========================================================================

-- Hogar × alimento × días que se consumió (alim17_1..12)
CREATE TABLE ds2.ds2_hogar_consumo_alim (
    folioviv      VARCHAR(10) NOT NULL,
    foliohog      VARCHAR(2)  NOT NULL,
    id_alimento   SMALLINT    NOT NULL,
    dias_consumo  SMALLINT    NOT NULL,
    PRIMARY KEY (folioviv, foliohog, id_alimento),
    CONSTRAINT fk_hca_hogar    FOREIGN KEY (folioviv, foliohog) REFERENCES ds2.ds2_hogar(folioviv, foliohog) ON DELETE CASCADE,
    CONSTRAINT fk_hca_alimento FOREIGN KEY (id_alimento)        REFERENCES ds2.ds2_cat_alimento(id_alimento),
    CONSTRAINT chk_hca_dias    CHECK (dias_consumo BETWEEN 0 AND 9)
);
COMMENT ON TABLE ds2.ds2_hogar_consumo_alim IS
  '1FN: extracción de las 12 columnas alim17_1..12 del CSV. Cada par '
  '(hogar, alimento) tiene un único valor de días de consumo.';

-- Hogar × tipo de vehículo × cantidad y año del último adquirido
CREATE TABLE ds2.ds2_hogar_vehiculo (
    folioviv      VARCHAR(10) NOT NULL,
    foliohog      VARCHAR(2)  NOT NULL,
    id_vehiculo   SMALLINT    NOT NULL,
    cantidad      SMALLINT    NOT NULL,
    anio_ultimo   VARCHAR(4),
    PRIMARY KEY (folioviv, foliohog, id_vehiculo),
    CONSTRAINT fk_hv_hogar    FOREIGN KEY (folioviv, foliohog) REFERENCES ds2.ds2_hogar(folioviv, foliohog) ON DELETE CASCADE,
    CONSTRAINT fk_hv_vehiculo FOREIGN KEY (id_vehiculo)        REFERENCES ds2.ds2_cat_vehiculo(id_vehiculo),
    CONSTRAINT chk_hv_cantidad CHECK (cantidad >= 0)
);

-- Hogar × aparato (electrodoméstico/electrónico) × cantidad y año
CREATE TABLE ds2.ds2_hogar_aparato (
    folioviv     VARCHAR(10) NOT NULL,
    foliohog     VARCHAR(2)  NOT NULL,
    id_aparato   SMALLINT    NOT NULL,
    cantidad     SMALLINT    NOT NULL,
    anio_ultimo  VARCHAR(4),
    PRIMARY KEY (folioviv, foliohog, id_aparato),
    CONSTRAINT fk_ha_hogar   FOREIGN KEY (folioviv, foliohog) REFERENCES ds2.ds2_hogar(folioviv, foliohog) ON DELETE CASCADE,
    CONSTRAINT fk_ha_aparato FOREIGN KEY (id_aparato)         REFERENCES ds2.ds2_cat_aparato(id_aparato),
    CONSTRAINT chk_ha_cantidad CHECK (cantidad >= 0)
);

-- Hogar × pregunta acceso alimentario (acc_alim1..16, 18) × respuesta
CREATE TABLE ds2.ds2_hogar_acceso_alim (
    folioviv      VARCHAR(10) NOT NULL,
    foliohog      VARCHAR(2)  NOT NULL,
    id_pregunta   SMALLINT    NOT NULL,
    respuesta     VARCHAR(2)  NOT NULL,
    PRIMARY KEY (folioviv, foliohog, id_pregunta),
    CONSTRAINT fk_haa_hogar    FOREIGN KEY (folioviv, foliohog) REFERENCES ds2.ds2_hogar(folioviv, foliohog) ON DELETE CASCADE,
    CONSTRAINT fk_haa_pregunta FOREIGN KEY (id_pregunta)        REFERENCES ds2.ds2_cat_pregunta_acc_alim(id_pregunta)
);

-- Hogar × fenómeno climático presenciado
CREATE TABLE ds2.ds2_hogar_fenomeno (
    folioviv     VARCHAR(10) NOT NULL,
    foliohog     VARCHAR(2)  NOT NULL,
    id_fenomeno  SMALLINT    NOT NULL,
    presencio    VARCHAR(2)  NOT NULL,
    PRIMARY KEY (folioviv, foliohog, id_fenomeno),
    CONSTRAINT fk_hf_hogar    FOREIGN KEY (folioviv, foliohog) REFERENCES ds2.ds2_hogar(folioviv, foliohog) ON DELETE CASCADE,
    CONSTRAINT fk_hf_fenomeno FOREIGN KEY (id_fenomeno)        REFERENCES ds2.ds2_cat_fenomeno_climatico(id_fenomeno)
);

-- Hogar × tipo de afectación
CREATE TABLE ds2.ds2_hogar_afectacion (
    folioviv      VARCHAR(10) NOT NULL,
    foliohog      VARCHAR(2)  NOT NULL,
    id_afectacion SMALLINT    NOT NULL,
    afecto        VARCHAR(2)  NOT NULL,
    PRIMARY KEY (folioviv, foliohog, id_afectacion),
    CONSTRAINT fk_haf_hogar      FOREIGN KEY (folioviv, foliohog) REFERENCES ds2.ds2_hogar(folioviv, foliohog) ON DELETE CASCADE,
    CONSTRAINT fk_haf_afectacion FOREIGN KEY (id_afectacion)      REFERENCES ds2.ds2_cat_afectacion(id_afectacion)
);

-- Persona × actividad de uso del tiempo (8 actividades, hor + min + clave)
CREATE TABLE ds2.ds2_persona_uso_tiempo (
    folioviv      VARCHAR(10) NOT NULL,
    foliohog      VARCHAR(2)  NOT NULL,
    numren        VARCHAR(2)  NOT NULL,
    id_actividad  SMALLINT    NOT NULL,
    horas         SMALLINT,
    minutos       SMALLINT,
    clave_uso     VARCHAR(2),
    PRIMARY KEY (folioviv, foliohog, numren, id_actividad),
    CONSTRAINT fk_put_persona   FOREIGN KEY (folioviv, foliohog, numren) REFERENCES ds2.ds2_persona(folioviv, foliohog, numren) ON DELETE CASCADE,
    CONSTRAINT fk_put_actividad FOREIGN KEY (id_actividad)               REFERENCES ds2.ds2_cat_actividad_uso_tiempo(id_actividad),
    CONSTRAINT chk_put_horas   CHECK (horas   IS NULL OR horas   BETWEEN 0 AND 24),
    CONSTRAINT chk_put_minutos CHECK (minutos IS NULL OR minutos BETWEEN 0 AND 59)
);
COMMENT ON TABLE ds2.ds2_persona_uso_tiempo IS
  'Ejemplo crítico de descomposición 4FN: en el CSV plano, una persona '
  'tiene 8 grupos repetidos (hor_i, min_i, usotiempo_i). La presencia '
  'simultánea de varias actividades NO depende del valor de las demás '
  'columnas; es una multivaluación natural. Aquí queda separada.';

-- Índices recomendados para análisis
CREATE INDEX idx_persona_hogar           ON ds2.ds2_persona(folioviv, foliohog);
CREATE INDEX idx_ingreso_persona         ON ds2.ds2_persona_ingreso(folioviv, foliohog, numren);
CREATE INDEX idx_gasto_hogar             ON ds2.ds2_hogar_gasto(folioviv, foliohog);
CREATE INDEX idx_gasto_clave             ON ds2.ds2_hogar_gasto(clave);
CREATE INDEX idx_vivienda_entidad        ON ds2.ds2_vivienda(cod_entidad);
