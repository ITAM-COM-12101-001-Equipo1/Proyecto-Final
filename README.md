# Obligaciones Laborales: Analisis IAS 19 / NIF D-3

**Bases de Datos COM-12101-001 - Primavera 2026**

| Nombre | Matricula |
|--------|-----------|
| David Fernando Avila Diaz | 197851 |
| Jose Roberto Uribe Clemente | 214129 |
| Emiliano Sebastian Millan Giffard | 214360 |
| Gerardo Andre Butron Ramirez | 217582 |

## Dataset

Remuneraciones de **246,820 servidores publicos** de la CDMX (17 atributos, ~45 MB CSV).

- **Fuente:** [Datos Abiertos CDMX](https://datos.cdmx.gob.mx/dataset/remuneraciones-al-personal-de-la-ciudad-de-mexico/resource/7f0d7073-6861-4d8c-9ca5-17ebe3ff2388)
- **Certificacion:** WDF (`data/publico/CERTIFICATE.json`)
- **SHA-256:** `e88d0ae870c3ebb556c2c78f9e51e48bb8fd98740579a79141923dac71b91648`

## Entregas

| # | Entrega | Documento |
|---|---------|-----------|
| E1 | Seleccion del dataset | [`docs/E1_dataset.md`](docs/Entrega1_Remuneraciones_CDMX_v2.pptx) |
| E2 | Limpieza y carga | *pendiente* |
| E3 | Normalizacion | *pendiente* |
| E4 | Analisis | *pendiente* |
| E5 | API REST | *pendiente* |

## Estructura

```
Proyecto-Final/
├── README.md
├── data/
│   ├── publico/
│   │   ├── WDF_remuneraciones_cdmx.csv    # Dataset CDMX (45 MB, 246,820 registros)
│   │   ├── CERTIFICATE.json               # Certificacion WDF con SHA-256
│   │   └── README-DATASET.md              # Ficha tecnica del dataset
│   └── privado/                           # (en recopilacion)
├── sql/
│   ├── e2_staging/                        # E2: Scripts de staging + EDA
│   ├── e3_normalizacion/                  # E3: DDL + migracion + FDs
│   ├── e4_analisis/                       # E4: Queries avanzadas
│   └── e5_seed/                           # E5: Seed data para API
├── api/                                   # E5: FastAPI CRUD
├── docs/
│   ├── E1_dataset.md                      # E1: Seleccion del dataset
│   ├── presentaciones/
│   │   └── Entrega1_Remuneraciones_CDMX_v2.pptx
│   └── diagramas/                         # E3: Diagrama ER
└── .gitignore
```



# Análisis de Obligaciones Laborales CDMX (IAS 19 / NIF D-3)

## 1. Selección del Conjunto de Datos (Entrega 1)

* **Resumen:** Este proyecto analiza las remuneraciones de los servidores públicos de la Ciudad de México para modelar obligaciones laborales y simular pasivos (como primas de antigüedad y aguinaldos).
* **Origen y Autoría:** Gobierno de la CDMX (Datos Abiertos), con certificación de World Data Foundation.
* **Justificación:** Cuantificar el posicionamiento del servidor público dentro de la distribución de ingresos a nivel nacional y estimar costos de terminación por dependencia.
* **Disponibilidad y Acceso:** [Portal de Datos Abiertos CDMX](https://datos.cdmx.gob.mx/dataset/remuneraciones-al-personal-de-la-ciudad-de-mexico/resource/7f0d7073-6861-4d8c-9ca5-17ebe3ff2388)
* **Dimensiones:** 246,821 registros y 17 atributos (73 sectores, 1,772 puestos).

### Diccionario de Datos (Muestra)
* **Cuantitativas:** `edad` (16-60 años), `id_tipo_nomina`, `id_nivel_salarial`, `sueldo_tabular_bruto`, `sueldo_tabular_neto`.
* **Cualitativas:** `nombre`, `apellido_1`, `sexo`, `n_puesto`, `tipo_contratacion`, `tipo_personal`, `n_cabeza_sector`.
* **Temporal:** `fecha_ingreso` (para cálculo de antigüedad).

### Consideraciones Éticas
Los datos personales (nombres, sexo, edad) son públicos bajo el Art. 70 de la LGTAIP y se manejan con estricta responsabilidad. El enfoque del análisis es sobre patrones sistémicos, no sobre individuos.


## 2. Limpieza y Carga Preliminar (Entrega 2)
*(Nota: Scripts disponibles en la carpeta `sql/e2_staging/`)*

Se ha diseñado un esquema inicial para la ingesta de datos crudos (`staging_remuneraciones`). El análisis exploratorio (EDA) mediante SQL evaluará:
1. Rango de fechas para determinar la antigüedad laboral máxima y mínima.
2. Detección de valores nulos o inconsistencias lógicas (ej. sueldo neto > sueldo bruto).
3. Distribución demográfica y salarial por cabeza de sector.

## 3. Normalización (Entrega 2)
*(Nota: DDL disponible en la carpeta `sql/e3_normalizacion/`)*

Para eliminar dependencias transitivas y redundancias (ej. el nombre del sector repitiéndose miles de veces), la base se está normalizando hasta la Cuarta Forma Normal (4NF), separando la información en catálogos independientes (Sectores, Puestos, Tipos de Nómina) y una tabla central de Nombramientos/Personas.