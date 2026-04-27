-- ============================================================
-- NORMALIZACIÓN 4NF — Remuneraciones CDMX
-- Autor: André Butrón
-- Prerrequisito: staging_remuneraciones ya cargada (E2)
-- ============================================================

-- ============================================================
-- PARTE 1: DDL — Crear tablas normalizadas
-- ============================================================

DROP TABLE IF EXISTS nombramientos CASCADE;
DROP TABLE IF EXISTS personas CASCADE;
DROP TABLE IF EXISTS cat_niveles_salariales CASCADE;
DROP TABLE IF EXISTS cat_tipo_personal CASCADE;
DROP TABLE IF EXISTS cat_tipo_contratacion CASCADE;
DROP TABLE IF EXISTS cat_tipo_nomina CASCADE;
DROP TABLE IF EXISTS cat_puestos CASCADE;
DROP TABLE IF EXISTS cat_universos CASCADE;
DROP TABLE IF EXISTS cat_sectores CASCADE;

-- 1. Catálogo de sectores
CREATE TABLE cat_sectores (
    id_sector VARCHAR(50) PRIMARY KEY,
    n_cabeza_sector VARCHAR(255) NOT NULL
);

-- 2. Catálogo de universos (depende de sector)
CREATE TABLE cat_universos (
    id_universo VARCHAR(50) PRIMARY KEY,
    n_universo VARCHAR(255) NOT NULL,
    id_sector VARCHAR(50) NOT NULL REFERENCES cat_sectores(id_sector)
);

-- 3. Catálogo de puestos
CREATE TABLE cat_puestos (
    id_puesto SERIAL PRIMARY KEY,
    n_puesto VARCHAR(255) UNIQUE NOT NULL
);

-- 4. Catálogo de tipo de nómina
CREATE TABLE cat_tipo_nomina (
    id_tipo_nomina INT PRIMARY KEY
);

-- 5. Catálogo de tipo de contratación
CREATE TABLE cat_tipo_contratacion (
    id_tipo_contratacion SERIAL PRIMARY KEY,
    tipo_contratacion VARCHAR(255) UNIQUE NOT NULL
);

-- 6. Catálogo de tipo de personal
CREATE TABLE cat_tipo_personal (
    id_tipo_personal SERIAL PRIMARY KEY,
    tipo_personal VARCHAR(255) UNIQUE NOT NULL
);

-- 7. Catálogo de niveles salariales
CREATE TABLE cat_niveles_salariales (
    id_nivel_salarial INT PRIMARY KEY,
    sueldo_tabular_bruto NUMERIC(12,2) NOT NULL,
    sueldo_tabular_neto NUMERIC(12,2) NOT NULL
);

-- 8. Personas
CREATE TABLE personas (
    id_persona SERIAL PRIMARY KEY,
    nombre VARCHAR(255),
    apellido_1 VARCHAR(255),
    apellido_2 VARCHAR(255),
    sexo VARCHAR(50)
);

-- 9. Nombramientos (tabla central de hechos)
CREATE TABLE nombramientos (
    id_nombramiento SERIAL PRIMARY KEY,
    id_persona INT NOT NULL REFERENCES personas(id_persona),
    id_puesto INT NOT NULL REFERENCES cat_puestos(id_puesto),
    id_tipo_nomina INT NOT NULL REFERENCES cat_tipo_nomina(id_tipo_nomina),
    id_tipo_contratacion INT NOT NULL REFERENCES cat_tipo_contratacion(id_tipo_contratacion),
    id_tipo_personal INT NOT NULL REFERENCES cat_tipo_personal(id_tipo_personal),
    id_universo VARCHAR(50) NOT NULL REFERENCES cat_universos(id_universo),
    id_nivel_salarial INT NOT NULL REFERENCES cat_niveles_salariales(id_nivel_salarial),
    fecha_ingreso DATE,
    edad INT
);

-- ============================================================
-- PARTE 2: Migración — Poblar desde staging_remuneraciones
-- Ejecutar en orden (los catálogos primero, nombramientos al final)
-- ============================================================

-- 1. Sectores
INSERT INTO cat_sectores (id_sector, n_cabeza_sector)
SELECT DISTINCT id_sector, n_cabeza_sector
FROM staging_remuneraciones
WHERE id_sector IS NOT NULL;

-- 2. Universos
INSERT INTO cat_universos (id_universo, n_universo, id_sector)
SELECT DISTINCT id_universo, n_universo, id_sector
FROM staging_remuneraciones
WHERE id_universo IS NOT NULL;

-- 3. Puestos
INSERT INTO cat_puestos (n_puesto)
SELECT DISTINCT n_puesto
FROM staging_remuneraciones
WHERE n_puesto IS NOT NULL;

-- 4. Tipo de nómina
INSERT INTO cat_tipo_nomina (id_tipo_nomina)
SELECT DISTINCT id_tipo_nomina
FROM staging_remuneraciones
WHERE id_tipo_nomina IS NOT NULL;

-- 5. Tipo de contratación
INSERT INTO cat_tipo_contratacion (tipo_contratacion)
SELECT DISTINCT tipo_contratacion
FROM staging_remuneraciones
WHERE tipo_contratacion IS NOT NULL;

-- 6. Tipo de personal
INSERT INTO cat_tipo_personal (tipo_personal)
SELECT DISTINCT tipo_personal
FROM staging_remuneraciones
WHERE tipo_personal IS NOT NULL;

-- 7. Niveles salariales
INSERT INTO cat_niveles_salariales (id_nivel_salarial, sueldo_tabular_bruto, sueldo_tabular_neto)
SELECT DISTINCT id_nivel_salarial, sueldo_tabular_bruto, sueldo_tabular_neto
FROM staging_remuneraciones
WHERE id_nivel_salarial IS NOT NULL;

-- 8. Personas (deduplicar por nombre completo + sexo)
INSERT INTO personas (nombre, apellido_1, apellido_2, sexo)
SELECT DISTINCT nombre, apellido_1, apellido_2, sexo
FROM staging_remuneraciones;

-- 9. Nombramientos (join contra todos los catálogos)
INSERT INTO nombramientos (
    id_persona, id_puesto, id_tipo_nomina,
    id_tipo_contratacion, id_tipo_personal,
    id_universo, id_nivel_salarial,
    fecha_ingreso, edad
)
SELECT
    p.id_persona,
    pu.id_puesto,
    s.id_tipo_nomina,
    tc.id_tipo_contratacion,
    tp.id_tipo_personal,
    s.id_universo,
    s.id_nivel_salarial,
    s.fecha_ingreso,
    s.edad
FROM staging_remuneraciones s
JOIN personas p
    ON  s.nombre     = p.nombre
    AND s.apellido_1 = p.apellido_1
    AND s.apellido_2 = p.apellido_2
    AND s.sexo       = p.sexo
JOIN cat_puestos pu
    ON s.n_puesto = pu.n_puesto
JOIN cat_tipo_contratacion tc
    ON s.tipo_contratacion = tc.tipo_contratacion
JOIN cat_tipo_personal tp
    ON s.tipo_personal = tp.tipo_personal;

-- ============================================================
-- VERIFICACIÓN — Contar registros para validar migración
-- ============================================================
SELECT 'cat_sectores' AS tabla, COUNT(*) FROM cat_sectores
UNION ALL SELECT 'cat_universos', COUNT(*) FROM cat_universos
UNION ALL SELECT 'cat_puestos', COUNT(*) FROM cat_puestos
UNION ALL SELECT 'cat_tipo_nomina', COUNT(*) FROM cat_tipo_nomina
UNION ALL SELECT 'cat_tipo_contratacion', COUNT(*) FROM cat_tipo_contratacion
UNION ALL SELECT 'cat_tipo_personal', COUNT(*) FROM cat_tipo_personal
UNION ALL SELECT 'cat_niveles_salariales', COUNT(*) FROM cat_niveles_salariales
UNION ALL SELECT 'personas', COUNT(*) FROM personas
UNION ALL SELECT 'nombramientos', COUNT(*) FROM nombramientos
UNION ALL SELECT 'staging_original', COUNT(*) FROM staging_remuneraciones;
