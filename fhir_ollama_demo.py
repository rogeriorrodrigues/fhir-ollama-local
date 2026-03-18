import requests

FHIR_URL = "http://localhost:8080/fhir"
OLLAMA_URL = "http://localhost:11434/api/generate"
PATIENT_ID = "maria-001"

def get_fhir_context(patient_id):
    """Consulta dados clinicos do paciente via FHIR REST API"""
    patient = requests.get(f"{FHIR_URL}/Patient/{patient_id}").json()
    name = patient["name"][0]
    info = (
        f"Paciente: {name['given'][0]} {name['family']}, "
        f"{patient['gender']}, nascimento: {patient['birthDate']}"
    )

    # Conditions
    conditions = requests.get(f"{FHIR_URL}/Condition?patient={patient_id}").json()
    conds = []
    for e in conditions.get("entry", []):
        c = e["resource"]["code"]["coding"][0]
        conds.append(f"- {c['display']} (SNOMED: {c['code']})")

    # Observations
    observations = requests.get(f"{FHIR_URL}/Observation?patient={patient_id}").json()
    obs = []
    for e in observations.get("entry", []):
        r = e["resource"]
        code = r["code"]["coding"][0]["display"]
        if "valueQuantity" in r:
            v = r["valueQuantity"]
            obs.append(f"- {code}: {v['value']} {v['unit']}")
        elif "component" in r:
            parts = []
            for comp in r["component"]:
                c = comp["code"]["coding"][0]["display"]
                v = comp["valueQuantity"]
                parts.append(f"{c}: {v['value']}{v['unit']}")
            obs.append(f"- {code}: {', '.join(parts)}")

    # Medications
    meds = requests.get(
        f"{FHIR_URL}/MedicationRequest?patient={patient_id}&status=active"
    ).json()
    med_list = []
    for e in meds.get("entry", []):
        r = e["resource"]
        med_name = r["medicationCodeableConcept"]["text"]
        dosage = r["dosageInstruction"][0]["text"]
        med_list.append(f"- {med_name} ({dosage})")

    nl = "\n"
    return f"""{info}

Condicoes ativas:
{nl.join(conds)}

Observacoes recentes:
{nl.join(obs)}

Medicacoes ativas:
{nl.join(med_list)}"""


def ask_ollama(context, question):
    """Envia contexto clinico + pergunta pro Ollama local"""
    prompt = f"""Voce e um assistente clinico. Responda APENAS com base nos dados fornecidos.
Se a informacao nao estiver nos dados, diga que nao tem essa informacao.

DADOS CLINICOS DO PACIENTE (fonte: servidor FHIR R4):
{context}

PERGUNTA: {question}"""

    resp = requests.post(
        OLLAMA_URL,
        json={"model": "llama3", "prompt": prompt, "stream": False},
    )
    return resp.json()["response"]


if __name__ == "__main__":
    print("\n=== Consultando servidor FHIR ===")
    ctx = get_fhir_context(PATIENT_ID)
    print(f"\nDados recuperados:\n{ctx}")
    print("\n" + "=" * 50)

    q = (
        "Quais sao as condicoes dessa paciente e como os exames "
        "se relacionam com o tratamento atual?"
    )
    print(f"\nPerguntando ao Ollama (llama3)...")
    print(f"Pergunta: {q}\n")
    answer = ask_ollama(ctx, q)
    print(f"Resposta:\n{answer}")
