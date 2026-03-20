import requests
import math

FHIR_URL = "http://localhost:8080/fhir"
OLLAMA_URL = "http://localhost:11434/api/generate"
PAGE_SIZE = 10


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
        names = r.get("name") or [{}]
        name = names[0] if names else {}
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
