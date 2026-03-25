import requests
import math
import base64

FHIR_URL = "http://localhost:8082/fhir"
OLLAMA_URL = "http://localhost:11435/api/generate"
MODEL = "llama3.2:3b"
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


def has_clinical_data(patient_id):
    """Verifica se o paciente tem dados clinicos (conditions ou observations)"""
    conds = requests.get(
        f"{FHIR_URL}/Condition?patient={patient_id}&_summary=count"
    ).json().get("total", 0)
    if conds > 0:
        return True
    obs = requests.get(
        f"{FHIR_URL}/Observation?patient={patient_id}&_summary=count"
    ).json().get("total", 0)
    return obs > 0


def get_synthea_patients(page=0):
    """Lista pacientes Synthea com dados clinicos (exclui curados e vazios)"""
    curated_ids = {p["id"] for p in CURATED_PATIENTS}
    url = f"{FHIR_URL}/Patient?_count=100&_sort=family"
    resp = requests.get(url).json()
    all_patients = []
    for e in resp.get("entry", []):
        r = e["resource"]
        if r["id"] in curated_ids:
            continue
        if not has_clinical_data(r["id"]):
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

    # Encounter (only active/in-progress, most recent first)
    encounters = requests.get(
        f"{FHIR_URL}/Encounter?patient={patient_id}&_sort=-date&_count=5"
    ).json()
    enc_info = []
    for e in encounters.get("entry", []):
        r = e["resource"]
        status = r.get("status", "")
        enc_class = r.get("class", {}).get("display", r.get("class", {}).get("code", ""))
        reason_codes = [
            rc.get("coding", [{}])[0].get("display", "")
            for rc in r.get("reasonCode", [])
        ]
        locations = [
            loc["location"]["display"]
            for loc in r.get("location", [])
            if "display" in loc.get("location", {})
        ]
        parts = []
        if enc_class:
            parts.append(enc_class)
        if locations:
            parts.append(f"Local: {', '.join(locations)}")
        if reason_codes:
            parts.append(f"Motivo: {', '.join(r for r in reason_codes if r)}")
        parts.append(f"status: {status}")
        enc_info.append(f"- {' | '.join(parts)}")

    # Conditions (active only, deduplicated)
    conditions = requests.get(f"{FHIR_URL}/Condition?patient={patient_id}").json()
    conds = []
    seen_conditions = set()
    for e in conditions.get("entry", []):
        code_block = e["resource"].get("code", {})
        coding = code_block.get("coding", [{}])[0]
        display = coding.get("display", code_block.get("text", "Desconhecido"))
        code_val = coding.get("code", "")
        if display in seen_conditions:
            continue
        seen_conditions.add(display)
        severity = ""
        sev = e["resource"].get("severity")
        if sev:
            sev_coding = sev.get("coding", [{}])[0]
            severity = f" - Gravidade: {sev_coding.get('display', '')}"
        conds.append(f"- {display} (SNOMED: {code_val}){severity}")

    # Observations (most recent 20, sorted by date)
    observations = requests.get(
        f"{FHIR_URL}/Observation?patient={patient_id}&_sort=-date&_count=20"
    ).json()
    obs = []
    for e in observations.get("entry", []):
        r = e["resource"]
        code_display = r.get("code", {}).get("coding", [{}])[0].get("display", "")
        date = r.get("effectiveDateTime", r.get("issued", ""))[:10]
        date_suffix = f" ({date})" if date else ""
        if "valueQuantity" in r:
            v = r["valueQuantity"]
            obs.append(f"- {code_display}: {v.get('value', '')} {v.get('unit', '')}{date_suffix}")
        elif "component" in r:
            parts = []
            for comp in r["component"]:
                c = comp.get("code", {}).get("coding", [{}])[0].get("display", "")
                v = comp.get("valueQuantity", {})
                parts.append(f"{c}: {v.get('value', '')}{v.get('unit', '')}")
            obs.append(f"- {code_display}: {', '.join(parts)}{date_suffix}")
        elif "valueCodeableConcept" in r:
            v = r["valueCodeableConcept"]
            val_display = v.get("coding", [{}])[0].get("display", v.get("text", ""))
            obs.append(f"- {code_display}: {val_display}{date_suffix}")

    # Medications (active + completed recent)
    meds = requests.get(
        f"{FHIR_URL}/MedicationRequest?patient={patient_id}&_sort=-date&_count=20"
    ).json()
    med_list = []
    for e in meds.get("entry", []):
        r = e["resource"]
        status = r.get("status", "")
        med_concept = r.get("medicationCodeableConcept", {})
        med_name = med_concept.get("text") or (
            med_concept.get("coding", [{}])[0].get("display", "")
        )
        if not med_name and "medicationReference" in r:
            med_name = r["medicationReference"].get("display", "Medicamento")
        dosage_list = r.get("dosageInstruction", [])
        dosage = dosage_list[0].get("text", "") if dosage_list else ""
        status_label = f" [{status}]" if status != "active" else ""
        if dosage:
            med_list.append(f"- {med_name} ({dosage}){status_label}")
        else:
            med_list.append(f"- {med_name}{status_label}")

    # Procedures (recent)
    procedures = requests.get(
        f"{FHIR_URL}/Procedure?patient={patient_id}&_sort=-date&_count=10"
    ).json()
    proc_list = []
    for e in procedures.get("entry", []):
        r = e["resource"]
        code_display = r.get("code", {}).get("coding", [{}])[0].get("display", r.get("code", {}).get("text", ""))
        date = r.get("performedDateTime", r.get("performedPeriod", {}).get("start", ""))[:10]
        if code_display:
            proc_list.append(f"- {code_display} ({date})" if date else f"- {code_display}")

    # CarePlans
    careplans = requests.get(
        f"{FHIR_URL}/CarePlan?patient={patient_id}&status=active&_count=5"
    ).json()
    care_list = []
    for e in careplans.get("entry", []):
        r = e["resource"]
        categories = [
            cat.get("coding", [{}])[0].get("display", cat.get("text", ""))
            for cat in r.get("category", [])
        ]
        activities = [
            a.get("detail", {}).get("code", {}).get("coding", [{}])[0].get("display", "")
            for a in r.get("activity", [])
        ]
        activities = [a for a in activities if a]
        label = ", ".join(categories) if categories else "Plano de cuidado"
        if activities:
            care_list.append(f"- {label}: {', '.join(activities[:3])}")
        else:
            care_list.append(f"- {label}")

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

    nl = "\n"
    sections = [info]
    if enc_info:
        sections.append(f"\nInternacoes/Consultas recentes:\n{nl.join(enc_info)}")
    if conds:
        sections.append(f"\nCondicoes ativas:\n{nl.join(conds)}")
    if obs:
        sections.append(f"\nObservacoes recentes:\n{nl.join(obs)}")
    if med_list:
        sections.append(f"\nMedicacoes:\n{nl.join(med_list)}")
    if proc_list:
        sections.append(f"\nProcedimentos recentes:\n{nl.join(proc_list)}")
    if care_list:
        sections.append(f"\nPlanos de cuidado ativos:\n{nl.join(care_list)}")
    if notes:
        sections.append(f"\nEvolucoes clinicas:\n{nl.join(notes)}")
    return "\n".join(sections)


def ask_ollama(context, question):
    """Envia contexto clinico + pergunta pro Ollama local"""
    prompt = f"""Voce e um assistente clinico. Responda APENAS com base nos dados fornecidos.
Se a informacao nao estiver nos dados, diga que nao tem essa informacao.

DADOS CLINICOS DO PACIENTE (fonte: servidor FHIR R4):
{context}

PERGUNTA: {question}"""

    try:
        resp = requests.post(
            OLLAMA_URL,
            json={"model": MODEL, "prompt": prompt, "stream": False},
            timeout=180,
        )
        data = resp.json()
        if "error" in data:
            return f"[Erro do modelo: {data['error']}]"
        return data.get("response", "[Sem resposta do modelo]")
    except requests.exceptions.Timeout:
        return "[Erro: timeout - o modelo demorou demais para responder]"
    except Exception as e:
        return f"[Erro ao consultar Ollama: {e}]"


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
