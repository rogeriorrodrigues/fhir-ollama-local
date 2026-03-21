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
