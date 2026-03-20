# Synthea Integration Design

**Date**: 2026-03-19
**Status**: Review
**Goal**: Replace hardcoded patient data (load_patient.sh) with automated Synthea generation, maintaining the project's philosophy of zero-setup, reproducible, offline-first clinical AI pipeline.

---

## Context

The project currently loads 3 fixed patients (Maria, João, Ana) via `load_patient.sh` using curl commands. This limits clinical variety and allows students to memorize cases. Synthea generates realistic, randomized FHIR R4 patient records with full clinical histories.

### Requirements (from brainstorming)

- **Replace** `load_patient.sh` entirely — all data from Synthea
- **Container in docker-compose** — auto-generates and uploads on `podman-compose up -d`
- **Manual option** — `podman-compose run synthea` to regenerate anytime
- **Configurable** — population size, clinical modules, seed for reproducibility
- **Dynamic menu** — Python demo queries FHIR server instead of hardcoded dict, with pagination

---

## Architecture

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────┐
│  HAPI FHIR  │◄───│     Synthea      │    │   Ollama    │
│   :8080     │    │  (generate +     │    │   :11434    │
│             │    │   upload)         │    │             │
└──────┬──────┘    └──────────────────┘    └──────┬──────┘
       │                                          │
       │           ┌──────────────────┐           │
       └───────────│  fhir_ollama_    │───────────┘
                   │  demo.py         │
                   │  (dynamic menu)  │
                   └──────────────────┘
```

### Services (docker-compose.yml)

| Service | Image | Port | Behavior |
|---------|-------|------|----------|
| `fhir` | `hapiproject/hapi:latest` | 8080 | FHIR R4 server (unchanged) |
| `ollama` | `ollama/ollama:latest` | 11434 | LLM runtime (unchanged) |
| `synthea` | Custom (Dockerfile) | — | Generates patients, uploads to FHIR, exits |

The `synthea` service:
- `depends_on` fhir with health check
- Runs once and exits (not a long-running service)
- Can be re-invoked via `podman-compose run synthea`

---

## New Files

```
fhir-ollama-local/
├── docker-compose.yml              # Modified: add synthea service + fhir healthcheck
├── synthea/
│   ├── Dockerfile                  # eclipse-temurin:17-jre + Synthea JAR
│   ├── entrypoint.sh               # Wait for FHIR, generate, upload bundles
│   └── synthea.properties          # Synthea config: FHIR R4 output, locale, etc.
├── fhir_ollama_demo.py             # Modified: dynamic patient menu with pagination
└── load_patient.sh                 # Removed
```

---

## Synthea Container

### Dockerfile

- Base: `eclipse-temurin:17-jre-alpine` (~180MB, lightweight JRE)
- Downloads Synthea JAR from GitHub releases (pinned version for reproducibility)
- Copies `entrypoint.sh` and `synthea.properties`
- Entrypoint: `entrypoint.sh`

### synthea.properties

Key settings:
```properties
exporter.fhir.export = true
exporter.fhir.transaction_bundle = true
exporter.hospital.fhir.export = false
exporter.practitioner.fhir.export = false
exporter.ccda.export = false
exporter.csv.export = false
generate.append_numbers_to_person_names = false
```

Only FHIR bundles are exported — no CSV, CCDA, or other formats. Hospital/practitioner resources are excluded to keep the data focused on patient clinical records.

### entrypoint.sh

```
1. Wait for HAPI FHIR to respond at /metadata (poll with retries)
2. Parse environment variables (SYNTHEA_POPULATION, SYNTHEA_MODULES, SYNTHEA_SEED, SYNTHEA_CLEAN_FIRST, etc.)
3. If SYNTHEA_CLEAN_FIRST=true, delete all existing Patient resources from FHIR server
4. For each module in SYNTHEA_MODULES (comma-separated):
   - Run Synthea JAR with: -p $SYNTHEA_POPULATION -m $MODULE -s $SYNTHEA_SEED (if set)
   - Note: Synthea's -m flag accepts ONE module at a time, so we iterate
5. For each .json bundle in /output/fhir/:
   - POST to $FHIR_URL (transaction bundle)
   - Log success/failure
6. Print summary: "X patients loaded into FHIR server"
7. Exit 0
```

**Note on `-m` flag**: Synthea's `-m` runs in "module-only" mode and accepts a single module name per invocation. To generate patients with multiple condition profiles, the entrypoint iterates over the comma-separated `SYNTHEA_MODULES` list, running Synthea once per module. Each run generates `SYNTHEA_POPULATION` patients with that specific condition.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SYNTHEA_POPULATION` | `20` | Number of patients to generate **per module** |
| `SYNTHEA_STATE` | `Massachusetts` | State for demographic data |
| `SYNTHEA_MODULES` | `diabetes,asthma,congestive_heart_failure` | Clinical modules — one Synthea run per module |
| `SYNTHEA_SEED` | _(empty)_ | Random seed — if empty, generates different data each run |
| `SYNTHEA_CLEAN_FIRST` | `false` | If `true`, deletes all existing patients before generating |
| `FHIR_URL` | `http://fhir:8080/fhir` | FHIR server URL (internal Podman network) |

Default modules align with the original 3 scenarios:
- `diabetes` → covers Maria's diabetes + hypertension profile
- `asthma` → covers Ana's asthma scenario
- `congestive_heart_failure` → covers João's ICC scenario

Hypertension, pneumonia, atrial fibrillation, and CKD emerge naturally as comorbidities within these modules.

**Note on demographics**: Synthea does not have native Brazilian demographic data. Students at UFSC will see American names and US-based demographics by default. Synthea's internationalization options can be explored in future iterations.

---

## docker-compose.yml Changes

```yaml
services:
  fhir:
    image: hapiproject/hapi:latest
    ports:
      - "8080:8080"
    environment:
      - hapi.fhir.allow_multiple_delete=true
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:8080/fhir/metadata || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 12

  synthea:
    build: ./synthea
    depends_on:
      fhir:
        condition: service_healthy
    environment:
      - SYNTHEA_POPULATION=${SYNTHEA_POPULATION:-20}
      - SYNTHEA_STATE=${SYNTHEA_STATE:-Massachusetts}
      - SYNTHEA_MODULES=${SYNTHEA_MODULES:-diabetes,asthma,congestive_heart_failure}
      - SYNTHEA_SEED=${SYNTHEA_SEED:-}
      - SYNTHEA_CLEAN_FIRST=${SYNTHEA_CLEAN_FIRST:-false}
      - FHIR_URL=http://fhir:8080/fhir

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama

volumes:
  ollama_data:
```

Key changes:
- Added `healthcheck` to `fhir` service so `synthea` waits properly
- `synthea` uses `depends_on` with `condition: service_healthy`
- All Synthea config overridable via `.env` file or command line
- Removed `version: '3.8'` (obsolete)

---

## fhir_ollama_demo.py Changes

### Remove hardcoded PATIENTS dict

Replace with dynamic FHIR queries.

### New function: `list_patients(page, page_size=10)`

Uses FHIR Bundle pagination (following `Bundle.link` with `relation: "next"`/`"previous"`) rather than `_offset`, which may not be available in default HAPI FHIR configuration.

First page: `GET /Patient?_count={page_size}&_sort=family`
Next pages: follow the `next` link URL from the Bundle response.

Returns list of `{id, name, gender, birthDate}`.

### New function: `get_patient_summary(patient_id)`

```
GET /Condition?patient={patient_id}&clinical-status=active
```

Returns list of active condition display names for the menu. Does not use `_summary=true` to ensure `code.coding[0].display` is available in the response.

### Updated `show_menu()`

Displays paginated patient list with condition summaries:

```
==================================================
  FHIR + Ollama - Assistente Clinico
==================================================

Pacientes disponiveis (pagina 1/3):

  [1] John Smith (M, 1958-03-12)
      Diabetes mellitus, Hypertensive disorder
  [2] Jane Doe (F, 1990-07-22)
      Asthma, Pneumonia
  ...
  [10] Carlos Lima (M, 1972-01-05)
       Heart failure, Atrial fibrillation

  [n] Proxima pagina
  [p] Pagina anterior
  [0] Sair
```

### Flow

1. Query total patient count: `GET /Patient?_summary=count`
2. Display current page with condition summaries
3. User selects patient number, `n`, `p`, or `0`
4. On selection, `get_fhir_context()` + `ask_ollama()` flow continues (with defensive fixes below)
5. If no patients found, display: "Nenhum paciente encontrado. Aguarde o carregamento do Synthea."

---

## Removed Files

- `load_patient.sh` — fully replaced by Synthea container

---

## Usage After Integration

### Default (automatic):
```bash
podman-compose up -d
# Synthea generates 20 patients and loads into FHIR automatically
# Wait ~1-2 min for generation + upload

podman exec -it $(podman ps -q -f name=ollama) ollama pull phi4  # first time only

python3 fhir_ollama_demo.py
```

### Custom population:
```bash
SYNTHEA_POPULATION=50 podman-compose up -d
```

### Regenerate patients (additive):
```bash
podman-compose run synthea
```

### Regenerate patients (clean slate):
```bash
SYNTHEA_CLEAN_FIRST=true podman-compose run synthea
```

### Reproducible runs (same patients every time):
```bash
SYNTHEA_SEED=42 podman-compose up -d
```

### Filter specific modules:
```bash
SYNTHEA_MODULES=diabetes,lung_cancer podman-compose up -d
```

---

## Compatibility Notes

- **Podman**: All commands use `podman-compose`. Dockerfile and compose file are Podman-compatible.
- **Offline**: Synthea JAR is baked into the Docker image at build time. No internet needed at runtime.
- **LGPD/GDPR**: Synthea generates fully synthetic data — no real patient information.

---

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Synthea image size (~300MB with JRE) | Use alpine-based JRE image; only runs once then exits |
| Generation time for large populations | Default is 20 patients (~30s); documented that 500+ may take minutes |
| Synthea modules may not perfectly match original scenarios | Default modules cover diabetes, asthma, CHF; document how to customize |
| FHIR bundle upload failures | entrypoint.sh logs errors per bundle; non-zero exit on failure |
| `get_fhir_context()` may break with Synthea's richer data | **Required fix**: medication name extraction must handle both `medicationCodeableConcept.text`, `medicationCodeableConcept.coding[0].display`, and `medicationReference`. Dosage must handle missing `dosageInstruction`. All field access must use `.get()` with fallbacks. |
| Empty FHIR server if demo runs before Synthea finishes | Show friendly message: "Nenhum paciente encontrado. Aguarde o carregamento do Synthea." |
