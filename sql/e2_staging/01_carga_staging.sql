-- Creación de la tabla "sucia" para recibir el CSV
CREATE TABLE staging_remuneraciones (
    nombre VARCHAR(255),
    apellido_1 VARCHAR(255),
    apellido_2 VARCHAR(255),
    sexo VARCHAR(50),
    edad INT,
    n_puesto VARCHAR(255),
    id_tipo_nomina INT,
    tipo_contratacion VARCHAR(255),
    tipo_personal VARCHAR(255),
    fecha_ingreso DATE,
    id_universo VARCHAR(50),
    n_universo VARCHAR(255),
    id_sector VARCHAR(50),
    n_cabeza_sector VARCHAR(255),
    id_nivel_salarial INT,
    sueldo_tabular_bruto NUMERIC(12,2),
    sueldo_tabular_neto NUMERIC(12,2)
);

-- Comando para cargar (ajustar ruta local si es necesario)
-- COPY staging_remuneraciones FROM '/repo/data/publico/WDF_remuneraciones_cdmx.csv' WITH (FORMAT csv, HEADER true);