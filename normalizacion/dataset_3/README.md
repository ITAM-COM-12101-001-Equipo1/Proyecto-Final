# Dataset 3 — CONSAR (Sistema de Ahorro para el Retiro, México)

> Entregable de las **Etapas 1, 2 y 3** del proyecto de Bases de Datos Relacionales aplicado al tercer dataset: documentación, limpieza/staging y normalización hasta 4FN.
>
> Carpeta autocontenida. Nada fuera de `/normalizacion/dataset_3/` se modifica. Las instrucciones de integración con el resto del proyecto están en `INTEGRATION.md`.

---

# Etapa 1 — Documentación del dataset

## 1. Resumen

El dataset reúne 11 archivos publicados por la **Comisión Nacional del Sistema de Ahorro para el Retiro (CONSAR)** vía el portal de datos abiertos del gobierno mexicano (datos.gob.mx) y el repositorio operativo de la ATDT. Cada archivo cubre una serie temporal específica del SAR: precios de bolsa de las SIEFOREs (#01, #11), comisiones cobradas por las AFOREs (#06), traspasos entre AFOREs (#08), entradas y salidas de recursos (#04), cuentas administradas (#05), recursos por tipo (#09), rendimientos (#10), activos netos (#07), medidas de sensibilidad regulatorias (#03) y un agregado nacional anual sobre PEA vs cotizantes (#02).

Total: **~1.29 millones de filas** distribuidas en 11 archivos, con cobertura desde **enero 1997 hasta diciembre 2025**.

## 2. Origen y autoría

- **Publicador**: Comisión Nacional del Sistema de Ahorro para el Retiro (**CONSAR**), órgano desconcentrado de la Secretaría de Hacienda y Crédito Público (SHCP), México.
- **Distribución oficial**: portal **datos.gob.mx** (Datos Abiertos del Gobierno de México), replicado por la Agencia de Transformación Digital y Telecomunicaciones (**ATDT**) en `repodatos.atdt.gob.mx`.
- **URL canónica de cada archivo**:
  `https://repodatos.atdt.gob.mx/api_update/consar/{slug}/{archivo}`
- **Licencia**: CC-BY 4.0 (Datos Abiertos de México).

## 3. Justificación

El SAR concentra el ahorro para el retiro de la población económicamente activa de México. Los datos publicados por CONSAR permiten:

- Comparar el desempeño financiero de las AFOREs en distintas dimensiones (precios de gestión, rendimientos, comisiones).
- Vigilar la concentración de cuentas, traspasos y flujos.
- Cuantificar la exposición sistémica del SAR (medidas de sensibilidad #03, activos netos #07).
- Estudiar la cobertura del sistema (PEA vs cotizantes en #02).

Pedagógicamente, el dataset ofrece una mezcla rica de patrones de normalización: PKs compuestas con múltiples dimensiones, formato ancho que requiere pivot a 1FN, identidades contables verificables y curaduría de catálogos con etiquetas mixtas (afores reales vs agregados sentinel).

## 4. Disponibilidad y acceso

- **URL base**: <https://repodatos.atdt.gob.mx/api_update/consar/>
- **Slugs ATDT** (uno por archivo):

| # | Slug ATDT | Archivo CSV | Filas |
|---|---|---|---:|
| 01 | precios_bolsa_siefore | `01_precios_bolsa_siefores.csv` (publicado como `datosgob_01_*.csv`) | 635,167 |
| 02 | porcentaje_poblacion_economicamente_activa_cotiza_afore | `02_pea_vs_cotizantes_datos_abiertos_2024.csv` | 15 |
| 03 | medidas_sensibilidad_siefore | `03_medidas.csv` | 7,840 |
| 04 | flujo_recursos_afore | `04_entradas_salidas.csv` | 1,980 |
| 05 | cuentas_administradas_afore | `05_cuentas.csv` | 4,303 |
| 06 | comisiones_siefore | `06_comisiones.csv` | 2,080 |
| 07 | activos_netos_siefore | `07_activos_netos.csv` | 9,849 |
| 08 | traspasos_afore_afore | `08_traspasos.csv` | 3,200 |
| 09 | monto_recursos_registrados_afore | `09_recursos.csv` | 3,586 |
| 10 | rendimientos_afore | `10_rendimientos_precio_bolsa.csv` | 35,041 |
| 11 | precios_gestion_siefore | `11_precios_gestion_siefores.csv` | 588,318 |

- **Copia local**: `data/raw/datosgob_*.csv` (UTF-8, listos para `COPY`).

## 5. Periodicidad de actualización

- **Series diarias**: #01 y #11 (precios) — actualización al final de cada jornada bursátil.
- **Series mensuales**: #03–#10 — primer día de mes con corte al cierre de mes anterior.
- **Series anuales**: #02 (PEA) — un dato por año.

CONSAR publica actualizaciones acumulativas; cada CSV se refresca en bloque preservando la histórica.

## 6. Dimensiones

| Métrica | Valor |
|---|---|
| Archivos CSV | **11** |
| Filas totales (todos los archivos) | **~1,291,479** |
| Tamaño total CSV | ~46 MB |
| Encoding | UTF-8 (no requiere recodificación) |
| Rango temporal global | **1997-01-07 → 2025-12-06** |

## 7. Diccionario de datos

**Identificadores y dimensiones compartidas**:

| Campo | Naturaleza | Cardinalidad |
|---|---|---|
| `fecha` | Fecha (DATE) — diaria/mensual según archivo | Multivariada |
| `afore` | Categórico — AFORE comercial o etiqueta agregada | ~63 valores distintos (curados) |
| `siefore` | Categórico — Sociedad de Inversión | ~38 valores |
| `tipo_recurso` | Categórico — clasificación de activo/recurso | ~41 valores |
| `plazo` | Categórico — horizonte de retorno | 5 valores |

**Métricas por dataset**:

| Archivo | Métrica(s) | Tipo |
|---|---|---|
| #01, #11 | `precio` | NUMERIC(20,8) |
| #02 | `cotizantes`, `pea`, `porcentaje_pea_afore` | BIGINT, BIGINT, NUMERIC |
| #03 | 7 medidas de sensibilidad | NUMERIC |
| #04 | `montos_entradas`, `montos_salidas` | NUMERIC |
| #05 | 11 conteos (cuentas y trabajadores) | NUMERIC/BIGINT |
| #06 | `comision` (porcentaje anualizado) | NUMERIC(7,4) |
| #07, #09, #10 | `monto` (en dimensiones distintas) | NUMERIC |
| #08 | `num_tras_cedido`, `num_tras_recibido` | INTEGER |

## 8. Variables cuantitativas

| Métrica | Min | Max | Promedio aproximado |
|---|---:|---:|---:|
| Precio (#01) | 0.985 | 8.5+ | 2.x |
| Comisión (#06) | 0.49 | 1.96 | ~1.0 |
| Activos netos (#07) | 100 | 1,000,000+ (millones) | varía |
| Rendimiento (#10) | -10% | +25% | varía por plazo |

## 9. Variables cualitativas

`afore`, `siefore`, `tipo_recurso`, `plazo`, además de los nombres de columna que codifican métricas en los datasets anchos (#03, #05, #09).

## 10. Texto no estructurado

**Ninguno**. Todos los campos son escalares atómicos. Las descripciones de las dimensiones viven en los catálogos como cadenas cortas tipo `INITCAP(slug)`.

## 11. Series temporales

**Sí, todos los datasets excepto #02 son series temporales explícitas**, con `fecha` como atributo central:

- **Diarias**: #01 y #11 (precios bursátiles, cobertura 1997–2025).
- **Mensuales**: #03 (2019–2025), #04 (2009–2025), #05 (1997–2025), #06 (2008–2025), #07 (2019–2025), #08 (1998–2025), #09 (1998–2025), #10 (2019–2025).
- **Anual**: #02 (2010–2024, 15 años).

A diferencia de Dataset 1 y Dataset 2 (donde la serie temporal estaba ausente o implícita), aquí el modelo final tiene `fecha` (o `anio`) como parte de la PK del fact en cada tabla.

## 12. Visión estratégica

**Objetivo del análisis** (a definir en E4): el dataset permite responder, entre otras:

- ¿Cómo evoluciona el precio relativo de las SIEFOREs entre AFOREs en distintos horizontes (#01 vs #11)?
- ¿Qué AFOREs concentran el mayor flujo neto de cuentas (#04, #08)?
- ¿Hay una relación entre comisiones cobradas (#06) y rendimientos (#10) por AFORE?
- ¿Qué AFOREs muestran mayor exposición a riesgo (medidas #03)?
- ¿Cómo ha evolucionado la cobertura del SAR sobre la PEA (#02)?

**Cómo se implementa**: cada dataset tiene su propio fact con grano natural. Las dimensiones compartidas (AFORE, SIEFORE, tipo_recurso, plazo) viven en catálogos reutilizables, lo que permite joins directos para análisis cruzados entre datasets.

## 13. Consideraciones éticas

| Tema | Detalle |
|---|---|
| **Datos personales** | NULOS. CONSAR publica solo agregados por AFORE / fecha; no hay información identificable de cotizantes individuales. |
| **Sesgos comerciales** | Las AFOREs pueden re-marcarse o fusionarse (ej. Banamex → Citibanamex; Banorte adquiere XXI). El catálogo `cat_afore` preserva ambas etiquetas históricamente. |
| **Sentinels engañosos** | Algunas filas usan la columna `afore` para etiquetar agregados (`'total de cuentas administradas en el sar'`, `'sb pensiones promedio ponderado'`). Si no se filtran, se duplican totales en agregaciones. Resuelto con `cat_afore.es_agregado=TRUE` y tabla `ds3_agregado_observado`. |
| **Comparabilidad temporal** | La nomenclatura SIEFORE cambió en 2019 (transición a SIEFOREs Generacionales). Hay variantes históricas y actuales conviviendo en el catálogo. Cualquier análisis longitudinal debe contemplar la fusión semántica. |
| **Uso responsable** | Los rankings entre AFOREs basados en datos CONSAR son útiles, pero no deben presentarse como recomendación financiera personalizada — son agregados regulatorios. |

---

# Etapa 2 — Limpieza y staging

## Documentación de scripts

| Script | Qué hace |
|---|---|
| `sql/01_staging_create.sql` | Crea schema `ds3` + 11 tablas de staging (TEXT en todas las columnas). Replica EXACTAMENTE las columnas oficiales del CSV. Las columnas con espacios del #09 se preservan con comillas dobles. |
| `sql/02_staging_load.sql` | `TRUNCATE` + `COPY` para los 11 CSVs. Termina con conteo de cargados. |
| `sql/03_exploratory_analysis.sql` | Bloques A–H: PKs, rangos temporales, estadísticas, catálogos compartidos, redundancias (datasets anchos), distribuciones, nulos, sentinels, identidades contables preliminares. |
| `sql/04_normalized_schema.sql` | DDL del modelo en 4FN: 6 catálogos + 11 facts + 1 tabla auxiliar de sentinels. |
| `sql/05_migration.sql` | Carga catálogos primero (con curaduría `es_agregado`); luego 11 facts; pivots wide→long para #03/#05/#09 vía `LATERAL VALUES`. |
| `sql/06_verification.sql` | V1–V6: conteos, cardinalidades, integridad de pivots, FKs, **identidad contable #08** (`SUM(cedidos)=SUM(recibidos)`), balance #04. |

## Resultados del análisis exploratorio

### A. PKs naturales (verificadas empíricamente)

| Dataset | PK natural | Total = Distintos |
|---|---|---|
| #01 precios_bolsa | `(fecha, afore, siefore)` | 635,167 ✓ |
| #02 pea_cotizantes | `anio` | 15 ✓ |
| #03 medidas | `(fecha, siefore, afore)` (formato ancho con 7 métricas) | 7,840 ✓ |
| #04 entradas_salidas | `(fecha, afore)` | 1,980 ✓ |
| #05 cuentas | `(fecha, afore)` (formato ancho con 11 métricas) | 4,303 ✓ |
| #06 comisiones | `(fecha, afore)` | 2,080 ✓ |
| #07 activos_netos | `(fecha, tipo_recurso, afore)` | 9,849 ✓ |
| #08 traspasos | `(fecha, afore)` | 3,200 ✓ |
| #09 recursos | `(fecha, afore)` (formato ancho con 15 métricas) | 3,586 ✓ |
| #10 rendimientos | `(fecha, tipo_recurso, plazo, afore)` | 35,041 ✓ |
| #11 precios_gestion | `(fecha, afore, siefore)` | 588,318 ✓ |

Todos los PKs son únicos y válidos. **Diferencia con Dataset 2** (donde `gastoshogar` requirió surrogate): aquí los datasets sí tienen PKs naturales limpias.

### B. Rango temporal por dataset

Cobertura más larga: #01, #11 (1997–2025, ~28 años de precios diarios). Cobertura más corta: #03, #07, #10 (desde 2019).

### C. Estadísticas numéricas

Comisiones (#06): rango 0.49–1.96 % anualizado (ha bajado consistentemente desde 2008 cuando empezó la serie con valores >1.5%). Precios bolsa (#01): rango 0.985–8.5+ (las SIEFOREs maduras acumulan más valor). Activos netos: del orden de cientos de miles de millones de pesos.

### D. Catálogos compartidos

| Catálogo | Distintos | Comentario |
|---|---:|---|
| AFORE | 63 | Mezcla AFOREs comerciales (azteca, banamex, sura, xxi banorte, etc.) con sub-portfolios `(siav)`, `(sps1..10)`, `av1..3`, y **agregados** (`'total ...'`, `'... promedio ponderado'`). |
| SIEFORE | 38 | Variantes históricas (`sb 55-59`) y actuales (`siefore básica 55-59`). |
| TIPO_RECURSO | 26 (en #07, #10) + 15 (en #09) = 41 totales | Mezcla métricas regulatorias y tipos de fondo. |
| PLAZO | 5 | `12 meses, 24 meses, 36 meses, 5 años, historico`. |

### E. Columnas redundantes / formato ancho

3 datasets vienen ANCHOS y violan 1FN:

- **#03 medidas**: 7 columnas de métrica por fila → pivot a `ds3_medida_sensibilidad`.
- **#05 cuentas**: 11 columnas de conteo por fila → pivot a `ds3_cuenta_administrada`.
- **#09 recursos**: 15 columnas `monto_*` por fila → pivot a `ds3_recurso_afore` (reusa catálogo `tipo_recurso`).

### F. Distribución categórica (extracto)

Top AFOREs por presencia en #01: xxi-banorte, banamex, profuturo, sura, citibanamex (las más grandes del SAR moderno). Las series desaparecen y reaparecen conforme las AFOREs se fusionan (Banamex (siav2) discontinuó alrededor de 2019; xxi-banorte 1..10 son sub-portfolios temporales).

### G. Valores nulos

Datasets angostos (#01, #11, #06, #10, #07): nulos casi cero. Datasets anchos (#03, #05, #09): alta tasa de nulos por la naturaleza de "no toda métrica aplica a toda AFORE en toda fecha". El pivot wide→long los descarta naturalmente.

### H. Inconsistencias / sentinels detectados

| # | Inconsistencia | Detalle |
|---|---|---|
| H1 | Etiquetas agregadas en columna `afore` | ej. `'total de cuentas administradas en el sar'` (en #05), `'sb pensiones promedio ponderado'` (en #10), `'prestadora de servicios'` (en #09). NO son AFOREs comerciales. Resuelto con flag `es_agregado=TRUE` + tabla `ds3_agregado_observado`. |
| H2 | Sub-portfolios temporales | `xxi-banorte (sps1..sps10)`, `sura (siav1/2)`, `banamex (siav2)` — versiones históricas o sub-fondos. Quedan en el catálogo como entradas separadas; el equipo decidirá si fusionarlos. |
| H3 | Nomenclatura SIEFORE dual | `sb 55-59` (histórica) vs `siefore básica 55-59` (actual). Conservadas como dos slugs hasta validación con CONSAR. |
| H4 | Datasets anchos (3) | Violan 1FN — resuelto vía pivots wide→long. |

---

# Etapa 3 — Normalización hasta 4FN

## Resumen del modelo

**18 tablas** en 4FN: 4 catálogos primarios + 2 catálogos derivados (métricas) + 11 facts (uno por archivo) + 1 tabla auxiliar de sentinels (`ds3_agregado_observado`). Detalles paso a paso, ejemplos reales y prueba formal en `docs/normalization_steps.md`.

## Diagrama Entidad-Relación

- Versión renderizada: [`docs/erd.png`](docs/erd.png).
- Versión Mermaid editable: [`docs/erd.mermaid`](docs/erd.mermaid).

## Dependencias funcionales y multivaluadas

- DFs aceptadas (21) + rechazadas (6 con evidencia): [`docs/functional_dependencies.md`](docs/functional_dependencies.md).
- MVDs: análisis par por par con conclusión de **ausencia** (a diferencia de Dataset 2). [`docs/multivalued_dependencies.md`](docs/multivalued_dependencies.md).
- Pasos 1FN→2FN→3FN→BCNF→4FN con ejemplos reales del CSV: [`docs/normalization_steps.md`](docs/normalization_steps.md).

## Conteos esperados tras la migración

| Tabla | Filas |
|---|---:|
| `ds3_cat_afore` (incluye agregados) | ~63 |
| `ds3_cat_siefore` | ~38 |
| `ds3_cat_tipo_recurso` | ~41 |
| `ds3_cat_plazo` | 5 |
| `ds3_cat_metrica_sensibilidad` | 7 |
| `ds3_cat_metrica_cuenta` | 11 |
| `ds3_precio_bolsa` (#01) | hasta 635,167 (filtrando agregados) |
| `ds3_pea_cotizantes` (#02) | 15 |
| `ds3_medida_sensibilidad` (#03 post-pivot) | hasta ~55,000 |
| `ds3_flujo_recurso` (#04) | hasta 1,980 |
| `ds3_cuenta_administrada` (#05 post-pivot) | hasta ~30,000 |
| `ds3_comision` (#06) | hasta 2,080 |
| `ds3_activo_neto` (#07) | hasta 9,849 |
| `ds3_traspaso` (#08) | hasta 3,200 |
| `ds3_recurso_afore` (#09 post-pivot) | hasta ~50,000 |
| `ds3_rendimiento` (#10) | hasta 35,041 |
| `ds3_precio_gestion` (#11) | hasta 588,318 |
| `ds3_agregado_observado` | variable |

V1–V6 del script 06 confirman conteos, integridad y la identidad contable principal (#08: `SUM(cedidos)=SUM(recibidos)` por mes a nivel sistema).

## Identidades contables verificadas

1. **#08 Traspasos** (verificación V5): para cada mes, la suma de cuentas cedidas a nivel sistema debe igualar la suma de cuentas recibidas (todo traspaso cedido por una AFORE es recibido por otra).
2. **#04 Flujo de recursos** (verificación V6): flujo neto del sistema = entradas − salidas. No es identidad estricta, sí métrica derivada útil.
3. **#03/#05/#09 Pivots** (verificación V3): la suma agregada de cualquier columna del staging debe coincidir con la suma de la métrica correspondiente filtrada en el fact normalizado.

---

# Preguntas para el equipo

### Sobre el dataset y origen

1. **Catálogo curado vs no curado**: el `cat_afore` incluye 63 entradas, ~50 son AFOREs / sub-portfolios y ~13 son agregados sentinel. La regla heurística (`LIKE '%promedio ponderado%'`, etc.) acierta la mayoría pero ¿el equipo quiere revisar cada slug para reclasificar manualmente?
2. **Fusión histórica AFORE**: `Banamex` y `Citibanamex` aparecen como slugs separados (Banamex se renombró a Citibanamex en 2019). ¿Fusionar bajo el slug nuevo, conservar ambos (default actual), o agregar metadato `slug_canonico`?
3. **Sub-portfolios `(siav1)`, `(sps1..10)`, `av1..3`**: ¿son AFOREs distintas o variantes contables de la misma? Decisión pendiente.
4. **Nomenclatura SIEFORE dual**: ¿`sb 55-59` y `siefore básica 55-59` son la misma SIEFORE? CONSAR cambió la nomenclatura ~2019; el equipo debe confirmar la equivalencia.

### Sobre supuestos de modelado

5. **Surrogate vs PK natural en `cat_afore`**: usamos `id_afore SERIAL` con UNIQUE en `slug`. ¿Suficiente o el equipo prefiere `slug` como PK natural?
6. **Tabla `ds3_agregado_observado`**: preserva los sentinels en lugar de descartarlos. ¿OK o se eliminan completamente?
7. **`#09` reusa `cat_tipo_recurso`**: las 15 "métricas" del CSV son tipos de recurso conceptuales. ¿Está bien fusionar el catálogo de tipo_recurso con los slugs derivados, o crear un `cat_tipo_recurso_recursos` separado?
8. **`#02 pea_cotizantes` sin afore**: es un agregado nacional. Su grano es solo `anio`. ¿OK como tabla independiente o mover a una tabla "indicadores macro" más amplia (futura)?

### Sobre datos sospechosos

9. **#08 Identidad cedidos=recibidos**: si V5 falla en algunos meses (esperado en periodos antiguos por afores que ya no operan), ¿descartar esos meses o conservar con advertencia?
10. **Comisiones >100%**: el CHECK actual permite hasta 100%. ¿Suficiente o hay casos legítimos del histórico (cuando comisiones eran sobre saldo)? CONSAR cambió la base regulatoria varias veces.
11. **Precios negativos**: el modelo rechaza `precio<0`. ¿Hay valor histórico observado de precios negativos por casos de retiros forzosos? Validar con datos.

### Sobre integración

12. **Schema `ds3`**: confirma la convención.
13. **CSVs en repo**: ~46 MB total. Más manejable que ENIGH; el `.gitignore` actual los versiona. Confirmar.
14. **Re-ejecutar pipeline**: scripts son idempotentes (TRUNCATE + COPY + DROP CASCADE). Confirmar.
15. **Curaduría manual de catálogo AFORE**: requerirá ~30 min de revisión humana antes del entregable final. ¿Quién lo hace?
