<div align="center">

# 🏥 Local Clinical AI + FHIR Pipeline

### _Zero Cloud · Zero Cost · Zero Data Leakage_

<br>

[![FHIR R4](https://img.shields.io/badge/FHIR-R4-blue?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyQzYuNDggMiAyIDYuNDggMiAxMnM0LjQ4IDEwIDEwIDEwIDEwLTQuNDggMTAtMTBTMTcuNTIgMiAxMiAyem0wIDE4Yy00LjQxIDAtOC0zLjU5LTgtOHMzLjU5LTggOC04IDggMy41OSA4IDgtMy41OSA4LTggOHoiLz48L3N2Zz4=)](https://hl7.org/fhir/)
[![Ollama](https://img.shields.io/badge/Ollama-LLaMA_3.2-black?style=for-the-badge&logo=meta)](https://ollama.com)
[![Podman](https://img.shields.io/badge/Podman-Compose-892CA0?style=for-the-badge&logo=podman&logoColor=white)](https://podman.io)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br>

**A fully local clinical AI pipeline that reads patient data from a FHIR R4 server using Ollama. No data leaves your machine. Ever.**

**Um pipeline de IA clínica 100% local que lê dados de pacientes de um servidor FHIR R4 usando Ollama. Nenhum dado sai da sua máquina. Nunca.**

<br>

[🇬🇧 English](#-what-it-does) · [🇧🇷 Português](#-o-que-faz) · [📖 Full Docs ↓](#-full-documentation)

</div>

---

## 🇬🇧 What It Does

```
┌─────────────┐     REST API      ┌─────────────┐     Context      ┌─────────────┐
│             │  ──────────────►  │             │  ────────────►  │             │
│  HAPI FHIR  │   Patient data    │   Python    │   Clinical      │   Ollama    │
│  Server     │  ◄──────────────  │   Demo      │   reasoning     │  llama3.2   │
│  (FHIR R4)  │     JSON+FHIR     │             │  ◄────────────  │   (Local)   │
└─────────────┘                   └─────────────┘                 └─────────────┘
      ▲
      │ auto-loads patients & notes
┌─────────────┐
│   Synthea   │
│  (patient   │
│  generator) │
└─────────────┘
```

Three containers. One Python script. That's it.

The HAPI FHIR server stores clinical data (the same standard Brazil's national health network RNDS uses — 2.8 billion records). Synthea automatically generates synthetic patients on startup. The Python script queries patient data via REST API, builds a clinical context including DocumentReference evolution notes, and sends it to Ollama running llama3.2:3b locally. The AI responds with clinical reasoning grounded **exclusively** in the FHIR data. No hallucination. No cloud.

### 👥 Two Types of Patients

| Type | Patients | Language | Notes |
|------|----------|----------|-------|
| **Curated demo** | Maria Santos, João Oliveira, Ana Ferreira | Portuguese | Handwritten clinical + nursing evolution notes |
| **Synthea-generated** | Volume (configurable) | English | Template-generated evolution notes |

The Python demo shows curated patients first, then Synthea patients, with a dynamic paginated menu.

### ⚡ Quickstart

```bash
git clone https://github.com/rogeriorrodrigues/fhir-ollama-local.git
cd fhir-ollama-local

# Start all 3 services (FHIR + Ollama + Synthea — patients auto-generated)
podman-compose up -d

# Pull the model
podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b

# Run the demo
python3 fhir_ollama_demo.py
```

> Synthea generates patients automatically on startup. No need to run `load_patient.sh` manually for synthetic data. The curated demo patients (Maria/João/Ana) are loaded via `load_patient.sh` as part of the Synthea container's entrypoint.

### ⚙️ Synthea Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SYNTHEA_POPULATION` | `10` | Number of patients to generate |
| `SYNTHEA_SEED` | `42` | Random seed for reproducibility |
| `SYNTHEA_CLEAN_FIRST` | `false` | Wipe FHIR server before loading |
| `SYNTHEA_MIN_AGE` | `18` | Minimum patient age |
| `SYNTHEA_MAX_AGE` | `85` | Maximum patient age |

---

## 🇧🇷 O Que Faz

Três containers. Um script Python. Só isso.

O servidor HAPI FHIR armazena dados clínicos no padrão FHIR R4 — o mesmo que a RNDS do SUS usa (2,8 bilhões de registros). O Synthea gera pacientes sintéticos automaticamente ao iniciar. O script Python consulta os dados do paciente via REST API, monta o contexto clínico incluindo notas de evolução em DocumentReference, e envia para o Ollama rodando llama3.2:3b localmente. A IA responde com raciocínio clínico fundamentado **exclusivamente** nos dados do FHIR. Sem alucinação. Sem cloud.

### 👥 Dois Tipos de Pacientes

| Tipo | Pacientes | Idioma | Notas |
|------|-----------|--------|-------|
| **Demo curados** | Maria Santos, João Oliveira, Ana Ferreira | Português | Evoluções médicas e de enfermagem escritas à mão |
| **Gerados pelo Synthea** | Volume configurável | Inglês | Evoluções geradas por template |

O menu do demo exibe pacientes curados primeiro, depois pacientes do Synthea, com paginação dinâmica.

### ⚡ Início Rápido

```bash
git clone https://github.com/rogeriorrodrigues/fhir-ollama-local.git
cd fhir-ollama-local

# Sobe os 3 serviços (FHIR + Ollama + Synthea — pacientes gerados automaticamente)
podman-compose up -d

# Baixa o modelo
podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b

# Roda o demo
python3 fhir_ollama_demo.py
```

---

## 🩺 Curated Demo Patients

| Patient | Conditions | Key Observations |
|---------|------------|-----------------|
| **Maria Santos** | Diabetes mellitus, Hypertension | HbA1c 9.2%, BP 150/95 |
| **João Oliveira** | Heart failure, Chronic kidney disease | EF 35%, Creatinine 2.1 |
| **Ana Ferreira** | Asthma, Anxiety | Peak flow 320 L/min |

All resources use official terminologies (SNOMED CT, LOINC, UCUM) and follow the FHIR R4 spec. Each patient has DocumentReference resources with medical and nursing evolution notes in Portuguese.

---

## 🛠️ Stack

| Component | Role | License |
|-----------|------|---------|
| [HAPI FHIR](https://github.com/hapifhir/hapi-fhir-jpaserver-starter) | Clinical data server (FHIR R4) | Apache 2.0 |
| [Ollama](https://ollama.com) | Local LLM runtime | MIT |
| [llama3.2:3b](https://ollama.com/library/llama3.2) | Language model (lightweight) | Meta License |
| [Synthea](https://synthetichealth.github.io/synthea/) | Synthetic patient generator | Apache 2.0 |
| [Python](https://python.org) | Orchestration + demo | MIT |
| [Podman](https://podman.io) | Container runtime (rootless) | Apache 2.0 |

### Key Files

| File | Purpose |
|------|---------|
| `fhir_ollama_demo.py` | Interactive demo with dynamic paginated menu |
| `load_patient.sh` | Loads curated demo patients (Maria/João/Ana) |
| `load_evolutions.sh` | Loads clinical evolution notes (DocumentReference) |
| `synthea/Dockerfile` | Synthea container image |
| `synthea/entrypoint.sh` | Auto-generates patients and notes on startup |
| `synthea/generate_notes.py` | Creates template evolution notes for Synthea patients |
| `synthea/synthea.properties` | Synthea configuration (FHIR R4 output) |

---

## 🔐 Why It Matters

| | Traditional Cloud AI | This Pipeline |
|---|---|---|
| **Privacy** | Data sent to external APIs | Data never leaves your machine |
| **Cost** | API fees per token | Completely free |
| **Compliance** | Complex LGPD/GDPR setup | LGPD-friendly by design |
| **Standard** | Proprietary formats | FHIR R4 (RNDS/SUS compatible) |
| **Reproducible** | Depends on API availability | Runs offline, anytime |

---

## 📖 Full Documentation

| Language | Link |
|----------|------|
| 🇬🇧 English | [docs/README.en.md](docs/README.en.md) |
| 🇧🇷 Português | [docs/README.pt.md](docs/README.pt.md) |
| 🇪🇸 Español | [docs/README.es.md](docs/README.es.md) |
| 🇮🇹 Italiano | [docs/README.it.md](docs/README.it.md) |

---

## 🗺️ Roadmap

- [x] 🧬 Synthea integration for automated patient generation
- [x] 📋 Clinical evolution notes (DocumentReference) for all patients
- [ ] 🛡️ [Presidio](https://microsoft.github.io/presidio/) integration for pre-LLM anonymization
- [ ] 📊 RAGAS quality evaluation pipeline
- [ ] 🔌 MCP Server for standardized AI-FHIR access
- [ ] 🎓 Clinical simulation scenarios for nursing students

### 🛡️ About Presidio (future)

[Microsoft Presidio](https://microsoft.github.io/presidio/) is an open-source SDK for data protection and de-identification. It detects and anonymizes PII (names, CPFs, phone numbers, addresses) in text before sending it to an LLM. In this project, Presidio is **not yet integrated** because all patient data is already synthetic — curated patients are fictional and Synthea generates fully synthetic records. Presidio will become essential when the pipeline evolves to ingest real clinical data (e.g., from electronic health records), adding a pre-LLM anonymization layer to ensure LGPD/GDPR compliance even with real patient information.

[Presidio](https://microsoft.github.io/presidio/) é um SDK open-source da Microsoft para proteção e desidentificação de dados. Ele detecta e anonimiza dados pessoais (nomes, CPFs, telefones, endereços) em texto antes de enviar ao LLM. Neste projeto, o Presidio **ainda não está integrado** porque todos os dados de pacientes já são sintéticos — os pacientes curados são fictícios e o Synthea gera registros totalmente sintéticos. O Presidio se tornará essencial quando o pipeline evoluir para ingerir dados clínicos reais (ex: de prontuários eletrônicos), adicionando uma camada de anonimização pré-LLM para garantir conformidade com a LGPD mesmo com dados reais de pacientes.

---

## 👨‍💻 Author

**Rogério Rodrigues** — Azure MVP · UFSC Health Informatics Researcher · Professor USP/FIAP

*This repo is part of my master's research at UFSC on clinical simulation with AI for nursing students.*

---

<div align="center">

Made in Mato with ☕ from a sítio in Santa Catarina, Brazil

⭐ Star this repo if you found it useful!

</div>
