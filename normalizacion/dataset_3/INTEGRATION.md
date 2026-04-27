# Integración del Dataset 3 (CONSAR) al proyecto principal

> Pasos numerados para que el equipo principal incorpore este entregable al
> repositorio y a la base de datos del proyecto, **sin riesgo para los
> datasets 1 y 2** y **sin tocar nada fuera de `/normalizacion/dataset_3/`**.

## 0. Prerrequisitos

- **PostgreSQL >= 12**.
- Cliente `psql` accesible.
- Acceso al servidor con permisos para crear schemas, tablas y FKs.
- Espacio en disco: ~150–200 MB para schema `ds3` con índices (los precios
  diarios #01 y #11 son los más voluminosos).

## 1. Copiar la carpeta al repo principal

Si trabajas desde otra ubicación:
```bash
cp -R /Users/davicho/Normalizacion/Proyecto-Final-main/normalizacion/dataset_3 \
      ./normalizacion/dataset_3
```

Estructura esperada:
```
<repo>/normalizacion/dataset_3/
├── README.md
├── INTEGRATION.md
├── data/raw/datosgob_*.csv          ← 11 CSVs CONSAR (UTF-8)
├── sql/01_staging_create.sql … 06_verification.sql
└── docs/
    ├── erd.png + erd.mermaid
    ├── functional_dependencies.md
    ├── multivalued_dependencies.md
    └── normalization_steps.md
```

## 2. Verificación de los CSVs

```bash
cd normalizacion/dataset_3/data/raw
ls -la datosgob_*.csv | wc -l        # → 11
md5 -q datosgob_09_recursos.csv     # → 19083c9a46d9d958b1428056c2f5f0b1
```

El MD5 del archivo #09 (`19083c9a46d9d958b1428056c2f5f0b1`) puede usarse como
chek de integridad — coincide con el MD5 documentado por la ATDT.

A diferencia de Dataset 1 y Dataset 2, **NO requiere recodificación**:
los CSVs vienen en UTF-8 desde el portal.

## 3. Ajustar la ruta absoluta en `02_staging_load.sql`

El script usa `\set BASE '/Users/davicho/...'`. Cambiar a la ruta del repo en
tu máquina si es distinta.

Para servidores remotos sin acceso al filesystem local, sustituir `COPY` por
`\COPY` (sintaxis psql cliente).

## 4. Ejecutar el pipeline en orden

```bash
cd normalizacion/dataset_3
DB=proyecto_normalizacion

psql -d $DB -f sql/01_staging_create.sql
psql -d $DB -f sql/02_staging_load.sql           # carga ~46 MB total
psql -d $DB -f sql/03_exploratory_analysis.sql   # opcional, informativo
psql -d $DB -f sql/04_normalized_schema.sql
psql -d $DB -f sql/05_migration.sql              # ~2-3 minutos
psql -d $DB -f sql/06_verification.sql
```

Tiempo estimado en hardware típico: 3–5 minutos en total (mucho menor que
Dataset 2 — los CSVs son más chicos).

## 5. Verificación de éxito

| Verificación | Resultado esperado |
|---|---|
| V1: conteos staging vs fact | iguales (módulo filas con afore agregada que van a `ds3_agregado_observado`) |
| V2: cardinalidad de catálogos | ~63 / ~38 / ~41 / 5 / 7 / 11 |
| V3: pivot integrity | sumas idénticas en columna staging vs métrica fact |
| V4: FKs rotas | 0 |
| V5: identidad contable #08 (cedidos=recibidos por mes) | meses_no_cuadran=0 a nivel sistema (ver pregunta 9 del README) |
| V6: balance #04 (entradas vs salidas anual) | informativo |

## 6. Aislamiento

Schema `ds3` separado de `ds1` (Dataset 1) y `ds2` (Dataset 2).
Todas las tablas usan prefijo `ds3_`.
No se asume nada del schema `public` ni de tablas existentes.

## 7. Rollback

```sql
DROP SCHEMA ds3 CASCADE;
```

Borra todas las tablas de staging, catálogos y modelo normalizado del
Dataset 3. No afecta `ds1` ni `ds2`.

## 8. Notas para el README principal del proyecto

Sugerencia de línea a añadir bajo "Datasets" en el README raíz:

> - **Dataset 3 — CONSAR (Sistema de Ahorro para el Retiro)** → ver
>   `normalizacion/dataset_3/README.md`. Schema `ds3`, 18 tablas en 4FN,
>   ~1.29 M registros migrados. Identidad contable #08 verificada.

## 9. Pendientes para ratificación

Ver la sección **"Preguntas para el equipo"** al final de `README.md` (15
preguntas explícitas). Las más críticas para integración:

- **Q1** (curaduría manual del catálogo AFORE — sentinels vs reales).
- **Q2** y **Q4** (fusión Banamex/Citibanamex; nomenclatura SIEFORE dual).
- **Q9** (política para meses donde la identidad contable #08 no cuadra).
- **Q15** (¿quién hace la curaduría manual?).
