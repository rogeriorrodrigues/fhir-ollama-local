#!/bin/bash
# Use FHIR_URL from environment (set by entrypoint.sh) or default to localhost
FHIR_URL="${FHIR_URL:-http://localhost:8080/fhir}"

# Skip wait if called from entrypoint.sh (FHIR already confirmed up)
if [ -z "$SKIP_FHIR_WAIT" ]; then
  echo "=== Aguardando HAPI FHIR subir (pode levar ~30s) ==="
  until curl -s "$FHIR_URL/metadata" > /dev/null 2>&1; do
    echo "  aguardando..."
    sleep 5
  done
  echo "HAPI FHIR pronto!"
fi

########################################
# PACIENTE 1: Maria Santos
# Diabetes mellitus + Hipertensao
########################################
echo ""
echo "=========================================="
echo "  PACIENTE 1: Maria Santos"
echo "  Diabetes + Hipertensao (ambulatorial)"
echo "=========================================="

curl -s -X PUT "$FHIR_URL/Patient/maria-001" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "maria-001",
    "name": [{"family": "Santos", "given": ["Maria"]}],
    "gender": "female",
    "birthDate": "1966-05-12"
  }' > /dev/null && echo "Patient criado (maria-001)"

curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/maria-001"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "73211009", "display": "Diabetes mellitus"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]}
  }' > /dev/null && echo "Condition: Diabetes mellitus"

curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/maria-001"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "38341003", "display": "Hypertensive disorder"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]}
  }' > /dev/null && echo "Condition: Hypertensive disorder"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/maria-001"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "4548-4", "display": "Hemoglobin A1c"}]},
    "valueQuantity": {"value": 9.2, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: HbA1c 9.2%"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/maria-001"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 150, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 95, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA 150/95 mmHg"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/maria-001"},
    "medicationCodeableConcept": {"text": "Metformina 850mg"},
    "dosageInstruction": [{"text": "850mg 2x/dia"}]
  }' > /dev/null && echo "Medication: Metformina 850mg"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/maria-001"},
    "medicationCodeableConcept": {"text": "Losartana 50mg"},
    "dosageInstruction": [{"text": "50mg 1x/dia"}]
  }' > /dev/null && echo "Medication: Losartana 50mg"

########################################
# PACIENTE 2: Joao Oliveira
# ICC descompensada - UTI
########################################
echo ""
echo "=========================================="
echo "  PACIENTE 2: Joao Oliveira"
echo "  ICC descompensada (UTI)"
echo "=========================================="

curl -s -X PUT "$FHIR_URL/Patient/joao-002" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "joao-002",
    "name": [{"family": "Oliveira", "given": ["Joao"]}],
    "gender": "male",
    "birthDate": "1954-08-23"
  }' > /dev/null && echo "Patient criado (joao-002)"

# Encounter UTI
curl -s -X POST "$FHIR_URL/Encounter" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Encounter",
    "status": "in-progress",
    "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IMP", "display": "inpatient encounter"},
    "subject": {"reference": "Patient/joao-002"},
    "location": [{"location": {"display": "UTI Cardiologica"}, "status": "active"}],
    "reasonCode": [{"coding": [{"system": "http://snomed.info/sct", "code": "56675007", "display": "Acute heart failure"}]}]
  }' > /dev/null && echo "Encounter: UTI Cardiologica (internado)"

# ICC
curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "84114007", "display": "Heart failure"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]},
    "severity": {"coding": [{"system": "http://snomed.info/sct", "code": "24484000", "display": "Severe"}]}
  }' > /dev/null && echo "Condition: Heart failure (severe)"

# Edema pulmonar
curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "19242006", "display": "Pulmonary edema"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]}
  }' > /dev/null && echo "Condition: Pulmonary edema"

# Fibrilacao atrial
curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "49436004", "display": "Atrial fibrillation"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]}
  }' > /dev/null && echo "Condition: Atrial fibrillation"

# Doenca renal cronica
curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "709044004", "display": "Chronic kidney disease stage 3"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]}
  }' > /dev/null && echo "Condition: Chronic kidney disease stage 3"

# BNP elevado
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "30934-4", "display": "BNP (Brain natriuretic peptide)"}]},
    "valueQuantity": {"value": 1850, "unit": "pg/mL", "system": "http://unitsofmeasure.org", "code": "pg/mL"}
  }' > /dev/null && echo "Observation: BNP 1850 pg/mL (elevado)"

# Fracao de ejecao
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "10230-1", "display": "Left ventricular ejection fraction"}]},
    "valueQuantity": {"value": 25, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: Fracao de ejecao 25%"

# Creatinina elevada
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "2160-0", "display": "Creatinine"}]},
    "valueQuantity": {"value": 2.1, "unit": "mg/dL", "system": "http://unitsofmeasure.org", "code": "mg/dL"}
  }' > /dev/null && echo "Observation: Creatinina 2.1 mg/dL"

# Sodio baixo
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "2951-2", "display": "Sodium"}]},
    "valueQuantity": {"value": 131, "unit": "mEq/L", "system": "http://unitsofmeasure.org", "code": "meq/L"}
  }' > /dev/null && echo "Observation: Sodio 131 mEq/L (baixo)"

# Potassio
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "2823-3", "display": "Potassium"}]},
    "valueQuantity": {"value": 5.3, "unit": "mEq/L", "system": "http://unitsofmeasure.org", "code": "meq/L"}
  }' > /dev/null && echo "Observation: Potassio 5.3 mEq/L"

# SpO2
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 88, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 88%"

# PA
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/joao-002"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 90, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 60, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA 90/60 mmHg (hipotensao)"

# Medicacoes UTI
curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/joao-002"},
    "medicationCodeableConcept": {"text": "Furosemida EV"},
    "dosageInstruction": [{"text": "80mg EV 12/12h"}]
  }' > /dev/null && echo "Medication: Furosemida EV 80mg"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/joao-002"},
    "medicationCodeableConcept": {"text": "Dobutamina"},
    "dosageInstruction": [{"text": "5 mcg/kg/min em bomba de infusao continua"}]
  }' > /dev/null && echo "Medication: Dobutamina 5 mcg/kg/min"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/joao-002"},
    "medicationCodeableConcept": {"text": "Carvedilol 3.125mg"},
    "dosageInstruction": [{"text": "3.125mg 2x/dia (dose baixa por hipotensao)"}]
  }' > /dev/null && echo "Medication: Carvedilol 3.125mg"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/joao-002"},
    "medicationCodeableConcept": {"text": "Enoxaparina 40mg"},
    "dosageInstruction": [{"text": "40mg SC 1x/dia (profilaxia TVP)"}]
  }' > /dev/null && echo "Medication: Enoxaparina 40mg"

########################################
# PACIENTE 3: Ana Costa
# Asma grave + Pneumonia (emergencia)
########################################
echo ""
echo "=========================================="
echo "  PACIENTE 3: Ana Costa"
echo "  Asma grave + Pneumonia (emergencia)"
echo "=========================================="

curl -s -X PUT "$FHIR_URL/Patient/ana-003" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "ana-003",
    "name": [{"family": "Costa", "given": ["Ana"]}],
    "gender": "female",
    "birthDate": "1990-11-03"
  }' > /dev/null && echo "Patient criado (ana-003)"

# Asma
curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/ana-003"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "195967001", "display": "Asthma"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]},
    "severity": {"coding": [{"system": "http://snomed.info/sct", "code": "24484000", "display": "Severe"}]}
  }' > /dev/null && echo "Condition: Asthma (severe)"

# Pneumonia
curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/ana-003"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "233604007", "display": "Pneumonia"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]}
  }' > /dev/null && echo "Condition: Pneumonia"

# Temperatura
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/ana-003"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "8310-5", "display": "Body temperature"}]},
    "valueQuantity": {"value": 38.7, "unit": "C", "system": "http://unitsofmeasure.org", "code": "Cel"}
  }' > /dev/null && echo "Observation: Temperatura 38.7 C"

# SpO2
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/ana-003"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 91, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 91%"

# Frequencia respiratoria
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/ana-003"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "9279-1", "display": "Respiratory rate"}]},
    "valueQuantity": {"value": 28, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FR 28/min (taquipneia)"

# Leucocitos
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/ana-003"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "6690-2", "display": "Leukocytes"}]},
    "valueQuantity": {"value": 15200, "unit": "/uL", "system": "http://unitsofmeasure.org", "code": "/uL"}
  }' > /dev/null && echo "Observation: Leucocitos 15200/uL"

# PCR
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/ana-003"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "1988-5", "display": "C reactive protein"}]},
    "valueQuantity": {"value": 89, "unit": "mg/L", "system": "http://unitsofmeasure.org", "code": "mg/L"}
  }' > /dev/null && echo "Observation: PCR 89 mg/L (elevado)"

# Peak flow
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/ana-003"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "19935-6", "display": "Peak expiratory flow rate"}]},
    "valueQuantity": {"value": 180, "unit": "L/min", "system": "http://unitsofmeasure.org", "code": "L/min"}
  }' > /dev/null && echo "Observation: Peak flow 180 L/min (reduzido)"

# Medicacoes
curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/ana-003"},
    "medicationCodeableConcept": {"text": "Salbutamol nebulizacao"},
    "dosageInstruction": [{"text": "5mg nebulizacao 4/4h"}]
  }' > /dev/null && echo "Medication: Salbutamol nebulizacao"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/ana-003"},
    "medicationCodeableConcept": {"text": "Prednisolona 40mg"},
    "dosageInstruction": [{"text": "40mg VO 1x/dia por 5 dias"}]
  }' > /dev/null && echo "Medication: Prednisolona 40mg"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/ana-003"},
    "medicationCodeableConcept": {"text": "Amoxicilina + Clavulanato 875mg"},
    "dosageInstruction": [{"text": "875mg VO 12/12h por 7 dias"}]
  }' > /dev/null && echo "Medication: Amoxicilina+Clavulanato 875mg"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/ana-003"},
    "medicationCodeableConcept": {"text": "Brometo de Ipratropio"},
    "dosageInstruction": [{"text": "0.5mg nebulizacao 6/6h"}]
  }' > /dev/null && echo "Medication: Brometo de Ipratropio"

########################################
# VERIFICACAO FINAL
########################################
echo ""
echo "=========================================="
echo "  VERIFICACAO"
echo "=========================================="
for P in maria-001 joao-002 ana-003; do
  TOTAL=$(curl -s "$FHIR_URL/Patient/$P/\$everything" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total', len(d.get('entry',[]))))" 2>/dev/null)
  echo "Paciente $P: $TOTAL resources"
done
echo ""
echo "Pacientes carregados com sucesso! Pronto para rodar fhir_ollama_demo.py"
