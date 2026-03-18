#!/bin/bash
FHIR_URL="http://localhost:8080/fhir"

echo "=== Aguardando HAPI FHIR subir (pode levar ~30s) ==="
until curl -s "$FHIR_URL/metadata" > /dev/null 2>&1; do
  echo "  aguardando..."
  sleep 5
done
echo "✅ HAPI FHIR pronto!"

echo ""
echo "=== Criando Patient: Maria Santos ==="
curl -s -X PUT "$FHIR_URL/Patient/maria-001" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "maria-001",
    "name": [{"family": "Santos", "given": ["Maria"]}],
    "gender": "female",
    "birthDate": "1966-05-12"
  }' > /dev/null && echo "✅ Patient criado (maria-001)"

echo ""
echo "=== Criando Conditions ==="
curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/maria-001"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "73211009", "display": "Diabetes mellitus"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]}
  }' > /dev/null && echo "✅ Diabetes mellitus (SNOMED 73211009)"

curl -s -X POST "$FHIR_URL/Condition" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Condition",
    "subject": {"reference": "Patient/maria-001"},
    "code": {"coding": [{"system": "http://snomed.info/sct", "code": "38341003", "display": "Hypertensive disorder"}]},
    "clinicalStatus": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]}
  }' > /dev/null && echo "✅ Hypertensive disorder (SNOMED 38341003)"

echo ""
echo "=== Criando Observations ==="
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "subject": {"reference": "Patient/maria-001"},
    "code": {"coding": [{"system": "http://loinc.org", "code": "4548-4", "display": "Hemoglobin A1c"}]},
    "valueQuantity": {"value": 9.2, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "✅ HbA1c: 9.2% (LOINC 4548-4)"

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
  }' > /dev/null && echo "✅ PA: 150/95 mmHg (LOINC 85354-9)"

echo ""
echo "=== Criando MedicationRequests ==="
curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/maria-001"},
    "medicationCodeableConcept": {"text": "Metformina 850mg"},
    "dosageInstruction": [{"text": "850mg 2x/dia"}]
  }' > /dev/null && echo "✅ Metformina 850mg (2x/dia)"

curl -s -X POST "$FHIR_URL/MedicationRequest" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "MedicationRequest",
    "status": "active",
    "intent": "order",
    "subject": {"reference": "Patient/maria-001"},
    "medicationCodeableConcept": {"text": "Losartana 50mg"},
    "dosageInstruction": [{"text": "50mg 1x/dia"}]
  }' > /dev/null && echo "✅ Losartana 50mg (1x/dia)"

echo ""
echo "=== VERIFICAÇÃO ==="
TOTAL=$(curl -s "$FHIR_URL/Patient/maria-001/\$everything" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total', len(d.get('entry',[]))))" 2>/dev/null)
echo "✅ Total de resources para maria-001: $TOTAL"
echo ""
echo "🎉 Paciente carregado com sucesso! Pronto para rodar fhir_ollama_demo.py"
