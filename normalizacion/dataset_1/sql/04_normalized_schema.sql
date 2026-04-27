/*
================================================================================
 Script:      04_normalized_schema.sql
 Dataset:     1 - Remuneraciones del personal de la CDMX
 Etapa:       3 (Normalización hasta 4FN)
 Propósito:   Crear el esquema normalizado en 4FN (también satisface BCNF).
              Define los catálogos, la entidad Persona y la tabla de
              remuneración (asignación) que actúa como "hecho" del modelo.
 Entrada:     Ninguna (DDL puro). Se ejecuta antes de la migración.
 Salida:      Tablas vacías en el schema `ds1`, con PKs, FKs y restricciones.
 Decisiones:
   - Surrogate keys SERIAL/SMALLINT para la mayoría de catálogos por
     consistencia y porque algunos identificadores naturales del CSV son
     códigos textuales (ej. 02CD06).
   - id_universo, id_sector, id_tipo_nomina conservan su valor natural del
     CSV como PK (son identificadores oficiales, estables y cortos).
   - Persona usa surrogate persona_id: la trinidad (nombre, ap1, ap2) NO
     es única (2,788 colisiones por homonimia) y el CSV no incluye RFC/CURP.
     Cada fila del staging genera una persona distinta. Esto se documenta
     como decisión y como pregunta para el equipo.
   - sueldo_tabular_bruto y sueldo_tabular_neto viven en
     ds1_remuneracion (atributos del registro), NO en un catálogo de
     tabulador, porque id_nivel_salarial NO los determina funcionalmente
     en este corte (88/721 niveles tienen >1 sueldo).
   - id_nivel_salarial se conserva como atributo textual de la
     remuneración (no es FK a un tabulador) por la misma razón.
   - tipo_contratacion vive SOLO en ds1_tipo_nomina porque
     id_tipo_nomina → tipo_contratacion es DF estricta (verificada).
   - tipo_personal sí merece catálogo (11 valores fijos) y se referencia
     desde la remuneración.
   - Sin columnas derivadas: el CSV no trae periodo/fecha y no se
     fabrica ninguna.
================================================================================
*/

-- Limpieza idempotente (orden importa por las FKs)
DROP TABLE IF EXISTS ds1.ds1_remuneracion   CASCADE;
DROP TABLE IF EXISTS ds1.ds1_persona        CASCADE;
DROP TABLE IF EXISTS ds1.ds1_puesto         CASCADE;
DROP TABLE IF EXISTS ds1.ds1_tipo_personal  CASCADE;
DROP TABLE IF EXISTS ds1.ds1_tipo_nomina    CASCADE;
DROP TABLE IF EXISTS ds1.ds1_sector         CASCADE;
DROP TABLE IF EXISTS ds1.ds1_universo       CASCADE;

-- ---------------------------------------------------------------------------
-- Catálogo: Universo (27 filas esperadas)
-- DF: id_universo → n_universo
-- ---------------------------------------------------------------------------
CREATE TABLE ds1.ds1_universo (
    id_universo   VARCHAR(8)  PRIMARY KEY,
    n_universo    VARCHAR(80) NOT NULL UNIQUE
);
COMMENT ON TABLE ds1.ds1_universo IS
  'Catálogo de universos de personal (clasificación de alto nivel CDMX). '
  'Justificación: id_universo → n_universo es DF estricta verificada.';

-- ---------------------------------------------------------------------------
-- Catálogo: Sector / cabeza de sector (73 filas esperadas)
-- DF: id_sector → n_cabeza_sector
-- ---------------------------------------------------------------------------
CREATE TABLE ds1.ds1_sector (
    id_sector         VARCHAR(8)   PRIMARY KEY,
    n_cabeza_sector   VARCHAR(150) NOT NULL UNIQUE
);
COMMENT ON TABLE ds1.ds1_sector IS
  'Catálogo de cabezas de sector / entes públicos (alcaldías, secretarías, '
  'organismos). Justificación: id_sector → n_cabeza_sector es DF estricta.';

-- ---------------------------------------------------------------------------
-- Catálogo: Tipo de nómina (7 filas esperadas)
-- DF: id_tipo_nomina → tipo_contratacion (estricta)
-- ---------------------------------------------------------------------------
CREATE TABLE ds1.ds1_tipo_nomina (
    id_tipo_nomina       SMALLINT    PRIMARY KEY,
    tipo_contratacion    VARCHAR(40) NOT NULL UNIQUE
);
COMMENT ON TABLE ds1.ds1_tipo_nomina IS
  'Catálogo de tipos de nómina con su tipo de contratación asociado. '
  'tipo_contratacion vive aquí (no en remuneración) porque '
  'id_tipo_nomina → tipo_contratacion es DF estricta (BCNF).';

-- ---------------------------------------------------------------------------
-- Catálogo: Tipo de personal (11 filas esperadas)
-- ---------------------------------------------------------------------------
CREATE TABLE ds1.ds1_tipo_personal (
    id_tipo_personal   SMALLSERIAL  PRIMARY KEY,
    tipo_personal      VARCHAR(40)  NOT NULL UNIQUE
);
COMMENT ON TABLE ds1.ds1_tipo_personal IS
  'Catálogo de categorías de personal (SINDICALIZADOS, CONFIANZA, '
  'HABERES, ESTRUCTURA, INTERINATO, etc.). Surrogate key porque el CSV '
  'no trae código oficial para esta dimensión.';

-- ---------------------------------------------------------------------------
-- Catálogo: Puesto (~1,772 filas esperadas)
-- ---------------------------------------------------------------------------
CREATE TABLE ds1.ds1_puesto (
    id_puesto   SERIAL       PRIMARY KEY,
    n_puesto    VARCHAR(120) NOT NULL UNIQUE
);
COMMENT ON TABLE ds1.ds1_puesto IS
  'Catálogo de nombres de puesto. Surrogate key porque n_puesto es '
  'texto largo y se repite mucho. n_puesto NO determina id_nivel_salarial '
  'ni id_tipo_nomina (verificado), por eso esos atributos NO viven aquí.';

-- ---------------------------------------------------------------------------
-- Entidad: Persona (1 fila por fila del staging — ver decisiones)
-- ---------------------------------------------------------------------------
CREATE TABLE ds1.ds1_persona (
    id_persona    BIGSERIAL   PRIMARY KEY,
    nombre        VARCHAR(80) NOT NULL,
    apellido_1    VARCHAR(60) NOT NULL,
    apellido_2    VARCHAR(60) NOT NULL,
    sexo          VARCHAR(15) NOT NULL,
    edad          SMALLINT    NOT NULL,
    CONSTRAINT chk_persona_sexo
        CHECK (sexo IN ('MASCULINO','FEMENINO','NA')),
    CONSTRAINT chk_persona_edad
        CHECK (edad BETWEEN 0 AND 120)
);
COMMENT ON TABLE ds1.ds1_persona IS
  'Entidad Persona. Surrogate key porque (nombre, apellido_1, apellido_2) '
  'NO es única en este corte (homonimias confirmadas). Una fila del '
  'staging produce exactamente una persona en esta tabla; deduplicar por '
  'nombre completo perdería datos legítimos.';

-- ---------------------------------------------------------------------------
-- Hecho / asignación: Remuneración (1 fila por fila del staging)
-- ---------------------------------------------------------------------------
CREATE TABLE ds1.ds1_remuneracion (
    id_remuneracion        BIGSERIAL      PRIMARY KEY,
    id_persona             BIGINT         NOT NULL,
    id_puesto              INT            NOT NULL,
    id_tipo_nomina         SMALLINT       NOT NULL,
    id_tipo_personal       SMALLINT       NOT NULL,
    id_universo            VARCHAR(8)     NOT NULL,
    id_sector              VARCHAR(8)     NOT NULL,
    id_nivel_salarial      VARCHAR(10)    NOT NULL,
    sueldo_tabular_bruto   NUMERIC(12,2)  NOT NULL,
    sueldo_tabular_neto    NUMERIC(12,2)  NOT NULL,
    CONSTRAINT fk_rem_persona
        FOREIGN KEY (id_persona)       REFERENCES ds1.ds1_persona(id_persona),
    CONSTRAINT fk_rem_puesto
        FOREIGN KEY (id_puesto)        REFERENCES ds1.ds1_puesto(id_puesto),
    CONSTRAINT fk_rem_tipo_nomina
        FOREIGN KEY (id_tipo_nomina)   REFERENCES ds1.ds1_tipo_nomina(id_tipo_nomina),
    CONSTRAINT fk_rem_tipo_personal
        FOREIGN KEY (id_tipo_personal) REFERENCES ds1.ds1_tipo_personal(id_tipo_personal),
    CONSTRAINT fk_rem_universo
        FOREIGN KEY (id_universo)      REFERENCES ds1.ds1_universo(id_universo),
    CONSTRAINT fk_rem_sector
        FOREIGN KEY (id_sector)        REFERENCES ds1.ds1_sector(id_sector),
    CONSTRAINT chk_rem_sueldos_positivos
        CHECK (sueldo_tabular_bruto > 0 AND sueldo_tabular_neto > 0)
);
COMMENT ON TABLE ds1.ds1_remuneracion IS
  'Tabla central: cada fila es una asignación persona-puesto-sector con '
  'su tabulador. sueldo_tabular_bruto y sueldo_tabular_neto viven aquí '
  'porque id_nivel_salarial NO los determina (88/721 niveles tienen >1 '
  'sueldo en este corte). id_nivel_salarial se conserva como atributo '
  'textual, no como FK a un tabulador (no existe tal tabulador derivable '
  'de los datos).';

-- Índices recomendados para análisis típicos (consultas por dimensión).
CREATE INDEX idx_rem_sector       ON ds1.ds1_remuneracion(id_sector);
CREATE INDEX idx_rem_universo     ON ds1.ds1_remuneracion(id_universo);
CREATE INDEX idx_rem_tipo_nomina  ON ds1.ds1_remuneracion(id_tipo_nomina);
CREATE INDEX idx_rem_puesto       ON ds1.ds1_remuneracion(id_puesto);
CREATE INDEX idx_rem_persona      ON ds1.ds1_remuneracion(id_persona);
