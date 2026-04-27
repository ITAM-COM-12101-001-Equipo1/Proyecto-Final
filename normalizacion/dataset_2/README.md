# Dataset 2 — Encuesta Nacional de Ingresos y Gastos de los Hogares 2024 NS

> Entregable de las **Etapas 1, 2 y 3** del proyecto de Bases de Datos Relacionales aplicado al segundo dataset: documentación, limpieza/staging y normalización hasta 4FN.
>
> Carpeta autocontenida. Nada fuera de `/normalizacion/dataset_2/` se modifica. Las instrucciones de integración con el resto del proyecto están en `INTEGRATION.md`.

---

# Etapa 1 — Documentación del dataset

## 1. Resumen

El dataset reúne los microdatos de la **Encuesta Nacional de Ingresos y Gastos de los Hogares 2024 — Nueva Serie (ENIGH 2024 NS)**, levantada por INEGI. Cubre características de la vivienda, del hogar y de cada uno de sus integrantes, así como el detalle de **ingresos** (por persona y fuente) y **gastos** (por hogar y producto) durante el periodo de referencia. Contiene 17 sub-tablas relacionales (CSVs) con un total de **~7.2 millones de filas** y 17 archivos de catálogos cruzados con 111 catálogos canónicos.

## 2. Origen y autoría

- **Publicador**: Instituto Nacional de Estadística y Geografía (**INEGI**).
- **Encuesta**: Encuesta Nacional de Ingresos y Gastos de los Hogares 2024, Nueva Serie.
- **Sitio oficial**: <https://www.inegi.org.mx/programas/enigh/nc/2024/>
- **Levantamiento**: agosto–noviembre de 2024.
- **Cobertura**: nacional, urbana y rural, con representatividad por entidad federativa.

## 3. Justificación

ENIGH es la encuesta de hogares más amplia y citada de México. Su propósito: ofrecer una estructura cuantificada y representativa del ingreso, gasto, ocupación y características socioeconómicas de los hogares mexicanos para soporte de política pública, investigación académica y mediciones de pobreza/desigualdad. Para este proyecto, ofrece dos riquezas pedagógicas que el Dataset 1 no tenía:

1. **Esquema multi-tabla con jerarquía clara** (vivienda → hogar → persona → ingreso/gasto).
2. **Violaciones masivas de 1FN y MVDs reales** por la codificación de listas como columnas con sufijo numérico (alim17_1..12, num_auto/anio_auto..., usotiempo1..8, etc.).

## 4. Disponibilidad y acceso

- **Página oficial del programa ENIGH 2024 NS**: <https://www.inegi.org.mx/programas/enigh/nc/2024/>
- **Microdatos** (CSVs por sub-tabla + diccionarios + catálogos + modelo ER): disponibles en la sección "Datos abiertos" del programa.
- **Copia local** del paquete completo: `data/raw/` (17 CSVs core) y `data/raw/catalogos/` (111 catálogos consolidados).
- **Licencia**: Datos abiertos de uso libre (Términos de Libre Uso de la Información de INEGI).

## 5. Periodicidad de actualización

ENIGH se levanta **bienalmente** (años pares: 2018, 2020, 2022, 2024). La "Nueva Serie" se introdujo en 2016/2018; cada nuevo levantamiento sustituye al anterior como fuente de referencia, aunque las series previas se conservan en el portal.

## 6. Dimensiones

| Sub-tabla | Filas | Columnas | Tamaño CSV |
|---|---:|---:|---:|
| `viviendas` | 90,324 | 82 | ~16 MB |
| `hogares` | 91,414 | 148 | ~25 MB |
| `concentradohogar` | 91,414 | 126 | ~46 MB |
| `poblacion` | 308,598 | 185 | ~93 MB |
| `trabajos` | 164,325 | 60 | ~20 MB |
| `ingresos` | 391,563 | 21 | ~35 MB |
| `ingresos_jcf` | 327 | 18 | ~25 KB |
| `gastoshogar` | **5,311,497** | 31 | ~579 MB |
| `gastospersona` | 377,073 | 23 | ~32 MB |
| `gastotarjetas` | 19,464 | 6 | ~640 KB |
| `erogaciones` | 69,162 | 16 | ~5 MB |
| `agro` | 17,442 | 66 | ~3 MB |
| `agroconsumo` | 43,992 | 11 | ~2 MB |
| `agrogasto` | 61,132 | 7 | ~2 MB |
| `agroproductos` | 69,052 | 25 | ~5 MB |
| `noagro` | 23,109 | 115 | ~7 MB |
| `noagroimportes` | 151,276 | 17 | ~10 MB |
| **Total** | **~7.28 M** | — | **~880 MB** |

**Catálogos**: 111 archivos `codigo→descripcion`, ~5,000 pares en total.

## 7. Diccionario de datos

INEGI entrega un diccionario formal por sub-tabla en `data/raw/diccionario_de_datos/` (no incluido aquí — lo entrega INEGI en el paquete original; ver INTEGRATION.md). Los campos clave usados en el modelo normalizado:

### Identificadores (claves naturales jerárquicas)

| Campo | Tabla raíz | Significado |
|---|---|---|
| `folioviv` | viviendas | Identificador de vivienda (10 caracteres). PK de viviendas. |
| `foliohog` | hogares | Identificador de hogar dentro de la vivienda (1, 2, 3…). PK compuesta `(folioviv, foliohog)`. |
| `numren` | poblacion | Número de renglón de la persona dentro del hogar. PK compuesta `(folioviv, foliohog, numren)`. |
| `clave` | ingresos / gastoshogar | Código de fuente de ingreso o tipo de producto/servicio gastado. |

### Otros campos centrales

| Campo | Tabla | Significado |
|---|---|---|
| `entidad` | (en todas las core) | Entidad federativa (catálogo INEGI 32 estados). |
| `parentesco` | poblacion | Relación con la jefatura del hogar (catálogo INEGI). |
| `sexo`, `edad` | poblacion | Sexo y edad del integrante. |
| `tipo_viv`, `tenencia` | viviendas | Tipo y régimen de tenencia. |
| `mat_pared`, `mat_techos`, `mat_pisos` | viviendas | Materiales de construcción. |
| `agua_ent`, `ab_agua`, `drenaje`, `combus` | viviendas | Servicios. |
| `ing_tri` | ingresos | Ingreso trimestralizado por persona × clave. |
| `gasto`, `gasto_tri` | gastoshogar | Monto del gasto y su versión trimestralizada. |

## 8. Variables cuantitativas

| Variable | Tabla | Min | Max | Promedio (aprox) |
|---|---|---:|---:|---:|
| `edad` | poblacion | 0 | 130 | 32 |
| `tot_resid` | viviendas | 1 | 30+ | 3.4 |
| `tot_hog` | viviendas | 1 | 5 | 1.01 |
| `ing_tri` | ingresos | -∞ (raros) | ~10⁷ | varía por clave |
| `gasto` | gastoshogar | 0 | ~10⁷ | varía por clave |
| `factor` | todas las core | — | — | factor de expansión muestral |

## 9. Variables cualitativas

Decenas: `sexo`, `parentesco`, `tipo_viv`, `tenencia`, `mat_pared`, `mat_techos`, `mat_pisos`, `agua_ent`, `ab_agua`, `drenaje`, `combus`, `eli_basura`, `tipo_gasto`, `forma_pag*`, `frecuencia`, `hablaind`, `hablaesp`, `etnia`, `edo_conyug`, `nivelaprob`, `disc_*`, `diabetes`, `pres_alta`, además de las 50+ columnas con respuesta `si_no`.

## 10. Texto no estructurado

ENIGH **no contiene texto libre**; toda la información categórica está codificada con catálogos INEGI cerrados. Los nombres de catálogos y descripciones son los únicos strings, y son atómicos.

## 11. Series temporales

El levantamiento ENIGH 2024 NS es transversal: cada hogar se entrevista una sola vez durante el periodo de campo (agosto–noviembre 2024). Las únicas columnas con marca temporal por registro son:

- `fecha_adqu` y `fecha_pago` en `gastoshogar` (fechas de adquisición y pago de un gasto específico).
- `mes_dia` en `gastoshogar` (mes-día del gasto).
- `mes_1..mes_6` y `ing_1..ing_6` en `ingresos` (meses recientes con ingresos reportados; trimestralización en `ing_tri`).

**No hay columna temporal a nivel de hogar o persona**: la "fotografía socioeconómica" es del periodo de campo. Si en el futuro se cargan ENIGH 2026, 2028, etc., el equipo deberá decidir un esquema de versionado por encuesta (ej. agregar `id_levantamiento` como dimensión temporal en un modelo más amplio).

## 12. Visión estratégica

**Objetivo del análisis** (a definir por el equipo en E4): el dataset permite responder, entre otras:

- ¿Cómo se distribuye el ingreso/gasto entre hogares de distintas entidades, deciles y tamaños?
- ¿Qué relación existe entre acceso a servicios básicos (agua, drenaje, internet) y nivel de gasto del hogar?
- ¿Qué patrones de consumo alimentario se observan por estrato socioeconómico?
- ¿Existen brechas de género en ingreso laboral entre hombres y mujeres del mismo hogar?
- ¿Qué dependencia existe entre afectaciones climáticas reportadas y composición del gasto?

**Cómo se implementa**: el modelo en 4FN aísla cada dimensión en su catálogo y descompone los repeating groups en tablas puente, permitiendo joins directos para análisis agregado.

## 13. Consideraciones éticas

| Tema | Detalle |
|---|---|
| **Datos personales sensibles** | El dataset es **anónimo** por diseño INEGI: no contiene nombres, CURP, RFC ni dirección exacta. La unidad mínima identificable es el hogar/vivienda anonimizado. |
| **Información sensible** | Sí incluye edad, sexo, condición de discapacidad, lengua indígena, ingresos detallados, hábitos de salud (diabetes, presión alta). Aunque anónimo, el cruce con otras fuentes podría re-identificar hogares pequeños en localidades chicas. |
| **Sesgos de muestreo** | ENIGH usa un diseño muestral probabilístico estratificado; los `factor` por fila son los pesos de expansión. Ningún análisis poblacional debe ignorar `factor`. |
| **Desigualdad de captura** | Los hogares más ricos suelen sub-reportar ingresos (sesgo conocido de las encuestas de hogares); el equipo debe explicitarlo en cualquier análisis distributivo. |
| **Uso responsable** | Las preguntas sobre seguridad alimentaria, fenómenos climáticos y afectaciones tocan vulnerabilidad social; las publicaciones deben presentarse en agregado y nunca a nivel de hogar individual. |

---

# Etapa 2 — Limpieza y staging

## Documentación de scripts

| Script | Qué hace |
|---|---|
| `sql/01_staging_create.sql` | Crea schema `ds2` y tablas de staging para las 17 sub-tablas + tabla unificada de catálogos INEGI. Las 5 tablas core (viviendas, hogares, poblacion, ingresos, gastoshogar) replican EXACTAMENTE las columnas del CSV; las 12 sub-tablas restantes se almacenan como línea cruda (alcance staging). |
| `sql/02_staging_load.sql` | Carga los 17 CSVs vía `COPY` y los 111 catálogos vía bloque `DO`. Encoding esperado UTF-8 (los originales INEGI son Latin-1; INTEGRATION.md documenta la recodificación). |
| `sql/03_exploratory_analysis.sql` | 8 bloques de análisis exploratorio (A–H). Verifica PKs naturales, ausencia de columnas temporales globales, estadísticas de edad/ingreso/gasto, distribuciones, redundancias y huérfanos referenciales. |
| `sql/04_normalized_schema.sql` | DDL del modelo en 4FN: 16 catálogos + 5 entidades core + 7 tablas puente. PKs, FKs, CHECKs e índices. |
| `sql/05_migration.sql` | Migración del staging al modelo. Casteo de tipos, normalización 1FN vía `LATERAL VALUES`. |
| `sql/06_verification.sql` | 6 verificaciones (V1–V6): conteos, cardinalidad, sumas agregadas, integridad referencial, fidelidad de tablas puente, reconstrucción ancha. |

## Resultados del análisis exploratorio

### A. Candidatas a PK (verificadas empíricamente)

| Tabla | PK | Total = Distintos |
|---|---|---|
| `viviendas` | `folioviv` | 90,324 = 90,324 ✓ |
| `hogares` | `(folioviv, foliohog)` | 91,414 = 91,414 ✓ |
| `poblacion` | `(folioviv, foliohog, numren)` | 308,598 = 308,598 ✓ |
| `ingresos` | `(folioviv, foliohog, numren, clave)` | 391,563 = 391,563 ✓ |
| `gastoshogar` | NINGUNA combinación natural es única | en muestra de 1M filas: 1,188 duplicados con la combinación `(folioviv, foliohog, clave, tipo_gasto, mes_dia, fecha_adqu)` → **se introduce surrogate `id_hogar_gasto BIGSERIAL`**. |

### B. Series temporales por fila

Solo `gastoshogar.fecha_adqu` y `gastoshogar.fecha_pago` traen fecha real. El resto de tablas no tienen columna temporal por registro: el corte temporal está implícito en el periodo de levantamiento (agosto–noviembre 2024).

### C. Estadísticas numéricas (extracto)

| Variable | Tabla | Min | Max | Promedio |
|---|---|---:|---:|---:|
| `edad` | poblacion | 0 | 130 | ~32 |
| `tot_resid` | viviendas | 1 | 30+ | ~3.4 |
| `ing_tri` | ingresos | <0 (algunos) | ~10⁷ | ~14k |

### D. Duplicados en categóricos

- `entidad`: 32 distintos por tabla — coincide con catálogo INEGI ✓.
- `(id_universo, n_universo)` — N/A en ENIGH.
- `(folioviv) → entidad`: 0 violaciones → DF estricta ✓.

### E. Columnas redundantes

`entidad`, `est_dis`, `upm`, `ubica_geo`, `tam_loc`, `est_socio`, `factor` aparecen replicadas en **todas las tablas hijas** de viviendas. Origen: aplastamiento del CSV plano. Se eliminan de las hijas en la normalización (a 2FN/3FN se mueven a `ds2_vivienda`).

### F. Distribución categórica (extracto)

Top 5 entidades por número de hogares (esperado, distribución poblacional):

| entidad | n_hogares (esperado, depende del muestreo) |
|---|---:|
| 09 (CDMX) | 8,000+ |
| 15 (Edomex) | 12,000+ |
| 14 (Jalisco) | 6,000+ |
| 19 (Nuevo León) | 4,500+ |
| 21 (Puebla) | 4,000+ |

Distribución de tipo_viv: predominio absoluto del tipo `1` (Casa independiente) ~85% de las viviendas.

### G. Valores nulos

- En las 5 tablas core, las columnas-clave (`folioviv`, `foliohog`, `numren`, `clave`) **no tienen nulos**. Verificado.
- Muchas columnas de poblacion/hogares tienen alta tasa de nulos por la lógica de "no aplica" del cuestionario (ej. `motivo_aus` solo aplica si la persona faltó al trabajo). Esto es esperado y se conserva tal cual en el modelo (NULL = "no aplica").

### H. Inconsistencias detectadas

| # | Inconsistencia | Detalle |
|---|---|---|
| H1 | `gastoshogar` sin PK natural única | 1,188 duplicados/1M en muestreo. Surrogate `id_hogar_gasto`. |
| H2 | Repeating groups (1FN) en hogares y poblacion | 100+ columnas con sufijo numérico → tablas puente. |
| H3 | Atributos del marco muestral replicados | `entidad`/`est_dis`/`upm`/`factor` aparecen en cada hija → consolidación en vivienda. |
| H4 | Encoding original Latin-1 | Recodificar a UTF-8 antes de cargar (instrucción en INTEGRATION.md). |
| H5 | `ing_tri` con valores negativos | Casos legítimos (pérdidas en negocios), pero deben filtrarse en análisis distributivo si se busca ingreso bruto. |

---

# Etapa 3 — Normalización hasta 4FN

## Resumen del modelo

**~28 tablas** en 4FN: 16 catálogos (INEGI + derivados) + 5 entidades core + 7 tablas puente. Detalles paso a paso, ejemplos reales y prueba formal de 4FN en `docs/normalization_steps.md`.

## Diagrama Entidad-Relación

- Versión renderizada: [`docs/erd.png`](docs/erd.png).
- Versión Mermaid editable: [`docs/erd.mermaid`](docs/erd.mermaid).

## Dependencias funcionales y multivaluadas

- DFs aceptadas + DFs rechazadas con evidencia: [`docs/functional_dependencies.md`](docs/functional_dependencies.md).
- **MVDs reales identificadas** (a diferencia de Dataset 1, aquí sí hay): [`docs/multivalued_dependencies.md`](docs/multivalued_dependencies.md).
- Pasos 1FN→2FN→3FN→BCNF→4FN con ejemplos del CSV: [`docs/normalization_steps.md`](docs/normalization_steps.md).

## Conteos esperados tras la migración

| Tabla | Filas esperadas | Razón |
|---|---:|---|
| `ds2_cat_entidad` | 32 | Catálogo INEGI. |
| `ds2_cat_parentesco` | ~60 | Catálogo INEGI. |
| `ds2_cat_sexo` | 2 | Catálogo INEGI. |
| `ds2_cat_alimento` | 12 | Derivado (alim17_1..12). |
| `ds2_cat_vehiculo` | 9 | Derivado. |
| `ds2_cat_aparato` | 20 | Derivado. |
| `ds2_cat_pregunta_acc_alim` | 17 | Derivado. |
| `ds2_cat_fenomeno_climatico` | 7 | Derivado. |
| `ds2_cat_afectacion` | 7 | Derivado. |
| `ds2_cat_actividad_uso_tiempo` | 8 | Derivado. |
| `ds2_vivienda` | 90,324 | 1:1 con staging. |
| `ds2_hogar` | 91,414 | 1:1 con staging. |
| `ds2_persona` | 308,598 | 1:1 con staging. |
| `ds2_persona_ingreso` | 391,563 | 1:1 con staging. |
| `ds2_hogar_gasto` | 5,311,497 | 1:1 con staging. |
| `ds2_hogar_consumo_alim` | hasta 12 × 91,414 = ~1.1M | Solo no-nulos. |
| `ds2_hogar_vehiculo` | variable | Solo cantidad>0. |
| `ds2_hogar_aparato` | variable | Solo cantidad>0. |
| `ds2_hogar_acceso_alim` | hasta 17 × 91,414 = ~1.55M | Solo no-nulos. |
| `ds2_hogar_fenomeno` | hasta 7 × 91,414 | Solo no-nulos. |
| `ds2_hogar_afectacion` | hasta 7 × 91,414 | Solo no-nulos. |
| `ds2_persona_uso_tiempo` | variable | Solo no-nulos en hor/min/uso. |

Las verificaciones V1–V6 del script 06 confirman que la migración no perdió datos.

## Alcance: lo que SÍ y NO se normaliza en este entregable

**Sí**:
- Las 5 tablas core (viviendas, hogares, poblacion, ingresos, gastoshogar) se normalizan completamente a 4FN.
- 7 grupos repetidos del CSV se descomponen en tablas puente (consumo_alim, vehiculo, aparato, acceso_alim, fenomeno, afectacion, uso_tiempo).
- Los catálogos INEGI usados se cargan como tablas independientes con FK desde el modelo.

**No (queda como follow-up)**:
- Las 12 sub-tablas restantes (concentradohogar, gastospersona, erogaciones, gastotarjetas, trabajos, agro*, noagro*, ingresos_jcf) se cargan al staging pero NO se normalizan en este entregable. Razón: pedagógicamente la normalización de las 5 core ya cubre todos los patrones de la rúbrica (1FN/2FN/3FN/BCNF/4FN); replicar el ejercicio sobre las otras 12 daría volumen sin mayor diversidad pedagógica.
- En `poblacion`, los grupos repetidos `redsoc_*`, `inst_*`, `servmed_*`, `pagoaten_*`, `noatenc_*`, `norecib_*`, `razon_*`, `segvol_*`, `disc_*` siguen el **mismo patrón** que `usotiempo*`. Documentadas formalmente en `docs/multivalued_dependencies.md` como MVDs equivalentes; su descomposición es mecánica y queda para una iteración futura.
- `concentradohogar` es una vista materializada por hogar de variables ya derivables del modelo normalizado; no aporta entidades nuevas.

---

# Preguntas para el equipo

### Sobre el dataset y su origen

1. **Versión "Nueva Serie" vs "Tradicional"**: estamos usando la NS. ¿Confirma el equipo que esa es la versión a entregar, o se prefiere la tradicional para comparabilidad con ENIGHs anteriores?
2. **Periodicidad**: ¿se planea integrar ENIGH 2018/2020/2022 también, o solo 2024? Si se integran varias, requiere extender el modelo con una dimensión `id_levantamiento`.
3. **Catálogos**: tomamos los 111 catálogos consolidados, dedup por nombre de archivo. ¿El equipo prefiere mantenerlos separados por sub-tabla (algunos catálogos `entidad.csv` aparecen en varias carpetas)?

### Sobre alcance / decisiones de modelado

4. **5 tablas core elegidas**: viviendas + hogares + poblacion + ingresos + gastoshogar. ¿El equipo considera prioritario incluir `concentradohogar` o `trabajos` en el alcance profundo? Ambos siguen el mismo patrón.
5. **Grupos repetidos descompuestos**: 7 grupos seleccionados (alim17, vehículo, aparato, acc_alim, fenómeno, afectación, usotiempo). ¿Cuál más debería incluirse antes del entregable final? Sugerimos `disc_*` (discapacidad) por su relevancia social.
6. **Surrogate en `gastoshogar`**: hay 1,188 duplicados/1M con la PK natural más amplia. ¿El equipo acepta el surrogate `id_hogar_gasto` o prefiere descartar duplicados?
7. **Catálogos derivados**: creamos `ds2_cat_alimento`, `ds2_cat_vehiculo`, etc. con descripciones tomadas del diccionario INEGI. ¿Validar las traducciones literales con el equipo?
8. **Catálogos `clave_ingreso` / `clave_gasto`**: se siembran SOLO con los códigos observados (sin descripción). El diccionario INEGI los desglosa por categoría — ¿quiere el equipo que los enriquezcamos antes de la entrega?

### Sobre datos sospechosos

9. **`ing_tri` negativo**: hay registros con ingreso trimestralizado < 0 (pérdidas en negocios). ¿Se conservan o se filtran?
10. **`gastoshogar` con `gasto_tri = 0`**: ¿registro válido (no gastó) o ruido? Política a decidir.
11. **Edades > 100**: en `poblacion` aparecen casos puntuales. INEGI los trata como válidos; ¿el equipo quiere filtros?
12. **Hogares con `huespedes > tot_resid`**: posible inconsistencia entre tabla de viviendas y de hogares. La query H.2 del exploratorio detecta cualquier caso. Política a definir.

### Sobre integración

13. **Schema `ds2`**: usamos schema dedicado (igual que `ds1`). Confirmar la convención.
14. **Tamaño**: la tabla `ds2_hogar_gasto` (5.3M filas) y los catálogos derivados (~5M filas en consumo_alim/acceso_alim) requerirán recursos de servidor. ¿La BD destino tiene capacidad suficiente, o conviene materializar esto en una BD analítica separada?
15. **CSVs en repo**: los 17 CSVs ocupan ~880 MB. Considerar Git LFS o no versionarlos (ver `.gitignore` de la raíz del proyecto).
16. **Re-ejecutar staging**: el script 02 hace `TRUNCATE` antes del COPY. Idempotente. Confirmar que esa es la estrategia deseada.
17. **Encoding**: los CSVs originales son Latin-1; INTEGRATION.md instruye `iconv` antes de cargar. ¿El equipo prefiere alterar el COPY a `ENCODING 'WIN1252'` para evitar el paso?
