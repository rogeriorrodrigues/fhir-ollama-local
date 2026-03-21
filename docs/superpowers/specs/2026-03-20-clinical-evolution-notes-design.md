# Clinical Evolution Notes Design

**Date**: 2026-03-20
**Status**: Review
**Goal**: Add clinical evolution history (medical and nursing notes) to both curated and Synthea patients, enabling the AI to answer questions about patient evolution, nursing assessments, and medical decision-making.

---

## Context

The project currently has two types of patients:
- **Curated** (Maria, João, Ana): rich clinical data (Conditions, Observations, Medications) but no narrative evolution notes
- **Synthea**: generated patients with full clinical histories but also no narrative documentation

Students and clinicians need to query the AI about clinical evolution: "What happened in the last 24h?", "What did nursing document?", "Was there a change in treatment plan?" — which requires narrative clinical notes.

### Requirements (from brainstorming)

- **Dual FHIR resources**: `DocumentReference` for narrative notes + `Observation` for structured nursing assessments (category: `vital-signs` for vitals/weight, `survey` for pain/consciousness/fluid balance)
- **Curated patients**: handwritten evolution notes in **Portuguese**, volume scaled to scenario (ambulatorial=few, UTI=many, emergência=moderate)
- **Synthea patients**: template-generated evolution notes in **English**, based on patient's real FHIR data
- **AI integration**: `get_fhir_context()` includes recent evolution notes in the context sent to Ollama

---

## FHIR Resources

### DocumentReference (narrative notes)

Used for: medical progress notes, nursing evolution notes, admission notes, triage notes.

```json
{
  "resourceType": "DocumentReference",
  "status": "current",
  "type": {
    "coding": [{
      "system": "http://loinc.org",
      "code": "11506-3",
      "display": "Progress note"
    }]
  },
  "category": [{
    "coding": [{
      "system": "http://loinc.org",
      "code": "34117-2",
      "display": "History and physical note"
    }]
  }],
  "subject": {"reference": "Patient/joao-002"},
  "date": "2026-03-19T08:00:00Z",
  "author": [{"display": "Dr. Ricardo Mendes - Cardiologia"}],
  "description": "Evolucao medica - manha",
  "context": {
    "encounter": [{"reference": "Encounter/encounter-id"}]
  },
  "content": [{
    "attachment": {
      "contentType": "text/plain",
      "data": "<base64-encoded text>"
    }
  }]
}
```

**Date convention:** All curated evolution notes use dates relative to a fixed scenario date of `2026-03-19` (day of admission/consultation). This avoids confusion with "last 24h" queries.

**Encounter reference:** DocumentReferences for João and Ana include `context.encounter` linking to the relevant Encounter resource. Maria's notes reference her consultation encounters (to be created as part of this change).
```

**LOINC codes for document types:**

| Code | Display | Usage |
|------|---------|-------|
| `11506-3` | Progress note | Medical evolution notes |
| `28651-8` | Nurse notes | Nursing evolution notes |
| `34878-9` | Emergency medicine Note | Emergency triage/assessment |
| `11488-4` | Consultation note | Outpatient consultation |
| `18842-5` | Discharge summary | Discharge notes |

### Observation (structured nursing assessments)

Used for: serial vital signs by shift, fluid balance, pain scale, consciousness level.

**Category mapping:**
- Vital signs (BP, HR, RR, SpO2, Temperature, Weight) → category `vital-signs`
- Fluid balance, pain scale, consciousness level (Glasgow) → category `survey`

```json
{
  "resourceType": "Observation",
  "status": "final",
  "category": [{
    "coding": [{
      "system": "http://terminology.hl7.org/CodeSystem/observation-category",
      "code": "vital-signs",
      "display": "Vital Signs"
    }]
  }],
  "code": {
    "coding": [{
      "system": "http://loinc.org",
      "code": "29463-7",
      "display": "Body weight"
    }]
  },
  "subject": {"reference": "Patient/joao-002"},
  "effectiveDateTime": "2026-03-19T08:00:00Z",
  "performer": [{"display": "Enf. Lucia Ferreira"}],
  "valueQuantity": {"value": 82.5, "unit": "kg", "system": "http://unitsofmeasure.org", "code": "kg"}
}
```

**Note:** Existing curated Observations in `load_patient.sh` lack `effectiveDateTime`. New evolution Observations will include timestamps. Existing Observations should be backfilled with `effectiveDateTime` as part of this change for consistency.

---

## Curated Patients (Portuguese)

### Maria Santos — Ambulatorial (2 consultas)

**Consulta 1 (initial):**
- DocumentReference (type: `11488-4` Consultation note): Medical consultation note describing diabetes + hypertension diagnosis, initial labs, treatment plan
- 2 Observations: vital signs at consultation (BP, weight)

**Consulta 2 (retorno 30 dias):**
- DocumentReference (type: `11506-3` Progress note): Follow-up evaluation — HbA1c still elevated, medication adjustment, education about diet
- 2 Observations: vital signs at follow-up

**Total: 2 DocumentReferences, 4 Observations**

### João Oliveira — UTI (2 days, every 6h shift)

**Day 1:**
- DocumentReference: Admission note (medical) — acute heart failure presentation, initial stabilization, ICU admission rationale
- DocumentReference: Nursing admission assessment — Glasgow 15, edema ++/4+, respiratory distress, venous access, monitoring
- DocumentReference: Medical evolution (afternoon) — response to diuretics, hemodynamic status
- DocumentReference: Nursing evolution (night) — fluid balance, vital signs trends, oxygen therapy adjustment

**Day 2:**
- DocumentReference: Medical evolution (morning) — clinical improvement, plan to wean dobutamine
- DocumentReference: Nursing evolution (morning) — reduced edema, improving SpO2, patient mobilization
- DocumentReference: Medical evolution (afternoon) — echocardiogram results, cardiology consult
- DocumentReference: Nursing evolution (night) — stable, reducing O2 support

**Structured nursing assessments (Observations, every 6h):**
- Vital signs: BP, HR, RR, SpO2, Temperature (8 sets over 2 days)
- Fluid balance: intake/output every 12h (4 records)
- Weight: daily (2 records)

**Total: 8 DocumentReferences, ~22 Observations**

### Ana Costa — Emergência (PS flow)

**PS flow:**
- DocumentReference: Triage note (type: `34878-9`) — chief complaint, initial assessment, Manchester classification
- DocumentReference: Medical assessment — asthma exacerbation + pneumonia diagnosis, treatment plan
- DocumentReference: Nursing note — medication administration, nebulization, oxygen therapy, monitoring
- DocumentReference: Medical reassessment (2h later) — response to treatment, decision to admit vs discharge

**Structured assessments:**
- Vital signs: arrival + post-nebulization + 2h reassessment (3 sets)
- Peak flow: pre and post-bronchodilator (2 records)

**Total: 4 DocumentReferences, ~8 Observations**

---

## Synthea Patients (English, templates)

### Template-based generation

A Python script (`generate_notes.py`) runs after Synthea bundles are uploaded. For each Synthea patient with clinical data:

1. Query the patient's active Conditions, recent Observations, active Medications
2. Check for recent Encounters; if none found, use Conditions as basis for notes
3. For each patient with clinical data (up to 3 Encounters, or 1 note if no Encounters):
   - Generate 1 medical progress note (DocumentReference, type `11506-3`)
   - Generate 1 nursing note (DocumentReference, type `28651-8`)
4. POST the DocumentReferences to the FHIR server

**Note:** Uses `urllib.request` from the Python standard library (no `requests` dependency needed in the container).

### Templates

**Medical progress note template:**
```
Assessment and Plan - {encounter_date}

Patient: {name}, {age}y/o {gender}

Active Conditions:
{conditions_list}

Current Medications:
{medications_list}

Recent Vitals:
{vitals_summary}

Assessment:
Patient with {primary_condition} presenting for {encounter_reason}. Current treatment includes {key_medications}. Vital signs {vitals_assessment}.

Plan:
- Continue current medications
- Monitor {key_vitals}
- Follow-up as scheduled
```

**Nursing note template:**
```
Nursing Assessment - {encounter_date}

Patient: {name} | Room: N/A | Shift: Day

Vital Signs:
{vitals_detail}

Current Medications Administered:
{medications_list}

Assessment:
Patient is alert and oriented, ambulatory with assistance. {condition_observations}.

Interventions:
- Vital signs monitoring per protocol
- Medication administration as ordered
- Patient education on {primary_condition}

Plan:
- Continue monitoring q{frequency}h
- Report changes in {key_parameters}
```

### Vitals assessment logic

The template fills `vitals_assessment` based on actual Observation values:
- BP > 140/90 → "elevated blood pressure"
- SpO2 < 95% → "low oxygen saturation"
- HR > 100 → "tachycardia"
- Temp > 38°C → "febrile"
- Otherwise → "within normal limits"

---

## File Structure

```
fhir-ollama-local/
├── load_patient.sh                 # MODIFY: add DocumentReference + Observation entries for curated patients
├── synthea/
│   ├── generate_notes.py           # CREATE: template-based note generator for Synthea patients
│   ├── entrypoint.sh               # MODIFY: call generate_notes.py after Synthea upload
│   └── Dockerfile                  # MODIFY: add python3 to the image
├── fhir_ollama_demo.py             # MODIFY: add DocumentReference to get_fhir_context()
```

---

## Changes to get_fhir_context()

Add a new section after Medications that fetches recent DocumentReferences:

Note: `import base64` goes at the top of the file alongside `import requests`.

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
    # Decode content
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
        # Truncate long notes to keep context manageable
        truncated = content[:500] + "..." if len(content) > 500 else content
        notes.append(f"{header}\n  {truncated}")
    else:
        notes.append(header)
```

This adds an "Evolucoes clinicas:" section to the context sent to Ollama (no accents, consistent with existing section headers like "Condicoes ativas:", "Observacoes recentes:").

---

## Changes to entrypoint.sh

After the Synthea bundle upload section, add:

```bash
# Generate clinical notes for Synthea patients
echo ""
echo "Gerando evolucoes clinicas para pacientes Synthea..."
python3 /opt/generate_notes.py "$FHIR_URL"
```

### Dockerfile changes

Add `python3` to the apt-get install line:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends curl jq python3 && rm -rf /var/lib/apt/lists/*
```

---

## Usage

No changes to the user workflow. Evolution notes are loaded automatically:
- Curated patients: via `load_patient.sh` (hardcoded, rich Portuguese narratives)
- Synthea patients: via `generate_notes.py` (templated English notes based on real data)

The AI can now answer:
- "Qual a evolução do João nas últimas 24h?"
- "O que a enfermagem registrou sobre a Maria?"
- "What did the nurse document for this patient?"
- "Was there any change in treatment plan?"

---

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| DocumentReference content too large for LLM context | Truncate notes to 500 chars in get_fhir_context(); show most recent 10 |
| Template notes may feel generic | Templates include real patient data (conditions, meds, vitals) for realism |
| python3 not in Synthea container | Add to Dockerfile apt-get install |
| `requests` not available in container Python | Use `urllib.request` from standard library instead |
| base64 encoding adds complexity | Use standard library base64 module; straightforward encode/decode |
| load_patient.sh growing too large | Evolution notes use same curl pattern; manageable growth |
| Existing Observations lack effectiveDateTime | Backfill existing Observations with timestamps as part of this change |
| Patients without Encounters for note generation | Fall back to Conditions-based notes; skip patients with no clinical data |
