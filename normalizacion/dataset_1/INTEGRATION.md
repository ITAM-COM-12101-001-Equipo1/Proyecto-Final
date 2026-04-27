# Integración del Dataset 1 al proyecto principal

> Pasos numerados para que el equipo principal incorpore este entregable al
> repositorio y a la base de datos del proyecto, **sin riesgo para datasets
> 2 y 3** y **sin tocar nada fuera de `/normalizacion/dataset_1/`**.

## 0. Prerrequisitos

- PostgreSQL **>= 12** (probado mentalmente con sintaxis 12+; no usa nada de 14+).
- Cliente `psql` accesible en línea de comandos.
- Acceso al servidor con privilegios para crear schemas y tablas.
- Para la carga: el archivo CSV debe estar accesible desde el servidor (modo `COPY`)
  o desde el cliente que ejecuta `psql` (modo `\COPY`).

## 1. Copiar la carpeta al repo principal

```bash
# Desde la raíz del repo principal del proyecto:
cp -R /Users/davicho/Normalizacion/normalizacion/dataset_1 \
      ./normalizacion/dataset_1
```

La estructura debe quedar:

```
<repo>/
└── normalizacion/
    └── dataset_1/
        ├── README.md
        ├── INTEGRATION.md
        ├── data/raw/remuneraciones_da_qna_14_23.csv
        ├── sql/01..06.sql
        └── docs/
```

## 2. Verificar el CSV de entrada

```bash
file normalizacion/dataset_1/data/raw/remuneraciones_da_qna_14_23.csv
# Esperado: ASCII text  (UTF-8 ASCII-compatible)

wc -l normalizacion/dataset_1/data/raw/remuneraciones_da_qna_14_23.csv
# Esperado: 246822  (246,821 datos + 1 encabezado)
```

Si el archivo se actualiza desde el portal CDMX en otra fecha y vuelve a venir
en Windows-1252, recodificarlo antes de la carga:

```bash
iconv -f WINDOWS-1252 -t UTF-8 source.csv > \
  normalizacion/dataset_1/data/raw/remuneraciones_da_qna_14_23.csv
```

## 3. Ejecutar los scripts SQL en orden

Asumiendo que la BD destino se llama `proyecto_normalizacion` y el rol con
permisos es `postgres`:

```bash
cd normalizacion/dataset_1

psql -d proyecto_normalizacion -f sql/01_staging_create.sql
psql -d proyecto_normalizacion -f sql/02_staging_load.sql
psql -d proyecto_normalizacion -f sql/03_exploratory_analysis.sql   # opcional, informativo
psql -d proyecto_normalizacion -f sql/04_normalized_schema.sql
psql -d proyecto_normalizacion -f sql/05_migration.sql
psql -d proyecto_normalizacion -f sql/06_verification.sql
```

**Si el servidor no tiene acceso al filesystem del CSV**: editar
`02_staging_load.sql` y reemplazar `COPY ... FROM '/...'` por
`\COPY ... FROM '/...'` (sin el punto y coma final, según sintaxis psql), o
ejecutarlo desde un cliente psql que sí tenga el archivo.

## 4. Verificación de éxito

Tras ejecutar `06_verification.sql`, validar los siguientes resultados:

| Verificación | Resultado esperado |
|---|---|
| V1: `staging`, `remuneracion`, `persona` | 246,821 cada una |
| V2: cardinalidades de catálogos | 27, 73, 7, 11, 1772 |
| V3: `bruto_ok`, `neto_ok` | `true` y `true` |
| V4: huérfanas en ambos sentidos | 0 y 0 |
| V5: FKs rotas | 0 en las 6 verificaciones |
| V6: discrepancias staging ↔ normalizado | 0 |

## 5. Aislamiento respecto a datasets 2 y 3

Todos los objetos del dataset 1 viven bajo el **schema `ds1`** y todas las
tablas usan el **prefijo `ds1_`**. Datasets 2 y 3 deberán seguir la misma
convención (`ds2`, `ds3`) para garantizar coexistencia limpia. No se modificó
ni se asumió nada del schema `public` ni de tablas existentes.

## 6. Rollback (si fuese necesario)

```sql
-- Borra TODO el dataset 1 sin tocar otros schemas:
DROP SCHEMA ds1 CASCADE;
```

## 7. Notas para el README principal del proyecto

Se sugiere añadir, **en el README principal del repo (no por este equipo)**, una
línea bajo "Datasets" con el siguiente contenido:

> - **Dataset 1 — Remuneraciones del personal de la CDMX** → ver `normalizacion/dataset_1/README.md`. Esquema `ds1`, 7 tablas en 4FN, 246,821 registros migrados.

## 8. Pendientes que el equipo debe ratificar antes de la entrega final

Ver la sección **"Preguntas para el equipo"** al final de `README.md` (17
preguntas explícitas). Las más críticas para integración son:

- **Q4** (interpretación del rango temporal `qna_14_23`).
- **Q5** (política de deduplicación de personas).
- **Q15** (convención de schemas para datasets 2 y 3).
- **Q17** (modalidad de carga: server-side vs cliente).
