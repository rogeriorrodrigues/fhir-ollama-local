import requests
import math

FHIR_URL = "http://localhost:8080/fhir"
OLLAMA_URL = "http://localhost:11434/api/generate"
PAGE_SIZE = 10

# Curated demo patients with rich clinical data (loaded by load_patient.sh)
CURATED_PATIENTS = [
    {"id": "maria-001", "nome": "Maria Santos", "cenario": "Diabetes + Hipertensao (ambulatorial)"},
    {"id": "joao-002", "nome": "Joao Oliveira", "cenario": "ICC descompensada (UTI)"},
    {"id": "ana-003", "nome": "Ana Costa", "cenario": "Asma grave + Pneumonia (emergencia)"},
]


def get_curated_patients():
    """Retorna pacientes curados que existem no servidor FHIR"""
    available = []
    for p in CURATED_PATIENTS:
        resp = requests.get(f"{FHIR_URL}/Patient/{p['id']}")
        if resp.status_code == 200:
            available.append(p)
    return available


def get_synthea_patients(page=0):
    """Lista pacientes Synthea (exclui curados) com paginacao"""
    curated_ids = {p["id"] for p in CURATED_PATIENTS}
    url = f"{FHIR_URL}/Patient?_count=100&_sort=family"
    resp = requests.get(url).json()
    all_patients = []
    for e in resp.get("entry", []):
        r = e["resource"]
        if r["id"] in curated_ids:
            continue
        names = r.get("name") or [{}]
        name = names[0] if names else {}
        given = name.get("given", [""])[0]
        family = name.get("family", "")
        all_patients.append({
            "id": r["id"],
            "name": f"{given} {family}".strip(),
            "gender": r.get("gender", ""),
            "birthDate": r.get("birthDate", ""),
        })
    # Paginate
    start = page * PAGE_SIZE
    return all_patients[start:start + PAGE_SIZE], len(all_patients)


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
        if display and display not in conditions:
            conditions.append(display)
    return conditions


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


def show_menu(curated, synthea_patients, synthea_page, synthea_total_pages):
    print("\n" + "=" * 50)
    print("  FHIR + Ollama - Assistente Clinico")
    print("=" * 50)

    idx = 1

    # Section 1: Curated demo patients
    if curated:
        print("\n-- Cenarios clinicos curados (dados ricos) --\n")
        for p in curated:
            print(f"  [{idx}] {p['nome']} - {p['cenario']}")
            idx += 1

    # Section 2: Synthea patients
    if synthea_patients:
        print(f"\n-- Pacientes Synthea (pagina {synthea_page + 1}/{synthea_total_pages}) --\n")
        for p in synthea_patients:
            gender_label = p["gender"][0].upper() if p["gender"] else "?"
            print(f"  [{idx}] {p['name']} ({gender_label}, {p['birthDate']})")
            conditions = get_patient_conditions(p["id"])
            if conditions:
                print(f"      {', '.join(conditions[:5])}")
            idx += 1

    if not curated and not synthea_patients:
        print("\n  Nenhum paciente encontrado.")
        print("  Aguarde o carregamento do Synthea.")

    print()
    if synthea_total_pages > 1:
        if synthea_page < synthea_total_pages - 1:
            print("  [n] Proxima pagina (Synthea)")
        if synthea_page > 0:
            print("  [p] Pagina anterior (Synthea)")
    print("  [0] Sair")
    print()


if __name__ == "__main__":
    synthea_page = 0
    while True:
        curated = get_curated_patients()
        synthea_patients, synthea_total = get_synthea_patients(synthea_page)
        synthea_total_pages = max(1, math.ceil(synthea_total / PAGE_SIZE))

        show_menu(curated, synthea_patients, synthea_page, synthea_total_pages)
        choice = input("Escolha o paciente: ").strip().lower()

        if choice == "0":
            print("\nEncerrado. Ate logo!")
            break
        elif choice == "n" and synthea_page < synthea_total_pages - 1:
            synthea_page += 1
            continue
        elif choice == "p" and synthea_page > 0:
            synthea_page -= 1
            continue

        # Build combined list for index lookup
        all_options = []
        for p in curated:
            all_options.append({"id": p["id"], "name": p["nome"]})
        for p in synthea_patients:
            all_options.append({"id": p["id"], "name": p["name"]})

        try:
            idx = int(choice) - 1
            if 0 <= idx < len(all_options):
                patient = all_options[idx]
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
