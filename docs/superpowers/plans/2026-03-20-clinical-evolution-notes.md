# Clinical Evolution Notes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add clinical evolution history (medical and nursing notes) as DocumentReference and Observation resources to both curated and Synthea patients, so the AI can answer questions about patient evolution.

**Architecture:** Curated patients get handwritten Portuguese evolution notes via a new `load_evolutions.sh` script (called from `load_patient.sh`). Synthea patients get template-generated English notes via a new `generate_notes.py` script (called from `entrypoint.sh`). The Python demo's `get_fhir_context()` gains a DocumentReference section to include notes in the AI context.

**Tech Stack:** Bash/curl (curated notes), Python 3 stdlib (Synthea notes), FHIR R4 DocumentReference/Observation, HAPI FHIR server

**Spec:** `docs/superpowers/specs/2026-03-20-clinical-evolution-notes-design.md`

---

## File Structure

```
fhir-ollama-local/
├── load_patient.sh                 # MODIFY: add effectiveDateTime to existing Observations, call load_evolutions.sh
├── load_evolutions.sh              # CREATE: DocumentReference + nursing Observations for curated patients
├── synthea/
│   ├── generate_notes.py           # CREATE: template-based note generator for Synthea patients
│   ├── entrypoint.sh               # MODIFY: call generate_notes.py after Synthea upload
│   └── Dockerfile                  # MODIFY: add python3
├── fhir_ollama_demo.py             # MODIFY: add import base64, add DocumentReference section to get_fhir_context()
```

---

### Task 1: Backfill effectiveDateTime on existing Observations in load_patient.sh

**Files:**
- Modify: `load_patient.sh`

All existing Observations lack `effectiveDateTime`. Add timestamps using the scenario date `2026-03-19`.

- [ ] **Step 1: Add effectiveDateTime to Maria's Observations**

In `load_patient.sh`, add `"effectiveDateTime": "2026-03-19T10:00:00Z"` to every Observation for maria-001 (HbA1c at line 56, BP at line 66). Add the field right after `"status": "final",`.

For HbA1c (line 53-61), change to:
```json
    "resourceType": "Observation",
    "status": "final",
    "effectiveDateTime": "2026-03-19T10:00:00Z",
    "subject": {"reference": "Patient/maria-001"},
```

For BP panel (line 63-74), same pattern with `"effectiveDateTime": "2026-03-19T10:00:00Z"`.

- [ ] **Step 2: Add effectiveDateTime to Joao's Observations**

Add timestamps spread across 2 days for João's 7 Observations:
- BNP: `"effectiveDateTime": "2026-03-19T08:00:00Z"` (admission day 1 morning)
- Ejection fraction: `"effectiveDateTime": "2026-03-19T09:00:00Z"`
- Creatinine: `"effectiveDateTime": "2026-03-19T08:30:00Z"`
- Sodium: `"effectiveDateTime": "2026-03-19T08:30:00Z"`
- Potassium: `"effectiveDateTime": "2026-03-19T08:30:00Z"`
- SpO2: `"effectiveDateTime": "2026-03-19T08:00:00Z"`
- BP: `"effectiveDateTime": "2026-03-19T08:00:00Z"`

- [ ] **Step 3: Add effectiveDateTime to Ana's Observations**

Add timestamps for Ana's 6 Observations (PS arrival):
- Temperature: `"effectiveDateTime": "2026-03-19T14:00:00Z"`
- SpO2: `"effectiveDateTime": "2026-03-19T14:00:00Z"`
- RR: `"effectiveDateTime": "2026-03-19T14:00:00Z"`
- WBC: `"effectiveDateTime": "2026-03-19T14:30:00Z"`
- CRP: `"effectiveDateTime": "2026-03-19T14:30:00Z"`
- Peak flow: `"effectiveDateTime": "2026-03-19T14:15:00Z"`

- [ ] **Step 4: Commit**

```bash
git add load_patient.sh
git commit -m "fix: backfill effectiveDateTime on all curated Observations"
```

---

### Task 2: Create load_evolutions.sh with Maria's evolution notes

**Files:**
- Create: `load_evolutions.sh`

Create a new script for evolution notes. Start with Maria (simplest — 2 consultations).

- [ ] **Step 1: Create load_evolutions.sh with header and Maria's notes**

Create `load_evolutions.sh`:

```bash
#!/bin/bash
# Evolution notes for curated patients
# Called from load_patient.sh after base resources are created
FHIR_URL="${FHIR_URL:-http://localhost:8080/fhir}"

########################################
# MARIA SANTOS - Evolucoes ambulatoriais
########################################
echo ""
echo "--- Evolucoes: Maria Santos ---"

# Consulta 1 - Nota medica (consultation note)
NOTE1=$(echo -n "CONSULTA MEDICA - 19/03/2026
Medico: Dra. Fernanda Lima - Endocrinologia

Motivo: Primeira consulta para avaliacao de diabetes e hipertensao.

Historia: Paciente feminina, 59 anos, encaminhada pela UBS com glicemia de jejum
alterada e PA elevada em duas consultas consecutivas. Refere poliuria, polidipsia
e cansaco ha 3 meses. Nega dor toracica, dispneia ou edema. Antecedente familiar
de DM2 (mae e irmao). Sedentaria, IMC 31.2.

Exame fisico: PA 150/95 mmHg, FC 82 bpm, peso 78kg.
Ausculta cardiaca: RCR 2T, sem sopros. Pulmonar: MV presente bilateral.
Pele: sem lesoes. Extremidades: sem edema, pulsos presentes.

Exames: HbA1c 9.2% (meta <7%), glicemia jejum 198 mg/dL.

Diagnosticos:
1. Diabetes mellitus tipo 2 - diagnostico recente, descompensada
2. Hipertensao arterial sistemica

Conduta:
1. Metformina 850mg 2x/dia (iniciar com 850mg 1x/dia na primeira semana)
2. Losartana 50mg 1x/dia
3. Orientacao dietetica: restricao de carboidratos simples e sodio
4. Solicitar: perfil lipidico, funcao renal, fundo de olho, ECG
5. Retorno em 30 dias com exames" | base64 -w0)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11488-4\", \"display\": \"Consultation note\"}]},
    \"subject\": {\"reference\": \"Patient/maria-001\"},
    \"date\": \"2026-03-19T10:00:00Z\",
    \"author\": [{\"display\": \"Dra. Fernanda Lima - Endocrinologia\"}],
    \"description\": \"Consulta medica inicial - Endocrinologia\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE1\"}}]
  }" > /dev/null && echo "DocumentReference: Consulta medica inicial (Maria)"

# Consulta 2 - Retorno 30 dias (progress note)
NOTE2=$(echo -n "EVOLUCAO MEDICA - RETORNO 30 DIAS
Medico: Dra. Fernanda Lima - Endocrinologia
Data: 19/04/2026

Subjetivo: Paciente retorna para reavaliacao. Refere melhora parcial da poliuria.
Aderiu a dieta com restricao de carboidratos. Tolera bem Metformina 850mg 2x/dia.
Sem hipoglicemia. PA em domicilio variando 135-145/85-90 mmHg.

Objetivo: PA 142/88 mmHg, FC 78 bpm, peso 76.5kg (-1.5kg).
HbA1c controle: 8.4% (anterior 9.2% - melhora, porem ainda acima da meta).
Perfil lipidico: CT 245, LDL 155, HDL 38, TG 210. Creatinina 0.9, TFG 85.
Fundo de olho: sem retinopatia. ECG: ritmo sinusal, sem alteracoes.

Avaliacao:
1. DM2 em melhora, mas HbA1c ainda acima da meta - intensificar tratamento
2. HAS controlada parcialmente
3. Dislipidemia mista

Conduta:
1. Manter Metformina 850mg 2x/dia
2. Adicionar Glicazida 30mg 1x/dia (manha)
3. Manter Losartana 50mg 1x/dia
4. Iniciar Sinvastatina 20mg 1x/dia (noite)
5. Reforcar atividade fisica: caminhada 30min/dia
6. Retorno em 60 dias" | base64 -w0)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11506-3\", \"display\": \"Progress note\"}]},
    \"subject\": {\"reference\": \"Patient/maria-001\"},
    \"date\": \"2026-04-19T10:00:00Z\",
    \"author\": [{\"display\": \"Dra. Fernanda Lima - Endocrinologia\"}],
    \"description\": \"Retorno 30 dias - Endocrinologia\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE2\"}}]
  }" > /dev/null && echo "DocumentReference: Retorno 30 dias (Maria)"
```

- [ ] **Step 2: Make executable and commit**

```bash
chmod +x load_evolutions.sh
git add load_evolutions.sh
git commit -m "feat: add Maria Santos evolution notes (2 consultations)"
```

---

### Task 3: Add Joao's evolution notes to load_evolutions.sh

**Files:**
- Modify: `load_evolutions.sh`

Add João's 8 DocumentReferences (2 days of ICU) and serial vital signs Observations.

- [ ] **Step 1: Add João's Day 1 notes (4 DocumentReferences)**

Append to `load_evolutions.sh` after Maria's section. Include:

1. **Admission note (medical)** — `type: 11506-3`, date `2026-03-19T08:00:00Z`, author "Dr. Ricardo Mendes - Cardiologia". Content: ICC descompensada NYHA IV, edema agudo de pulmao, FA de alta resposta, admissao UTI, plano de estabilizacao com furosemida EV + dobutamina.

2. **Nursing admission** — `type: 28651-8`, date `2026-03-19T08:30:00Z`, author "Enf. Lucia Ferreira". Content: Glasgow 15, dispneia intensa, edema MMII ++/4+, ortopneia, acesso venoso central, monitorizacao continua, balanco hidrico, cateter O2 5L/min.

3. **Medical evolution afternoon** — `type: 11506-3`, date `2026-03-19T14:00:00Z`, author "Dr. Ricardo Mendes". Content: Resposta parcial a diureticos, debito urinario 400ml em 6h, PA estavel 90/60, SpO2 melhorando 91%, mantido dobutamina, ajuste furosemida.

4. **Nursing evolution night** — `type: 28651-8`, date `2026-03-19T20:00:00Z`, author "Enf. Patricia Santos". Content: Balanco hidrico negativo -800ml, SpO2 92% com O2 3L/min, aceitou dieta leve, sem queixas de dor, diurese presente.

Each note follows the same curl pattern as Maria's notes: base64 encode the text, POST to `/DocumentReference`.

- [ ] **Step 2: Add João's Day 2 notes (4 DocumentReferences)**

5. **Medical evolution morning** — `type: 11506-3`, date `2026-03-20T08:00:00Z`, author "Dr. Ricardo Mendes". Content: Melhora clinica significativa, edema reduzido, PA 100/65, SpO2 94% ar ambiente, BNP controle 980, inicio de desmame de dobutamina, ecocardiograma solicitado.

6. **Nursing evolution morning** — `type: 28651-8`, date `2026-03-20T08:30:00Z`, author "Enf. Lucia Ferreira". Content: Paciente sentado no leito, edema +/4+, aceitando dieta, deambulou ao banheiro com auxilio, peso 80.5kg (-2kg), balanco -1200ml 24h.

7. **Medical evolution afternoon** — `type: 11506-3`, date `2026-03-20T14:00:00Z`, author "Dr. Ricardo Mendes". Content: Ecocardiograma: FE 25%, insuficiencia mitral moderada, VE dilatado. Parecer cardio: manter carvedilol dose baixa, suspender dobutamina gradual, avaliar alta UTI em 24-48h.

8. **Nursing evolution night** — `type: 28651-8`, date `2026-03-20T20:00:00Z`, author "Enf. Patricia Santos". Content: Estavel, dobutamina reduzida para 2.5mcg/kg/min, sem intercorrencias, diurese mantida, SpO2 95% ar ambiente, aceitou dieta completa.

- [ ] **Step 3: Add João's serial vital signs (Observations every 6h)**

Append 8 sets of vital signs (BP, HR, SpO2) showing clinical progression across 2 days. Each Observation has `effectiveDateTime`, `performer`, and category `vital-signs`.

**Day 1 progression (improving from admission):**
- 08h: PA 90/60, FC 112, SpO2 88%
- 14h: PA 95/62, FC 105, SpO2 91%
- 20h: PA 98/65, FC 98, SpO2 92%

**Day 2 progression (continued improvement):**
- 02h: PA 100/65, FC 95, SpO2 93%
- 08h: PA 105/68, FC 88, SpO2 94%
- 14h: PA 108/70, FC 85, SpO2 95%
- 20h: PA 110/72, FC 82, SpO2 95%

Use the existing BP panel pattern (LOINC 85354-9 with components) and individual Observations for HR (LOINC 8867-4) and SpO2 (LOINC 2708-6). Each set is 3 curl calls.

Also add 2 weight Observations (daily):
- Day 1: 82.5kg `2026-03-19T08:00:00Z`
- Day 2: 80.5kg `2026-03-20T08:00:00Z`

- [ ] **Step 4: Commit**

```bash
git add load_evolutions.sh
git commit -m "feat: add Joao Oliveira ICU evolution notes (8 notes + serial vitals)"
```

---

### Task 4: Add Ana's evolution notes to load_evolutions.sh

**Files:**
- Modify: `load_evolutions.sh`

Add Ana's 4 DocumentReferences (PS flow) and post-treatment vital signs.

- [ ] **Step 1: Add Ana's PS flow notes (4 DocumentReferences)**

1. **Triage note** — `type: 34878-9`, date `2026-03-19T14:00:00Z`, author "Enf. Marcos Silva - Triagem". Content: Queixa principal: falta de ar e febre ha 2 dias. Asmatica cronica em uso de bombinha de resgate. Classificacao Manchester: LARANJA (urgente). SV: T 38.7, FR 28, SpO2 91%, PA 130/85.

2. **Medical assessment** — `type: 11506-3`, date `2026-03-19T14:30:00Z`, author "Dr. Carlos Souza - Emergencia". Content: Exacerbacao de asma grave + pneumonia comunitaria. Sibilos difusos, crepitantes em base D, uso de musculatura acessoria. Peak flow 180 L/min (40% previsto). Leucocitos 15200, PCR 89. Conduta: nebulizacao salbutamol+ipratropio, prednisolona VO, amoxicilina-clavulanato, O2 cateter 3L/min.

3. **Nursing note** — `type: 28651-8`, date `2026-03-19T15:00:00Z`, author "Enf. Julia Andrade". Content: Realizada nebulizacao com salbutamol 5mg + ipratropio 0.5mg. Paciente referiu melhora parcial apos 15 min. SpO2 subiu de 91% para 94%. Administrada prednisolona 40mg VO. Iniciado amoxicilina-clavulanato 875mg VO. Acesso periferico MSD. Mantida em observacao.

4. **Medical reassessment** — `type: 11506-3`, date `2026-03-19T16:30:00Z`, author "Dr. Carlos Souza - Emergencia". Content: Reavaliacao 2h apos tratamento. Melhora significativa: FR 20, SpO2 94%, sibilos leves, sem uso de musculatura acessoria. Peak flow 280 L/min (62% previsto). Decisao: manter em observacao por mais 2h, se estavel alta com prescricao.

- [ ] **Step 2: Add Ana's post-treatment vital signs**

3 sets showing improvement:
- Arrival (14:00): SpO2 91%, FR 28, FC 110, PA 130/85, T 38.7
- Post-nebulization (15:00): SpO2 94%, FR 24, FC 98, PA 125/82
- Reassessment (16:30): SpO2 94%, FR 20, FC 88, PA 120/80

Plus post-bronchodilator peak flow:
- Post (15:15): Peak flow 280 L/min

- [ ] **Step 3: Commit**

```bash
git add load_evolutions.sh
git commit -m "feat: add Ana Costa PS evolution notes (4 notes + post-treatment vitals)"
```

---

### Task 5: Call load_evolutions.sh from load_patient.sh

**Files:**
- Modify: `load_patient.sh`

- [ ] **Step 1: Add call to load_evolutions.sh at the end of load_patient.sh**

Before the "VERIFICACAO FINAL" section (line 448), add:

```bash
########################################
# EVOLUCOES CLINICAS
########################################
echo ""
echo "=========================================="
echo "  Carregando evolucoes clinicas"
echo "=========================================="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/load_evolutions.sh" ]; then
  bash "$SCRIPT_DIR/load_evolutions.sh"
elif [ -f "/opt/load_evolutions.sh" ]; then
  bash "/opt/load_evolutions.sh"
fi
```

- [ ] **Step 2: Commit**

```bash
git add load_patient.sh
git commit -m "feat: call load_evolutions.sh from load_patient.sh"
```

---

### Task 6: Update Dockerfile to include python3 and load_evolutions.sh

**Files:**
- Modify: `synthea/Dockerfile`

- [ ] **Step 1: Add python3 to apt-get and COPY load_evolutions.sh**

In `synthea/Dockerfile`, change:
```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends curl jq && rm -rf /var/lib/apt/lists/*
```
to:
```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends curl jq python3 && rm -rf /var/lib/apt/lists/*
```

And add after the existing COPY lines:
```dockerfile
COPY load_evolutions.sh /opt/load_evolutions.sh
```

And update chmod:
```dockerfile
RUN chmod +x /opt/entrypoint.sh /opt/load_patient.sh /opt/load_evolutions.sh
```

- [ ] **Step 2: Commit**

```bash
git add synthea/Dockerfile
git commit -m "feat: add python3 and load_evolutions.sh to Synthea container"
```

---

### Task 7: Create generate_notes.py for Synthea patients

**Files:**
- Create: `synthea/generate_notes.py`

Python script using only stdlib (`urllib.request`, `json`, `base64`) that generates template-based clinical notes for Synthea patients.

- [ ] **Step 1: Create generate_notes.py**

Create `synthea/generate_notes.py`:

```python
#!/usr/bin/env python3
"""Generate clinical evolution notes for Synthea patients using templates."""
import sys
import json
import base64
import urllib.request
from datetime import datetime

CURATED_IDS = {"maria-001", "joao-002", "ana-003"}


def fhir_get(fhir_url, path):
    """GET a FHIR resource, return parsed JSON."""
    url = f"{fhir_url}/{path}"
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except Exception:
        return {}


def fhir_post(fhir_url, resource_type, data):
    """POST a FHIR resource."""
    url = f"{fhir_url}/{resource_type}"
    body = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Content-Type", "application/fhir+json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status
    except Exception as e:
        print(f"  AVISO: falha ao postar {resource_type}: {e}")
        return 0


def get_patients(fhir_url):
    """Get all patients, excluding curated ones."""
    data = fhir_get(fhir_url, "Patient?_count=100&_sort=family")
    patients = []
    for e in data.get("entry", []):
        r = e["resource"]
        if r["id"] in CURATED_IDS:
            continue
        names = r.get("name") or [{}]
        name = names[0] if names else {}
        given = name.get("given", [""])[0]
        family = name.get("family", "")
        patients.append({
            "id": r["id"],
            "name": f"{given} {family}".strip(),
            "gender": r.get("gender", "unknown"),
            "birthDate": r.get("birthDate", ""),
        })
    return patients


def get_conditions(fhir_url, patient_id):
    """Get active conditions for a patient."""
    data = fhir_get(fhir_url, f"Condition?patient={patient_id}&_count=20")
    conditions = []
    seen = set()
    for e in data.get("entry", []):
        coding = e["resource"].get("code", {}).get("coding", [{}])[0]
        display = coding.get("display", "")
        if display and display not in seen:
            seen.add(display)
            conditions.append(display)
    return conditions


def get_medications(fhir_url, patient_id):
    """Get medications for a patient."""
    data = fhir_get(fhir_url, f"MedicationRequest?patient={patient_id}&_count=10")
    meds = []
    for e in data.get("entry", []):
        r = e["resource"]
        concept = r.get("medicationCodeableConcept", {})
        name = concept.get("text") or (concept.get("coding", [{}])[0].get("display", ""))
        if not name and "medicationReference" in r:
            name = r["medicationReference"].get("display", "")
        if name:
            meds.append(name)
    return meds


def get_recent_vitals(fhir_url, patient_id):
    """Get recent vital sign observations."""
    data = fhir_get(fhir_url, f"Observation?patient={patient_id}&_sort=-date&_count=10")
    vitals = {}
    for e in data.get("entry", []):
        r = e["resource"]
        code = r.get("code", {}).get("coding", [{}])[0].get("display", "")
        if "valueQuantity" in r:
            v = r["valueQuantity"]
            vitals[code] = f"{v.get('value', '')} {v.get('unit', '')}"
        elif "component" in r:
            parts = []
            for comp in r["component"]:
                c = comp.get("code", {}).get("coding", [{}])[0].get("display", "")
                v = comp.get("valueQuantity", {})
                parts.append(f"{c}: {v.get('value', '')}{v.get('unit', '')}")
            vitals[code] = ", ".join(parts)
    return vitals


def assess_vitals(vitals):
    """Generate vitals assessment text."""
    findings = []
    for key, val in vitals.items():
        if "blood pressure" in key.lower() and "systolic" in val.lower():
            try:
                sys_val = float(val.split(":")[1].split("mm")[0].strip())
                if sys_val > 140:
                    findings.append("elevated blood pressure")
            except (ValueError, IndexError):
                pass
        if "oxygen" in key.lower():
            try:
                spo2 = float(val.split()[0])
                if spo2 < 95:
                    findings.append("low oxygen saturation")
            except (ValueError, IndexError):
                pass
        if "heart rate" in key.lower():
            try:
                hr = float(val.split()[0])
                if hr > 100:
                    findings.append("tachycardia")
            except (ValueError, IndexError):
                pass
        if "temperature" in key.lower():
            try:
                temp = float(val.split()[0])
                if temp > 38:
                    findings.append("febrile")
            except (ValueError, IndexError):
                pass
    return ", ".join(findings) if findings else "within normal limits"


def generate_medical_note(patient, conditions, medications, vitals):
    """Generate a medical progress note from template."""
    vitals_lines = "\n".join(f"- {k}: {v}" for k, v in vitals.items()) or "- No recent vitals available"
    cond_lines = "\n".join(f"- {c}" for c in conditions) or "- No active conditions documented"
    med_lines = "\n".join(f"- {m}" for m in medications) or "- No active medications"
    primary = conditions[0] if conditions else "medical condition"
    key_meds = ", ".join(medications[:3]) if medications else "current regimen"
    assessment = assess_vitals(vitals)

    return f"""Assessment and Plan - {datetime.now().strftime('%Y-%m-%d')}

Patient: {patient['name']}, {patient['gender']}

Active Conditions:
{cond_lines}

Current Medications:
{med_lines}

Recent Vitals:
{vitals_lines}

Assessment:
Patient with {primary}. Current treatment includes {key_meds}. Vital signs {assessment}.

Plan:
- Continue current medications
- Monitor vital signs
- Follow-up as scheduled"""


def generate_nursing_note(patient, conditions, medications, vitals):
    """Generate a nursing assessment note from template."""
    vitals_lines = "\n".join(f"- {k}: {v}" for k, v in vitals.items()) or "- No recent vitals available"
    med_lines = "\n".join(f"- {m}" for m in medications) or "- No active medications"
    primary = conditions[0] if conditions else "medical condition"
    cond_obs = f"Diagnosed with {', '.join(conditions[:3])}" if conditions else "No active conditions documented"

    return f"""Nursing Assessment - {datetime.now().strftime('%Y-%m-%d')}

Patient: {patient['name']} | Shift: Day

Vital Signs:
{vitals_lines}

Current Medications Administered:
{med_lines}

Assessment:
Patient is alert and oriented, ambulatory with assistance. {cond_obs}.

Interventions:
- Vital signs monitoring per protocol
- Medication administration as ordered
- Patient education on {primary}

Plan:
- Continue monitoring
- Report changes in vital signs or symptoms"""


def create_document_reference(fhir_url, patient_id, doc_type_code, doc_type_display, author, description, content_text):
    """Create and POST a DocumentReference."""
    encoded = base64.b64encode(content_text.encode("utf-8")).decode("ascii")
    doc = {
        "resourceType": "DocumentReference",
        "status": "current",
        "type": {"coding": [{"system": "http://loinc.org", "code": doc_type_code, "display": doc_type_display}]},
        "subject": {"reference": f"Patient/{patient_id}"},
        "date": datetime.now().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "author": [{"display": author}],
        "description": description,
        "content": [{"attachment": {"contentType": "text/plain", "data": encoded}}],
    }
    return fhir_post(fhir_url, "DocumentReference", doc)


def main():
    if len(sys.argv) < 2:
        print("Usage: generate_notes.py <FHIR_URL>")
        sys.exit(1)

    fhir_url = sys.argv[1]
    patients = get_patients(fhir_url)
    generated = 0

    for patient in patients:
        conditions = get_conditions(fhir_url, patient["id"])
        if not conditions:
            continue

        medications = get_medications(fhir_url, patient["id"])
        vitals = get_recent_vitals(fhir_url, patient["id"])

        # Medical progress note
        med_note = generate_medical_note(patient, conditions, medications, vitals)
        status = create_document_reference(
            fhir_url, patient["id"],
            "11506-3", "Progress note",
            "Dr. Smith - Internal Medicine",
            "Medical progress note",
            med_note,
        )
        if 200 <= status < 300:
            generated += 1

        # Nursing note
        nrs_note = generate_nursing_note(patient, conditions, medications, vitals)
        status = create_document_reference(
            fhir_url, patient["id"],
            "28651-8", "Nurse notes",
            "RN Johnson",
            "Nursing assessment",
            nrs_note,
        )
        if 200 <= status < 300:
            generated += 1

    print(f"  {generated} notas clinicas geradas para {len([p for p in patients if get_conditions(fhir_url, p['id'])])} pacientes Synthea")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Commit**

```bash
git add synthea/generate_notes.py
git commit -m "feat: add template-based clinical note generator for Synthea patients"
```

---

### Task 8: Update entrypoint.sh to call generate_notes.py

**Files:**
- Modify: `synthea/entrypoint.sh`

- [ ] **Step 1: Add generate_notes.py call after Synthea upload**

At the end of `entrypoint.sh`, before the final "Synthea concluido!" message, add:

```bash
# Generate clinical notes for Synthea patients
echo ""
echo "Gerando evolucoes clinicas para pacientes Synthea..."
python3 /opt/generate_notes.py "$FHIR_URL"
```

- [ ] **Step 2: Commit**

```bash
git add synthea/entrypoint.sh
git commit -m "feat: call generate_notes.py from entrypoint after Synthea upload"
```

---

### Task 9: Add DocumentReference section to get_fhir_context() in fhir_ollama_demo.py

**Files:**
- Modify: `fhir_ollama_demo.py`

- [ ] **Step 1: Add `import base64` at the top of the file**

Add `import base64` after `import math` (line 2).

- [ ] **Step 2: Add DocumentReference query section to get_fhir_context()**

After the CarePlans section and before the final `sections` assembly, add:

```python
    # Clinical notes (evolucoes clinicas)
    docs = requests.get(
        f"{FHIR_URL}/DocumentReference?patient={patient_id}&_sort=-date&_count=10"
    ).json()
    notes = []
    for e in docs.get("entry", []):
        r = e["resource"]
        doc_type = r.get("type", {}).get("coding", [{}])[0].get("display", "Note")
        date = r.get("date", "")[:16]
        author = r.get("author", [{}])[0].get("display", "")
        description = r.get("description", "")
        content = ""
        for c in r.get("content", []):
            data = c.get("attachment", {}).get("data", "")
            if data:
                content = base64.b64decode(data).decode("utf-8", errors="replace")
        header = f"- [{doc_type}] {date}"
        if author:
            header += f" | {author}"
        if description:
            header += f" | {description}"
        if content:
            truncated = content[:500] + "..." if len(content) > 500 else content
            notes.append(f"{header}\n  {truncated}")
        else:
            notes.append(header)
```

- [ ] **Step 3: Add the notes section to the context assembly**

In the sections assembly block, add after the care_list section:

```python
    if notes:
        sections.append(f"\nEvolucoes clinicas:\n{nl.join(notes)}")
```

- [ ] **Step 4: Test with curated patients**

```bash
cd /Users/rogerio/90dayswithfhir/fhir-ollama-local
python3 -c "
import requests, base64
FHIR_URL = 'http://localhost:8080/fhir'
resp = requests.get(f'{FHIR_URL}/DocumentReference?patient=maria-001&_count=5').json()
total = resp.get('total', len(resp.get('entry', [])))
print(f'Maria DocumentReferences: {total}')
for e in resp.get('entry', []):
    r = e['resource']
    desc = r.get('description', '')
    date = r.get('date', '')[:16]
    print(f'  {date} - {desc}')
"
```

Expected: Shows Maria's 2 evolution notes.

- [ ] **Step 5: Commit**

```bash
git add fhir_ollama_demo.py
git commit -m "feat: add DocumentReference section to get_fhir_context for evolution notes"
```

---

### Task 10: Copy generate_notes.py into Dockerfile and rebuild

**Files:**
- Modify: `synthea/Dockerfile`

- [ ] **Step 1: Add COPY for generate_notes.py**

Add after the existing COPY lines:
```dockerfile
COPY synthea/generate_notes.py /opt/generate_notes.py
```

- [ ] **Step 2: Rebuild and test end-to-end**

```bash
cd /Users/rogerio/90dayswithfhir/fhir-ollama-local
podman-compose build synthea
podman run --rm --network host \
  -e FHIR_URL=http://localhost:8080/fhir \
  -e SYNTHEA_POPULATION=5 \
  -e SYNTHEA_CLEAN_FIRST=true \
  localhost/fhir-ollama-local_synthea:latest
```

Expected: Curated patients loaded with evolution notes, Synthea patients generated with template notes.

```bash
# Verify DocumentReferences exist
python3 -c "
import requests
FHIR_URL = 'http://localhost:8080/fhir'
for pid in ['maria-001', 'joao-002', 'ana-003']:
    total = requests.get(f'{FHIR_URL}/DocumentReference?patient={pid}&_summary=count').json().get('total', 0)
    print(f'{pid}: {total} DocumentReferences')
# Check a Synthea patient
resp = requests.get(f'{FHIR_URL}/Patient?_count=100').json()
for e in resp.get('entry',[]):
    pid = e['resource']['id']
    if pid not in ['maria-001','joao-002','ana-003']:
        total = requests.get(f'{FHIR_URL}/DocumentReference?patient={pid}&_summary=count').json().get('total',0)
        if total > 0:
            name = e['resource'].get('name',[{}])[0].get('given',[''])[0]
            print(f'{name} ({pid}): {total} DocumentReferences')
            break
"
```

Expected: Maria=2, Joao=8, Ana=4 DocumentReferences, plus Synthea patients with 2 each.

- [ ] **Step 3: Test the demo app**

```bash
python3 fhir_ollama_demo.py
```

Select João, ask: "Qual foi a evolução nas últimas 24h?"
Expected: AI response referencing the evolution notes.

- [ ] **Step 4: Commit**

```bash
git add synthea/Dockerfile
git commit -m "feat: add generate_notes.py to Synthea container, complete evolution notes feature"
```

- [ ] **Step 5: Push**

```bash
git push origin main
```
