import requests

FHIR_URL = "http://localhost:8080/fhir"
OLLAMA_URL = "http://localhost:11434/api/generate"

PATIENTS = {
    "1": {"id": "maria-001", "nome": "Maria Santos", "cenario": "Diabetes + Hipertensao (ambulatorial)"},
    "2": {"id": "joao-002", "nome": "Joao Oliveira", "cenario": "ICC descompensada (UTI)"},
    "3": {"id": "ana-003", "nome": "Ana Costa", "cenario": "Asma grave + Pneumonia (emergencia)"},
}


def get_fhir_context(patient_id):
    """Consulta dados clinicos do paciente via FHIR REST API"""
    patient = requests.get(f"{FHIR_URL}/Patient/{patient_id}").json()
    name = patient["name"][0]
    info = (
        f"Paciente: {name['given'][0]} {name['family']}, "
        f"{patient['gender']}, nascimento: {patient['birthDate']}"
    )

    # Encounter
    encounters = requests.get(f"{FHIR_URL}/Encounter?patient={patient_id}").json()
    enc_info = []
    for e in encounters.get("entry", []):
        r = e["resource"]
        status = r.get("status", "")
        locations = [loc["location"]["display"] for loc in r.get("location", []) if "display" in loc.get("location", {})]
        if locations:
            enc_info.append(f"- Local: {', '.join(locations)} (status: {status})")

    # Conditions
    conditions = requests.get(f"{FHIR_URL}/Condition?patient={patient_id}").json()
    conds = []
    for e in conditions.get("entry", []):
        c = e["resource"]["code"]["coding"][0]
        severity = ""
        sev = e["resource"].get("severity")
        if sev:
            severity = f" - Gravidade: {sev['coding'][0]['display']}"
        conds.append(f"- {c['display']} (SNOMED: {c['code']}){severity}")

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
    sections = [info]
    if enc_info:
        sections.append(f"\nInternacao:\n{nl.join(enc_info)}")
    sections.append(f"\nCondicoes ativas:\n{nl.join(conds)}")
    sections.append(f"\nObservacoes recentes:\n{nl.join(obs)}")
    sections.append(f"\nMedicacoes ativas:\n{nl.join(med_list)}")
    return "\n".join(sections)


def ask_ollama(context, question):
    """Envia contexto clinico + pergunta pro Ollama local"""
    prompt = f"""Voce e um assistente clinico. Responda APENAS com base nos dados fornecidos.
Se a informacao nao estiver nos dados, diga que nao tem essa informacao.

DADOS CLINICOS DO PACIENTE (fonte: servidor FHIR R4):
{context}

PERGUNTA: {question}"""

    resp = requests.post(
        OLLAMA_URL,
        json={"model": "phi4", "prompt": prompt, "stream": False},
        timeout=120,
    )
    return resp.json()["response"]


def show_menu():
    print("\n" + "=" * 50)
    print("  FHIR + Ollama - Assistente Clinico")
    print("=" * 50)
    print("\nPacientes disponiveis:\n")
    for key, p in PATIENTS.items():
        print(f"  [{key}] {p['nome']} - {p['cenario']}")
    print(f"\n  [0] Sair")
    print()


if __name__ == "__main__":
    while True:
        show_menu()
        choice = input("Escolha o paciente: ").strip()

        if choice == "0":
            print("\nEncerrado. Ate logo!")
            break

        if choice not in PATIENTS:
            print("\nOpcao invalida. Tente novamente.")
            continue

        patient = PATIENTS[choice]
        print(f"\n>>> Consultando FHIR para: {patient['nome']}...")
        ctx = get_fhir_context(patient["id"])
        print(f"\n{ctx}")
        print("\n" + "-" * 50)
        print(f"Modo interativo - Paciente: {patient['nome']}")
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
