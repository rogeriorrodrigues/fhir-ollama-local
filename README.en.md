<div align="center">

# 🏥 Local Clinical AI + FHIR Pipeline

### 🇬🇧 Full English Documentation

[← Back to Main README](../README.md) · [🇧🇷 Português](README.pt.md) · [🇪🇸 Español](README.es.md) · [🇮🇹 Italiano](README.it.md)

</div>

---

## 📋 Table of Contents

- [What It Does](#-what-it-does)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Step-by-Step Setup](#-step-by-step-setup)
- [Understanding the Code](#-understanding-the-code)
- [FHIR Resources Explained](#-fhir-resources-explained)
- [Expected Output](#-expected-output)
- [Why This Matters](#-why-this-matters)
- [Troubleshooting](#-troubleshooting)
- [Next Steps](#-next-steps)

---

## 🎯 What It Does

This pipeline runs a **fully local clinical AI** that reads patient data from a FHIR R4 server and provides clinical reasoning — all without sending a single byte to the cloud.

**Three components, one `docker compose up`:**

| Component | What It Does | Port |
|-----------|-------------|------|
| 🔥 **HAPI FHIR** | Stores clinical data in FHIR R4 format | `8080` |
| 🦙 **Ollama** | Runs LLaMA 3 locally as the AI brain | `11434` |
| 🐍 **Python script** | Queries FHIR → builds context → asks Ollama | — |

The AI **does not hallucinate** because it only works with data retrieved from the FHIR server. Every claim in its response traces back to a real clinical resource.

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        YOUR MACHINE                              │
│                                                                  │
│  ┌─────────────┐                          ┌─────────────┐       │
│  │  HAPI FHIR  │◄── REST API (JSON) ──►  │   Python    │       │
│  │  Server     │    GET /Patient          │   Script    │       │
│  │             │    GET /Condition         │  (60 lines) │       │
│  │  Port 8080  │    GET /Observation       │             │       │
│  │             │    GET /MedicationRequest │             │       │
│  └─────────────┘                          └──────┬──────┘       │
│       Docker                                     │              │
│                                                   │              │
│                                          POST /api/generate      │
│                                                   │              │
│                                          ┌────────▼──────┐      │
│                                          │    Ollama     │      │
│                                          │   LLaMA 3    │      │
│                                          │  Port 11434  │      │
│                                          └───────────────┘      │
│                                               Docker            │
│                                                                  │
│  🔒 Nothing leaves this box. LGPD/GDPR-friendly by design.     │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

| Requirement | Minimum | Notes |
|-------------|---------|-------|
| Docker + Docker Compose | v20+ | [Install Docker](https://docs.docker.com/get-docker/) |
| Python | 3.8+ | With `requests` library |
| Free disk space | ~5 GB | For HAPI FHIR image + LLaMA 3 model |
| RAM | 8 GB+ | LLaMA 3 needs ~4GB RAM |

```bash
# Install Python dependency
pip install requests
```

---

## 🚀 Step-by-Step Setup

### Step 1: Clone and start services

```bash
git clone https://github.com/YOUR_USER/fhir-ollama-local.git
cd fhir-ollama-local
docker compose up -d
```

This starts two containers: HAPI FHIR (port 8080) and Ollama (port 11434).

### Step 2: Download the LLaMA 3 model

```bash
docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3
```

> ⏳ First time only. Downloads ~4GB. Go grab a coffee ☕

### Step 3: Load the sample patient

```bash
bash load_patient.sh
```

This creates Maria Santos with all her clinical data in the FHIR server. The script waits for HAPI FHIR to be ready before loading.

### Step 4: Run the demo

```bash
python fhir_ollama_demo.py
```

🎉 Watch the AI read clinical data and provide grounded reasoning!

---

## 🧠 Understanding the Code

### `docker-compose.yml`

```yaml
services:
  fhir:
    image: hapiproject/hapi:latest    # FHIR R4 server
    ports: ["8080:8080"]              # REST API accessible on localhost
  ollama:
    image: ollama/ollama:latest       # Local LLM runtime
    ports: ["11434:11434"]            # Ollama API accessible on localhost
```

Two containers. No external dependencies. No API keys. No cloud accounts.

### `fhir_ollama_demo.py` — The Core Logic

The script does three things:

**1. Queries FHIR** — Four REST calls to get the complete clinical picture:
```python
GET /Patient/{id}              → Demographics
GET /Condition?patient={id}    → Active conditions (diabetes, hypertension)
GET /Observation?patient={id}  → Lab results (HbA1c, blood pressure)
GET /MedicationRequest?patient={id} → Active medications (metformin, losartan)
```

**2. Builds context** — Structures the data into a readable clinical summary.

**3. Asks Ollama** — Sends the context with a strict prompt: "respond ONLY based on the provided data."

### `load_patient.sh`

Creates 7 FHIR resources using `curl` commands with proper terminologies:
- Uses `PUT` (not POST) for the Patient to guarantee the ID `maria-001`
- All Conditions include the required `clinicalStatus` system
- Blood pressure uses proper LOINC component codes with UCUM units

---

## 🩺 FHIR Resources Explained

### What is FHIR?

FHIR (Fast Healthcare Interoperability Resources) is the global standard for exchanging healthcare data. Think of it as **REST + JSON for clinical data**. If you've built REST APIs, you already understand 70% of FHIR.

### Resources Created

| Resource | FHIR Type | Terminology | Code | Value |
|----------|-----------|-------------|------|-------|
| Patient | `Patient` | — | — | Maria Santos, F, 1966 |
| Diabetes | `Condition` | SNOMED CT | `73211009` | Active |
| Hypertension | `Condition` | SNOMED CT | `38341003` | Active |
| HbA1c | `Observation` | LOINC | `4548-4` | 9.2% |
| Blood Pressure | `Observation` | LOINC | `85354-9` | 150/95 mmHg |
| Metformin | `MedicationRequest` | Free text | — | 850mg BID |
| Losartan | `MedicationRequest` | Free text | — | 50mg QD |

---

## 📺 Expected Output

```
=== Consultando servidor FHIR ===

Dados recuperados:
Paciente: Maria Santos, female, nascimento: 1966-05-12

Condicoes ativas:
- Diabetes mellitus (SNOMED: 73211009)
- Hypertensive disorder (SNOMED: 38341003)

Observacoes recentes:
- Hemoglobin A1c: 9.2 %
- Blood pressure panel: Systolic blood pressure: 150mmHg, Diastolic blood pressure: 95mmHg

Medicacoes ativas:
- Metformina 850mg (850mg 2x/dia)
- Losartana 50mg (50mg 1x/dia)

==================================================

Perguntando ao Ollama (llama3)...
Pergunta: Quais sao as condicoes dessa paciente e como os exames se relacionam com o tratamento atual?

Resposta:
[Ollama provides clinical reasoning grounded in the FHIR data]
```

---

## 🔐 Why This Matters

### 🏛️ LGPD / GDPR Compliance
No patient data leaves your machine. The entire pipeline runs locally. This eliminates the most common blocker for clinical AI adoption: **"we can't send patient data to external APIs."**

### 🇧🇷 RNDS Compatibility
HAPI FHIR uses the same standard as Brazil's RNDS (Rede Nacional de Dados em Saúde) — FHIR R4. The RNDS already has 2.8 billion records. Building on FHIR today means compatibility with the national health infrastructure tomorrow.

### 💰 Zero Cost
Docker (free) + Ollama (free) + HAPI FHIR (Apache 2.0) + Python (free) = **$0/month**.

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| `Connection refused` on port 8080 | HAPI FHIR takes ~30s to start. Wait or run `load_patient.sh` (it auto-waits). |
| `model not found` in Ollama | Run `docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3` |
| Python `ModuleNotFoundError: requests` | Run `pip install requests` |
| Ollama response is slow | LLaMA 3 needs ~4GB RAM. Close other apps or use a smaller model (`llama3:8b`). |
| Patient not found (404) | Re-run `bash load_patient.sh`. It uses PUT to force the ID. |

---

## 🗺️ Next Steps

- [ ] 🧬 **Synthea** — Generate hundreds of synthetic patients automatically
- [ ] 🛡️ **Presidio** — Add Microsoft's anonymization layer before the LLM
- [ ] 📊 **RAGAS** — Evaluate response quality with faithfulness > 0.85
- [ ] 🔌 **MCP Server** — Standardized AI-to-FHIR access protocol
- [ ] 🎓 **Clinical scenarios** — Nursing simulation with adaptive feedback

---

<div align="center">

**[⬆ Back to top](#-local-clinical-ai--fhir-pipeline)**

Made with ☕ by [Rogério Rodrigues](https://linkedin.com/in/rogeriorodrigues)

</div>
