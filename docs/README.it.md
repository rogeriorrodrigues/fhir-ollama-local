<div align="center">

# 🏥 IA Clinica Locale + Pipeline FHIR

### 🇮🇹 Documentazione Completa in Italiano

[← Torna al README Principale](../README.md) · [🇬🇧 English](README.en.md) · [🇧🇷 Português](README.pt.md) · [🇪🇸 Español](README.es.md)

</div>

---

## 📋 Indice

- [Cosa Fa](#-cosa-fa)
- [Architettura](#-architettura)
- [Prerequisiti](#-prerequisiti)
- [Passo dopo Passo](#-passo-dopo-passo)
- [Capire il Codice](#-capire-il-codice)
- [Risorse FHIR Spiegate](#-risorse-fhir-spiegate)
- [Output Atteso](#-output-atteso)
- [Perché È Importante](#-perché-è-importante)
- [Risoluzione Problemi](#-risoluzione-problemi)
- [Prossimi Passi](#-prossimi-passi)

---

## 🎯 Cosa Fa

Questa pipeline esegue un'**IA clinica completamente locale** che legge i dati dei pazienti da un server FHIR R4 e fornisce ragionamento clinico — il tutto senza inviare un singolo byte al cloud.

**Tre componenti, un `docker compose up`:**

| Componente | Cosa Fa | Porta |
|------------|---------|-------|
| 🔥 **HAPI FHIR** | Memorizza dati clinici in formato FHIR R4 | `8080` |
| 🦙 **Ollama** | Esegue LLaMA 3 localmente come cervello dell'IA | `11434` |
| 🐍 **Script Python** | Interroga FHIR → costruisce contesto → chiede a Ollama | — |

L'IA **non allucina** perché lavora esclusivamente con i dati recuperati dal server FHIR. Ogni affermazione nella risposta è riconducibile a una risorsa clinica reale.

---

## 🏗️ Architettura

```
┌──────────────────────────────────────────────────────────────────┐
│                       LA TUA MACCHINA                            │
│                                                                  │
│  ┌─────────────┐                          ┌─────────────┐       │
│  │  HAPI FHIR  │◄── REST API (JSON) ──►  │   Python    │       │
│  │  Server     │    GET /Patient          │   Script    │       │
│  │             │    GET /Condition         │ (60 righe)  │       │
│  │  Porta 8080 │    GET /Observation       │             │       │
│  │             │    GET /MedicationRequest │             │       │
│  └─────────────┘                          └──────┬──────┘       │
│       Docker                                     │              │
│                                          POST /api/generate      │
│                                                   │              │
│                                          ┌────────▼──────┐      │
│                                          │    Ollama     │      │
│                                          │   LLaMA 3    │      │
│                                          │  Porta 11434 │      │
│                                          └───────────────┘      │
│                                               Docker            │
│                                                                  │
│  🔒 Nulla esce da questa macchina. Conforme GDPR by design.    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisiti

| Requisito | Minimo | Note |
|-----------|--------|------|
| Docker + Docker Compose | v20+ | [Installa Docker](https://docs.docker.com/get-docker/) |
| Python | 3.8+ | Con libreria `requests` |
| Spazio su disco | ~5 GB | Immagine HAPI FHIR + modello LLaMA 3 |
| RAM | 8 GB+ | LLaMA 3 necessita ~4GB RAM |

```bash
pip install requests
```

---

## 🚀 Passo dopo Passo

### Passo 1: Clona e avvia i servizi

```bash
git clone https://github.com/YOUR_USER/fhir-ollama-local.git
cd fhir-ollama-local
docker compose up -d
```

### Passo 2: Scarica il modello LLaMA 3

```bash
docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3
```

> ⏳ Solo la prima volta. Scarica ~4GB. Tempo per un caffè ☕

### Passo 3: Carica il paziente di esempio

```bash
bash load_patient.sh
```

### Passo 4: Esegui la demo

```bash
python fhir_ollama_demo.py
```

🎉 Guarda l'IA leggere i dati clinici e ragionare in modo fondato!

---

## 🧠 Capire il Codice

### `fhir_ollama_demo.py` — La Logica Centrale

Lo script fa tre cose:

**1. Interroga FHIR** — Quattro chiamate REST per ottenere il quadro clinico completo:
```python
GET /Patient/{id}              → Dati demografici
GET /Condition?patient={id}    → Condizioni attive (diabete, ipertensione)
GET /Observation?patient={id}  → Risultati di laboratorio (HbA1c, pressione arteriosa)
GET /MedicationRequest?patient={id} → Farmaci attivi (metformina, losartan)
```

**2. Costruisce il contesto** — Struttura i dati in un riepilogo clinico leggibile.

**3. Chiede a Ollama** — Invia il contesto con un prompt restrittivo: "rispondi SOLO sulla base dei dati forniti."

---

## 🩺 Risorse FHIR Spiegate

### Cos'è FHIR?

FHIR (Fast Healthcare Interoperability Resources) è lo standard globale per lo scambio di dati sanitari. Pensalo come **REST + JSON per dati clinici**. Se hai già costruito API REST, capisci già il 70% di FHIR.

### Risorse Create

| Risorsa | Tipo FHIR | Terminologia | Codice | Valore |
|---------|-----------|--------------|--------|--------|
| Paziente | `Patient` | — | — | Maria Santos, F, 1966 |
| Diabete | `Condition` | SNOMED CT | `73211009` | Attivo |
| Ipertensione | `Condition` | SNOMED CT | `38341003` | Attivo |
| HbA1c | `Observation` | LOINC | `4548-4` | 9.2% |
| Pressione Art. | `Observation` | LOINC | `85354-9` | 150/95 mmHg |
| Metformina | `MedicationRequest` | Testo libero | — | 850mg BID |
| Losartan | `MedicationRequest` | Testo libero | — | 50mg QD |

---

## 📺 Output Atteso

```
=== Consultando servidor FHIR ===

Dati recuperati:
Paziente: Maria Santos, female, nascita: 1966-05-12

Condizioni attive:
- Diabetes mellitus (SNOMED: 73211009)
- Hypertensive disorder (SNOMED: 38341003)

Osservazioni recenti:
- Hemoglobin A1c: 9.2 %
- Blood pressure panel: Systolic: 150mmHg, Diastolic: 95mmHg

Farmaci attivi:
- Metformina 850mg (850mg 2x/dia)
- Losartana 50mg (50mg 1x/dia)

==================================================

Chiedendo a Ollama (llama3)...

Risposta:
[Ollama risponde con ragionamento clinico basato sui dati FHIR]
```

---

## 🔐 Perché È Importante

### 🏛️ Privacy (GDPR)
Nessun dato del paziente esce dalla tua macchina. L'intera pipeline gira localmente. Questo elimina l'ostacolo più comune all'adozione dell'IA clinica: **"non possiamo inviare i dati dei pazienti ad API esterne."**

### 🌍 Standard Internazionale
FHIR R4 è lo standard globale usato da Epic, Oracle Health (Cerner), la RNDS brasiliana e sistemi sanitari in oltre 22 paesi. Costruire su FHIR oggi significa compatibilità con le infrastrutture sanitarie di domani.

### 💰 Costo Zero
Docker (gratis) + Ollama (gratis) + HAPI FHIR (Apache 2.0) + Python (gratis) = **€0/mese**.

---

## 🔧 Risoluzione Problemi

| Problema | Soluzione |
|----------|----------|
| `Connection refused` sulla porta 8080 | HAPI FHIR impiega ~30s ad avviarsi. Attendi o esegui `load_patient.sh`. |
| `model not found` in Ollama | Esegui `docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3` |
| Python `ModuleNotFoundError: requests` | Esegui `pip install requests` |
| Ollama lento a rispondere | LLaMA 3 necessita ~4GB RAM. Chiudi altre app. |

---

## 🗺️ Prossimi Passi

- [ ] 🧬 **Synthea** — Generare pazienti sintetici automaticamente
- [ ] 🛡️ **Presidio** — Strato di anonimizzazione Microsoft prima del LLM
- [ ] 📊 **RAGAS** — Valutazione qualità con faithfulness > 0.85
- [ ] 🔌 **MCP Server** — Protocollo standardizzato accesso IA-FHIR
- [ ] 🎓 **Scenari clinici** — Simulazione infermieristica con feedback adattivo

---

<div align="center">

**[⬆ Torna in cima](#-ia-clinica-locale--pipeline-fhir)**

Fatto con ☕ da un sítio a Santa Catarina, Brasile

</div>
