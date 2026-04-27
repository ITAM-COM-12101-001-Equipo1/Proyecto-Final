# Integración del Dataset 2 (ENIGH 2024 NS) al proyecto principal

> Pasos numerados para que el equipo principal incorpore este entregable al
> repositorio y a la base de datos del proyecto, **sin riesgo para los
> datasets 1 y 3** y **sin tocar nada fuera de `/normalizacion/dataset_2/`**.

## 0. Prerrequisitos

- **PostgreSQL >= 12** con espacio en disco suficiente. La tabla
  `ds2_hogar_gasto` por sí sola tendrá ~5.3M filas; reservar ~3 GB
  conservadoramente para schema `ds2` con índices.
- Cliente `psql` accesible.
- Acceso al servidor con permisos para crear schemas, tablas y FKs.
- **`iconv`** disponible si los CSV originales vienen en Latin-1
  (lo habitual en INEGI).

## 1. Copiar la carpeta al repo principal

Si trabajas desde otra ubicación:
```bash
cp -R /Users/davicho/Normalizacion/Proyecto-Final-main/normalizacion/dataset_2 \
      ./normalizacion/dataset_2
```

La estructura final esperada:
```
<repo>/normalizacion/dataset_2/
├── README.md
├── INTEGRATION.md
├── data/raw/                                   ← 17 CSVs
│   ├── conjunto_de_datos_viviendas_*.csv
│   ├── conjunto_de_datos_hogares_*.csv
│   ├── conjunto_de_datos_poblacion_*.csv
│   ├── conjunto_de_datos_ingresos_*.csv
│   ├── conjunto_de_datos_gastoshogar_*.csv
│   └── ... (12 más)
│   └── catalogos/                              ← 111 catálogos INEGI
├── sql/01_staging_create.sql … 06_verification.sql
└── docs/
    ├── erd.png + erd.mermaid
    ├── functional_dependencies.md
    ├── multivalued_dependencies.md
    └── normalization_steps.md
```

## 2. Recodificar los CSVs (Latin-1 → UTF-8)

Los CSVs INEGI vienen en Windows-1252. Antes de cargar:

```bash
cd normalizacion/dataset_2/data/raw
for f in conjunto_de_datos_*.csv; do
    iconv -f WINDOWS-1252 -t UTF-8 "$f" > "_utf8_$f"
    mv "_utf8_$f" "$f"
done

# También para los catálogos:
for f in catalogos/*.csv; do
    iconv -f WINDOWS-1252 -t UTF-8 "$f" > "${f}.utf8" && mv "${f}.utf8" "$f"
done
```

Alternativa: editar `02_staging_load.sql` y cambiar `ENCODING 'UTF8'` por
`ENCODING 'WIN1252'` en cada `COPY`.

## 3. Ajustar las rutas absolutas en los scripts

Los scripts `02_staging_load.sql` y los `\set BASE` interno usan rutas
absolutas. Editar la primera línea con `\set BASE` para que apunte a la
ruta donde quedó tu `data/raw/`:

```sql
\set BASE '/ruta/a/repo/normalizacion/dataset_2/data/raw'
```

Si tu cliente psql ejecuta SQL contra un servidor remoto que NO tiene
acceso al filesystem local, sustituir `COPY` por `\COPY` (sintaxis psql,
sin punto y coma terminal).

## 4. Ejecutar el pipeline en orden

```bash
cd normalizacion/dataset_2
DB=proyecto_normalizacion

psql -d $DB -f sql/01_staging_create.sql
psql -d $DB -f sql/02_staging_load.sql           # ← carga ~880 MB de CSV
psql -d $DB -f sql/03_exploratory_analysis.sql   # opcional, informativo
psql -d $DB -f sql/04_normalized_schema.sql
psql -d $DB -f sql/05_migration.sql              # ← genera ~10M+ filas en el modelo
psql -d $DB -f sql/06_verification.sql
```

Tiempo estimado en hardware típico (laptop moderna):
- `02_staging_load`: 2–5 minutos.
- `05_migration`: 5–15 minutos (depende del IO; gastoshogar es la pieza pesada).

## 5. Verificación de éxito

Tras ejecutar `06_verification.sql`, validar:

| Verificación | Resultado esperado |
|---|---|
| V1: conteos staging vs normalizado en las 5 core | iguales |
| V2: cardinalidad catálogos | ≥ los esperados (32, 60, 2, 12, 9, 20, 17, 7, 7, 8, …) |
| V3: SUM(ing_tri) y SUM(gasto) idénticos | true / true |
| V4: FKs rotas | 0 en todas las verificaciones |
| V5: tablas puente vs no-nulos del staging | iguales |
| V6: reconstrucción ancha de muestra | filas legibles con descripciones de catálogo |

## 6. Aislamiento

- Schema `ds2` separado del `ds1` (Dataset 1) y de cualquier `ds3` futuro.
- Todas las tablas usan prefijo `ds2_`.
- No se asume nada del schema `public` ni de tablas existentes.

## 7. Rollback

```sql
DROP SCHEMA ds2 CASCADE;
```

Esto borra todas las tablas de staging, catálogos y modelo normalizado del
Dataset 2. No afecta `ds1` ni nada más en la BD.

## 8. Notas para el README principal del proyecto

Sugerencia de línea a añadir bajo "Datasets" en el README raíz (no por
este equipo, sino por quien centralice el repo):

> - **Dataset 2 — ENIGH 2024 NS (INEGI)** → ver
>   `normalizacion/dataset_2/README.md`. Schema `ds2`, ~28 tablas en 4FN,
>   ~7.2 M registros migrados.

## 9. Pendientes para ratificación

Ver la sección **"Preguntas para el equipo"** al final de `README.md` (17
preguntas explícitas). Las más críticas para integración:

- **Q4** (alcance: ¿incluir concentradohogar o trabajos?).
- **Q5** (¿añadir descomposición de `disc_*` antes del entregable final?).
- **Q14** (recursos del servidor para `gastoshogar` 5.3M filas).
- **Q15** (versionado del CSV ~880 MB en Git).
- **Q17** (encoding: recodificar a UTF-8 vs `WIN1252` en COPY).
