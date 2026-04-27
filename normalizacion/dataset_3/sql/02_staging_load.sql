/*
================================================================================
 Script:      02_staging_load.sql
 Dataset:     3 - CONSAR
 Etapa:       2 (Limpieza y staging)
 Propósito:   Cargar los 11 CSVs CONSAR en sus tablas de staging.
 Entrada:     Archivos en data/raw/datosgob_*.csv (UTF-8, header en línea 1).
 Salida:      11 tablas pobladas. Conteos esperados (filas con datos):
                #01 precios_bolsa       635,167
                #02 pea_cotizantes           15
                #03 medidas               7,840
                #04 entradas_salidas      1,980
                #05 cuentas               4,303
                #06 comisiones            2,080
                #07 activos_netos         9,849
                #08 traspasos             3,200
                #09 recursos              3,586
                #10 rendimientos         35,041
                #11 precios_gestion     588,318
                ------                ---------
                TOTAL                 1,291,479
 Notas:
   - Los CSV vienen en UTF-8 desde el portal ATDT — no requieren recodificar.
   - MD5 de cada CSV se documenta en el README maestro.
   - Si los archivos no son accesibles desde el servidor, sustituir COPY por
     \COPY en cliente psql.
================================================================================
*/

TRUNCATE ds3.ds3_staging_precios_bolsa     RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_pea_cotizantes    RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_medidas           RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_entradas_salidas  RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_cuentas           RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_comisiones        RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_activos_netos     RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_traspasos         RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_recursos          RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_rendimientos      RESTART IDENTITY;
TRUNCATE ds3.ds3_staging_precios_gestion   RESTART IDENTITY;

\set BASE '/Users/davicho/Normalizacion/Proyecto-Final-main/normalizacion/dataset_3/data/raw'

COPY ds3.ds3_staging_precios_bolsa     (fecha, afore, siefore, precio)
  FROM :'BASE'/datosgob_01_precios_bolsa_siefores.csv     WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_pea_cotizantes    (anio, cotizantes, pea, porcentaje_pea_afore)
  FROM :'BASE'/datosgob_02_pea_vs_cotizantes_datos_abiertos_2024.csv WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_medidas
  FROM :'BASE'/datosgob_03_medidas.csv                   WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');
-- Nota: el orden por defecto en `medidas` coincide con el header del CSV.

COPY ds3.ds3_staging_entradas_salidas  (fecha, afore, montos_entradas, montos_salidas)
  FROM :'BASE'/datosgob_04_entradas_salidas.csv          WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_cuentas
  FROM :'BASE'/datosgob_05_cuentas.csv                   WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_comisiones        (fecha, afore, comision)
  FROM :'BASE'/datosgob_06_comisiones.csv                WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_activos_netos     (fecha, tipo_recurso, afore, monto)
  FROM :'BASE'/datosgob_07_activos_netos.csv             WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_traspasos         (fecha, afore, num_tras_cedido, num_tras_recibido)
  FROM :'BASE'/datosgob_08_traspasos.csv                 WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_recursos
  FROM :'BASE'/datosgob_09_recursos.csv                  WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_rendimientos      (fecha, tipo_recurso, plazo, afore, monto)
  FROM :'BASE'/datosgob_10_rendimientos_precio_bolsa.csv WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds3.ds3_staging_precios_gestion   (fecha, afore, siefore, precio)
  FROM :'BASE'/datosgob_11_precios_gestion_siefores.csv  WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

-- Conteos rápidos.
SELECT '01_precios_bolsa'    AS dataset, COUNT(*) AS filas FROM ds3.ds3_staging_precios_bolsa     UNION ALL
SELECT '02_pea_cotizantes',         COUNT(*) FROM ds3.ds3_staging_pea_cotizantes                  UNION ALL
SELECT '03_medidas',                COUNT(*) FROM ds3.ds3_staging_medidas                         UNION ALL
SELECT '04_entradas_salidas',       COUNT(*) FROM ds3.ds3_staging_entradas_salidas                UNION ALL
SELECT '05_cuentas',                COUNT(*) FROM ds3.ds3_staging_cuentas                         UNION ALL
SELECT '06_comisiones',             COUNT(*) FROM ds3.ds3_staging_comisiones                      UNION ALL
SELECT '07_activos_netos',          COUNT(*) FROM ds3.ds3_staging_activos_netos                   UNION ALL
SELECT '08_traspasos',              COUNT(*) FROM ds3.ds3_staging_traspasos                       UNION ALL
SELECT '09_recursos',               COUNT(*) FROM ds3.ds3_staging_recursos                        UNION ALL
SELECT '10_rendimientos',           COUNT(*) FROM ds3.ds3_staging_rendimientos                    UNION ALL
SELECT '11_precios_gestion',        COUNT(*) FROM ds3.ds3_staging_precios_gestion;
