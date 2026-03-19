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
