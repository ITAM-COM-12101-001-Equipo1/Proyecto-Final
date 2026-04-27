/*
================================================================================
 Script:      02_staging_load.sql
 Dataset:     2 - ENIGH 2024 NS (INEGI)
 Etapa:       2 (Limpieza y staging)
 Propósito:   Cargar los 17 CSVs de ENIGH 2024 + los 111 catálogos INEGI en
              las tablas de staging creadas en 01_staging_create.sql.
 Entrada:     Archivos en data/raw/*.csv (17 sub-tablas + carpeta catalogos/).
 Salida:      Tablas de staging pobladas. Conteos esperados:
                viviendas         90,324
                hogares           91,414
                poblacion        308,598
                ingresos         391,563
                gastoshogar    5,311,497
                concentradohogar  91,414
                + 12 sub-tablas restantes (ver README)
                + ~5,000 filas de catálogos consolidados.
 Pre-requisitos:
   - Ejecutar 01_staging_create.sql antes.
   - Los CSVs originales del INEGI vienen en encoding Latin-1 / Windows-1252.
     Se asume que el equipo recodifica a UTF-8 antes de la carga (instrucción
     en INTEGRATION.md, paso 2).
   - Si los CSVs siguen en Latin-1, sustituir ENCODING 'UTF8' por
     ENCODING 'WIN1252' en cada COPY.
 Notas:
   - Se usa COPY server-side. Sustituir por \COPY si el archivo no es
     accesible desde el servidor PostgreSQL.
   - Las 12 sub-tablas fuera del alcance profundo se cargan en formato
     "línea cruda" (una columna TEXT por fila); el desglose queda fuera
     de este entregable. Documentado en el README.
================================================================================
*/

TRUNCATE ds2.ds2_staging_viviendas        RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_hogares          RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_poblacion        RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_ingresos         RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_gastoshogar      RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_concentradohogar RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_gastospersona    RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_erogaciones      RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_gastotarjetas    RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_trabajos         RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_agro             RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_agroconsumo      RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_agrogasto        RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_agroproductos    RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_noagro           RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_noagroimportes   RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_ingresos_jcf     RESTART IDENTITY;
TRUNCATE ds2.ds2_staging_catalogo_inegi   RESTART IDENTITY;

-- ===========================================================================
-- 5 tablas core (alcance profundo: se normalizan a 4FN)
-- ===========================================================================

\set BASE '/Users/davicho/Normalizacion/Proyecto-Final-main/normalizacion/dataset_2/data/raw'

COPY ds2.ds2_staging_viviendas (
    folioviv, tipo_viv, mat_pared, mat_techos, mat_pisos, antiguedad, antigua_ne,
    cocina, cocina_dor, cuart_dorm, num_cuarto, lugar_coc, agua_ent, ab_agua,
    agua_noe, dotac_agua, excusado, uso_compar, sanit_agua, biodigest,
    bano_comp, bano_excus, bano_regad, drenaje, disp_elect, focos, focos_ahor,
    combus, fogon_chi, eli_basura, tenencia, renta, estim_pago, pago_viv,
    pago_mesp, tipo_adqui, viv_usada, finan_1, finan_2, finan_3, finan_4,
    finan_5, finan_6, finan_7, finan_8, num_dueno1, hog_dueno1, num_dueno2,
    hog_dueno2, escrituras, lavadero, fregadero, regadera, tinaco_azo, cisterna,
    pileta, calent_sol, calent_gas, calen_lena, medid_luz, bomba_agua,
    tanque_gas, aire_acond, calefacc, p_grietas, p_pandeos, p_levanta,
    p_humedad, p_fractura, p_electric, p_tuberias, tot_resid, tot_hom, tot_muj,
    tot_hog, ubica_geo, tam_loc, est_socio, est_dis, upm, factor, procaptar
)
FROM :'BASE'/conjunto_de_datos_viviendas_enigh2024_ns.csv
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds2.ds2_staging_hogares
FROM :'BASE'/conjunto_de_datos_hogares_enigh2024_ns.csv
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8',
      FORCE_NULL (folioviv));  -- no aplica en realidad; placeholder seguro

-- Nota: el COPY anterior usa el orden por defecto de columnas de la tabla.
-- Si el orden del CSV difiere del DDL, listar las columnas explícitamente
-- como en `viviendas`. Se sabe por inspección que los 148 nombres del CSV
-- de hogares coinciden 1:1 con el DDL en orden.

COPY ds2.ds2_staging_poblacion
FROM :'BASE'/conjunto_de_datos_poblacion_enigh2024_ns.csv
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds2.ds2_staging_ingresos
FROM :'BASE'/conjunto_de_datos_ingresos_enigh2024_ns.csv
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY ds2.ds2_staging_gastoshogar
FROM :'BASE'/conjunto_de_datos_gastoshogar_enigh2024_ns.csv
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

-- ===========================================================================
-- 12 tablas restantes (alcance staging únicamente — almacenadas como línea
-- cruda). El equipo puede expandir el desglose en una iteración futura.
-- ===========================================================================

COPY ds2.ds2_staging_concentradohogar (contenido)
FROM :'BASE'/conjunto_de_datos_concentradohogar_enigh2024_ns.csv WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_gastospersona (contenido)
FROM :'BASE'/conjunto_de_datos_gastospersona_enigh2024_ns.csv   WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_erogaciones (contenido)
FROM :'BASE'/conjunto_de_datos_erogaciones_enigh2024_ns.csv     WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_gastotarjetas (contenido)
FROM :'BASE'/conjunto_de_datos_gastotarjetas_enigh2024_ns.csv   WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_trabajos (contenido)
FROM :'BASE'/conjunto_de_datos_trabajos_enigh2024_ns.csv        WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_agro (contenido)
FROM :'BASE'/conjunto_de_datos_agro_enigh2024_ns.csv            WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_agroconsumo (contenido)
FROM :'BASE'/conjunto_de_datos_agroconsumo_enigh2024_ns.csv     WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_agrogasto (contenido)
FROM :'BASE'/conjunto_de_datos_agrogasto_enigh2024_ns.csv       WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_agroproductos (contenido)
FROM :'BASE'/conjunto_de_datos_agroproductos_enigh2024_ns.csv   WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_noagro (contenido)
FROM :'BASE'/conjunto_de_datos_noagro_enigh2024_ns.csv          WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_noagroimportes (contenido)
FROM :'BASE'/conjunto_de_datos_noagroimportes_enigh2024_ns.csv  WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');
COPY ds2.ds2_staging_ingresos_jcf (contenido)
FROM :'BASE'/conjunto_de_datos_ingresos_jcf_enigh2024_ns.csv    WITH (FORMAT CSV, HEADER FALSE, QUOTE E'\b', DELIMITER E'\x01');

-- ===========================================================================
-- Catálogos INEGI: cada CSV tiene formato (codigo, descripcion). Se cargan
-- a una tabla intermedia y luego se enriquecen con `catalogo_nombre` mediante
-- un script Python auxiliar (no incluido en este SQL para mantener el flujo
-- 100% SQL). En la práctica:
--
--   for cat in data/raw/catalogos/*.csv:
--       psql ... <<EOF
--           CREATE TEMP TABLE _t (codigo TEXT, descripcion TEXT);
--           COPY _t FROM '$cat' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');
--           INSERT INTO ds2.ds2_staging_catalogo_inegi (catalogo_nombre, codigo, descripcion)
--           SELECT '$(basename $cat .csv)', codigo, descripcion FROM _t;
--       EOF
--
-- INTEGRATION.md documenta el wrapper bash que ejecuta esto sobre los 111
-- catálogos. Aquí incluimos a modo de ejemplo dos catálogos críticos:
-- ===========================================================================

DO $$
DECLARE
    cat_files TEXT[] := ARRAY[
        'entidad', 'parentesco', 'sexo', 'pais_nac', 'nivel', 'edo_conyug',
        'mat_pared', 'mat_techos', 'mat_pisos', 'tipo_viv', 'tenencia',
        'agua_ent', 'ab_agua', 'drenaje', 'combus', 'eli_basura',
        'si_no', 'si_no_nosabe',
        'habito', 'fenomeno', 'acc_alim18', 'frec_dicon', 'pago_dicon'
    ];
    cat_name TEXT;
BEGIN
    FOREACH cat_name IN ARRAY cat_files LOOP
        EXECUTE format($f$
            CREATE TEMP TABLE _t (codigo TEXT, descripcion TEXT);
            COPY _t FROM %L WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');
            INSERT INTO ds2.ds2_staging_catalogo_inegi
                   (catalogo_nombre, codigo, descripcion)
            SELECT %L, codigo, descripcion FROM _t;
            DROP TABLE _t;
        $f$, '/Users/davicho/Normalizacion/Proyecto-Final-main/normalizacion/dataset_2/data/raw/catalogos/' || cat_name || '.csv', cat_name);
    END LOOP;
END$$;

-- Conteos rápidos.
SELECT 'viviendas'        AS tabla, COUNT(*) AS filas FROM ds2.ds2_staging_viviendas        UNION ALL
SELECT 'hogares',          COUNT(*) FROM ds2.ds2_staging_hogares          UNION ALL
SELECT 'poblacion',        COUNT(*) FROM ds2.ds2_staging_poblacion        UNION ALL
SELECT 'ingresos',         COUNT(*) FROM ds2.ds2_staging_ingresos         UNION ALL
SELECT 'gastoshogar',      COUNT(*) FROM ds2.ds2_staging_gastoshogar      UNION ALL
SELECT 'concentradohogar', COUNT(*) FROM ds2.ds2_staging_concentradohogar UNION ALL
SELECT 'catalogo_inegi',   COUNT(*) FROM ds2.ds2_staging_catalogo_inegi;
