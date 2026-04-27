-- Ejemplo de normalización basada en sus esquemas de API
CREATE TABLE cat_sectores (
    id_sector SERIAL PRIMARY KEY,
    nombre_sector VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE cat_puestos (
    id_puesto SERIAL PRIMARY KEY,
    nombre_puesto VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE personas (
    id_persona SERIAL PRIMARY KEY,
    nombre VARCHAR(255),
    apellido_1 VARCHAR(255),
    apellido_2 VARCHAR(255),
    sexo VARCHAR(50),
    edad INT
);