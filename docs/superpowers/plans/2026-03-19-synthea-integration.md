# Synthea Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hardcoded patient data with automated Synthea generation in a Podman container, and make the Python demo dynamically list patients from the FHIR server with pagination.

**Architecture:** A new `synthea` service in docker-compose builds a custom image (JRE + Synthea JAR), waits for HAPI FHIR health check, generates patients per clinical module, and uploads FHIR bundles. The Python demo queries the FHIR server dynamically instead of using a hardcoded patient dict.

**Tech Stack:** Podman/podman-compose, Java 17 JRE (eclipse-temurin), Synthea JAR, HAPI FHIR R4, Python 3 (requests), Bash

**Spec:** `docs/superpowers/specs/2026-03-19-synthea-integration-design.md`

---

## File Structure

```
fhir-ollama-local/
├── docker-compose.yml              # MODIFY: add synthea service, fhir healthcheck, remove version
├── synthea/                        # CREATE: new directory
│   ├── Dockerfile                  # CREATE: JRE + Synthea JAR image
│   ├── entrypoint.sh               # CREATE: generate + upload logic
│   └── synthea.properties          # CREATE: Synthea export config
├── fhir_ollama_demo.py             # MODIFY: dynamic menu, defensive FHIR parsing
└── load_patient.sh                 # DELETE: replaced by Synthea
```

---

### Task 1: Create Synthea Dockerfile

**Files:**
- Create: `synthea/Dockerfile`

- [ ] **Step 1: Create synthea directory**

```bash
mkdir -p synthea
```

- [ ] **Step 2: Write the Dockerfile**

Create `synthea/Dockerfile`:

```dockerfile
FROM eclipse-temurin:17-jre-alpine

RUN apk add --no-cache bash curl jq

# Pin Synthea version for reproducibility
ENV SYNTHEA_VERSION=3.3.0
RUN curl -L -o /opt/synthea.jar \
    https://github.com/synthetichealth/synthea/releases/download/v${SYNTHEA_VERSION}/synthea-with-dependencies.jar

COPY synthea.properties /opt/synthea.properties
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

WORKDIR /opt
ENTRYPOINT ["/opt/entrypoint.sh"]
```

- [ ] **Step 3: Commit**

```bash
git add synthea/Dockerfile
git commit -m "feat: add Synthea Dockerfile with JRE alpine and pinned version"
```

---

### Task 2: Create synthea.properties

**Files:**
- Create: `synthea/synthea.properties`

- [ ] **Step 1: Write synthea.properties**

Create `synthea/synthea.properties`:

```properties
# Export only FHIR R4 transaction bundles
exporter.fhir.export = true
exporter.fhir.transaction_bundle = true

# Disable all other exporters
exporter.hospital.fhir.export = false
exporter.practitioner.fhir.export = false
exporter.ccda.export = false
exporter.csv.export = false
exporter.text.export = false
exporter.html.export = false

# Patient name settings
generate.append_numbers_to_person_names = false
```

- [ ] **Step 2: Commit**

```bash
git add synthea/synthea.properties
git commit -m "feat: add Synthea properties for FHIR-only export"
```

---

### Task 3: Create entrypoint.sh

**Files:**
- Create: `synthea/entrypoint.sh`

- [ ] **Step 1: Write entrypoint.sh**

Create `synthea/entrypoint.sh`:

```bash
#!/bin/bash
set -e

FHIR_URL="${FHIR_URL:-http://fhir:8080/fhir}"
POPULATION="${SYNTHEA_POPULATION:-20}"
STATE="${SYNTHEA_STATE:-Massachusetts}"
MODULES="${SYNTHEA_MODULES:-diabetes,asthma,congestive_heart_failure}"
SEED="${SYNTHEA_SEED:-}"
CLEAN_FIRST="${SYNTHEA_CLEAN_FIRST:-false}"

echo "=== Synthea Patient Generator ==="
echo "  Population per module: $POPULATION"
echo "  State: $STATE"
echo "  Modules: $MODULES"
echo "  Seed: ${SEED:-random}"
echo "  Clean first: $CLEAN_FIRST"
echo "  FHIR URL: $FHIR_URL"
echo ""

# Wait for HAPI FHIR
echo "Aguardando HAPI FHIR..."
RETRIES=0
MAX_RETRIES=60
until curl -sf "$FHIR_URL/metadata" > /dev/null 2>&1; do
  RETRIES=$((RETRIES + 1))
  if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
    echo "ERRO: HAPI FHIR nao respondeu apos $MAX_RETRIES tentativas"
    exit 1
  fi
  echo "  aguardando... ($RETRIES/$MAX_RETRIES)"
  sleep 5
done
echo "HAPI FHIR pronto!"

# Clean existing data if requested
if [ "$CLEAN_FIRST" = "true" ]; then
  echo ""
  echo "Limpando pacientes existentes..."
  # Get all patient IDs and delete them (using jq, available in the container)
  PATIENT_IDS=$(curl -sf "$FHIR_URL/Patient?_elements=id&_count=1000" | \
    jq -r '.entry[]?.resource.id // empty' 2>/dev/null || true)
  for PID in $PATIENT_IDS; do
    curl -sf -X DELETE "$FHIR_URL/Patient/$PID?_cascade=delete" > /dev/null 2>&1 || true
    echo "  Deletado: Patient/$PID"
  done
  echo "Limpeza concluida."
fi

# Generate patients per module
TOTAL_UPLOADED=0
IFS=',' read -ra MODULE_LIST <<< "$MODULES"

for MODULE in "${MODULE_LIST[@]}"; do
  MODULE=$(echo "$MODULE" | xargs)  # trim whitespace
  echo ""
  echo "--- Gerando pacientes com modulo: $MODULE ---"

  # Build Synthea command (using array to handle spaces in STATE safely)
  CMD=(java -jar /opt/synthea.jar -p "$POPULATION" -m "$MODULE"
       --exporter.baseDirectory "/output/$MODULE" -c /opt/synthea.properties)
  if [ -n "$SEED" ]; then
    CMD+=(-s "$SEED")
  fi
  CMD+=("$STATE")

  echo "Executando: ${CMD[*]}"
  "${CMD[@]}"

  # Upload FHIR bundles
  BUNDLE_DIR="/output/$MODULE/fhir"
  if [ -d "$BUNDLE_DIR" ]; then
    BUNDLE_COUNT=0
    for BUNDLE in "$BUNDLE_DIR"/*.json; do
      [ -f "$BUNDLE" ] || continue
      HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" \
        -X POST "$FHIR_URL" \
        -H "Content-Type: application/fhir+json" \
        -d @"$BUNDLE")
      if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
        BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
      else
        echo "  AVISO: falha ao carregar $BUNDLE (HTTP $HTTP_CODE)"
      fi
    done
    echo "  Modulo $MODULE: $BUNDLE_COUNT bundles carregados"
    TOTAL_UPLOADED=$((TOTAL_UPLOADED + BUNDLE_COUNT))
  else
    echo "  AVISO: nenhum bundle gerado para modulo $MODULE"
  fi
done

echo ""
echo "=========================================="
echo "  Synthea concluido!"
echo "  Total: $TOTAL_UPLOADED bundles carregados"
echo "=========================================="
```

- [ ] **Step 2: Make executable**

```bash
chmod +x synthea/entrypoint.sh
```

- [ ] **Step 3: Commit**

```bash
git add synthea/entrypoint.sh
git commit -m "feat: add Synthea entrypoint with module iteration and FHIR upload"
```

---

### Task 4: Update docker-compose.yml

**Files:**
- Modify: `docker-compose.yml`

- [ ] **Step 1: Rewrite docker-compose.yml**

Replace the full content of `docker-compose.yml`:

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

- [ ] **Step 2: Verify compose file is valid**

```bash
podman-compose config
```

Expected: prints resolved YAML without errors.

- [ ] **Step 3: Commit**

```bash
git add docker-compose.yml
git commit -m "feat: add synthea service with healthcheck and env config"
```

---

### Task 5: Harden get_fhir_context() for Synthea data

**Files:**
- Modify: `fhir_ollama_demo.py:13-78`

Synthea generates richer FHIR data with different field patterns than the hardcoded data. The `get_fhir_context()` function must handle:
- `medicationCodeableConcept` with `coding[0].display` instead of `text`
- `medicationReference` instead of `medicationCodeableConcept`
- Missing `dosageInstruction`
- Missing `name`, `given`, `family` fields
- Observations with `valueCodeableConcept` instead of `valueQuantity`

- [ ] **Step 1: Rewrite get_fhir_context() with defensive field access**

Replace `get_fhir_context()` in `fhir_ollama_demo.py` (lines 13-78) with:

```python
def get_fhir_context(patient_id):
    """Consulta dados clinicos do paciente via FHIR REST API"""
    patient = requests.get(f"{FHIR_URL}/Patient/{patient_id}").json()
    names = patient.get("name") or [{}]
    name = names[0] if names else {}
    given = name.get("given", [""])[0]
    family = name.get("family", "")
    gender = patient.get("gender", "")
    birth = patient.get("birthDate", "")
    info = f"Paciente: {given} {family}, {gender}, nascimento: {birth}"

    # Encounter
    encounters = requests.get(f"{FHIR_URL}/Encounter?patient={patient_id}").json()
    enc_info = []
    for e in encounters.get("entry", []):
        r = e["resource"]
        status = r.get("status", "")
        locations = [
            loc["location"]["display"]
            for loc in r.get("location", [])
            if "display" in loc.get("location", {})
        ]
        if locations:
            enc_info.append(f"- Local: {', '.join(locations)} (status: {status})")

    # Conditions
    conditions = requests.get(f"{FHIR_URL}/Condition?patient={patient_id}").json()
    conds = []
    for e in conditions.get("entry", []):
        code_block = e["resource"].get("code", {})
        coding = code_block.get("coding", [{}])[0]
        display = coding.get("display", code_block.get("text", "Desconhecido"))
        code_val = coding.get("code", "")
        severity = ""
        sev = e["resource"].get("severity")
        if sev:
            sev_coding = sev.get("coding", [{}])[0]
            severity = f" - Gravidade: {sev_coding.get('display', '')}"
        conds.append(f"- {display} (SNOMED: {code_val}){severity}")

    # Observations
    observations = requests.get(f"{FHIR_URL}/Observation?patient={patient_id}").json()
    obs = []
    for e in observations.get("entry", []):
        r = e["resource"]
        code_display = r.get("code", {}).get("coding", [{}])[0].get("display", "")
        if "valueQuantity" in r:
            v = r["valueQuantity"]
            obs.append(f"- {code_display}: {v.get('value', '')} {v.get('unit', '')}")
        elif "component" in r:
            parts = []
            for comp in r["component"]:
                c = comp.get("code", {}).get("coding", [{}])[0].get("display", "")
                v = comp.get("valueQuantity", {})
                parts.append(f"{c}: {v.get('value', '')}{v.get('unit', '')}")
            obs.append(f"- {code_display}: {', '.join(parts)}")
        elif "valueCodeableConcept" in r:
            v = r["valueCodeableConcept"]
            val_display = v.get("coding", [{}])[0].get("display", v.get("text", ""))
            obs.append(f"- {code_display}: {val_display}")

    # Medications
    meds = requests.get(
        f"{FHIR_URL}/MedicationRequest?patient={patient_id}&status=active"
    ).json()
    med_list = []
    for e in meds.get("entry", []):
        r = e["resource"]
        # Handle both medicationCodeableConcept and medicationReference
        med_concept = r.get("medicationCodeableConcept", {})
        med_name = med_concept.get("text") or (
            med_concept.get("coding", [{}])[0].get("display", "")
        )
        if not med_name and "medicationReference" in r:
            med_name = r["medicationReference"].get("display", "Medicamento")
        dosage_list = r.get("dosageInstruction", [])
        dosage = dosage_list[0].get("text", "") if dosage_list else ""
        if dosage:
            med_list.append(f"- {med_name} ({dosage})")
        else:
            med_list.append(f"- {med_name}")

    nl = "\n"
    sections = [info]
    if enc_info:
        sections.append(f"\nInternacao:\n{nl.join(enc_info)}")
    if conds:
        sections.append(f"\nCondicoes ativas:\n{nl.join(conds)}")
    if obs:
        sections.append(f"\nObservacoes recentes:\n{nl.join(obs)}")
    if med_list:
        sections.append(f"\nMedicacoes ativas:\n{nl.join(med_list)}")
    return "\n".join(sections)
```

- [ ] **Step 2: Verify existing patients still work**

```bash
python3 -c "
import requests
FHIR_URL = 'http://localhost:8080/fhir'
exec(open('fhir_ollama_demo.py').read().split('if __name__')[0])
print(get_fhir_context('maria-001'))
"
```

Expected: Maria Santos' clinical context prints without errors.

- [ ] **Step 3: Commit**

```bash
git add fhir_ollama_demo.py
git commit -m "fix: harden get_fhir_context for Synthea's richer FHIR data"
```

---

### Task 6: Replace hardcoded menu with dynamic patient listing

**Files:**
- Modify: `fhir_ollama_demo.py:1-10,99-147`

- [ ] **Step 1: Replace constants and add patient listing functions**

Replace lines 1-10 of `fhir_ollama_demo.py` (imports + PATIENTS dict) with:

```python
import requests
import math

FHIR_URL = "http://localhost:8080/fhir"
OLLAMA_URL = "http://localhost:11434/api/generate"
PAGE_SIZE = 10
```

- [ ] **Step 2: Add list_patients function**

Add after the constants (before `get_fhir_context`):

```python
def get_patient_count():
    """Retorna total de pacientes no servidor FHIR"""
    resp = requests.get(f"{FHIR_URL}/Patient?_summary=count").json()
    return resp.get("total", 0)


def list_patients(page=0):
    """Lista pacientes com paginacao usando Bundle links"""
    url = f"{FHIR_URL}/Patient?_count={PAGE_SIZE}&_sort=family"
    # Navigate to the correct page by following next links
    for _ in range(page):
        resp = requests.get(url).json()
        next_link = None
        for link in resp.get("link", []):
            if link.get("relation") == "next":
                next_link = link["url"]
                break
        if not next_link:
            return []
        url = next_link

    resp = requests.get(url).json()
    patients = []
    for e in resp.get("entry", []):
        r = e["resource"]
        name = r.get("name", [{}])[0]
        given = name.get("given", [""])[0]
        family = name.get("family", "")
        patients.append({
            "id": r["id"],
            "name": f"{given} {family}".strip(),
            "gender": r.get("gender", ""),
            "birthDate": r.get("birthDate", ""),
        })
    return patients


def get_patient_conditions(patient_id):
    """Retorna lista de condicoes ativas para exibir no menu"""
    resp = requests.get(
        f"{FHIR_URL}/Condition?patient={patient_id}&clinical-status=active"
    ).json()
    conditions = []
    for e in resp.get("entry", []):
        code_block = e["resource"].get("code", {})
        coding = code_block.get("coding", [{}])[0]
        display = coding.get("display", code_block.get("text", ""))
        if display:
            conditions.append(display)
    return conditions
```

- [ ] **Step 3: Replace show_menu and main loop**

Replace everything from `show_menu()` to end of file (lines 99-147) with:

```python
def show_menu(patients, page, total_pages):
    print("\n" + "=" * 50)
    print("  FHIR + Ollama - Assistente Clinico")
    print("=" * 50)

    if not patients:
        print("\n  Nenhum paciente encontrado.")
        print("  Aguarde o carregamento do Synthea.")
        print(f"\n  [0] Sair")
        print()
        return

    print(f"\nPacientes disponiveis (pagina {page + 1}/{total_pages}):\n")
    for i, p in enumerate(patients, 1):
        gender_label = p["gender"][0].upper() if p["gender"] else "?"
        print(f"  [{i}] {p['name']} ({gender_label}, {p['birthDate']})")
        conditions = get_patient_conditions(p["id"])
        if conditions:
            print(f"      {', '.join(conditions[:5])}")

    print()
    if total_pages > 1:
        if page < total_pages - 1:
            print("  [n] Proxima pagina")
        if page > 0:
            print("  [p] Pagina anterior")
    print("  [0] Sair")
    print()


if __name__ == "__main__":
    page = 0
    while True:
        total = get_patient_count()
        total_pages = max(1, math.ceil(total / PAGE_SIZE))
        patients = list_patients(page)

        show_menu(patients, page, total_pages)
        choice = input("Escolha o paciente: ").strip().lower()

        if choice == "0":
            print("\nEncerrado. Ate logo!")
            break
        elif choice == "n" and page < total_pages - 1:
            page += 1
            continue
        elif choice == "p" and page > 0:
            page -= 1
            continue

        try:
            idx = int(choice) - 1
            if 0 <= idx < len(patients):
                patient = patients[idx]
            else:
                print("\nOpcao invalida. Tente novamente.")
                continue
        except ValueError:
            print("\nOpcao invalida. Tente novamente.")
            continue

        print(f"\n>>> Consultando FHIR para: {patient['name']}...")
        ctx = get_fhir_context(patient["id"])
        print(f"\n{ctx}")
        print("\n" + "-" * 50)
        print(f"Modo interativo - Paciente: {patient['name']}")
        print("Digite suas perguntas (ou 'voltar' para trocar de paciente)")
        print("-" * 50)

        while True:
            try:
                q = input("\nVoce: ").strip()
            except (KeyboardInterrupt, EOFError):
                print("\n\nEncerrado. Ate logo!")
                exit(0)

            if not q:
                continue
            if q.lower() == "voltar":
                break

            print("\nPensando...\n")
            answer = ask_ollama(ctx, q)
            print(f"Resposta:\n{answer}")
```

- [ ] **Step 4: Verify dynamic menu works with existing patients**

```bash
python3 -c "
exec(open('fhir_ollama_demo.py').read().split('if __name__')[0])
count = get_patient_count()
print(f'Total patients: {count}')
patients = list_patients(0)
for p in patients:
    conds = get_patient_conditions(p['id'])
    print(f\"  {p['name']} - {', '.join(conds)}\")
"
```

Expected: Lists 3 existing patients (Maria, João, Ana) with their conditions.

- [ ] **Step 5: Commit**

```bash
git add fhir_ollama_demo.py
git commit -m "feat: dynamic patient menu with FHIR pagination and condition summaries"
```

---

### Task 7: Delete load_patient.sh

**Files:**
- Delete: `load_patient.sh`

- [ ] **Step 1: Remove load_patient.sh**

```bash
rm load_patient.sh
```

- [ ] **Step 2: Commit**

```bash
git add -u load_patient.sh
git commit -m "chore: remove hardcoded load_patient.sh, replaced by Synthea"
```

---

### Task 8: Build and test Synthea container

**Files:**
- All `synthea/` files + `docker-compose.yml`

- [ ] **Step 1: Stop existing containers**

```bash
podman-compose down
```

- [ ] **Step 2: Build the Synthea image**

```bash
podman-compose build synthea
```

Expected: Image builds successfully, downloads Synthea JAR.

- [ ] **Step 3: Start all services**

```bash
podman-compose up -d
```

Expected: fhir starts, passes healthcheck, synthea starts generating patients.

- [ ] **Step 4: Watch Synthea logs**

```bash
podman-compose logs -f synthea
```

Expected: See module iteration, bundle uploads, and final count summary.

- [ ] **Step 5: Verify patients in FHIR server**

```bash
curl -s http://localhost:8080/fhir/Patient?_summary=count | python3 -c "import sys,json; print(f\"Total patients: {json.load(sys.stdin).get('total', 0)}\")"
```

Expected: Shows ~60 patients (20 per module x 3 modules).

- [ ] **Step 6: Test the Python demo**

```bash
python3 fhir_ollama_demo.py
```

Expected: Dynamic menu shows paginated Synthea patients with condition summaries. Selecting a patient and asking a question returns an Ollama response.

- [ ] **Step 7: Test manual regeneration with clean slate**

```bash
SYNTHEA_CLEAN_FIRST=true podman-compose run synthea
```

Expected: Deletes old patients, generates new ones, uploads successfully.

- [ ] **Step 8: Commit any fixes found during testing**

```bash
git add -A
git commit -m "fix: adjustments from integration testing"
```

---

### Task 9: Update .gitignore

**Files:**
- Modify: `gitignore` (rename to `.gitignore` if needed)

- [ ] **Step 1: Rename gitignore to .gitignore (if needed)**

```bash
[ -f gitignore ] && mv gitignore .gitignore
```

- [ ] **Step 2: Add Synthea output to .gitignore**

Append to `.gitignore`:

```
# Synthea generated output
synthea/output/
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: rename gitignore and add synthea output"
```
