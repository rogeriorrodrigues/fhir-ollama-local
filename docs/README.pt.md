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
- [Recursos FHIR Explicados](#-recursos-fhir-explicados)
- [Output Esperado](#-output-esperado)
- [Por Que Isso Importa](#-por-que-isso-importa)
- [Resolução de Problemas](#-resolução-de-problemas)
- [Próximos Passos](#-próximos-passos)

---

## 🎯 O Que Faz

Esse pipeline roda uma **IA clínica 100% local** que lê dados de pacientes de um servidor FHIR R4 e gera raciocínio clínico — tudo sem enviar um único byte pra cloud.

**Três componentes, um `docker compose up`:**

| Componente | O Que Faz | Porta |
|------------|----------|-------|
| 🔥 **HAPI FHIR** | Armazena dados clínicos em formato FHIR R4 | `8080` |
| 🦙 **Ollama** | Roda LLaMA 3 localmente como cérebro da IA | `11434` |
| 🐍 **Script Python** | Consulta FHIR → monta contexto → pergunta ao Ollama | — |

A IA **não alucina** porque trabalha exclusivamente com dados recuperados do servidor FHIR. Cada afirmação na resposta é rastreável a um recurso clínico real.

---

## 🏗️ Arquitetura

```
┌──────────────────────────────────────────────────────────────────┐
│                        SUA MÁQUINA                               │
│                                                                  │
│  ┌─────────────┐                          ┌─────────────┐       │
│  │  HAPI FHIR  │◄── REST API (JSON) ──►  │   Python    │       │
│  │  Servidor   │    GET /Patient          │   Script    │       │
│  │             │    GET /Condition         │  (60 linhas)│       │
│  │  Porta 8080 │    GET /Observation       │             │       │
│  │             │    GET /MedicationRequest │             │       │
│  └─────────────┘                          └──────┬──────┘       │
│       Docker                                     │              │
│                                          POST /api/generate      │
│                                                   │              │
│                                          ┌────────▼──────┐      │
│                                          │    Ollama     │      │
│                                          │   LLaMA 3    │      │
│                                          │  Porta 11434 │      │
│                                          └───────────────┘      │
│                                               Docker            │
│                                                                  │
│  🔒 Nada sai desta máquina. LGPD-friendly by design.           │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📦 Pré-requisitos

| Requisito | Mínimo | Notas |
|-----------|--------|-------|
| Docker + Docker Compose | v20+ | [Instalar Docker](https://docs.docker.com/get-docker/) |
| Python | 3.8+ | Com biblioteca `requests` |
| Espaço em disco | ~5 GB | Imagem HAPI FHIR + modelo LLaMA 3 |
| RAM | 8 GB+ | LLaMA 3 precisa de ~4GB RAM |

```bash
pip install requests
```

---

## 🚀 Passo a Passo

### Passo 1: Clone e suba os serviços

```bash
git clone https://github.com/YOUR_USER/fhir-ollama-local.git
cd fhir-ollama-local
docker compose up -d
```

Isso inicia dois containers: HAPI FHIR (porta 8080) e Ollama (porta 11434).

### Passo 2: Baixe o modelo LLaMA 3

```bash
docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3
```

> ⏳ Só na primeira vez. Baixa ~4GB. Hora do cafézinho ☕

### Passo 3: Carregue a paciente de exemplo

```bash
bash load_patient.sh
```

Isso cria a Maria Santos com todos os dados clínicos no servidor FHIR. O script aguarda o HAPI FHIR estar pronto antes de carregar.

### Passo 4: Rode a demo

```bash
python fhir_ollama_demo.py
```

🎉 Veja a IA lendo dados clínicos e gerando raciocínio fundamentado!

---

## 🧠 Entendendo o Código

### `docker-compose.yml`

```yaml
services:
  fhir:
    image: hapiproject/hapi:latest    # Servidor FHIR R4
    ports: ["8080:8080"]              # API REST acessível em localhost
  ollama:
    image: ollama/ollama:latest       # Runtime de LLM local
    ports: ["11434:11434"]            # API Ollama acessível em localhost
```

Dois containers. Zero dependências externas. Zero API keys. Zero contas de cloud.

### `fhir_ollama_demo.py` — A Lógica Central

O script faz três coisas:

**1. Consulta o FHIR** — Quatro chamadas REST pra montar o quadro clínico completo:
```python
GET /Patient/{id}              → Dados demográficos
GET /Condition?patient={id}    → Condições ativas (diabetes, hipertensão)
GET /Observation?patient={id}  → Resultados de exames (HbA1c, pressão arterial)
GET /MedicationRequest?patient={id} → Medicações ativas (metformina, losartana)
```

**2. Monta o contexto** — Estrutura os dados num resumo clínico legível.

**3. Pergunta ao Ollama** — Envia o contexto com prompt restritivo: "responda APENAS com base nos dados fornecidos."

### `load_patient.sh`

Cria 7 recursos FHIR usando `curl` com terminologias corretas:
- Usa `PUT` (não POST) pro Patient pra garantir o ID `maria-001`
- Todas as Conditions incluem o `clinicalStatus` com system obrigatório
- Pressão arterial usa codes LOINC de componentes com unidades UCUM

---

## 🩺 Recursos FHIR Explicados

### O Que é FHIR?

FHIR (Fast Healthcare Interoperability Resources) é o padrão global pra trocar dados de saúde. Pense nele como **REST + JSON pra dados clínicos**. Se você já fez API REST, já entende 70% do FHIR.

No Brasil, a **RNDS** (Rede Nacional de Dados em Saúde) usa FHIR R4 como padrão obrigatório. São 2,8 bilhões de registros conectando hospitais e UBS pelo SUS.

### Recursos Criados

| Recurso | Tipo FHIR | Terminologia | Código | Valor |
|---------|-----------|--------------|--------|-------|
| Paciente | `Patient` | — | — | Maria Santos, F, 1966 |
| Diabetes | `Condition` | SNOMED CT | `73211009` | Ativo |
| Hipertensão | `Condition` | SNOMED CT | `38341003` | Ativo |
| HbA1c | `Observation` | LOINC | `4548-4` | 9.2% |
| Pressão Arterial | `Observation` | LOINC | `85354-9` | 150/95 mmHg |
| Metformina | `MedicationRequest` | Texto livre | — | 850mg 2x/dia |
| Losartana | `MedicationRequest` | Texto livre | — | 50mg 1x/dia |

---

## 📺 Output Esperado

```
=== Consultando servidor FHIR ===

Dados recuperados:
Paciente: Maria Santos, female, nascimento: 1966-05-12

Condicoes ativas:
- Diabetes mellitus (SNOMED: 73211009)
- Hypertensive disorder (SNOMED: 38341003)

Observacoes recentes:
- Hemoglobin A1c: 9.2 %
- Blood pressure panel: Systolic: 150mmHg, Diastolic: 95mmHg

Medicacoes ativas:
- Metformina 850mg (850mg 2x/dia)
- Losartana 50mg (50mg 1x/dia)

==================================================

Perguntando ao Ollama (llama3)...

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
Docker (free) + Ollama (free) + HAPI FHIR (Apache 2.0) + Python (free) = **R$ 0/mês**.

---

## 🔧 Resolução de Problemas

| Problema | Solução |
|----------|---------|
| `Connection refused` na porta 8080 | HAPI FHIR demora ~30s pra subir. Aguarde ou rode `load_patient.sh` (ele espera automaticamente). |
| `model not found` no Ollama | Rode `docker exec -it $(docker ps -q -f name=ollama) ollama pull llama3` |
| Python `ModuleNotFoundError: requests` | Rode `pip install requests` |
| Ollama lento pra responder | LLaMA 3 precisa de ~4GB RAM. Feche outros apps ou use modelo menor (`llama3:8b`). |
| Paciente não encontrado (404) | Rode `bash load_patient.sh` novamente. Usa PUT pra forçar o ID. |

---

## 🗺️ Próximos Passos

- [ ] 🧬 **Synthea** — Gerar centenas de pacientes sintéticos automaticamente
- [ ] 🛡️ **Presidio** — Camada de anonimização da Microsoft antes do LLM
- [ ] 📊 **RAGAS** — Avaliar qualidade das respostas com faithfulness > 0.85
- [ ] 🔌 **MCP Server** — Protocolo padronizado de acesso IA-FHIR
- [ ] 🎓 **Cenários clínicos** — Simulação de enfermagem com feedback adaptativo

---

<div align="center">

**[⬆ Voltar ao topo](#-ia-clínica-local--fhir-pipeline)**

Feito com ☕ de um sítio em Santa Catarina, Brasil

</div>
