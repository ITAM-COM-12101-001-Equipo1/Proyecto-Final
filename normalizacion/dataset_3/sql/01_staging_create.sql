/*
================================================================================
 Script:      01_staging_create.sql
 Dataset:     3 - CONSAR (Sistema de Ahorro para el Retiro, México)
 Etapa:       2 (Limpieza y staging)
 Propósito:   Crear el schema `ds3` y las tablas de staging para los 11
              archivos publicados por CONSAR vía datos.gob.mx / ATDT.
              Todas las columnas se cargan como TEXT para preservar el dato
              original; el casteo definitivo ocurre en 05_migration.sql.
 Entrada:     Ninguna (DDL puro).
 Salida:      11 tablas de staging vacías (una por archivo CSV de CONSAR).
 Decisiones:
   - Schema dedicado `ds3` para aislar este dataset y evitar colisiones
     con dataset_1 (`ds1`) y dataset_2 (`ds2`).
   - Las columnas replican EXACTAMENTE los headers del CSV oficial CONSAR.
     No se introducen columnas derivadas ni se renombra nada.
   - `staging_row_id BIGSERIAL` y `cargado_en TIMESTAMP` son metadatos
     técnicos de carga (no son datos del CSV).
   - Notación: las columnas en el CSV #09 traen ESPACIOS en el header
     (ej. "monto_ahorro solidario"); se conservan tal cual usando comillas.
================================================================================
*/

CREATE SCHEMA IF NOT EXISTS ds3;

-- Limpieza idempotente.
DROP TABLE IF EXISTS ds3.ds3_staging_precios_bolsa     CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_pea_cotizantes    CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_medidas           CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_entradas_salidas  CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_cuentas           CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_comisiones        CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_activos_netos     CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_traspasos         CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_recursos          CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_rendimientos      CASCADE;
DROP TABLE IF EXISTS ds3.ds3_staging_precios_gestion   CASCADE;

-- ---------------------------------------------------------------------------
-- #01 precios_bolsa_siefores (635,167 filas) — series diarias
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_precios_bolsa (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha    TEXT,
    afore    TEXT,
    siefore  TEXT,
    precio   TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #02 pea_vs_cotizantes (16 filas, anual)
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_pea_cotizantes (
    staging_row_id BIGSERIAL PRIMARY KEY,
    anio                  TEXT,
    cotizantes            TEXT,
    pea                   TEXT,
    porcentaje_pea_afore  TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #03 medidas_sensibilidad (7,840 filas) — formato ANCHO con 7 métricas/fila
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_medidas (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha    TEXT,
    siefore  TEXT,
    afore    TEXT,
    coeficiente_liquidez                              TEXT,
    diferencial_valor_riesgo_condicional_dcvar        TEXT,
    error_seguimiento                                 TEXT,
    escenarios_valor_riesgo_var                       TEXT,
    plazo_promedio_ponderado_ppp                      TEXT,
    provision_exposicion_instrumentos_derivados_pid   TEXT,
    valor_riesgo_var                                  TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #04 entradas_salidas (1,980 filas) — formato angosto
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_entradas_salidas (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha             TEXT,
    afore             TEXT,
    montos_entradas   TEXT,
    montos_salidas    TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #05 cuentas_administradas (4,303 filas) — formato ANCHO con 11 métricas
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_cuentas (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha    TEXT,
    afore    TEXT,
    cuentas_inhabilitadas                                              TEXT,
    cuentas_resguardadas_fondo_pensiones_para_bienestar_010            TEXT,
    total_cuentas_administradas_sar                                    TEXT,
    total_cuentas_administradas_afores                                 TEXT,
    trabajadores_asignados                                             TEXT,
    trabajadores_asignados_recursos_depositados_banco_mexico           TEXT,
    trabajadores_asignados_recursos_depositados_siefores               TEXT,
    trabajadores_imss                                                  TEXT,
    trabajadores_independientes                                        TEXT,
    trabajadores_issste                                                TEXT,
    trabajadores_registrados                                           TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #06 comisiones (2,080 filas) — formato angosto
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_comisiones (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha     TEXT,
    afore     TEXT,
    comision  TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #07 activos_netos (9,849 filas) — formato angosto con dimensión tipo_recurso
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_activos_netos (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha          TEXT,
    tipo_recurso   TEXT,
    afore          TEXT,
    monto          TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #08 traspasos (3,200 filas)
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_traspasos (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha              TEXT,
    afore              TEXT,
    num_tras_cedido    TEXT,
    num_tras_recibido  TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #09 recursos (3,586 filas) — formato ANCHO, 16 columnas con espacios
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_recursos (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha    TEXT,
    afore    TEXT,
    "monto_ahorro solidario"                          TEXT,
    "monto_ahorro voluntario"                         TEXT,
    "monto_ahorro voluntario y solidario"             TEXT,
    "monto_bono de pension issste"                    TEXT,
    "monto_capital de las afores"                     TEXT,
    "monto_fondos de prevision social"                TEXT,
    monto_fovissste                                   TEXT,
    monto_infonavit                                   TEXT,
    "monto_rcv - imss"                                TEXT,
    "monto_rcv - issste"                              TEXT,
    "monto_recursos administrados por las afores"     TEXT,
    "monto_recursos de los trabajadores"              TEXT,
    "monto_recursos depositados en banco de méxico"   TEXT,
    "monto_recursos registrados en el sar"            TEXT,
    monto_vivienda                                    TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #10 rendimientos_precio_bolsa (35,041 filas) — formato angosto con dos
-- dimensiones (tipo_recurso, plazo)
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_rendimientos (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha          TEXT,
    tipo_recurso   TEXT,
    plazo          TEXT,
    afore          TEXT,
    monto          TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- #11 precios_gestion_siefores (588,318 filas) — series diarias
-- ---------------------------------------------------------------------------
CREATE TABLE ds3.ds3_staging_precios_gestion (
    staging_row_id BIGSERIAL PRIMARY KEY,
    fecha    TEXT,
    afore    TEXT,
    siefore  TEXT,
    precio   TEXT,
    cargado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON SCHEMA ds3 IS
  'Dataset 3 — CONSAR. 11 archivos publicados por la Comisión Nacional del '
  'Sistema de Ahorro para el Retiro vía repodatos.atdt.gob.mx (datos.gob.mx). '
  'Series desde 1997 hasta 2025. Schema separado de ds1 (CDMX) y ds2 (ENIGH).';
