# Formación de pensiones en México: salario, hogar y SAR — un análisis tri-capa

**Bases de Datos COM-12101-001 — Primavera 2026**

| Nombre | Matrícula |
|--------|-----------|
| David Fernando Avila Diaz | 197851 |
| Jose Roberto Uribe Clemente | 214129 |
| Emiliano Sebastian Millan Giffard | 214360 |
| Gerardo Andre Butron Ramirez | 217582 |

> Análisis comparado de tres fuentes de datos abiertos mexicanos para entender cómo se forma la capacidad de retiro digno en México: el salario que se gana, el ingreso–gasto que el hogar logra balancear, y el rendimiento que el SAR efectivamente entrega.

---

## 0. Evolución de la tesis (registro académico)

Esta sección documenta la trayectoria de la pregunta central del proyecto. Cada iteración se conserva — no se descarta — porque ilustra cómo el alcance de los datos disponibles esculpe la pregunta de investigación. **Cada tesis posterior absorbe a la anterior**, ampliando el ángulo en lugar de sustituirlo.

### §0.1 Tesis Original (Entrega 1) — IAS 19 / NIF D-3

- **Pregunta**: ¿Cuál es el pasivo laboral acumulado por antigüedad de los servidores públicos de la CDMX bajo el marco contable IAS 19 / NIF D-3 (primas de antigüedad y pasivos por terminación)?
- **Datos requeridos**: `fecha_ingreso`, tablas actuariales de mortalidad/rotación, supuestos de tasa de descuento.
- **Por qué evolucionó**: el dataset oficial publicado por el portal CDMX **no expone `fecha_ingreso`** ni ningún campo equivalente de antigüedad. Sin ese dato, cuantificar pasivos por antigüedad es imposible con esta única fuente.
- **Lo que se conserva**: el marco conceptual de "obligaciones de retiro / suficiencia futura" reaparece reforzado en la Tesis Final como **Q5 — proyección a 30 años de cohortes ilustrativas**. Y el PPTX de E1 se conserva en [`docs/Entrega1_Remuneraciones_CDMX_v2.pptx`](docs/Entrega1_Remuneraciones_CDMX_v2.pptx) como trazabilidad académica.

### §0.2 Tesis Intermedia — Brecha salarial y composición del gasto en la APCDMX

- **Pregunta**: ¿Cómo se distribuye el gasto en remuneraciones del Gobierno de la CDMX entre dependencias, universos y puestos, y qué brecha salarial por género se observa?
- **Datos requeridos**: solo Dataset 1 (Remuneraciones CDMX). Pregunta plenamente soportada por las 16 columnas disponibles.
- **Por qué evolucionó**: con la incorporación posterior de Dataset 2 (ENIGH 2024 NS) y Dataset 3 (CONSAR), la pregunta basada en un solo dataset queda **sub-dimensionada** respecto al alcance real del repositorio.
- **Lo que se conserva**: esta tesis es ahora **Q1** dentro de la Tesis Final — una de seis preguntas de investigación derivadas. Su núcleo (brecha salarial CDMX por sexo × sector × universo × puesto) es una pieza fundamental del análisis tri-capa.

### §0.3 Tesis Final — Formación tri-capa de pensiones

La tesis vigente del proyecto, expuesta en §1. Articula el espíritu de la tesis original (suficiencia para el retiro / obligaciones de largo plazo) usando los tres datasets disponibles, y orienta la narrativa hacia el ámbito de investigación sobre pensiones en México.

> **El alcance se amplió porque los datos disponibles permitieron una pregunta más rica, no más pobre.**

---

## 1. Tesis central

> **La capacidad de retiro digno en México se construye en tres capas desacopladas — el salario que se gana (CDMX como proxy del sector público), el ingreso-gasto que el hogar logra balancear (ENIGH como retrato del hogar mexicano), y el rendimiento que el SAR efectivamente entrega (CONSAR) — cuya brecha de género, suficiencia de ahorro y cobertura efectiva, analizadas en paralelo, revelan asimetrías estructurales en la formación de pensiones que ningún dataset aislado puede mostrar.**

### Por qué esta tesis y no otra

Conserva el espíritu de la Tesis Original (IAS 19: suficiencia de retiro y obligaciones laborales) reformulándolo como **análisis tri-capa de formación pensionaria**. Usa los 3 datasets sin forzarlos. Admite el desacople temporal y la ausencia de identificador común entre fuentes como **hallazgo metodológico**, no como debilidad. Y se alinea con los ejes que la literatura de pensiones en México valora — **cobertura, suficiencia, equidad** — sin pretender ser un estudio actuarial cerrado.

### Las tres capas

| Capa | Pregunta del nivel | Dataset principal |
|---|---|---|
| **Salario que se gana** | ¿Cuánto y con qué brecha cobran los trabajadores? | Dataset 1 — Remuneraciones CDMX |
| **Ingreso–gasto que se balancea** | ¿Qué fracción del ingreso queda disponible para ahorro de largo plazo? | Dataset 2 — ENIGH 2024 NS |
| **Rendimiento que el SAR entrega** | ¿Qué retorno real, comisión y cobertura logra el sistema de pensiones? | Dataset 3 — CONSAR |

### Seis preguntas de investigación derivadas

Cada pregunta se traduce 1:1 a una query SQL de E4 (ver §3 más abajo y `docs/tesis.md`):

| # | Pregunta | Capa | Schemas/tablas |
|---|---|---|---|
| **Q1** | ¿Cuál es la brecha salarial por sexo en CDMX, descompuesta por sector / universo / puesto, y qué universos concentran la mayor desventaja relativa? | Salario | `ds1_persona`, `ds1_remuneracion`, catálogos sector/universo/puesto |
| **Q2** | ¿Qué fracción del ingreso del hogar mexicano queda disponible para ahorro de largo plazo después del gasto corriente, por decil y composición demográfica? | Hogar | `ds2_hogar`, `ds2_persona_ingreso`, `ds2_hogar_gasto`, puente `acceso_alim` |
| **Q3** | ¿Cómo evolucionan rendimientos reales y comisiones del SAR por SIEFORE × tipo_recurso × plazo (1997–2025), y qué AFOREs sostienen rendimiento superior a su benchmark? | SAR | `ds3_rendimiento`, `ds3_comision`, `ds3_activo_neto` |
| **Q4** | ¿Qué cobertura efectiva tiene el SAR — cotizantes vs PEA — y qué nos dice el flujo de traspasos sobre la fricción del sistema? | SAR | `ds3_pea_cotizantes`, `ds3_cuenta_administrada`, `ds3_traspaso` |
| **Q5** | Combinando salario CDMX (Q1) × tasa de ahorro hogar (Q2) × rendimiento SAR (Q3), ¿cuál sería el saldo proyectado a 30 años para cohortes ilustrativas hombre / mujer? **Cohortes paralelas, no individuos enlazados.** | Tri-capa | `ds1.*` + `ds2.*` + `ds3_rendimiento` |
| **Q6** | ¿Qué SIEFOREs muestran mayor sensibilidad regulatoria y volatilidad de precios, y por tanto mayor riesgo para trabajadores próximos al retiro? | SAR | `ds3_medida_sensibilidad`, `ds3_precio_bolsa`, `ds3_precio_gestion` |

Mapeo completo pregunta → query → endpoint en [`docs/tesis.md`](docs/tesis.md).

---

## 2. Datasets en alcance

| # | Dataset | Origen | Filas | Tablas en 4FN | Capa |
|---|---|---|---:|---:|---|
| 1 | Remuneraciones CDMX | Datos Abiertos CDMX | 246,821 | 7 | Salario |
| 2 | ENIGH 2024 NS | INEGI | ~7.28 M | ~28 | Hogar |
| 3 | CONSAR (Sistema de Ahorro para el Retiro) | datos.gob.mx / ATDT | ~1.29 M | 18 | SAR |

Cada dataset tiene su carpeta autocontenida en `normalizacion/dataset_N/` con las 13 secciones de la rúbrica E1, los 6 scripts SQL (01–06), documentación de DFs/MVDs/normalización paso a paso, y ERD. Las **17 preguntas de validación al equipo** de cada dataset (Dataset 1, 2 y 3) se conservan en sus respectivos READMEs.

---

## 3. Entregas

| # | Entrega | Estado | Documento / Carpeta |
|---|---|---|---|
| E1 | Selección del dataset | Entregado (con tesis original; ver §0.1) | [`docs/Entrega1_Remuneraciones_CDMX_v2.pptx`](docs/Entrega1_Remuneraciones_CDMX_v2.pptx) |
| E2 | Limpieza y carga (staging) — Dataset 1 | **Entregado** | [`normalizacion/dataset_1/`](normalizacion/dataset_1/) |
| E2 | Limpieza y carga (staging) — Dataset 2 | **Entregado** | [`normalizacion/dataset_2/`](normalizacion/dataset_2/) |
| E2 | Limpieza y carga (staging) — Dataset 3 | **Entregado** | [`normalizacion/dataset_3/`](normalizacion/dataset_3/) |
| E3 | Normalización 4FN — Dataset 1 | **Entregado** | [`normalizacion/dataset_1/`](normalizacion/dataset_1/) |
| E3 | Normalización 4FN — Dataset 2 | **Entregado** | [`normalizacion/dataset_2/`](normalizacion/dataset_2/) |
| E3 | Normalización 4FN — Dataset 3 | **Entregado** | [`normalizacion/dataset_3/`](normalizacion/dataset_3/) |
| E4 | Análisis (8 queries SQL planeadas) | **Pendiente — alcance definido** | ver §3.1 |
| E5 | API REST FastAPI (10 endpoints planeados) | **Pendiente — alcance definido** | ver §3.2 |

### 3.1 Plan E4 — 8 queries SQL avanzadas

Cada query mapea a una pregunta de investigación de §1. La selección cubre los criterios de la rúbrica: window functions, agregaciones complejas, joins, y "atributos enriquecidos".

| # | Mapea a | Qué hace | Técnica clave |
|---|---|---|---|
| Q1a | Q1 | CTE sobre `ds1_remuneracion`: `AVG(neto)` por sexo × universo + `RANK() OVER` por brecha relativa entre universos | Window `RANK() OVER` |
| Q1b | Q1 | `PERCENTILE_CONT(0.5)` por sector × sexo en `ds1` para distinguir brecha de mediana vs. de cola distribucional | Funciones de percentil |
| Q2a | Q2 | `ds2_hogar` JOIN `ds2_persona_ingreso` JOIN `ds2_hogar_gasto`, `NTILE(10)` por decil de ingreso, tasa de ahorro = `(ingreso − gasto) / ingreso` | `NTILE` + agregaciones |
| Q2b | Q2 | Cruce `ds2_hogar_gasto` con puente `ds2_hogar_acceso_alim` → ¿inseguridad alimentaria correlaciona con tasa de ahorro estructuralmente nula? | Joins en bridge tables |
| Q3 | Q3 | `ds3_rendimiento` con `LAG(monto, 12)` y `AVG(monto) OVER (PARTITION BY siefore ORDER BY fecha ROWS 12 PRECEDING)` → rendimiento móvil 12m vs. benchmark del periodo | Window `LAG` + ventana móvil |
| Q4 | Q4 | JOIN `ds3_pea_cotizantes` × `ds3_cuenta_administrada` por año, ratio cotizantes/PEA, `LAG()` para delta interanual; UNION con flujo de `ds3_traspaso` | Window `LAG` + UNION |
| Q5 | Q5 | **Cross-schema ilustrativa**: CTE de salario por sexo (ds1) × tasa de ahorro mediana decil 5–7 (ds2) × rendimiento real anualizado SIEFORE básica (ds3) → proyección compuesta a 30 años. Documentado como **cohortes paralelas no enlazadas** | Joins por agregados, no por persona |
| Q6 | Q6 | `ds3_medida_sensibilidad` JOIN `ds3_precio_bolsa`, `STDDEV(precio) OVER` ventana móvil → ranking de SIEFOREs por riesgo | Window `STDDEV` |

Los scripts vivirán en `sql/e4_analisis/` cuando se entreguen.

### 3.2 Plan E5 — 10 endpoints REST FastAPI

Endpoints alineados con la tesis. Read-only para los analíticos; CRUD para `ds1.persona` (cumpliendo el requisito explícito de la rúbrica).

```
GET    /ds1/brecha-salarial?sector=&universo=&sexo=
GET    /ds1/ranking-puestos?top=&order=
GET    /ds2/tasa-ahorro?decil=&tamano_hogar=
GET    /ds2/composicion-gasto?decil=
GET    /ds3/rendimientos?siefore=&desde=&hasta=
GET    /ds3/comisiones-historico?afore=
GET    /ds3/cobertura?anio=
GET    /ds3/traspasos?afore_origen=&afore_destino=
GET    /proyeccion/saldo-30y?sexo=&decil=&siefore=    (Q5 cross-schema)
POST   /ds1/persona     +    PUT/DELETE /ds1/persona/{id}
```

Los scripts vivirán en `api/` cuando se entreguen.

---

## 4. Estructura del repositorio

```
Proyecto-Final/
├── README.md                                     ← este archivo
├── .gitignore
│
├── data/
│   ├── publico/
│   │   ├── WDF_remuneraciones_cdmx.csv           ← CSV oficial (~42 MB, Latin-1)
│   │   ├── CERTIFICATE.json                      ← certificación WDF (con discrepancia documentada)
│   │   └── README-DATASET.md
│   └── privado/
│       └── README-DATASET.md                     ← (en recopilación)
│
├── docs/
│   ├── tesis.md                                  ← tesis canónica + mapeo Q→query→endpoint
│   └── Entrega1_Remuneraciones_CDMX_v2.pptx      ← E1 (tesis original, conservado)
│
├── sql/
│   ├── e2_staging/01_carga_staging.sql           ← puntero a normalizacion/dataset_*/sql/01-02
│   ├── e3_normalizacion/01.ddl_4nf.sql           ← puntero a normalizacion/dataset_*/sql/04-06
│   ├── e4_analisis/                              ← (pendiente E4 — 8 queries)
│   └── e5_seed/                                  ← (pendiente E5)
│
├── normalizacion/                                ← E2 + E3 profundo por dataset
│   ├── dataset_1/                                ← Remuneraciones CDMX, 7 tablas en 4FN
│   ├── dataset_2/                                ← ENIGH 2024 NS, ~28 tablas en 4FN
│   └── dataset_3/                                ← CONSAR, 18 tablas en 4FN
│
├── conjunto_de_datos_enigh2024_ns_csv/           ← Paquete original INEGI (mantener intacto)
├── conjunto_datos_consar/                        ← Paquete original CONSAR (mantener intacto)
└── api/                                          ← (pendiente E5 — FastAPI)
```

---

## 5. Cómo replicar el pipeline (E2 + E3)

### Dataset 1 — CDMX

```bash
# 1. Recodificar el CSV de Latin-1 a UTF-8 (una vez).
iconv -f WINDOWS-1252 -t UTF-8 \
  data/publico/WDF_remuneraciones_cdmx.csv \
  > normalizacion/dataset_1/data/raw/remuneraciones_da_qna_14_23.csv

# 2. Ejecutar el pipeline.
DB=proyecto_normalizacion
for s in 01_staging_create 02_staging_load 03_exploratory_analysis \
         04_normalized_schema 05_migration 06_verification; do
    psql -d $DB -f normalizacion/dataset_1/sql/${s}.sql
done
```

### Dataset 2 — ENIGH 2024 NS

```bash
# 1. Recodificar los 17 CSVs (Latin-1 → UTF-8, una vez).
cd normalizacion/dataset_2/data/raw
for f in conjunto_de_datos_*.csv; do
    iconv -f WINDOWS-1252 -t UTF-8 "$f" > "_u_$f" && mv "_u_$f" "$f"
done
cd ../../../..

# 2. Ejecutar el pipeline.
DB=proyecto_normalizacion
for s in 01_staging_create 02_staging_load 03_exploratory_analysis \
         04_normalized_schema 05_migration 06_verification; do
    psql -d $DB -f normalizacion/dataset_2/sql/${s}.sql
done
```

### Dataset 3 — CONSAR

```bash
# Los CSVs ya vienen en UTF-8, no requieren recodificación.
DB=proyecto_normalizacion
for s in 01_staging_create 02_staging_load 03_exploratory_analysis \
         04_normalized_schema 05_migration 06_verification; do
    psql -d $DB -f normalizacion/dataset_3/sql/${s}.sql
done
```

Detalles operativos por dataset:
- [`normalizacion/dataset_1/INTEGRATION.md`](normalizacion/dataset_1/INTEGRATION.md)
- [`normalizacion/dataset_2/INTEGRATION.md`](normalizacion/dataset_2/INTEGRATION.md)
- [`normalizacion/dataset_3/INTEGRATION.md`](normalizacion/dataset_3/INTEGRATION.md)

---

## 6. Resumen de los modelos normalizados (E3)

### Dataset 1 — schema `ds1` (7 tablas)

| Tabla | Tipo | Filas |
|---|---|---:|
| `ds1_universo` | catálogo | 27 |
| `ds1_sector` | catálogo | 73 |
| `ds1_tipo_nomina` | catálogo (+`tipo_contratacion`) | 7 |
| `ds1_tipo_personal` | catálogo | 11 |
| `ds1_puesto` | catálogo | 1,772 |
| `ds1_persona` | entidad | 246,821 |
| `ds1_remuneracion` | hecho/asignación | 246,821 |

### Dataset 2 — schema `ds2` (~28 tablas)

5 entidades core + 7 tablas puente (1FN/4FN) + 16 catálogos (INEGI + derivados):

| Tabla | Tipo | Filas |
|---|---|---:|
| `ds2_vivienda` | entidad raíz | 90,324 |
| `ds2_hogar` | entidad | 91,414 |
| `ds2_persona` | entidad | 308,598 |
| `ds2_persona_ingreso` | hecho | 391,563 |
| `ds2_hogar_gasto` | hecho (surrogate PK) | 5,311,497 |
| `ds2_hogar_consumo_alim` | puente (1FN) | hasta ~1.1 M |
| `ds2_hogar_vehiculo` / `_aparato` | puentes (1FN) | variable |
| `ds2_hogar_acceso_alim` | puente (1FN) | hasta ~1.55 M |
| `ds2_hogar_fenomeno` / `_afectacion` | puentes (1FN) | hasta ~640 K c/u |
| `ds2_persona_uso_tiempo` | puente (4FN, MVD) | variable |
| `ds2_cat_*` | 16 catálogos | varios |

### Dataset 3 — schema `ds3` (18 tablas)

11 hechos (uno por archivo CONSAR) + 6 catálogos + 1 tabla auxiliar de sentinels:

| Tabla | Tipo | Filas |
|---|---|---:|
| `ds3_cat_afore` | catálogo (con flag `es_agregado`) | ~63 |
| `ds3_cat_siefore` | catálogo | ~38 |
| `ds3_cat_tipo_recurso` | catálogo | ~41 |
| `ds3_cat_plazo` | catálogo | 5 |
| `ds3_cat_metrica_sensibilidad` / `_cuenta` | catálogos derivados (post-pivot) | 7 / 11 |
| `ds3_precio_bolsa` (#01) | hecho (diario) | 635,167 |
| `ds3_precio_gestion` (#11) | hecho (diario) | 588,318 |
| `ds3_rendimiento` (#10) | hecho (mensual, dim. plazo + tipo_recurso) | 35,041 |
| `ds3_activo_neto` (#07) | hecho | 9,849 |
| `ds3_medida_sensibilidad` (#03 post-pivot) | hecho 1FN | ~55 K |
| `ds3_recurso_afore` (#09 post-pivot) | hecho 1FN | ~50 K |
| `ds3_cuenta_administrada` (#05 post-pivot) | hecho 1FN | ~30 K |
| `ds3_traspaso` (#08) | hecho (identidad cedidos=recibidos verificada) | 3,200 |
| `ds3_comision` (#06), `ds3_flujo_recurso` (#04), `ds3_pea_cotizantes` (#02) | hechos | varios |
| `ds3_agregado_observado` | sentinels preservados | variable |

ERDs por dataset: [`normalizacion/dataset_1/docs/erd.png`](normalizacion/dataset_1/docs/erd.png), [`dataset_2/docs/erd.png`](normalizacion/dataset_2/docs/erd.png), [`dataset_3/docs/erd.png`](normalizacion/dataset_3/docs/erd.png).

---

## 7. Riesgos metodológicos del análisis tri-capa

El análisis cruza tres datasets con grano, temporalidad y unidad de observación distintos. Esa es **la fuente de su poder y de su fragilidad** simultáneamente. Documentamos honestamente los riesgos para que el evaluador pueda calibrar el alcance de cualquier afirmación derivada de Q5 (la pregunta cross-schema).

| Riesgo | Mitigación |
|---|---|
| **No existe PK común entre schemas**: no se puede enlazar `ds1.persona` con `ds2.persona` ni con un cotizante de `ds3`. | **Q5 opera sobre cohortes paralelas ilustrativas, no individuos enlazados.** La proyección a 30 años es **indicativa, no causal**. Cualquier comparación se hace sobre agregados (sexo, decil, año), nunca sobre identificadores ficticios. |
| **Temporalidades dispares**: CDMX es un corte único (qna_14_23, año implícito); ENIGH es 2024; CONSAR es serie 1997–2025. | Cada query declara su ventana temporal explícitamente. Q5 fija año de referencia 2024 para alinear con ENIGH; CDMX se usa como proxy salarial con el corte disponible; CONSAR aporta el rendimiento histórico de la SIEFORE básica. |
| **CDMX cubre solo sector público sub-nacional**: 246k servidores públicos de la CDMX, no del país. | Documentado como **proxy del sector público**; ENIGH cubre el universo amplio (público + privado + informal). La comparativa público/privado se presenta con honestidad de alcance, no como muestra representativa nacional del sector público. |
| **Tentación de inventar joins cross-schema**. | **Política explícita del proyecto**: ningún JOIN cross-schema sin columna real compartida. Todo cruce es por agregados (sexo, decil, año). Si un análisis requiere enlazar individuos, no se hace. |
| **El SAR cubre régimen de contribución definida (post-1997)**: trabajadores con régimen anterior (Ley 73 IMSS, ISSSTE viejo) no están en CONSAR. | Documentado en cada query que toca CONSAR. Q4 usa `pea_cotizantes` para contextualizar la cobertura efectiva del sistema. |

### Lo que NO afirma este proyecto

- No afirma causalidad entre brecha salarial CDMX y suficiencia pensionaria individual.
- No es un estudio actuarial. Q5 es una proyección ilustrativa, no una recomendación financiera.
- No reemplaza fuentes oficiales del SAR, INEGI o CONSAR para análisis de política pública. Es un ejercicio académico de modelado relacional sobre datos abiertos.

---

## 8. Pendientes y notas para el equipo

- **E4 — Análisis**: 8 queries SQL ya planeadas en §3.1, una por pregunta de investigación. Arrancar por Q1a (brecha salarial CDMX) por ser la más reproducible y el ancla histórica del proyecto.
- **E5 — API REST**: 10 endpoints ya planeados en §3.2. El modelo en 4FN está listo; cada endpoint mapea a una query de E4 o a un CRUD de catálogo.
- **Certificado WDF**: decidir si actualizar `data/publico/CERTIFICATE.json` para reflejar el SHA real del CSV de Dataset 1 (`c55960ba…`) o conservar la versión histórica como evidencia del cambio de alcance.
- **Dataset privado** (`data/privado/`): aún en recopilación. Si su ingesta se materializa, replicar la estructura `normalizacion/dataset_N/` con prefijo de schema dedicado.
- **Preguntas de validación al equipo por dataset**:
  - Dataset 1 (17 preguntas): final de [`normalizacion/dataset_1/README.md`](normalizacion/dataset_1/README.md).
  - Dataset 2 (17 preguntas): final de [`normalizacion/dataset_2/README.md`](normalizacion/dataset_2/README.md).
  - Dataset 3 (15 preguntas): final de [`normalizacion/dataset_3/README.md`](normalizacion/dataset_3/README.md).
- **Orientación temática hacia el Premio de Investigación sobre Pensiones 2026**: la tesis tri-capa se redactó pensando en alimentar, en una fase posterior y separada del entregable académico, una postulación al premio. Este repo NO postula al premio; solo orienta su narrativa académica hacia los ejes que el premio valora (cobertura, suficiencia, equidad).
