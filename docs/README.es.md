<div align="center">

# 🏥 IA Clínica Local + Pipeline FHIR

### 🇪🇸 Documentación Completa en Español

[← Volver al README Principal](../README.md) · [🇬🇧 English](README.en.md) · [🇧🇷 Português](README.pt.md) · [🇮🇹 Italiano](README.it.md)

</div>

---

## 📋 Índice

- [Qué Hace](#-qué-hace)
- [Arquitectura](#-arquitectura)
- [Requisitos Previos](#-requisitos-previos)
- [Paso a Paso](#-paso-a-paso)
- [Entendiendo el Código](#-entendiendo-el-código)
- [Integración con Synthea](#-integración-con-synthea)
- [Notas de Evolución Clínica](#-notas-de-evolución-clínica)
- [Recursos FHIR Explicados](#-recursos-fhir-explicados)
- [Output Esperado](#-output-esperado)
- [Por Qué Importa](#-por-qué-importa)
- [Solución de Problemas](#-solución-de-problemas)
- [Próximos Pasos](#-próximos-pasos)

---

## 🎯 Qué Hace

Este pipeline ejecuta una **IA clínica 100% local** que lee datos de pacientes de un servidor FHIR R4 y genera razonamiento clínico — todo sin enviar un solo byte a la nube.

**Tres servicios, un `podman-compose up`:**

| Componente | Qué Hace | Puerto |
|------------|----------|--------|
| 🔥 **HAPI FHIR** | Almacena datos clínicos en formato FHIR R4 | `8080` |
| 🦙 **Ollama** | Ejecuta llama3.2:3b localmente como cerebro de IA | `11434` |
| 🧬 **Synthea** | Genera pacientes sintéticos realistas automáticamente | — |

El script Python consulta FHIR → construye contexto → pregunta a Ollama. La IA **no alucina** porque trabaja exclusivamente con datos recuperados del servidor FHIR. Cada afirmación en su respuesta es rastreable a un recurso clínico real.

---

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────────────────┐
│                        TU MÁQUINA                                │
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │  HAPI FHIR  │    │   Synthea   │    │   Python    │         │
│  │  Servidor   │◄───│  (genera    │    │   Script    │         │
│  │             │    │  pacientes) │    │             │         │
│  │  Puerto 8080│    └─────────────┘    │             │         │
│  │             │◄── REST API (JSON) ──►│             │         │
│  │             │    GET /Patient       │             │         │
│  │             │    GET /Condition     │             │         │
│  │             │    GET /Observation   │             │         │
│  │             │    GET /MedicationReq │             │         │
│  │             │    GET /DocumentRef   │             │         │
│  └─────────────┘                      └──────┬──────┘         │
│       Podman                                 │                 │
│                                      POST /api/generate        │
│                                             │                  │
│                                    ┌────────▼──────┐          │
│                                    │    Ollama     │          │
│                                    │ llama3.2:3b   │          │
│                                    │ Puerto 11434  │          │
│                                    └───────────────┘          │
│                                         Podman                 │
│                                                                  │
│  🔒 Nada sale de esta máquina. Compatible con RGPD/LGPD.       │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📦 Requisitos Previos

| Requisito | Mínimo | Notas |
|-----------|--------|-------|
| Podman + podman-compose | v4+ | [Instalar Podman](https://podman.io/getting-started/installation) |
| Python | 3.8+ | Con biblioteca `requests` |
| Espacio en disco | ~5 GB | Imagen HAPI FHIR + modelo llama3.2:3b |
| RAM | 8 GB+ | llama3.2:3b necesita ~2GB RAM |

```bash
pip install requests
```

---

## 🚀 Paso a Paso

### Paso 1: Clonar e iniciar servicios

```bash
git clone https://github.com/YOUR_USER/fhir-ollama-local.git
cd fhir-ollama-local
podman-compose up -d
```

> 🧬 Synthea genera pacientes sintéticos automáticamente al iniciar. No se necesita carga manual.

### Paso 2: Descargar el modelo llama3.2:3b

```bash
podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b
```

> ⏳ Solo la primera vez. Descarga ~2GB. Tiempo para un café ☕

### Paso 3: Ejecutar la demo

```bash
python3 fhir_ollama_demo.py
```

🎉 ¡Observa la IA leyendo datos clínicos y razonando de forma fundamentada!

---

## 🧠 Entendiendo el Código

### `fhir_ollama_demo.py` — La Lógica Central

El script orquesta tres servicios y presenta un menú dinámico de dos modos:

**Modo curado** — Paciente de referencia con condiciones conocidas (diabetes, hipertensión).

**Modo Synthea** — Selección interactiva entre los pacientes generados automáticamente en el directorio `synthea/`.

**1. Consulta FHIR** — Cinco llamadas REST para obtener el cuadro clínico completo:
```python
GET /Patient/{id}              → Datos demográficos
GET /Condition?patient={id}    → Condiciones activas (diabetes, hipertensión)
GET /Observation?patient={id}  → Resultados de laboratorio (HbA1c, presión arterial)
GET /MedicationRequest?patient={id} → Medicaciones activas (metformina, losartán)
GET /DocumentReference?patient={id} → Notas de evolución clínica de enfermería
```

**2. Construye contexto** — Estructura los datos en un resumen clínico legible.

**3. Pregunta a Ollama** — Envía el contexto con prompt restrictivo: "responde SOLO basándote en los datos proporcionados."

---

## 🧬 Integración con Synthea

Synthea genera automáticamente cohortes de pacientes sintéticos con historiales clínicos realistas al iniciar los servicios.

### Variables de entorno configurables

```bash
SYNTHEA_POPULATION=10        # Número de pacientes a generar (defecto: 10)
SYNTHEA_SEED=42              # Semilla para reproducibilidad
SYNTHEA_STATE=Massachusetts  # Estado/región para los datos demográficos
```

### Regenerar pacientes manualmente

```bash
# Limpiar y regenerar la cohorte completa
podman-compose down
rm -rf synthea/output/*
podman-compose up -d
```

### Estructura del directorio `synthea/`

```
synthea/
├── output/
│   ├── fhir/          # Bundles FHIR JSON listos para importar
│   └── csv/           # Datos en formato CSV (referencia)
└── synthea.properties # Configuración de la generación
```

---

## 📝 Notas de Evolución Clínica

El pipeline soporta **notas de enfermería y evolución clínica** a través del recurso `DocumentReference`, permitiendo razonamiento contextual enriquecido.

### Qué son

Las notas de evolución son registros narrativos escritos por enfermería que documentan la evolución del paciente, observaciones subjetivas y planes de cuidado — información que no cabe en campos estructurados de FHIR.

### Cómo se usan en este pipeline

```python
# El script recupera DocumentReference y los incluye en el contexto
GET /DocumentReference?patient={id}&category=clinical-note

# Ejemplo de nota recuperada:
{
  "resourceType": "DocumentReference",
  "type": { "text": "Nursing progress note" },
  "content": [{
    "attachment": {
      "contentType": "text/plain",
      "data": "<base64>"   # Nota narrativa decodificada y enviada al LLM
    }
  }]
}
```

### Beneficio para el razonamiento clínico

El LLM recibe tanto datos estructurados (laboratorios, medicaciones) como narrativa clínica (notas de enfermería), produciendo razonamiento más completo y contextualizado.

---

## 🩺 Recursos FHIR Explicados

### ¿Qué es FHIR?

FHIR (Fast Healthcare Interoperability Resources) es el estándar global para intercambiar datos de salud. Piensa en él como **REST + JSON para datos clínicos**. Si ya has construido APIs REST, ya entiendes el 70% de FHIR.

### Recursos Utilizados

| Recurso | Tipo FHIR | Terminología | Código | Ejemplo |
|---------|-----------|--------------|--------|---------|
| Paciente | `Patient` | — | — | Maria Santos, F, 1966 |
| Diabetes | `Condition` | SNOMED CT | `73211009` | Activo |
| Hipertensión | `Condition` | SNOMED CT | `38341003` | Activo |
| HbA1c | `Observation` | LOINC | `4548-4` | 9.2% |
| Presión Arterial | `Observation` | LOINC | `85354-9` | 150/95 mmHg |
| Metformina | `MedicationRequest` | Texto libre | — | 850mg 2x/día |
| Losartán | `MedicationRequest` | Texto libre | — | 50mg 1x/día |
| Nota clínica | `DocumentReference` | LOINC | `11506-3` | Nota de enfermería |

---

## 📺 Output Esperado

```
=== Pipeline IA Clínica Local ===

Selecciona modo:
  [1] Paciente curado (Maria Santos - diabetes + hipertensión)
  [2] Pacientes Synthea (generados automáticamente)

Opción: 2

Pacientes disponibles en Synthea:
  [1] John Doe, M, 1978 — Asthma, Hypertension
  [2] Ana Lima, F, 1990 — Type 2 Diabetes
  [3] Carlos Ramos, M, 1955 — COPD, Heart failure

Selecciona paciente: 1

=== Consultando servidor FHIR ===

Datos recuperados:
Paciente: John Doe, male, nacimiento: 1978-03-22

Condiciones activas:
- Asthma (SNOMED: 195967001)
- Hypertensive disorder (SNOMED: 38341003)

Observaciones recientes:
- Peak flow: 380 L/min
- Blood pressure: 145/90 mmHg

Medicaciones activas:
- Salbutamol 100mcg (PRN)
- Amlodipine 5mg QD

Notas de evolución:
- [Nota de enfermería — 2024-01-15]: Paciente refiere disnea leve nocturna...

==================================================

Preguntando a Ollama (llama3.2:3b)...

Respuesta:
[Ollama responde con razonamiento clínico basado en los datos FHIR]
```

---

## 🔐 Por Qué Importa

### 🏛️ Privacidad (RGPD / LGPD)
Ningún dato de paciente sale de tu máquina. El pipeline completo se ejecuta localmente. Esto elimina el bloqueo más común para la adopción de IA clínica: **"no podemos enviar datos de pacientes a APIs externas."**

### 🌎 Estándar Internacional
FHIR R4 es el estándar global usado por Epic, Oracle Health (Cerner), la RNDS de Brasil y sistemas de salud en más de 22 países. Construir sobre FHIR hoy significa compatibilidad con infraestructuras de salud mañana.

### 💰 Costo Cero
Podman (gratis) + Ollama (gratis) + HAPI FHIR (Apache 2.0) + Synthea (Apache 2.0) + Python (gratis) = **$0/mes**.

---

## 🔧 Solución de Problemas

| Problema | Solución |
|----------|----------|
| `Connection refused` en puerto 8080 | HAPI FHIR tarda ~30s en iniciar. Espera y reintenta. |
| `model not found` en Ollama | Ejecuta `podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b` |
| Python `ModuleNotFoundError: requests` | Ejecuta `pip install requests` |
| Ollama lento al responder | llama3.2:3b necesita ~2GB RAM. Cierra otras apps. |
| Synthea no generó pacientes | Verifica logs con `podman-compose logs synthea` |
| Menú no muestra pacientes Synthea | Confirma que `synthea/output/fhir/` contiene archivos `.json` |

---

## 🗺️ Próximos Pasos

- [x] ✅ 🧬 **Synthea** — Generación automática de pacientes sintéticos
- [ ] 🛡️ **Presidio** — Capa de anonimización antes del LLM
- [ ] 📊 **RAGAS** — Evaluación de calidad con faithfulness > 0.85
- [ ] 🔌 **MCP Server** — Protocolo estandarizado de acceso IA-FHIR
- [ ] 🎓 **Escenarios clínicos** — Simulación de enfermería con feedback adaptativo

---

<div align="center">

**[⬆ Volver arriba](#-ia-clínica-local--pipeline-fhir)**

Hecho con ☕ desde un sitio en Santa Catarina, Brasil

</div>
