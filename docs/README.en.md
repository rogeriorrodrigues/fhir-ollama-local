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
- [Synthea Integration](#-synthea-integration)
- [Clinical Evolution Notes](#-clinical-evolution-notes)
- [FHIR Resources Explained](#-fhir-resources-explained)
- [Expected Output](#-expected-output)
- [Why This Matters](#-why-this-matters)
- [Troubleshooting](#-troubleshooting)
- [Next Steps](#-next-steps)

---

## 🎯 What It Does

This pipeline runs a **fully local clinical AI** that reads patient data from a FHIR R4 server and provides clinical reasoning — all without sending a single byte to the cloud.

**Three components, one `podman-compose up`:**

| Component | What It Does | Port |
|-----------|-------------|------|
| 🔥 **HAPI FHIR** | Stores clinical data in FHIR R4 format | `8080` |
| 🦙 **Ollama** | Runs LLaMA 3.2 locally as the AI brain | `11434` |
| 🧬 **Synthea** | Auto-generates synthetic patients on startup | — |
| 🐍 **Python script** | Queries FHIR → builds context → asks Ollama | — |

The AI **does not hallucinate** because it only works with data retrieved from the FHIR server. Every claim in its response traces back to a real clinical resource.

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        YOUR MACHINE                              │
│                                                                  │
│  ┌─────────────┐   healthcheck   ┌─────────────┐                │
│  │  HAPI FHIR  │◄────────────────│   Synthea   │                │
│  │  Server     │   POST /fhir    │  (auto-gen) │                │
│  │             │   (bundles)     │             │                │
│  │  Port 8080  │                 └─────────────┘                │
│  │             │◄── REST API (JSON) ──►                         │
│  │             │    GET /Patient          ┌─────────────┐        │
│  │             │    GET /Condition        │   Python    │        │
│  │             │    GET /Observation      │   Script    │        │
│  │             │    GET /MedicationRequest│  (demo)     │        │
│  │             │    GET /DocumentReference│             │        │
│  └─────────────┘                          └──────┬──────┘        │
│       Podman                                     │               │
│                                                   │               │
│                                          POST /api/generate       │
│                                                   │               │
│                                          ┌────────▼──────┐       │
│                                          │    Ollama     │       │
│                                          │  LLaMA 3.2:3b │       │
│                                          │  Port 11434   │       │
│                                          └───────────────┘       │
│                                               Podman             │
│                                                                  │
│  🔒 Nothing leaves this box. LGPD/GDPR-friendly by design.     │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

| Requirement | Minimum | Notes |
|-------------|---------|-------|
| Podman + podman-compose | Podman v4+ | [Install Podman](https://podman.io/getting-started/installation) |
| Python | 3.8+ | With `requests` library |
| Free disk space | ~5 GB | For HAPI FHIR image + LLaMA 3.2 model |
| RAM | 8 GB+ | LLaMA 3.2:3b needs ~3GB RAM |

```bash
# Install Podman and podman-compose (macOS example)
brew install podman podman-compose

# Install Python dependency
pip install requests
```

---

## 🚀 Step-by-Step Setup

### Step 1: Clone and start services

```bash
git clone https://github.com/YOUR_USER/fhir-ollama-local.git
cd fhir-ollama-local
podman-compose up -d
```

This starts three containers: HAPI FHIR (port 8080), Ollama (port 11434), and Synthea. Synthea waits for FHIR to pass its healthcheck, then automatically generates synthetic patients and loads them — no manual step required.

### Step 2: Download the LLaMA 3.2 model

```bash
podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b
```

> First time only. Downloads ~2GB. Go grab a coffee ☕

### Step 3: Run the demo

```bash
python3 fhir_ollama_demo.py
```

🎉 A dual-mode interactive menu appears — pick a curated clinical scenario or any Synthea-generated patient!

> **No need to run `bash load_patient.sh` manually.** The Synthea container calls it automatically on startup.

---

## 🧠 Understanding the Code

### `docker-compose.yml`

```yaml
services:
  fhir:
    image: hapiproject/hapi:latest    # FHIR R4 server
    ports: ["8080:8080"]
    healthcheck:                      # Synthea waits for this to pass
      test: ["CMD-SHELL", "wget -q --spider http://localhost:8080/fhir/metadata || exit 1"]
      interval: 10s
      retries: 12

  synthea:
    build:
      context: .
      dockerfile: synthea/Dockerfile  # Builds Synthea image locally
    depends_on:
      fhir:
        condition: service_healthy    # Only starts after FHIR is ready
    environment:
      - SYNTHEA_POPULATION=20         # Default: 20 patients
      - SYNTHEA_STATE=Massachusetts

  ollama:
    image: ollama/ollama:latest       # Local LLM runtime
    ports: ["11434:11434"]
    volumes:
      - ollama_data:/root/.ollama     # Persists downloaded models
```

Three containers. No external dependencies. No API keys. No cloud accounts.

### `fhir_ollama_demo.py` — The Core Logic

The script presents a **dual-mode interactive menu**:

**Section 1 — Curated demo patients** (loaded by `load_patient.sh`):
- Maria Santos: Diabetes + Hypertension (outpatient)
- João Oliveira: Decompensated heart failure (ICU)
- Ana Costa: Severe asthma + Pneumonia (emergency)

**Section 2 — Synthea patients** (auto-generated, paginated):
- All patients with active clinical data
- Shows name, gender, birth date, and active conditions
- Navigate with `[n]` / `[p]` for next/previous pages

For each selected patient the script:

**1. Queries FHIR** — Seven REST calls to get the full clinical picture:
```python
GET /Patient/{id}                       → Demographics
GET /Encounter?patient={id}             → Recent hospitalizations / visits
GET /Condition?patient={id}             → Active conditions
GET /Observation?patient={id}           → Lab results and vitals
GET /MedicationRequest?patient={id}     → Active medications
GET /Procedure?patient={id}             → Recent procedures
GET /CarePlan?patient={id}              → Active care plans
GET /DocumentReference?patient={id}     → Clinical evolution notes
```

**2. Builds context** — Structures all data into a readable clinical summary.

**3. Asks Ollama** — Sends the context with a strict prompt: "respond ONLY based on the provided data."

**4. Enters interactive Q&A** — Type any clinical question; type `voltar` to pick another patient.

### `load_patient.sh` + `load_evolutions.sh`

`load_patient.sh` creates three curated patients with rich clinical data using `curl` commands and proper terminologies:
- Uses `PUT` (not POST) for each Patient to guarantee stable IDs (`maria-001`, `joao-002`, `ana-003`)
- All Conditions include the required `clinicalStatus` system
- Blood pressure uses proper LOINC component codes with UCUM units

`load_evolutions.sh` attaches clinical evolution notes (nursing assessments, serial vitals) as `DocumentReference` resources to those same patients.

Both scripts are called automatically by the Synthea container entrypoint — no manual execution needed.

### `synthea/` directory

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the Synthea image (Java + Synthea JAR + scripts) |
| `entrypoint.sh` | Orchestrates: waits for FHIR → loads curated patients → runs Synthea → uploads bundles → generates notes |
| `generate_notes.py` | Creates `DocumentReference` resources with clinical notes for Synthea patients |
| `synthea.properties` | Configures Synthea output format (FHIR R4 bundles) |

---

## 🧬 Synthea Integration

Synthea generates realistic synthetic patient populations. The integration is fully automatic — just `podman-compose up -d`.

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SYNTHEA_POPULATION` | `20` | Number of patients to generate |
| `SYNTHEA_STATE` | `Massachusetts` | US state for demographic data |
| `SYNTHEA_MIN_AGE` | `30` | Minimum patient age |
| `SYNTHEA_MAX_AGE` | `85` | Maximum patient age |
| `SYNTHEA_SEED` | _(random)_ | Fixed seed for reproducible runs |
| `SYNTHEA_MODULES` | _(all)_ | Comma-separated condition modules |
| `SYNTHEA_CLEAN_FIRST` | `false` | Delete existing patients before loading |

### Regenerating patients

```bash
# Regenerate with a different population (clean slate)
SYNTHEA_POPULATION=50 SYNTHEA_CLEAN_FIRST=true podman-compose up synthea

# Full simulation: specific disease modules only
SYNTHEA_MODULES=diabetes,hypertension SYNTHEA_POPULATION=30 podman-compose up synthea

# Reproducible run with fixed seed
SYNTHEA_SEED=42 podman-compose up synthea
```

### What Synthea generates

Synthea produces complete FHIR R4 bundles containing the full patient lifecycle:
- Patient demographics, encounters, conditions, observations
- Medications, procedures, immunizations, care plans
- Hospital and practitioner information bundles

After uploading all bundles, `generate_notes.py` creates additional `DocumentReference` resources with clinical notes for each Synthea patient.

---

## 📋 Clinical Evolution Notes

### What they are

Clinical evolution notes are structured narrative records added to patients as `DocumentReference` FHIR resources. They simulate the documentation nurses and physicians write during care.

### Curated patients (load_evolutions.sh)

The curated patients receive hand-crafted evolution notes, including:
- **Nursing assessments** — systematic evaluations of patient status
- **Serial vitals** — time-series blood pressure, heart rate, SpO2, and temperature readings
- **Physician notes** — clinical reasoning and treatment adjustments

### Synthea patients (generate_notes.py)

Each Synthea patient automatically receives a `DocumentReference` with a generated clinical note summarizing their active conditions and recent observations.

### How the demo uses them

The Python script retrieves `DocumentReference` resources, decodes the base64-encoded note content, and includes them in the clinical context sent to Ollama — giving the AI access to narrative documentation alongside structured FHIR data.

---

## 🩺 FHIR Resources Explained

### What is FHIR?

FHIR (Fast Healthcare Interoperability Resources) is the global standard for exchanging healthcare data. Think of it as **REST + JSON for clinical data**. If you've built REST APIs, you already understand 70% of FHIR.

### Resources Created

| Resource | FHIR Type | Terminology | Code | Example Value |
|----------|-----------|-------------|------|---------------|
| Patient | `Patient` | — | — | Maria Santos, F, 1966 |
| Diabetes | `Condition` | SNOMED CT | `73211009` | Active |
| Hypertension | `Condition` | SNOMED CT | `38341003` | Active |
| HbA1c | `Observation` | LOINC | `4548-4` | 9.2% |
| Blood Pressure | `Observation` | LOINC | `85354-9` | 150/95 mmHg |
| Metformin | `MedicationRequest` | Free text | — | 850mg BID |
| Losartan | `MedicationRequest` | Free text | — | 50mg QD |
| Nursing note | `DocumentReference` | LOINC | `34109-9` | Base64-encoded narrative |

---

## 📺 Expected Output

```
==================================================
  FHIR + Ollama - Assistente Clinico
==================================================

-- Cenarios clinicos curados (dados ricos) --

  [1] Maria Santos - Diabetes + Hipertensao (ambulatorial)
  [2] Joao Oliveira - ICC descompensada (UTI)
  [3] Ana Costa - Asma grave + Pneumonia (emergencia)

-- Pacientes Synthea (pagina 1/3) --

  [4] Alice Johnson (F, 1952-03-14)
      Diabetes mellitus type 2, Hypertensive disorder
  [5] Bob Smith (M, 1968-07-22)
      Coronary Heart Disease, Hyperlipidemia
  ...

  [n] Proxima pagina (Synthea)
  [0] Sair

Escolha o paciente: 1

>>> Consultando FHIR para: Maria Santos...

Paciente: Maria Santos, female, nascimento: 1966-05-12

Condicoes ativas:
- Diabetes mellitus (SNOMED: 73211009)
- Hypertensive disorder (SNOMED: 38341003)

Observacoes recentes:
- Hemoglobin A1c: 9.2 % (2024-11-15)
- Blood pressure panel: Systolic blood pressure: 150mmHg, Diastolic blood pressure: 95mmHg (2024-11-15)

Medicacoes:
- Metformina 850mg (850mg 2x/dia)
- Losartana 50mg (50mg 1x/dia)

Evolucoes clinicas:
- [Nursing Note] 2024-11-15T08:30 | Enf. Silva | Avaliacao de enfermagem
  Paciente consciente, orientada...

--------------------------------------------------
Modo interativo - Paciente: Maria Santos
Digite suas perguntas (ou 'voltar' para trocar de paciente)
--------------------------------------------------

Voce: Quais sao as condicoes dessa paciente e como os exames se relacionam com o tratamento atual?

Pensando...

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
Podman (free) + Ollama (free) + HAPI FHIR (Apache 2.0) + Synthea (Apache 2.0) + Python (free) = **$0/month**.

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| `Connection refused` on port 8080 | HAPI FHIR takes ~30s to start. The Synthea container waits automatically via healthcheck. |
| `model not found` in Ollama | Run `podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b` |
| Python `ModuleNotFoundError: requests` | Run `pip install requests` |
| Ollama response is slow | LLaMA 3.2:3b needs ~3GB RAM. Close other apps. |
| Patient not found (404) | Curated patients are loaded by Synthea container. Check `podman logs` for the synthea container. |
| Synthea container exits immediately | Check `podman logs <synthea-container-id>` for Java or curl errors. |
| No Synthea patients in menu | Synthea may still be running. Wait a minute and restart the demo. |

---

## 🗺️ Next Steps

- [x] ✅ **Synthea** — Auto-generates hundreds of synthetic patients on startup
- [ ] 🛡️ **[Presidio](https://microsoft.github.io/presidio/)** — Add Microsoft's anonymization layer before the LLM (see note below)
- [ ] 📊 **RAGAS** — Evaluate response quality with faithfulness > 0.85
- [ ] 🔌 **MCP Server** — Standardized AI-to-FHIR access protocol
- [ ] 🎓 **Clinical scenarios** — Nursing simulation with adaptive feedback

### 🛡️ About Presidio (future)

[Microsoft Presidio](https://microsoft.github.io/presidio/) is an open-source SDK for data protection and de-identification. It detects and anonymizes PII (names, SSNs, phone numbers, addresses) in text before sending it to an LLM. In this project, Presidio is **not yet integrated** because all patient data is already synthetic — curated patients are fictional and Synthea generates fully synthetic records. Presidio will become essential when the pipeline evolves to ingest real clinical data (e.g., from electronic health records), adding a pre-LLM anonymization layer to ensure LGPD/GDPR compliance even with real patient information.

---

<div align="center">

**[⬆ Back to top](#-local-clinical-ai--fhir-pipeline)**

Made with ☕ by [Rogério Rodrigues](https://linkedin.com/in/rogeriorodrigues)

</div>
