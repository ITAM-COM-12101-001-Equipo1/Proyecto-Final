# Proyecto-Final
Proyecto Final de Bases de Datos Primavera 2026 COM-12101-001

# Integrantes del Equipo
David Fernando Avila Díaz 197851
José Roberto Uribe Clemente 214129
Emiliano Sebastian Millan Giffard 214360

# Data Source
## 1. Conjunto de Datos

### Enlaces
* **Fuente del Dataset:** Credit Card Customers - Kaggle https://www.kaggle.com/datasets/sakshigoyal7/credit-card-customers
* **Repositorio del Proyecto:** [Inserta aquí el enlace a tu repositorio de GitHub]

#### Resumen
El conjunto de datos contiene información sobre 10,127 clientes de un banco y sus líneas de crédito. El atributo más importante es el `Attrition_Flag`, que indica si el cliente mantiene su cuenta activa o si la cerró. Los datos incluyen información demográfica (edad, género, estado civil), datos socioeconómicos (educación, ingresos) y métricas de comportamiento financiero (límite de crédito, transacciones totales, saldo rotativo).

#### Origen y Autoría
El dataset fue publicado y continúa en línea en Kaggle por Sakshi Goyal. Los datos representan una extracción de una cartera de clientes bancarios reales, anonimizados para su uso didáctico.

#### Justificación
La deserción de clientes (churn) es uno de los problemas más costosos para las instituciones financieras. Este conjunto de datos se seleccionó porque permite simular un escenario de negocio real: identificar patrones de comportamiento en clientes que abandonan el banco. 

Al normalizar y analizar estos datos, podemos responder preguntas críticas sobre qué perfil de cliente (basado en ingresos, educación o tipo de tarjeta) tiene mayor riesgo de fuga (tal cual como se aplicaría en el mundo laboral).

#### Disponibilidad y Acceso
El archivo se encuentra alojado públicamente en la plataforma **Kaggle** bajo licencia "CC0: Public Domain", lo que permite su libre uso, modificación y distribución para fines académicos.

#### Periodicidad de Actualización
Este es un conjunto de datos estático. Representa una "foto" del estado de los clientes en un momento determinado y no recibe actualizaciones por parte del autor original.

#### Dimensiones
* **Registros (Filas):** 10,127 clientes únicos.
* **Variables (Columnas):** 23 atributos iniciales (antes de toda limpieza y normalización).

---

## 2. Diccionario de Datos

### Variables Cuantitativas (Numéricas)
Magnitudes medibles para realizar operaciones:
* **Customer_Age:** Edad del cliente en años.
* **Dependent_count:** Número de dependientes económicos del cliente.
* **Months_on_book:** Periodo de relación con el banco (en meses).
* **Total_Relationship_Count:** Número total de productos que el cliente tiene con el banco.
* **Months_Inactive_12_mon:** Número de meses sin actividad en el último año.
* **Contacts_Count_12_mon:** Número de contactos entre el cliente y el banco en el último año.
* **Credit_Limit:** Límite de crédito asignado a la tarjeta.
* **Total_Revolving_Bal:** Saldo rotativo total de la tarjeta de crédito.
* **Avg_Open_To_Buy:** Línea de crédito abierta disponible para compras (promedio).
* **Total_Trans_Amt:** Monto total de las transacciones (últimos 12 meses).
* **Total_Trans_Ct:** Cantidad total de transacciones (últimos 12 meses).
* **Avg_Utilization_Ratio:** Ratio promedio de utilización de la tarjeta.

### Variables Cualitativas (Categóricas)
Etiquetas o categorías descriptivas:
* **CLIENTNUM:** Identificador único del cliente (Clave primaria candidata).
* **Attrition_Flag:** Estado de la cuenta ('Existing Customer' o 'Attrited Customer').
* **Gender:** Género del cliente (M=Male, F=Female).
* **Education_Level:** Nivel máximo de estudios alcanzado (ej. High School, Graduate, Doctorate).
* **Marital_Status:** Estado civil (Married, Single, Divorced, Unknown).
* **Income_Category:** Rango de ingresos anuales del cliente (ej. $40K - $60K).
* **Card_Category:** Tipo de tarjeta de crédito (Blue, Silver, Gold, Platinum).

> **Nota:** El dataset original incluye dos columnas finales (`Naive_Bayes_Classifier...`) generadas por un modelo predictivo externo. Estas columnas serán eliminadas durante la fase de limpieza ya que no son datos transaccionales ni demográficos reales.

---

## 3. Visión Estratégica

**Objetivo Principal:**
Diseñar y construir una base de datos relacional normalizada (de hasta 4NF) que permita analizar la relación entre el perfil demográfico de los clientes y su probabilidad de deserción.

**Implementación:**
1.  **Cargar datos:** Cargar los datos crudos (desde un CSV plano) en una tabla.
2.  **Normalización:** Descomponer la tabla extrayendo entidades repetitivas como `Education_Level`, `Marital_Status`, `Income_Category` y `Card_Category` hacia sus propias tablas dimensionales para reducir redundancia (y normalizar).
3.  **Consultas:** Utilizar SQL para generar reportes que comparen el comportamiento de gasto (`Total_Trans_Amt`) y frecuencia de uso (`Total_Trans_Ct`) entre clientes activos y desertores, por ejemplo.

---

## 4. Consideraciones Éticas

* **Privacidad:** Aunque el campo `CLIENTNUM` hace anónima la identidad directa, la combinación de edad, género, nivel educativo y estado civil podría, en teoría, facilitar la clasificación en grupos demográficos muy pequeños. Se tratará el `CLIENTNUM` como dato sensible interno.
* **Sesgo Algorítmico:** El dataset contiene variables protegidas como **Género** y **Edad**. Cualquier análisis derivado debe tener cuidado de no reforzar “sesgos históricos” (por ejemplo, asumir que cierto género tiene menor solvencia crediticia basándose únicamente en correlaciones simples sin contexto socioeconómico).
* **Integridad Financiera:** Al tratarse de datos financieros (límites de crédito, saldos), el manejo de la información debe ser responsable, asegurando que las conclusiones del análisis no se utilicen para prácticas discriminatorias.

