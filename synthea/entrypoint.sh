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
  PATIENT_IDS=$(curl -sf "$FHIR_URL/Patient?_elements=id&_count=1000" | \
    jq -r '.entry[]?.resource.id // empty' 2>/dev/null || true)
  for PID in $PATIENT_IDS; do
    curl -sf -X DELETE "$FHIR_URL/Patient/$PID?_cascade=delete" > /dev/null 2>&1 || true
    echo "  Deletado: Patient/$PID"
  done
  echo "Limpeza concluida."
fi

# Load curated demo patients (rich clinical data for demo scenarios)
echo ""
echo "=========================================="
echo "  Carregando pacientes curados (demo)"
echo "=========================================="
if [ -f /opt/load_patient.sh ]; then
  SKIP_FHIR_WAIT=1 bash /opt/load_patient.sh
else
  echo "  AVISO: load_patient.sh nao encontrado, pulando pacientes curados"
fi

# Generate Synthea patients (volume + variety)
echo ""
echo "=========================================="
echo "  Gerando pacientes Synthea (volume)"
echo "=========================================="
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

  # Upload FHIR bundles (hospital/practitioner first, then patients)
  BUNDLE_DIR="/output/$MODULE/fhir"
  if [ -d "$BUNDLE_DIR" ]; then
    BUNDLE_COUNT=0

    # Upload hospital and practitioner bundles first (they are referenced by patient bundles)
    for BUNDLE in "$BUNDLE_DIR"/hospitalInformation*.json "$BUNDLE_DIR"/practitionerInformation*.json; do
      [ -f "$BUNDLE" ] || continue
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$FHIR_URL" \
        -H "Content-Type: application/fhir+json" \
        -d @"$BUNDLE")
      if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
        BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
        echo "  Carregado: $(basename "$BUNDLE")"
      else
        echo "  AVISO: falha ao carregar $(basename "$BUNDLE") (HTTP $HTTP_CODE)"
      fi
    done

    # Upload patient bundles
    for BUNDLE in "$BUNDLE_DIR"/*.json; do
      [ -f "$BUNDLE" ] || continue
      # Skip hospital/practitioner files already uploaded
      case "$(basename "$BUNDLE")" in
        hospitalInformation*|practitionerInformation*) continue ;;
      esac
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$FHIR_URL" \
        -H "Content-Type: application/fhir+json" \
        -d @"$BUNDLE")
      if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
        BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
      else
        echo "  AVISO: falha ao carregar $(basename "$BUNDLE") (HTTP $HTTP_CODE)"
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
