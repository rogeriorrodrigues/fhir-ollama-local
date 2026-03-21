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
- [Integrazione con Synthea](#-integrazione-con-synthea)
- [Note di Evoluzione Clinica](#-note-di-evoluzione-clinica)
- [Risorse FHIR Spiegate](#-risorse-fhir-spiegate)
- [Output Atteso](#-output-atteso)
- [Perché È Importante](#-perché-è-importante)
- [Risoluzione Problemi](#-risoluzione-problemi)
- [Prossimi Passi](#-prossimi-passi)

---

## 🎯 Cosa Fa

Questa pipeline esegue un'**IA clinica completamente locale** che legge i dati dei pazienti da un server FHIR R4 e fornisce ragionamento clinico — il tutto senza inviare un singolo byte al cloud.

**Tre servizi, un `podman-compose up`:**

| Componente | Cosa Fa | Porta |
|------------|---------|-------|
| 🔥 **HAPI FHIR** | Memorizza dati clinici in formato FHIR R4 | `8080` |
| 🦙 **Ollama** | Esegue llama3.2:3b localmente come cervello dell'IA | `11434` |
| 🧬 **Synthea** | Genera pazienti sintetici realistici automaticamente | — |

Lo script Python interroga FHIR → costruisce contesto → chiede a Ollama. L'IA **non allucina** perché lavora esclusivamente con i dati recuperati dal server FHIR. Ogni affermazione nella risposta è riconducibile a una risorsa clinica reale.

---

## 🏗️ Architettura

```
┌──────────────────────────────────────────────────────────────────┐
│                       LA TUA MACCHINA                            │
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │  HAPI FHIR  │    │   Synthea   │    │   Python    │         │
│  │  Server     │◄───│  (genera    │    │   Script    │         │
│  │             │    │  pazienti)  │    │             │         │
│  │  Porta 8080 │    └─────────────┘    │             │         │
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
│                                    │  Porta 11434  │          │
│                                    └───────────────┘          │
│                                         Podman                 │
│                                                                  │
│  🔒 Nulla esce da questa macchina. Conforme GDPR by design.    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisiti

| Requisito | Minimo | Note |
|-----------|--------|------|
| Podman + podman-compose | v4+ | [Installa Podman](https://podman.io/getting-started/installation) |
| Python | 3.8+ | Con libreria `requests` |
| Spazio su disco | ~5 GB | Immagine HAPI FHIR + modello llama3.2:3b |
| RAM | 8 GB+ | llama3.2:3b necessita ~2GB RAM |

```bash
pip install requests
```

---

## 🚀 Passo dopo Passo

### Passo 1: Clona e avvia i servizi

```bash
git clone https://github.com/YOUR_USER/fhir-ollama-local.git
cd fhir-ollama-local
podman-compose up -d
```

> 🧬 Synthea genera pazienti sintetici automaticamente all'avvio. Non è necessario caricarli manualmente.

### Passo 2: Scarica il modello llama3.2:3b

```bash
podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b
```

> ⏳ Solo la prima volta. Scarica ~2GB. Tempo per un caffè ☕

### Passo 3: Esegui la demo

```bash
python3 fhir_ollama_demo.py
```

🎉 Guarda l'IA leggere i dati clinici e ragionare in modo fondato!

---

## 🧠 Capire il Codice

### `fhir_ollama_demo.py` — La Logica Centrale

Lo script orchestra tre servizi e presenta un menu dinamico a due modalità:

**Modalità curata** — Paziente di riferimento con condizioni note (diabete, ipertensione).

**Modalità Synthea** — Selezione interattiva tra i pazienti generati automaticamente nella directory `synthea/`.

**1. Interroga FHIR** — Cinque chiamate REST per ottenere il quadro clinico completo:
```python
GET /Patient/{id}              → Dati demografici
GET /Condition?patient={id}    → Condizioni attive (diabete, ipertensione)
GET /Observation?patient={id}  → Risultati di laboratorio (HbA1c, pressione arteriosa)
GET /MedicationRequest?patient={id} → Farmaci attivi (metformina, losartan)
GET /DocumentReference?patient={id} → Note di evoluzione clinica infermieristica
```

**2. Costruisce il contesto** — Struttura i dati in un riepilogo clinico leggibile.

**3. Chiede a Ollama** — Invia il contesto con un prompt restrittivo: "rispondi SOLO sulla base dei dati forniti."

---

## 🧬 Integrazione con Synthea

Synthea genera automaticamente coorti di pazienti sintetici con cartelle cliniche realistiche all'avvio dei servizi.

### Variabili d'ambiente configurabili

```bash
SYNTHEA_POPULATION=10        # Numero di pazienti da generare (default: 10)
SYNTHEA_SEED=42              # Seed per riproducibilità
SYNTHEA_STATE=Massachusetts  # Stato/regione per i dati demografici
```

### Rigenerare i pazienti manualmente

```bash
# Pulire e rigenerare la coorte completa
podman-compose down
rm -rf synthea/output/*
podman-compose up -d
```

### Struttura della directory `synthea/`

```
synthea/
├── output/
│   ├── fhir/          # Bundle FHIR JSON pronti per l'importazione
│   └── csv/           # Dati in formato CSV (riferimento)
└── synthea.properties # Configurazione della generazione
```

---

## 📝 Note di Evoluzione Clinica

La pipeline supporta **note infermieristiche e di evoluzione clinica** tramite la risorsa `DocumentReference`, consentendo un ragionamento contestuale arricchito.

### Cosa sono

Le note di evoluzione sono registrazioni narrative scritte dal personale infermieristico che documentano l'andamento del paziente, osservazioni soggettive e piani di cura — informazioni che non trovano posto nei campi strutturati di FHIR.

### Come vengono usate in questa pipeline

```python
# Lo script recupera i DocumentReference e li include nel contesto
GET /DocumentReference?patient={id}&category=clinical-note

# Esempio di nota recuperata:
{
  "resourceType": "DocumentReference",
  "type": { "text": "Nursing progress note" },
  "content": [{
    "attachment": {
      "contentType": "text/plain",
      "data": "<base64>"   # Nota narrativa decodificata e inviata al LLM
    }
  }]
}
```

### Beneficio per il ragionamento clinico

Il LLM riceve sia dati strutturati (laboratori, farmaci) che narrativa clinica (note infermieristiche), producendo un ragionamento più completo e contestualizzato.

---

## 🩺 Risorse FHIR Spiegate

### Cos'è FHIR?

FHIR (Fast Healthcare Interoperability Resources) è lo standard globale per lo scambio di dati sanitari. Pensalo come **REST + JSON per dati clinici**. Se hai già costruito API REST, capisci già il 70% di FHIR.

### Risorse Utilizzate

| Risorsa | Tipo FHIR | Terminologia | Codice | Esempio |
|---------|-----------|--------------|--------|---------|
| Paziente | `Patient` | — | — | Maria Santos, F, 1966 |
| Diabete | `Condition` | SNOMED CT | `73211009` | Attivo |
| Ipertensione | `Condition` | SNOMED CT | `38341003` | Attivo |
| HbA1c | `Observation` | LOINC | `4548-4` | 9.2% |
| Pressione Art. | `Observation` | LOINC | `85354-9` | 150/95 mmHg |
| Metformina | `MedicationRequest` | Testo libero | — | 850mg BID |
| Losartan | `MedicationRequest` | Testo libero | — | 50mg QD |
| Nota clinica | `DocumentReference` | LOINC | `11506-3` | Nota infermieristica |

---

## 📺 Output Atteso

```
=== Pipeline IA Clinica Locale ===

Seleziona modalità:
  [1] Paziente curato (Maria Santos - diabete + ipertensione)
  [2] Pazienti Synthea (generati automaticamente)

Opzione: 2

Pazienti disponibili in Synthea:
  [1] John Doe, M, 1978 — Asthma, Hypertension
  [2] Ana Lima, F, 1990 — Type 2 Diabetes
  [3] Carlos Ramos, M, 1955 — COPD, Heart failure

Seleziona paziente: 1

=== Consultando il server FHIR ===

Dati recuperati:
Paziente: John Doe, male, nascita: 1978-03-22

Condizioni attive:
- Asthma (SNOMED: 195967001)
- Hypertensive disorder (SNOMED: 38341003)

Osservazioni recenti:
- Peak flow: 380 L/min
- Blood pressure: 145/90 mmHg

Farmaci attivi:
- Salbutamol 100mcg (PRN)
- Amlodipine 5mg QD

Note di evoluzione:
- [Nota infermieristica — 2024-01-15]: Paziente riferisce dispnea lieve notturna...

==================================================

Chiedendo a Ollama (llama3.2:3b)...

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
Podman (gratis) + Ollama (gratis) + HAPI FHIR (Apache 2.0) + Synthea (Apache 2.0) + Python (gratis) = **€0/mese**.

---

## 🔧 Risoluzione Problemi

| Problema | Soluzione |
|----------|----------|
| `Connection refused` sulla porta 8080 | HAPI FHIR impiega ~30s ad avviarsi. Attendi e riprova. |
| `model not found` in Ollama | Esegui `podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b` |
| Python `ModuleNotFoundError: requests` | Esegui `pip install requests` |
| Ollama lento a rispondere | llama3.2:3b necessita ~2GB RAM. Chiudi altre app. |
| Synthea non ha generato pazienti | Verifica i log con `podman-compose logs synthea` |
| Il menu non mostra pazienti Synthea | Conferma che `synthea/output/fhir/` contenga file `.json` |

---

## 🗺️ Prossimi Passi

- [x] ✅ 🧬 **Synthea** — Generazione automatica di pazienti sintetici
- [ ] 🛡️ **[Presidio](https://microsoft.github.io/presidio/)** — Strato di anonimizzazione Microsoft prima del LLM (vedi nota sotto)
- [ ] 📊 **RAGAS** — Valutazione qualità con faithfulness > 0.85
- [ ] 🔌 **MCP Server** — Protocollo standardizzato accesso IA-FHIR
- [ ] 🎓 **Scenari clinici** — Simulazione infermieristica con feedback adattivo

### 🛡️ Informazioni su Presidio (futuro)

[Microsoft Presidio](https://microsoft.github.io/presidio/) è un SDK open-source per la protezione e la de-identificazione dei dati. Rileva e anonimizza dati personali (nomi, codici fiscali, numeri di telefono, indirizzi) nel testo prima di inviarlo al LLM. In questo progetto, Presidio **non è ancora integrato** perché tutti i dati dei pazienti sono già sintetici — i pazienti curati sono fittizi e Synthea genera record completamente sintetici. Presidio diventerà essenziale quando la pipeline si evolverà per acquisire dati clinici reali (es: da cartelle cliniche elettroniche), aggiungendo uno strato di anonimizzazione pre-LLM per garantire la conformità al GDPR anche con informazioni reali dei pazienti.

---

<div align="center">

**[⬆ Torna in cima](#-ia-clinica-locale--pipeline-fhir)**

Fatto con ☕ da un sítio a Santa Catarina, Brasile

</div>
