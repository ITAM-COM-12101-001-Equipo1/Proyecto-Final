/*
================================================================================
 Script:      01_staging_create.sql
 Dataset:     1 - Remuneraciones del personal de la CDMX
 Etapa:       2 (Limpieza y staging)
 Propósito:   Crear la tabla de staging que recibirá el CSV crudo "tal cual",
              con todas las columnas como TEXT/VARCHAR para no perder
              información durante la carga (sin validaciones de tipo).
 Entrada:     Ninguna (DDL puro).
 Salida:      Tabla `ds1_staging_remuneraciones` vacía, lista para el COPY.
 Decisiones:
   - Schema dedicado `ds1` para aislar este dataset y evitar colisiones
     con otros datasets del proyecto (ds2, ds3).
   - Todas las columnas TEXT en staging: el casteo se hace al migrar.
   - Se replican EXACTAMENTE las 16 columnas del CSV oficial; no se
     introducen columnas derivadas o inventadas.
   - Se agrega `staging_row_id BIGSERIAL` como clave técnica para
     auditoría y trazabilidad de filas problemáticas (no es un dato del
     CSV, es metadato de carga).
   - Se agrega `cargado_en TIMESTAMP DEFAULT NOW()` como timestamp del
     proceso de carga (metadato técnico, no atributo de negocio).
================================================================================
*/

CREATE SCHEMA IF NOT EXISTS ds1;

DROP TABLE IF EXISTS ds1.ds1_staging_remuneraciones CASCADE;

CREATE TABLE ds1.ds1_staging_remuneraciones (
    staging_row_id        BIGSERIAL PRIMARY KEY,
    nombre                TEXT,
    apellido_1            TEXT,
    apellido_2            TEXT,
    sexo                  TEXT,
    edad                  TEXT,
    n_puesto              TEXT,
    id_tipo_nomina        TEXT,
    tipo_contratacion     TEXT,
    tipo_personal         TEXT,
    id_universo           TEXT,
    n_universo            TEXT,
    id_sector             TEXT,
    n_cabeza_sector       TEXT,
    id_nivel_salarial     TEXT,
    sueldo_tabular_bruto  TEXT,
    sueldo_tabular_neto   TEXT,
    cargado_en            TIMESTAMP NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  ds1.ds1_staging_remuneraciones IS
  'Staging crudo del CSV de remuneraciones de la CDMX. '
  'Todas las columnas en TEXT para preservar el dato original; el casteo '
  'y la limpieza ocurren en el script 05_migration.sql. '
  'No se agregan columnas derivadas: el dataset oficial no contiene '
  'atributo temporal por registro y esa ausencia se documenta tal cual '
  'en el README, sección "Series temporales".';

COMMENT ON COLUMN ds1.ds1_staging_remuneraciones.staging_row_id IS
  'Identificador técnico de carga (no es dato del CSV).';
COMMENT ON COLUMN ds1.ds1_staging_remuneraciones.cargado_en IS
  'Timestamp del proceso de carga (no es dato del CSV).';
