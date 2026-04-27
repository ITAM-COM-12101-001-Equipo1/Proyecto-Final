/*
================================================================================
 Script:      02_staging_load.sql
 Dataset:     1 - Remuneraciones del personal de la CDMX
 Etapa:       2 (Limpieza y staging)
 Propósito:   Cargar el CSV (ya convertido a UTF-8) en
              `ds1.ds1_staging_remuneraciones`.
 Entrada:     CSV en data/raw/remuneraciones_da_qna_14_23.csv
              (UTF-8, encabezado en línea 1, separador coma, comillas dobles
              para campos con coma literal).
 Salida:      Tabla de staging poblada (esperado: 246,821 filas).
 Pre-requisitos:
   - Ejecutar `01_staging_create.sql` antes de este script.
   - El CSV original (Latin-1 / CP1252) fue recodificado a UTF-8 con:
       iconv -f WINDOWS-1252 -t UTF-8 \
         "remuneraciones_da_qna_14_23 (1).csv" \
         > data/raw/remuneraciones_da_qna_14_23.csv
 Notas:
   - Usamos COPY (server-side) por desempeño. Si el archivo no es accesible
     desde el servidor, sustituir COPY por \COPY (cliente psql).
   - 1,526 filas del CSV traen comas literales dentro del campo
     `n_cabeza_sector` correctamente entrecomilladas; FORMAT CSV con
     QUOTE '"' las maneja sin problema.
   - El CSV no contiene columna temporal por registro; no se inventa
     ninguna. La ausencia se documenta en el README, sección
     "Series temporales".
================================================================================
*/

-- Limpiar staging si tuviera datos previos.
TRUNCATE TABLE ds1.ds1_staging_remuneraciones RESTART IDENTITY;

-- Carga server-side. Para cliente psql, reemplazar `COPY ... FROM '...'`
-- por `\COPY ... FROM '...'` (sin punto y coma final ni comilla simple).
COPY ds1.ds1_staging_remuneraciones (
    nombre, apellido_1, apellido_2, sexo, edad, n_puesto,
    id_tipo_nomina, tipo_contratacion, tipo_personal,
    id_universo, n_universo, id_sector, n_cabeza_sector,
    id_nivel_salarial, sueldo_tabular_bruto, sueldo_tabular_neto
)
FROM '/Users/davicho/Normalizacion/normalizacion/dataset_1/data/raw/remuneraciones_da_qna_14_23.csv'
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8', QUOTE '"', ESCAPE '"');

-- Verificación rápida del conteo cargado (esperado: 246,821).
SELECT COUNT(*) AS filas_cargadas
  FROM ds1.ds1_staging_remuneraciones;
