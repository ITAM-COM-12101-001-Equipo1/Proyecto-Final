/*
================================================================================
 Script:      04_normalized_schema.sql
 Dataset:     3 - CONSAR
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   DDL del modelo normalizado en 4FN para los 11 datasets CONSAR.
              Cada dataset tiene su propia tabla de hechos (grano propio); las
              dimensiones (afore, siefore, tipo_recurso, plazo, métricas) se
              consolidan en catálogos compartidos.
 Decisiones (resumen, justificación completa en docs/):
   - 4 catálogos primarios compartidos: AFORE, SIEFORE, TIPO_RECURSO, PLAZO.
   - 2 catálogos derivados de los pivots wide→long:
       * METRICA_SENSIBILIDAD (7 métricas para #03)
       * METRICA_CUENTA       (11 métricas para #05)
       * (#09 reusa TIPO_RECURSO porque las métricas son montos por tipo).
   - 11 tablas de hechos, una por dataset, con grano:
       #01: (fecha, afore, siefore) → precio
       #02: (anio) → cotizantes, pea, %                     [agregado nacional]
       #03: (fecha, siefore, afore, id_metrica) → valor    [post-pivot]
       #04: (fecha, afore) → entradas, salidas
       #05: (fecha, afore, id_metrica_cuenta) → valor       [post-pivot]
       #06: (fecha, afore) → comision
       #07: (fecha, tipo_recurso, afore) → monto
       #08: (fecha, afore) → cedidos, recibidos
       #09: (fecha, afore, tipo_recurso) → monto            [post-pivot]
       #10: (fecha, tipo_recurso, plazo, afore) → monto
       #11: (fecha, afore, siefore) → precio
   - AFORE tiene flag `es_agregado` para marcar sentinels (ej.
     'total de cuentas administradas en el sar', 'sb pensiones promedio
     ponderado'). Los hechos del fact NO referencian afores agregados —
     se conservan en una tabla separada `ds3_agregado_observado` para
     reproducir al bit el CSV original.
================================================================================
*/

-- Limpieza idempotente (orden: facts → catálogos derivados → catálogos primarios).
DROP TABLE IF EXISTS ds3.ds3_precio_bolsa            CASCADE;
DROP TABLE IF EXISTS ds3.ds3_pea_cotizantes          CASCADE;
DROP TABLE IF EXISTS ds3.ds3_medida_sensibilidad     CASCADE;
DROP TABLE IF EXISTS ds3.ds3_flujo_recurso           CASCADE;
DROP TABLE IF EXISTS ds3.ds3_cuenta_administrada     CASCADE;
DROP TABLE IF EXISTS ds3.ds3_comision                CASCADE;
DROP TABLE IF EXISTS ds3.ds3_activo_neto             CASCADE;
DROP TABLE IF EXISTS ds3.ds3_traspaso                CASCADE;
DROP TABLE IF EXISTS ds3.ds3_recurso_afore           CASCADE;
DROP TABLE IF EXISTS ds3.ds3_rendimiento             CASCADE;
DROP TABLE IF EXISTS ds3.ds3_precio_gestion          CASCADE;
DROP TABLE IF EXISTS ds3.ds3_agregado_observado      CASCADE;

DROP TABLE IF EXISTS ds3.ds3_cat_metrica_cuenta      CASCADE;
DROP TABLE IF EXISTS ds3.ds3_cat_metrica_sensibilidad CASCADE;
DROP TABLE IF EXISTS ds3.ds3_cat_plazo               CASCADE;
DROP TABLE IF EXISTS ds3.ds3_cat_tipo_recurso        CASCADE;
DROP TABLE IF EXISTS ds3.ds3_cat_siefore             CASCADE;
DROP TABLE IF EXISTS ds3.ds3_cat_afore               CASCADE;

-- ===========================================================================
-- Catálogos primarios
-- ===========================================================================
CREATE TABLE ds3.ds3_cat_afore (
    id_afore       SERIAL      PRIMARY KEY,
    slug           VARCHAR(80) NOT NULL UNIQUE,
    nombre_display VARCHAR(120) NOT NULL,
    es_agregado    BOOLEAN     NOT NULL DEFAULT FALSE,
    activo         BOOLEAN     NOT NULL DEFAULT TRUE
);
COMMENT ON TABLE ds3.ds3_cat_afore IS
  'Catálogo de AFOREs y de etiquetas no-AFORE que aparecen en la columna '
  '`afore` del CSV crudo. `es_agregado=TRUE` marca etiquetas que NO son '
  'AFOREs comerciales (ej. "total de cuentas administradas en el sar", '
  '"sb pensiones promedio ponderado", "prestadora de servicios"). Las '
  'tablas de hechos solo deben referenciar afores con es_agregado=FALSE.';

CREATE TABLE ds3.ds3_cat_siefore (
    id_siefore     SERIAL      PRIMARY KEY,
    slug           VARCHAR(60) NOT NULL UNIQUE,
    nombre_display VARCHAR(120) NOT NULL
);
COMMENT ON TABLE ds3.ds3_cat_siefore IS
  'Catálogo de SIEFOREs (Sociedades de Inversión Especializadas en Fondos '
  'para el Retiro). El CSV mezcla nomenclaturas históricas ("sb 55-59") y '
  'actuales ("siefore básica 55-59") — se conservan como dos slugs distintos '
  'porque no podemos garantizar una equivalencia 1:1 sin documentación '
  'oficial CONSAR. Decisión de fusión queda pendiente con el equipo.';

CREATE TABLE ds3.ds3_cat_tipo_recurso (
    id_tipo_recurso SERIAL      PRIMARY KEY,
    slug            VARCHAR(80) NOT NULL UNIQUE,
    nombre_display  VARCHAR(120) NOT NULL
);

CREATE TABLE ds3.ds3_cat_plazo (
    id_plazo       SMALLSERIAL PRIMARY KEY,
    slug           VARCHAR(20) NOT NULL UNIQUE,
    nombre_display VARCHAR(40) NOT NULL,
    orden          SMALLINT
);

-- ===========================================================================
-- Catálogos derivados de los pivots wide → long
-- ===========================================================================
CREATE TABLE ds3.ds3_cat_metrica_sensibilidad (
    id_metrica   SMALLSERIAL PRIMARY KEY,
    columna_csv  VARCHAR(80) NOT NULL UNIQUE,
    descripcion  VARCHAR(150) NOT NULL,
    unidad       VARCHAR(40)
);

CREATE TABLE ds3.ds3_cat_metrica_cuenta (
    id_metrica   SMALLSERIAL PRIMARY KEY,
    columna_csv  VARCHAR(80) NOT NULL UNIQUE,
    descripcion  VARCHAR(150) NOT NULL
);

-- ===========================================================================
-- Tabla auxiliar: agregados observados (sentinels)
-- ===========================================================================
CREATE TABLE ds3.ds3_agregado_observado (
    id_agregado    BIGSERIAL PRIMARY KEY,
    archivo_csv    VARCHAR(60) NOT NULL,
    fecha          DATE,
    etiqueta_afore VARCHAR(120) NOT NULL,
    siefore        VARCHAR(120),
    tipo_recurso   VARCHAR(120),
    plazo          VARCHAR(40),
    valor          NUMERIC(20,6),
    valor_extra    NUMERIC(20,6)
);
COMMENT ON TABLE ds3.ds3_agregado_observado IS
  'Filas del CSV donde la columna `afore` no contiene una AFORE comercial '
  'sino una etiqueta agregada (Total, promedio ponderado, prestadora, etc.). '
  'Se preservan aquí para reproducir al bit el CSV original sin contaminar '
  'las tablas de hechos. Se usan para validar identidades contables.';

-- ===========================================================================
-- HECHOS — uno por dataset
-- ===========================================================================

-- #01 precio bolsa (diario por afore × siefore)
CREATE TABLE ds3.ds3_precio_bolsa (
    fecha       DATE         NOT NULL,
    id_afore    INT          NOT NULL,
    id_siefore  INT          NOT NULL,
    precio      NUMERIC(20,8) NOT NULL,
    PRIMARY KEY (fecha, id_afore, id_siefore),
    FOREIGN KEY (id_afore)   REFERENCES ds3.ds3_cat_afore(id_afore),
    FOREIGN KEY (id_siefore) REFERENCES ds3.ds3_cat_siefore(id_siefore)
);

-- #02 PEA vs cotizantes (anual, agregado nacional, sin afore)
CREATE TABLE ds3.ds3_pea_cotizantes (
    anio                  SMALLINT PRIMARY KEY,
    cotizantes            BIGINT   NOT NULL,
    pea                   BIGINT   NOT NULL,
    porcentaje_pea_afore  NUMERIC(6,2) NOT NULL,
    CONSTRAINT chk_pea_pct
        CHECK (porcentaje_pea_afore BETWEEN 0 AND 100)
);
COMMENT ON TABLE ds3.ds3_pea_cotizantes IS
  'Agregado nacional anual: PEA, cotizantes y porcentaje. NO tiene '
  'dimensión afore por diseño del CSV — es una serie macro.';

-- #03 medida de sensibilidad (post-pivot wide→long, 1FN)
CREATE TABLE ds3.ds3_medida_sensibilidad (
    fecha       DATE     NOT NULL,
    id_siefore  INT      NOT NULL,
    id_afore    INT      NOT NULL,
    id_metrica  SMALLINT NOT NULL,
    valor       NUMERIC(20,6) NOT NULL,
    PRIMARY KEY (fecha, id_siefore, id_afore, id_metrica),
    FOREIGN KEY (id_siefore) REFERENCES ds3.ds3_cat_siefore(id_siefore),
    FOREIGN KEY (id_afore)   REFERENCES ds3.ds3_cat_afore(id_afore),
    FOREIGN KEY (id_metrica) REFERENCES ds3.ds3_cat_metrica_sensibilidad(id_metrica)
);

-- #04 flujo de recursos (entradas y salidas)
CREATE TABLE ds3.ds3_flujo_recurso (
    fecha             DATE NOT NULL,
    id_afore          INT  NOT NULL,
    montos_entradas   NUMERIC(20,4),
    montos_salidas    NUMERIC(20,4),
    PRIMARY KEY (fecha, id_afore),
    FOREIGN KEY (id_afore) REFERENCES ds3.ds3_cat_afore(id_afore)
);

-- #05 cuentas administradas (post-pivot wide→long, 1FN)
CREATE TABLE ds3.ds3_cuenta_administrada (
    fecha       DATE     NOT NULL,
    id_afore    INT      NOT NULL,
    id_metrica  SMALLINT NOT NULL,
    valor       NUMERIC(20,2) NOT NULL,
    PRIMARY KEY (fecha, id_afore, id_metrica),
    FOREIGN KEY (id_afore)   REFERENCES ds3.ds3_cat_afore(id_afore),
    FOREIGN KEY (id_metrica) REFERENCES ds3.ds3_cat_metrica_cuenta(id_metrica)
);

-- #06 comisiones
CREATE TABLE ds3.ds3_comision (
    fecha     DATE NOT NULL,
    id_afore  INT  NOT NULL,
    comision  NUMERIC(7,4) NOT NULL,
    PRIMARY KEY (fecha, id_afore),
    FOREIGN KEY (id_afore) REFERENCES ds3.ds3_cat_afore(id_afore),
    CONSTRAINT chk_comision_pct
        CHECK (comision BETWEEN 0 AND 100)
);

-- #07 activos netos
CREATE TABLE ds3.ds3_activo_neto (
    fecha            DATE NOT NULL,
    id_tipo_recurso  INT  NOT NULL,
    id_afore         INT  NOT NULL,
    monto            NUMERIC(20,4) NOT NULL,
    PRIMARY KEY (fecha, id_tipo_recurso, id_afore),
    FOREIGN KEY (id_tipo_recurso) REFERENCES ds3.ds3_cat_tipo_recurso(id_tipo_recurso),
    FOREIGN KEY (id_afore)        REFERENCES ds3.ds3_cat_afore(id_afore)
);

-- #08 traspasos (cedidos / recibidos por mes)
CREATE TABLE ds3.ds3_traspaso (
    fecha              DATE NOT NULL,
    id_afore           INT  NOT NULL,
    num_tras_cedido    INTEGER,
    num_tras_recibido  INTEGER,
    PRIMARY KEY (fecha, id_afore),
    FOREIGN KEY (id_afore) REFERENCES ds3.ds3_cat_afore(id_afore),
    CONSTRAINT chk_traspaso_no_neg
        CHECK ((num_tras_cedido   IS NULL OR num_tras_cedido   >= 0)
           AND (num_tras_recibido IS NULL OR num_tras_recibido >= 0))
);

-- #09 recursos por afore (post-pivot wide→long, 1FN; usa TIPO_RECURSO)
CREATE TABLE ds3.ds3_recurso_afore (
    fecha            DATE NOT NULL,
    id_afore         INT  NOT NULL,
    id_tipo_recurso  INT  NOT NULL,
    monto            NUMERIC(20,4) NOT NULL,
    PRIMARY KEY (fecha, id_afore, id_tipo_recurso),
    FOREIGN KEY (id_afore)        REFERENCES ds3.ds3_cat_afore(id_afore),
    FOREIGN KEY (id_tipo_recurso) REFERENCES ds3.ds3_cat_tipo_recurso(id_tipo_recurso)
);

-- #10 rendimientos (con dos dimensiones: tipo_recurso × plazo)
CREATE TABLE ds3.ds3_rendimiento (
    fecha            DATE NOT NULL,
    id_tipo_recurso  INT  NOT NULL,
    id_plazo         SMALLINT NOT NULL,
    id_afore         INT  NOT NULL,
    monto            NUMERIC(20,6) NOT NULL,
    PRIMARY KEY (fecha, id_tipo_recurso, id_plazo, id_afore),
    FOREIGN KEY (id_tipo_recurso) REFERENCES ds3.ds3_cat_tipo_recurso(id_tipo_recurso),
    FOREIGN KEY (id_plazo)        REFERENCES ds3.ds3_cat_plazo(id_plazo),
    FOREIGN KEY (id_afore)        REFERENCES ds3.ds3_cat_afore(id_afore)
);

-- #11 precios de gestión (paralelo a #01, distinta serie)
CREATE TABLE ds3.ds3_precio_gestion (
    fecha       DATE NOT NULL,
    id_afore    INT  NOT NULL,
    id_siefore  INT  NOT NULL,
    precio      NUMERIC(20,8) NOT NULL,
    PRIMARY KEY (fecha, id_afore, id_siefore),
    FOREIGN KEY (id_afore)   REFERENCES ds3.ds3_cat_afore(id_afore),
    FOREIGN KEY (id_siefore) REFERENCES ds3.ds3_cat_siefore(id_siefore)
);

-- ===========================================================================
-- Índices recomendados
-- ===========================================================================
CREATE INDEX idx_precio_bolsa_afore     ON ds3.ds3_precio_bolsa(id_afore);
CREATE INDEX idx_precio_bolsa_siefore   ON ds3.ds3_precio_bolsa(id_siefore);
CREATE INDEX idx_precio_gestion_afore   ON ds3.ds3_precio_gestion(id_afore);
CREATE INDEX idx_precio_gestion_siefore ON ds3.ds3_precio_gestion(id_siefore);
CREATE INDEX idx_medida_afore           ON ds3.ds3_medida_sensibilidad(id_afore);
CREATE INDEX idx_cuenta_afore           ON ds3.ds3_cuenta_administrada(id_afore);
CREATE INDEX idx_recurso_afore          ON ds3.ds3_recurso_afore(id_afore);
CREATE INDEX idx_rendimiento_afore      ON ds3.ds3_rendimiento(id_afore);
CREATE INDEX idx_activo_neto_tipo       ON ds3.ds3_activo_neto(id_tipo_recurso);
CREATE INDEX idx_rendimiento_tipo       ON ds3.ds3_rendimiento(id_tipo_recurso);
