<div align="center">

# 🏥 Local Clinical AI + FHIR Pipeline

### _Zero Cloud · Zero Cost · Zero Data Leakage_

<br>

[![FHIR R4](https://img.shields.io/badge/FHIR-R4-blue?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyQzYuNDggMiAyIDYuNDggMiAxMnM0LjQ4IDEwIDEwIDEwIDEwLTQuNDggMTAtMTBTMTcuNTIgMiAxMiAyem0wIDE4Yy00LjQxIDAtOC0zLjU5LTgtOHMzLjU5LTggOC04IDggMy41OSA4IDgtMy41OSA4LTggOHoiLz48L3N2Zz4=)](https://hl7.org/fhir/)
[![Ollama](https://img.shields.io/badge/Ollama-LLaMA_3-black?style=for-the-badge&logo=meta)](https://ollama.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
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
│  Server     │  ◄──────────────  │   Script    │   reasoning     │   LLaMA 3   │
│  (FHIR R4)  │     JSON+FHIR     │             │  ◄────────────  │   (Local)   │
└─────────────┘                   └─────────────┘                 └─────────────┘
    Docker                           60 lines                        Docker
```

Two Docker containers. One Python script. That's it.

The HAPI FHIR server stores clinical data (the same standard Brazil's national health network RNDS uses — 2.8 billion records). The Python script queries patient data via REST API, builds a clinical context, and sends it to Ollama running LLaMA 3 locally. The AI responds with clinical reasoning grounded **exclusively** in the FHIR data. No hallucination. No cloud.

### ⚡ Quickstart

```bash
git clone https://github.com/rogerrrodrigues/fhir-ollama-local.git
cd fhir-ollama-local

docker compose up -d
docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3
bash load_patient.sh
python fhir_ollama_demo.py
```

---

## 🇧🇷 O Que Faz

Dois containers Docker. Um script Python de 60 linhas. Só isso.

O servidor HAPI FHIR armazena dados clínicos no padrão FHIR R4 — o mesmo que a RNDS do SUS usa (2,8 bilhões de registros). O script Python consulta os dados do paciente via REST API, monta o contexto clínico e envia para o Ollama rodando LLaMA 3 localmente. A IA responde com raciocínio clínico fundamentado **exclusivamente** nos dados do FHIR. Sem alucinação. Sem cloud.

### ⚡ Início Rápido

```bash
git clone https://github.com/rogerrrodrigues/fhir-ollama-local.git
cd fhir-ollama-local

docker compose up -d
docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3
bash load_patient.sh
python fhir_ollama_demo.py
```

---

## 🩺 Sample Patient: Maria Santos

| Resource | Details | Code |
|----------|---------|------|
| 👤 **Patient** | Maria Santos, female, born 1966-05-12 | — |
| 🔴 **Condition** | Diabetes mellitus | `SNOMED 73211009` |
| 🟠 **Condition** | Hypertensive disorder | `SNOMED 38341003` |
| 🔬 **Observation** | Hemoglobin A1c: **9.2%** | `LOINC 4548-4` |
| 💓 **Observation** | Blood pressure: **150/95 mmHg** | `LOINC 85354-9` |
| 💊 **Medication** | Metformin 850mg (2x/day) | — |
| 💊 **Medication** | Losartan 50mg (1x/day) | — |

All resources use official terminologies (SNOMED CT, LOINC, UCUM) and follow the FHIR R4 specification.

---

## 🛠️ Stack

| Component | Role | License |
|-----------|------|---------|
| [🔥 HAPI FHIR](https://github.com/hapifhir/hapi-fhir-jpaserver-starter) | Clinical data server (FHIR R4) | Apache 2.0 |
| [🦙 Ollama](https://ollama.com) | Local LLM runtime | MIT |
| [🧠 LLaMA 3](https://llama.meta.com) | Language model | Meta License |
| [🐍 Python](https://python.org) | Orchestration (60 lines) | MIT |
| [🐳 Docker](https://docker.com) | Container runtime | Apache 2.0 |

---

## 🔐 Why It Matters

| | Traditional Cloud AI | This Pipeline |
|---|---|---|
| 🔒 **Privacy** | Data sent to external APIs | Data never leaves your machine |
| 💰 **Cost** | API fees per token | Completely free |
| 📋 **Compliance** | Complex LGPD/GDPR setup | LGPD-friendly by design |
| 🏥 **Standard** | Proprietary formats | FHIR R4 (RNDS/SUS compatible) |
| 🔄 **Reproducible** | Depends on API availability | Runs offline, anytime |

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

- [ ] 🧬 Synthea integration for automated patient generation
- [ ] 🛡️ Presidio integration for pre-LLM anonymization
- [ ] 📊 RAGAS quality evaluation pipeline
- [ ] 🔌 MCP Server for standardized AI-FHIR access
- [ ] 🎓 Clinical simulation scenarios for nursing students

---

## 👨‍💻 Author

**Rogério Rodrigues** — Azure MVP · UFSC Health Informatics Researcher · Professor USP/FIAP

*This repo is part of my master's research at UFSC on clinical simulation with AI for nursing students.*

---

<div align="center">

Made with ☕ from a sítio in Santa Catarina, Brazil

⭐ Star this repo if you found it useful!

</div>
