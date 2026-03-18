# 🏥 IA Local + FHIR: Pipeline Clínico com Zero Cloud

Pipeline completo de IA clínica rodando **100% local**: HAPI FHIR R4 + Ollama (LLaMA 3) + Python.

Nenhum dado sai da sua máquina. Zero API paga. Zero cloud.

## O que faz

1. **HAPI FHIR** sobe como servidor de dados clínicos (padrão HL7 FHIR R4 — o mesmo da RNDS/SUS)
2. **Paciente sintética** é criada com diabetes, hipertensão, HbA1c 9.2%, PA 150/95, metformina e losartana
3. **Script Python** consulta o FHIR via REST API e monta contexto clínico estruturado
4. **Ollama (LLaMA 3)** recebe o contexto e responde com raciocínio clínico fundamentado nos dados

A IA **não inventa**. Só trabalha com o que veio do FHIR.

## Pré-requisitos

- Docker e Docker Compose
- Python 3.8+ com `requests` (`pip install requests`)
- ~4GB livres para o modelo LLaMA 3

## Quickstart

```bash
# 1. Suba os serviços
docker compose up -d

# 2. Baixe o modelo (primeira vez, ~4GB)
docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3

# 3. Aguarde o HAPI FHIR subir (~30s) e carregue a paciente
bash load_patient.sh

# 4. Rode a demo
python fhir_ollama_demo.py
```

## Output esperado

```
=== Consultando servidor FHIR ===

Dados recuperados:
Paciente: Maria Santos, female, nascimento: 1966-05-12

Condicoes ativas:
- Diabetes mellitus (SNOMED: 73211009)
- Hypertensive disorder (SNOMED: 38341003)

Observacoes recentes:
- Hemoglobin A1c: 9.2 %
- Blood pressure panel: Systolic blood pressure: 150mmHg, Diastolic blood pressure: 95mmHg

Medicacoes ativas:
- Metformina 850mg (850mg 2x/dia)
- Losartana 50mg (50mg 1x/dia)

==================================================

Perguntando ao Ollama (llama3)...
Pergunta: Quais sao as condicoes dessa paciente e como os exames se relacionam com o tratamento atual?

Resposta:
[Ollama responde com raciocínio clínico baseado nos dados FHIR]
```

## Stack

| Componente | Papel | Licença |
|-----------|-------|---------|
| [HAPI FHIR](https://github.com/hapifhir/hapi-fhir-jpaserver-starter) | Servidor FHIR R4 | Apache 2.0 |
| [Ollama](https://ollama.com) | Runtime de LLM local | MIT |
| [LLaMA 3](https://llama.meta.com) | Modelo de linguagem | Meta License |
| Python + requests | Orquestração | MIT |

## Recursos FHIR criados

- 1 **Patient** (Maria Santos, 58 anos)
- 2 **Conditions** (Diabetes SNOMED:73211009, Hipertensão SNOMED:38341003)
- 2 **Observations** (HbA1c LOINC:4548-4 = 9.2%, PA LOINC:85354-9 = 150/95)
- 2 **MedicationRequests** (Metformina 850mg BID, Losartana 50mg QD)

Todos os resources seguem o padrão FHIR R4 com terminologias oficiais (SNOMED CT, LOINC, UCUM).

## Por que isso importa

- **LGPD by design**: nenhum dado clínico sai da máquina
- **Padrão RNDS**: mesmo formato que o SUS usa (2,8 bilhões de registros em FHIR R4)
- **Custo zero**: Docker + Ollama + HAPI FHIR = tudo open-source
- **Reproduzível**: qualquer dev com Docker roda em 5 minutos

## Próximos passos

- [ ] Adicionar Synthea para geração automática de pacientes
- [ ] Integrar Presidio para anonimização pré-LLM
- [ ] Adicionar RAGAS para avaliação de qualidade das respostas
- [ ] Implementar MCP Server para acesso padronizado

## Autor

**Rogério Rodrigues** — Azure MVP | Pesquisador Mestrado UFSC (Informática em Saúde) | Professor USP/FIAP

---

*Esse repositório faz parte da minha pesquisa de mestrado na UFSC sobre simulação clínica com IA para estudantes de enfermagem.*
