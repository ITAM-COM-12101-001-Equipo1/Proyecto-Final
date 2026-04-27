/*
================================================================================
 Script:      05_migration.sql
 Dataset:     1 - Remuneraciones del personal de la CDMX
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   Migrar los datos desde `ds1.ds1_staging_remuneraciones` hacia
              el esquema normalizado en 4FN.
 Entrada:     Tabla de staging poblada (esperado: 246,821 filas).
 Salida:      Catálogos + ds1_persona + ds1_remuneracion poblados.
              Conteos esperados:
                - ds1_universo:       27
                - ds1_sector:         73
                - ds1_tipo_nomina:    7
                - ds1_tipo_personal:  11
                - ds1_puesto:         1,772
                - ds1_persona:        246,821 (1 por fila de staging)
                - ds1_remuneracion:   246,821
 Estrategia: Cargar primero los catálogos (orden de FKs), después
             persona, y al final remuneración con todos los joins.
 Decisiones:
   - Persona: una fila por fila del staging (sin deduplicar). El CSV no
     trae identificador estable de persona (CURP/RFC); deduplicar por
     (nombre, ap1, ap2) perdería ~3,400 filas legítimas por homonimia.
   - El emparejamiento Persona ↔ Remuneración usa el `staging_row_id` de
     staging como ancla: id_persona = staging_row_id.
   - Casteo a NUMERIC y SMALLINT con TRIM por seguridad.
================================================================================
*/

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Catálogos
-- ---------------------------------------------------------------------------
INSERT INTO ds1.ds1_universo (id_universo, n_universo)
SELECT DISTINCT TRIM(id_universo), TRIM(n_universo)
  FROM ds1.ds1_staging_remuneraciones
 ORDER BY 1;

INSERT INTO ds1.ds1_sector (id_sector, n_cabeza_sector)
SELECT DISTINCT TRIM(id_sector), TRIM(n_cabeza_sector)
  FROM ds1.ds1_staging_remuneraciones
 ORDER BY 1;

INSERT INTO ds1.ds1_tipo_nomina (id_tipo_nomina, tipo_contratacion)
SELECT DISTINCT TRIM(id_tipo_nomina)::SMALLINT, TRIM(tipo_contratacion)
  FROM ds1.ds1_staging_remuneraciones
 ORDER BY 1;

INSERT INTO ds1.ds1_tipo_personal (tipo_personal)
SELECT DISTINCT TRIM(tipo_personal)
  FROM ds1.ds1_staging_remuneraciones
 ORDER BY 1;

INSERT INTO ds1.ds1_puesto (n_puesto)
SELECT DISTINCT TRIM(n_puesto)
  FROM ds1.ds1_staging_remuneraciones
 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 2. Persona — una fila por fila del staging (preserva conteo)
--    Forzamos id_persona = staging_row_id para enlazar 1:1 sin ambigüedad.
-- ---------------------------------------------------------------------------
INSERT INTO ds1.ds1_persona (id_persona, nombre, apellido_1, apellido_2, sexo, edad)
SELECT
    s.staging_row_id,
    TRIM(s.nombre),
    TRIM(s.apellido_1),
    TRIM(s.apellido_2),
    TRIM(s.sexo),
    TRIM(s.edad)::SMALLINT
  FROM ds1.ds1_staging_remuneraciones s;

-- Sincronizar la secuencia para futuros INSERTs no automáticos.
SELECT setval(
    pg_get_serial_sequence('ds1.ds1_persona','id_persona'),
    (SELECT COALESCE(MAX(id_persona), 1) FROM ds1.ds1_persona)
);

-- ---------------------------------------------------------------------------
-- 3. Remuneración — joins con todos los catálogos
-- ---------------------------------------------------------------------------
INSERT INTO ds1.ds1_remuneracion (
    id_remuneracion, id_persona, id_puesto, id_tipo_nomina,
    id_tipo_personal, id_universo, id_sector,
    id_nivel_salarial, sueldo_tabular_bruto, sueldo_tabular_neto
)
SELECT
    s.staging_row_id                         AS id_remuneracion,
    s.staging_row_id                         AS id_persona,
    p.id_puesto,
    TRIM(s.id_tipo_nomina)::SMALLINT         AS id_tipo_nomina,
    tp.id_tipo_personal,
    TRIM(s.id_universo)                      AS id_universo,
    TRIM(s.id_sector)                        AS id_sector,
    TRIM(s.id_nivel_salarial)                AS id_nivel_salarial,
    TRIM(s.sueldo_tabular_bruto)::NUMERIC(12,2),
    TRIM(s.sueldo_tabular_neto)::NUMERIC(12,2)
  FROM ds1.ds1_staging_remuneraciones s
  JOIN ds1.ds1_puesto         p  ON p.n_puesto       = TRIM(s.n_puesto)
  JOIN ds1.ds1_tipo_personal  tp ON tp.tipo_personal = TRIM(s.tipo_personal);

-- Sincronizar la secuencia.
SELECT setval(
    pg_get_serial_sequence('ds1.ds1_remuneracion','id_remuneracion'),
    (SELECT COALESCE(MAX(id_remuneracion), 1) FROM ds1.ds1_remuneracion)
);

COMMIT;

-- Conteos rápidos (informativos; la verificación formal está en 06).
SELECT 'ds1_universo'      AS tabla, COUNT(*) AS filas FROM ds1.ds1_universo      UNION ALL
SELECT 'ds1_sector',           COUNT(*)              FROM ds1.ds1_sector          UNION ALL
SELECT 'ds1_tipo_nomina',      COUNT(*)              FROM ds1.ds1_tipo_nomina     UNION ALL
SELECT 'ds1_tipo_personal',    COUNT(*)              FROM ds1.ds1_tipo_personal   UNION ALL
SELECT 'ds1_puesto',           COUNT(*)              FROM ds1.ds1_puesto          UNION ALL
SELECT 'ds1_persona',          COUNT(*)              FROM ds1.ds1_persona         UNION ALL
SELECT 'ds1_remuneracion',     COUNT(*)              FROM ds1.ds1_remuneracion;
