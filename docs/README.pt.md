<div align="center">

# 🏥 IA Clínica Local + FHIR Pipeline

### 🇧🇷 Documentação Completa em Português

[← Voltar ao README Principal](../README.md) · [🇬🇧 English](README.en.md) · [🇪🇸 Español](README.es.md) · [🇮🇹 Italiano](README.it.md)

</div>

---

## 📋 Índice

- [O Que Faz](#-o-que-faz)
- [Arquitetura](#-arquitetura)
- [Pré-requisitos](#-pré-requisitos)
- [Passo a Passo](#-passo-a-passo)
- [Entendendo o Código](#-entendendo-o-código)
- [Integração com Synthea](#-integração-com-synthea)
- [Notas de Evolução Clínica](#-notas-de-evolução-clínica)
- [Recursos FHIR Explicados](#-recursos-fhir-explicados)
- [Output Esperado](#-output-esperado)
- [Por Que Isso Importa](#-por-que-isso-importa)
- [Resolução de Problemas](#-resolução-de-problemas)
- [Próximos Passos](#-próximos-passos)

---

## 🎯 O Que Faz

Esse pipeline roda uma **IA clínica 100% local** que lê dados de pacientes de um servidor FHIR R4 e gera raciocínio clínico — tudo sem enviar um único byte pra cloud.

**Três serviços, um `podman-compose up`:**

| Componente | O Que Faz | Porta |
|------------|----------|-------|
| 🔥 **HAPI FHIR** | Armazena dados clínicos em formato FHIR R4 | `8080` |
| 🧬 **Synthea** | Gera pacientes sintéticos realistas e os carrega no FHIR automaticamente | — |
| 🦙 **Ollama** | Roda llama3.2:3b localmente como cérebro da IA | `11434` |

O script Python `fhir_ollama_demo.py` consulta o servidor FHIR e passa os dados ao Ollama. A IA **não alucina** porque trabalha exclusivamente com dados recuperados do servidor FHIR. Cada afirmação na resposta é rastreável a um recurso clínico real.

---

## 🏗️ Arquitetura

```
┌──────────────────────────────────────────────────────────────────┐
│                        SUA MÁQUINA                               │
│                                                                  │
│  ┌─────────────┐   healthcheck   ┌─────────────┐                │
│  │  HAPI FHIR  │◄────────────────│   Synthea   │                │
│  │  Servidor   │   POST bundles  │  Container  │                │
│  │             │                 │ (auto-exit) │                │
│  │  Porta 8080 │                 └─────────────┘                │
│  │             │                                                 │
│  │             │◄── REST API (JSON) ──►  ┌─────────────┐        │
│  └─────────────┘    GET /Patient         │   Python    │        │
│       Podman         GET /Condition       │   Script    │        │
│                      GET /Observation     │ menu dual   │        │
│                      GET /DocumentRef     │  + Ollama   │        │
│                                          └──────┬──────┘        │
│                                                 │               │
│                                         POST /api/generate      │
│                                                 │               │
│                                         ┌───────▼───────┐       │
│                                         │    Ollama     │       │
│                                         │ llama3.2:3b   │       │
│                                         │  Porta 11434  │       │
│                                         └───────────────┘       │
│                                              Podman             │
│                                                                  │
│  🔒 Nada sai desta máquina. LGPD-friendly by design.           │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📦 Pré-requisitos

| Requisito | Mínimo | Notas |
|-----------|--------|-------|
| Podman | v4+ | [Instalar Podman](https://podman.io/docs/installation) |
| podman-compose | v1+ | `pip install podman-compose` |
| Python | 3.8+ | Com biblioteca `requests` |
| Espaço em disco | ~6 GB | Imagem HAPI FHIR + Synthea + modelo llama3.2:3b |
| RAM | 8 GB+ | llama3.2:3b precisa de ~3GB RAM |

```bash
pip install requests podman-compose
```

---

## 🚀 Passo a Passo

### Passo 1: Clone e suba os serviços

```bash
git clone https://github.com/YOUR_USER/fhir-ollama-local.git
cd fhir-ollama-local
podman-compose up -d
```

Isso inicia três containers: HAPI FHIR (porta 8080), Synthea (gera e carrega pacientes automaticamente) e Ollama (porta 11434).

O Synthea aguarda o HAPI FHIR ficar saudável (healthcheck), gera os pacientes sintéticos e os carrega no servidor — tudo sem intervenção manual.

### Passo 2: Baixe o modelo llama3.2:3b

```bash
podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b
```

> Só na primeira vez. Baixa ~2GB. Hora do cafézinho.

### Passo 3: Rode a demo

```bash
python3 fhir_ollama_demo.py
```

Não é necessário rodar `bash load_patient.sh` manualmente — o container Synthea já executa esse script automaticamente ao subir, carregando os 3 pacientes curados e gerando os pacientes Synthea.

---

## 🧠 Entendendo o Código

### `docker-compose.yml`

```yaml
services:
  fhir:
    image: hapiproject/hapi:latest    # Servidor FHIR R4
    ports: ["8080:8080"]
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:8080/fhir/metadata || exit 1"]
      interval: 10s
      retries: 12                     # Aguarda até ~2 min para o HAPI subir

  synthea:
    build: { context: ., dockerfile: synthea/Dockerfile }
    depends_on:
      fhir: { condition: service_healthy }   # Só começa após o FHIR estar pronto
    environment:
      - SYNTHEA_POPULATION=20         # Número de pacientes a gerar
      - SYNTHEA_STATE=Massachusetts
      - SYNTHEA_SEED=                 # Semente para reprodutibilidade (opcional)
      - FHIR_URL=http://fhir:8080/fhir

  ollama:
    image: ollama/ollama:latest       # Runtime de LLM local
    ports: ["11434:11434"]
    volumes: [ollama_data:/root/.ollama]
```

Três serviços. Zero dependências externas. Zero API keys. Zero contas de cloud.

### `fhir_ollama_demo.py` — A Lógica Central

O script usa um menu dinâmico com duas seções de pacientes e paginação:

**1. Consulta o FHIR** — Múltiplas chamadas REST pra montar o quadro clínico completo:
```python
GET /Patient/{id}                        → Dados demográficos
GET /Condition?patient={id}              → Condições ativas (SNOMED CT)
GET /Observation?patient={id}            → Exames e sinais vitais (LOINC)
GET /MedicationRequest?patient={id}      → Medicações ativas
GET /Encounter?patient={id}              → Internações e consultas
GET /Procedure?patient={id}              → Procedimentos
GET /CarePlan?patient={id}               → Planos de cuidado
GET /DocumentReference?patient={id}      → Notas de evolução clínica
```

**2. Menu dual com paginação** — Exibe pacientes curados e Synthea em seções separadas:
```python
CURATED_PATIENTS = [
    {"id": "maria-001", "cenario": "Diabetes + Hipertensao (ambulatorial)"},
    {"id": "joao-002",  "cenario": "ICC descompensada (UTI)"},
    {"id": "ana-003",   "cenario": "Asma grave + Pneumonia (emergencia)"},
]
# Pacientes Synthea listados com paginação (10 por página), excluindo curados
```

**3. Pergunta ao Ollama** — Envia o contexto com prompt restritivo: "responda APENAS com base nos dados fornecidos."

### `load_patient.sh` + `load_evolutions.sh`

Juntos criam os 3 pacientes curados com dados clínicos ricos:
- Usa `PUT` (não POST) pro Patient pra garantir IDs fixos (`maria-001`, `joao-002`, `ana-003`)
- Todas as Conditions incluem `clinicalStatus` com system obrigatório
- Pressão arterial usa codes LOINC de componentes com unidades UCUM
- `load_evolutions.sh` adiciona `DocumentReference` com notas médicas e de enfermagem, e séries de sinais vitais

### `synthea/` — Container de Geração

| Arquivo | Função |
|---------|--------|
| `Dockerfile` | Imagem com Java + Synthea JAR + scripts |
| `entrypoint.sh` | Aguarda FHIR, chama `load_patient.sh`, gera pacientes Synthea, faz upload dos bundles |
| `generate_notes.py` | Gera `DocumentReference` de evolução para os pacientes Synthea |
| `synthea.properties` | Configurações do Synthea (exportador FHIR R4, campos obrigatórios) |

---

## 🧬 Integração com Synthea

[Synthea](https://github.com/synthetichealth/synthea) é um gerador de pacientes sintéticos open-source que simula históricos clínicos completos e realistas — sem usar dados reais de nenhum paciente.

### Como Funciona

1. O container Synthea aguarda o HAPI FHIR ficar saudável (healthcheck)
2. Carrega os 3 pacientes curados (`load_patient.sh`)
3. Executa o Synthea para gerar N pacientes completos
4. Faz upload dos bundles FHIR gerados para o servidor (hospitais, profissionais, pacientes)
5. Gera notas de evolução clínica para cada paciente Synthea
6. O container termina — o FHIR fica rodando com todos os dados

### Variáveis de Ambiente

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `SYNTHEA_POPULATION` | `20` | Número de pacientes a gerar |
| `SYNTHEA_STATE` | `Massachusetts` | Estado americano para geolocalização |
| `SYNTHEA_SEED` | (vazio) | Semente para reprodutibilidade |
| `SYNTHEA_MIN_AGE` | `30` | Idade mínima dos pacientes |
| `SYNTHEA_MAX_AGE` | `85` | Idade máxima dos pacientes |
| `SYNTHEA_MODULES` | (vazio) | Módulos específicos de doença (vazio = todos) |
| `SYNTHEA_CLEAN_FIRST` | `false` | Apaga pacientes existentes antes de gerar |

### Regenerar Pacientes

Para gerar um conjunto diferente com semente fixa (reprodutível):

```bash
SYNTHEA_SEED=42 SYNTHEA_POPULATION=50 podman-compose up synthea
```

Para apagar tudo e recomeçar:

```bash
SYNTHEA_CLEAN_FIRST=true podman-compose up synthea
```

---

## 📝 Notas de Evolução Clínica

O pipeline suporta `DocumentReference` para notas clínicas textuais — o tipo de dado mais próximo do que médicos e enfermeiros escrevem na prática.

### Pacientes Curados (`load_evolutions.sh`)

Cada paciente curado recebe notas de evolução com:
- Evolução médica (raciocínio diagnóstico, conduta)
- Evolução de enfermagem (sinais vitais, cuidados)
- Séries de sinais vitais em horários distintos

As notas são armazenadas como `DocumentReference` com conteúdo em Base64:

```json
{
  "resourceType": "DocumentReference",
  "type": {"coding": [{"display": "Progress note"}]},
  "subject": {"reference": "Patient/maria-001"},
  "author": [{"display": "Dr. Pedro Almeida"}],
  "content": [{
    "attachment": {
      "contentType": "text/plain",
      "data": "<base64 da nota>"
    }
  }]
}
```

### Pacientes Synthea (`generate_notes.py`)

O script `generate_notes.py` percorre todos os pacientes Synthea no servidor FHIR e gera uma nota de evolução sintética baseada nas condições e observações de cada paciente.

---

## 🩺 Recursos FHIR Explicados

### O Que é FHIR?

FHIR (Fast Healthcare Interoperability Resources) é o padrão global pra trocar dados de saúde. Pense nele como **REST + JSON pra dados clínicos**. Se você já fez API REST, já entende 70% do FHIR.

No Brasil, a **RNDS** (Rede Nacional de Dados em Saúde) usa FHIR R4 como padrão obrigatório. São 2,8 bilhões de registros conectando hospitais e UBS pelo SUS.

### Recursos Criados

| Recurso | Tipo FHIR | Terminologia | Código | Exemplo |
|---------|-----------|--------------|--------|---------|
| Paciente | `Patient` | — | — | Maria Santos, F, 1966 |
| Diabetes | `Condition` | SNOMED CT | `73211009` | Ativo |
| Hipertensão | `Condition` | SNOMED CT | `38341003` | Ativo |
| HbA1c | `Observation` | LOINC | `4548-4` | 9.2% |
| Pressão Arterial | `Observation` | LOINC | `85354-9` | 150/95 mmHg |
| Metformina | `MedicationRequest` | Texto livre | — | 850mg 2x/dia |
| Losartana | `MedicationRequest` | Texto livre | — | 50mg 1x/dia |
| Nota médica | `DocumentReference` | LOINC | `11506-3` | Evolução médica |
| Nota enfermagem | `DocumentReference` | LOINC | `34746-8` | Evolução de enfermagem |

---

## 📺 Output Esperado

```
==================================================
  FHIR + Ollama - Assistente Clinico
==================================================

-- Cenarios clinicos curados (dados ricos) --

  [1] Maria Santos - Diabetes + Hipertensao (ambulatorial)
  [2] Joao Oliveira - ICC descompensada (UTI)
  [3] Ana Costa - Asma grave + Pneumonia (emergencia)

-- Pacientes Synthea (pagina 1/3) --

  [4] Alice Johnson (F, 1952-07-18)
      Diabetes mellitus, Hypertension, Chronic kidney disease
  [5] Robert Chen (M, 1968-03-05)
      Asthma, Prediabetes
  ...

  [n] Proxima pagina (Synthea)
  [0] Sair

Escolha o paciente: 1

>>> Consultando FHIR para: Maria Santos...

Paciente: Maria Santos, female, nascimento: 1966-05-12

Condicoes ativas:
- Diabetes mellitus (SNOMED: 73211009)
- Hypertensive disorder (SNOMED: 38341003)

Observacoes recentes:
- Hemoglobin A1c: 9.2 % (2026-03-19)
- Blood pressure panel: Systolic blood pressure: 150mmHg, Diastolic blood pressure: 95mmHg (2026-03-19)

Medicacoes:
- Metformina 850mg (850mg 2x/dia)
- Losartana 50mg (50mg 1x/dia)

Evolucoes clinicas:
- [Progress note] 2026-03-19T08:00 | Dr. Pedro Almeida
  Paciente refere cefaleia matinal...

--------------------------------------------------
Modo interativo - Paciente: Maria Santos
Digite suas perguntas (ou 'voltar' para trocar de paciente)
--------------------------------------------------

Voce: Qual o controle glicemico desta paciente?

Pensando...

Resposta:
[Ollama responde com raciocínio clínico baseado nos dados FHIR]
```

---

## 🔐 Por Que Isso Importa

### 🏛️ LGPD
Nenhum dado de paciente sai da sua máquina. O pipeline inteiro roda local. Isso elimina o bloqueio mais comum pra adoção de IA clínica: **"não podemos enviar dados de pacientes pra APIs externas."**

### 🇧🇷 Compatibilidade com a RNDS
O HAPI FHIR usa o mesmo padrão da RNDS — FHIR R4. A RNDS já tem 2,8 bilhões de registros. Construir em FHIR hoje é garantir compatibilidade com a infraestrutura nacional de saúde amanhã.

### 💰 Custo Zero
Podman (free) + Ollama (free) + HAPI FHIR (Apache 2.0) + Synthea (Apache 2.0) + Python (free) = **R$ 0/mês**.

---

## 🔧 Resolução de Problemas

| Problema | Solução |
|----------|---------|
| `Connection refused` na porta 8080 | HAPI FHIR demora ~30s pra subir. O Synthea aguarda automaticamente pelo healthcheck. |
| `model not found` no Ollama | Rode `podman exec -it $(podman ps -q -f name=ollama) ollama pull llama3.2:3b` |
| Python `ModuleNotFoundError: requests` | Rode `pip install requests` |
| Ollama lento pra responder | llama3.2:3b precisa de ~3GB RAM. Feche outros apps. |
| Nenhum paciente Synthea no menu | Aguarde o container Synthea terminar (pode levar 2-5 min na primeira execução). |
| Paciente curado não encontrado (404) | O Synthea não terminou ainda, ou rode `bash load_patient.sh` manualmente. |
| `podman-compose` não encontrado | Instale com `pip install podman-compose` |

---

## 🗺️ Próximos Passos

- [x] 🧬 **Synthea** — Geração automática de pacientes sintéticos ao subir os containers ✅
- [ ] 🛡️ **Presidio** — Camada de anonimização da Microsoft antes do LLM
- [ ] 📊 **RAGAS** — Avaliar qualidade das respostas com faithfulness > 0.85
- [ ] 🔌 **MCP Server** — Protocolo padronizado de acesso IA-FHIR
- [ ] 🎓 **Cenários clínicos** — Simulação de enfermagem com feedback adaptativo

---

<div align="center">

**[⬆ Voltar ao topo](#-ia-clínica-local--fhir-pipeline)**

Feito com ☕ de um sítio em Santa Catarina, Brasil

</div>
