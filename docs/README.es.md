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
- [Recursos FHIR Explicados](#-recursos-fhir-explicados)
- [Output Esperado](#-output-esperado)
- [Por Qué Importa](#-por-qué-importa)
- [Solución de Problemas](#-solución-de-problemas)
- [Próximos Pasos](#-próximos-pasos)

---

## 🎯 Qué Hace

Este pipeline ejecuta una **IA clínica 100% local** que lee datos de pacientes de un servidor FHIR R4 y genera razonamiento clínico — todo sin enviar un solo byte a la nube.

**Tres componentes, un `docker compose up`:**

| Componente | Qué Hace | Puerto |
|------------|----------|--------|
| 🔥 **HAPI FHIR** | Almacena datos clínicos en formato FHIR R4 | `8080` |
| 🦙 **Ollama** | Ejecuta LLaMA 3 localmente como cerebro de IA | `11434` |
| 🐍 **Script Python** | Consulta FHIR → construye contexto → pregunta a Ollama | — |

La IA **no alucina** porque trabaja exclusivamente con datos recuperados del servidor FHIR. Cada afirmación en su respuesta es rastreable a un recurso clínico real.

---

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────────────────┐
│                        TU MÁQUINA                                │
│                                                                  │
│  ┌─────────────┐                          ┌─────────────┐       │
│  │  HAPI FHIR  │◄── REST API (JSON) ──►  │   Python    │       │
│  │  Servidor   │    GET /Patient          │   Script    │       │
│  │             │    GET /Condition         │  (60 líneas)│       │
│  │  Puerto 8080│    GET /Observation       │             │       │
│  │             │    GET /MedicationRequest │             │       │
│  └─────────────┘                          └──────┬──────┘       │
│       Docker                                     │              │
│                                          POST /api/generate      │
│                                                   │              │
│                                          ┌────────▼──────┐      │
│                                          │    Ollama     │      │
│                                          │   LLaMA 3    │      │
│                                          │ Puerto 11434 │      │
│                                          └───────────────┘      │
│                                               Docker            │
│                                                                  │
│  🔒 Nada sale de esta máquina. Compatible con RGPD/LGPD.       │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📦 Requisitos Previos

| Requisito | Mínimo | Notas |
|-----------|--------|-------|
| Docker + Docker Compose | v20+ | [Instalar Docker](https://docs.docker.com/get-docker/) |
| Python | 3.8+ | Con biblioteca `requests` |
| Espacio en disco | ~5 GB | Imagen HAPI FHIR + modelo LLaMA 3 |
| RAM | 8 GB+ | LLaMA 3 necesita ~4GB RAM |

```bash
pip install requests
```

---

## 🚀 Paso a Paso

### Paso 1: Clonar e iniciar servicios

```bash
git clone https://github.com/YOUR_USER/fhir-ollama-local.git
cd fhir-ollama-local
docker compose up -d
```

### Paso 2: Descargar el modelo LLaMA 3

```bash
docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3
```

> ⏳ Solo la primera vez. Descarga ~4GB. Tiempo para un café ☕

### Paso 3: Cargar el paciente de ejemplo

```bash
bash load_patient.sh
```

### Paso 4: Ejecutar la demo

```bash
python fhir_ollama_demo.py
```

🎉 ¡Observa la IA leyendo datos clínicos y razonando de forma fundamentada!

---

## 🧠 Entendiendo el Código

### `fhir_ollama_demo.py` — La Lógica Central

El script hace tres cosas:

**1. Consulta FHIR** — Cuatro llamadas REST para obtener el cuadro clínico completo:
```python
GET /Patient/{id}              → Datos demográficos
GET /Condition?patient={id}    → Condiciones activas (diabetes, hipertensión)
GET /Observation?patient={id}  → Resultados de laboratorio (HbA1c, presión arterial)
GET /MedicationRequest?patient={id} → Medicaciones activas (metformina, losartán)
```

**2. Construye contexto** — Estructura los datos en un resumen clínico legible.

**3. Pregunta a Ollama** — Envía el contexto con prompt restrictivo: "responde SOLO basándote en los datos proporcionados."

---

## 🩺 Recursos FHIR Explicados

### ¿Qué es FHIR?

FHIR (Fast Healthcare Interoperability Resources) es el estándar global para intercambiar datos de salud. Piensa en él como **REST + JSON para datos clínicos**. Si ya has construido APIs REST, ya entiendes el 70% de FHIR.

### Recursos Creados

| Recurso | Tipo FHIR | Terminología | Código | Valor |
|---------|-----------|--------------|--------|-------|
| Paciente | `Patient` | — | — | Maria Santos, F, 1966 |
| Diabetes | `Condition` | SNOMED CT | `73211009` | Activo |
| Hipertensión | `Condition` | SNOMED CT | `38341003` | Activo |
| HbA1c | `Observation` | LOINC | `4548-4` | 9.2% |
| Presión Arterial | `Observation` | LOINC | `85354-9` | 150/95 mmHg |
| Metformina | `MedicationRequest` | Texto libre | — | 850mg 2x/día |
| Losartán | `MedicationRequest` | Texto libre | — | 50mg 1x/día |

---

## 📺 Output Esperado

```
=== Consultando servidor FHIR ===

Datos recuperados:
Paciente: Maria Santos, female, nacimiento: 1966-05-12

Condiciones activas:
- Diabetes mellitus (SNOMED: 73211009)
- Hypertensive disorder (SNOMED: 38341003)

Observaciones recientes:
- Hemoglobin A1c: 9.2 %
- Blood pressure panel: Systolic: 150mmHg, Diastolic: 95mmHg

Medicaciones activas:
- Metformina 850mg (850mg 2x/dia)
- Losartana 50mg (50mg 1x/dia)

==================================================

Preguntando a Ollama (llama3)...

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
Docker (gratis) + Ollama (gratis) + HAPI FHIR (Apache 2.0) + Python (gratis) = **$0/mes**.

---

## 🔧 Solución de Problemas

| Problema | Solución |
|----------|----------|
| `Connection refused` en puerto 8080 | HAPI FHIR tarda ~30s en iniciar. Espera o ejecuta `load_patient.sh`. |
| `model not found` en Ollama | Ejecuta `docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3` |
| Python `ModuleNotFoundError: requests` | Ejecuta `pip install requests` |
| Ollama lento al responder | LLaMA 3 necesita ~4GB RAM. Cierra otras apps. |

---

## 🗺️ Próximos Pasos

- [ ] 🧬 **Synthea** — Generar pacientes sintéticos automáticamente
- [ ] 🛡️ **Presidio** — Capa de anonimización antes del LLM
- [ ] 📊 **RAGAS** — Evaluación de calidad con faithfulness > 0.85
- [ ] 🔌 **MCP Server** — Protocolo estandarizado de acceso IA-FHIR
- [ ] 🎓 **Escenarios clínicos** — Simulación de enfermería con feedback adaptativo

---

<div align="center">

**[⬆ Volver arriba](#-ia-clínica-local--pipeline-fhir)**

Hecho con ☕ desde un sitio en Santa Catarina, Brasil

</div>
