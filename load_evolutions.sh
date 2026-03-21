#!/bin/bash
FHIR_URL="${FHIR_URL:-http://localhost:8080/fhir}"

echo ""
echo "=========================================="
echo "  EVOLUCOES CLINICAS - DocumentReferences"
echo "=========================================="

########################################
# MARIA SANTOS (maria-001)
# Consulta ambulatorial - DM2 + HAS
########################################
echo ""
echo "--- Maria Santos (maria-001) ---"

NOTE=$(echo -n "CONSULTA AMBULATORIAL - ENDOCRINOLOGIA
Data: 19/03/2026 | Hora: 10:00

Paciente: Maria Santos, 59 anos, feminino.
Motivo da consulta: Avaliacao inicial por diabetes mellitus tipo 2 e hipertensao arterial sistemica.

Historia clinica: Paciente refere poliuria e polidipsia ha aproximadamente 6 meses, associada a fadiga e visao turva ocasional. Nega cetoacidose previa. Historico familiar de DM2 (mae e irmao). Sedentaria, dieta rica em carboidratos refinados e gorduras saturadas. Tabagismo negado. Etilismo social ocasional.

Exame fisico:
- Estado geral: regular, consciente, orientada, hidratada, acianótica, anicterica.
- Peso: 82 kg | Altura: 1,63 m | IMC: 31 kg/m2 (obesidade grau I)
- PA: 150/95 mmHg (media de 2 afericoes) | FC: 82 bpm | FR: 16 irpm | Tax: 36,5 C
- Ausculta cardiaca: ritmo regular em 2 tempos, sem sopros.
- Ausculta pulmonar: murmuro vesicular presente bilateralmente, sem ruidos adventiciosos.
- Abdome: globoso, flacido, indolor a palpacao. Sem visceromegalias.
- MMII: sem edemas, pulsos perifericos presentes e simetricos.

Exames laboratoriais recentes (colhidos em 15/03/2026):
- HbA1c: 9,2% (meta < 7,0%)
- Glicemia de jejum: 218 mg/dL
- Colesterol total: 198 mg/dL | LDL: 128 mg/dL | HDL: 42 mg/dL | TG: 186 mg/dL
- Creatinina: 0,9 mg/dL | Ureia: 28 mg/dL
- Microalbuminuria: 28 mg/g creatinina (limiar superior)
- TSH: 2,1 mUI/L (normal)
- ECG: ritmo sinusal, sem alteracoes isquemicas.

Hipoteses diagnosticas:
1. Diabetes mellitus tipo 2 - mal controlada (HbA1c 9,2%)
2. Hipertensao arterial sistemica - estagio 2 (PA 150/95 mmHg)
3. Obesidade grau I (IMC 31)
4. Dislipidemia limítrofe (TG e LDL em acompanhamento)

Conduta:
- Iniciar Metformina 850 mg VO 2x/dia (cafe e jantar), com titulacao gradual.
- Iniciar Losartana 50 mg VO 1x/dia (manha) para controle pressórico e nefroprotetora.
- Orientacao nutricional: dieta hipocalorica, restricao de acucares simples e sodio.
- Encaminhamento para educador fisico: meta de 150 min/semana de atividade aerobica moderada.
- Retorno em 30 dias com HbA1c, glicemia de jejum, PA domiciliar registrada e peso.
- Solicitado fundo de olho e avaliacao com oftalmologia para rastreio de retinopatia.
- Orientada sobre sintomas de hipoglicemia e cuidados com os pes.

Dra. Fernanda Lima - Endocrinologia | CRM-SP 54321" | base64 -w0 2>/dev/null || echo -n "CONSULTA AMBULATORIAL - ENDOCRINOLOGIA
Data: 19/03/2026 | Hora: 10:00

Paciente: Maria Santos, 59 anos, feminino.
Motivo da consulta: Avaliacao inicial por diabetes mellitus tipo 2 e hipertensao arterial sistemica.

Historia clinica: Paciente refere poliuria e polidipsia ha aproximadamente 6 meses, associada a fadiga e visao turva ocasional. Nega cetoacidose previa. Historico familiar de DM2 (mae e irmao). Sedentaria, dieta rica em carboidratos refinados e gorduras saturadas. Tabagismo negado. Etilismo social ocasional.

Exame fisico:
- Estado geral: regular, consciente, orientada, hidratada, acianótica, anicterica.
- Peso: 82 kg | Altura: 1,63 m | IMC: 31 kg/m2 (obesidade grau I)
- PA: 150/95 mmHg (media de 2 afericoes) | FC: 82 bpm | FR: 16 irpm | Tax: 36,5 C
- Ausculta cardiaca: ritmo regular em 2 tempos, sem sopros.
- Ausculta pulmonar: murmuro vesicular presente bilateralmente, sem ruidos adventiciosos.
- Abdome: globoso, flacido, indolor a palpacao. Sem visceromegalias.
- MMII: sem edemas, pulsos perifericos presentes e simetricos.

Exames laboratoriais recentes (colhidos em 15/03/2026):
- HbA1c: 9,2% (meta < 7,0%)
- Glicemia de jejum: 218 mg/dL
- Colesterol total: 198 mg/dL | LDL: 128 mg/dL | HDL: 42 mg/dL | TG: 186 mg/dL
- Creatinina: 0,9 mg/dL | Ureia: 28 mg/dL
- Microalbuminuria: 28 mg/g creatinina (limiar superior)
- TSH: 2,1 mUI/L (normal)
- ECG: ritmo sinusal, sem alteracoes isquemicas.

Hipoteses diagnosticas:
1. Diabetes mellitus tipo 2 - mal controlada (HbA1c 9,2%)
2. Hipertensao arterial sistemica - estagio 2 (PA 150/95 mmHg)
3. Obesidade grau I (IMC 31)
4. Dislipidemia limítrofe (TG e LDL em acompanhamento)

Conduta:
- Iniciar Metformina 850 mg VO 2x/dia (cafe e jantar), com titulacao gradual.
- Iniciar Losartana 50 mg VO 1x/dia (manha) para controle pressórico e nefroprotetora.
- Orientacao nutricional: dieta hipocalorica, restricao de acucares simples e sodio.
- Encaminhamento para educador fisico: meta de 150 min/semana de atividade aerobica moderada.
- Retorno em 30 dias com HbA1c, glicemia de jejum, PA domiciliar registrada e peso.
- Solicitado fundo de olho e avaliacao com oftalmologia para rastreio de retinopatia.
- Orientada sobre sintomas de hipoglicemia e cuidados com os pes.

Dra. Fernanda Lima - Endocrinologia | CRM-SP 54321" | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11488-4\", \"display\": \"Consultation note\"}]},
    \"subject\": {\"reference\": \"Patient/maria-001\"},
    \"date\": \"2026-03-19T10:00:00Z\",
    \"author\": [{\"display\": \"Dra. Fernanda Lima - Endocrinologia\"}],
    \"description\": \"Consulta inicial - DM2 + HAS\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Consulta inicial - DM2 + HAS"

NOTE=$(echo -n "RETORNO AMBULATORIAL - ENDOCRINOLOGIA
Data: 19/04/2026 | Hora: 10:00

Paciente: Maria Santos, 59 anos, feminino.
Retorno: 30 dias apos consulta inicial por DM2 + HAS.

Evolucao subjetiva: Paciente relata boa tolerancia a Metformina apos periodo de adaptacao (nauseas leves na primeira semana, ja resolvidas). Realizando caminhadas 3x/semana, 30 minutos cada. Refere melhora do apetite e reducao de ingestao de doces. Pressao arterial domiciliar variando entre 130-145/85-92 mmHg. Nega hipoglicemias. Nega tontura ou cefaleia importante.

Exame fisico:
- Estado geral: bom, consciente, orientada, hidratada.
- Peso: 80,5 kg (reducao de 1,5 kg em 30 dias)
- PA: 138/88 mmHg | FC: 78 bpm | FR: 15 irpm | Tax: 36,3 C
- Ausculta cardiaca e pulmonar: sem alteracoes.
- MMII: sem edemas.

Exames laboratoriais (colhidos em 17/04/2026):
- HbA1c: 8,4% (reducao de 0,8 ponto - melhora parcial, ainda acima da meta)
- Glicemia de jejum: 178 mg/dL
- Colesterol total: 212 mg/dL | LDL: 142 mg/dL | HDL: 40 mg/dL | TG: 198 mg/dL
- Creatinina: 0,9 mg/dL (estavel)
- Microalbuminuria: 24 mg/g (leve reducao)

Avaliacao:
- DM2: melhora parcial com Metformina em monoterapia, necessita intensificacao do controle glicemico.
- HAS: controle parcial, pressao ainda acima da meta (< 130/80 para diabetico).
- Dislipidemia: LDL 142 mg/dL e TG 198 mg/dL - indicacao de tratamento farmacologico dado o risco cardiovascular elevado (DM2 + HAS).
- Peso: perda de 1,5 kg em 30 dias, progresso positivo.

Conduta:
- Intensificar controle glicemico: adicionar Glicazida MR 30 mg VO 1x/dia (cafe da manha), com possibilidade de aumento para 60 mg em proximo retorno conforme resposta.
- Iniciar Sinvastatina 20 mg VO 1x/dia (jantar) para controle de dislipidemia e reducao de risco cardiovascular.
- Manter Metformina 850 mg 2x/dia e Losartana 50 mg 1x/dia.
- Reforcar orientacoes dieteticas: reducao adicional de gorduras saturadas e carboidratos refinados.
- Solicitar perfil lipidico de controle em 90 dias apos inicio de estatina.
- Retorno em 60 dias com HbA1c, lipidograma e aferição de PA domiciliar.
- Encaminhamento para oftalmologia mantido.

Dra. Fernanda Lima - Endocrinologia | CRM-SP 54321" | base64 -w0 2>/dev/null || echo -n "RETORNO AMBULATORIAL - ENDOCRINOLOGIA
Data: 19/04/2026 | Hora: 10:00

Paciente: Maria Santos, 59 anos, feminino.
Retorno: 30 dias apos consulta inicial por DM2 + HAS.

Evolucao subjetiva: Paciente relata boa tolerancia a Metformina apos periodo de adaptacao (nauseas leves na primeira semana, ja resolvidas). Realizando caminhadas 3x/semana, 30 minutos cada. Refere melhora do apetite e reducao de ingestao de doces. Pressao arterial domiciliar variando entre 130-145/85-92 mmHg. Nega hipoglicemias. Nega tontura ou cefaleia importante.

Exame fisico:
- Estado geral: bom, consciente, orientada, hidratada.
- Peso: 80,5 kg (reducao de 1,5 kg em 30 dias)
- PA: 138/88 mmHg | FC: 78 bpm | FR: 15 irpm | Tax: 36,3 C
- Ausculta cardiaca e pulmonar: sem alteracoes.
- MMII: sem edemas.

Exames laboratoriais (colhidos em 17/04/2026):
- HbA1c: 8,4% (reducao de 0,8 ponto - melhora parcial, ainda acima da meta)
- Glicemia de jejum: 178 mg/dL
- Colesterol total: 212 mg/dL | LDL: 142 mg/dL | HDL: 40 mg/dL | TG: 198 mg/dL
- Creatinina: 0,9 mg/dL (estavel)
- Microalbuminuria: 24 mg/g (leve reducao)

Avaliacao:
- DM2: melhora parcial com Metformina em monoterapia, necessita intensificacao do controle glicemico.
- HAS: controle parcial, pressao ainda acima da meta (< 130/80 para diabetico).
- Dislipidemia: LDL 142 mg/dL e TG 198 mg/dL - indicacao de tratamento farmacologico dado o risco cardiovascular elevado (DM2 + HAS).
- Peso: perda de 1,5 kg em 30 dias, progresso positivo.

Conduta:
- Intensificar controle glicemico: adicionar Glicazida MR 30 mg VO 1x/dia (cafe da manha), com possibilidade de aumento para 60 mg em proximo retorno conforme resposta.
- Iniciar Sinvastatina 20 mg VO 1x/dia (jantar) para controle de dislipidemia e reducao de risco cardiovascular.
- Manter Metformina 850 mg 2x/dia e Losartana 50 mg 1x/dia.
- Reforcar orientacoes dieteticas: reducao adicional de gorduras saturadas e carboidratos refinados.
- Solicitar perfil lipidico de controle em 90 dias apos inicio de estatina.
- Retorno em 60 dias com HbA1c, lipidograma e aferição de PA domiciliar.
- Encaminhamento para oftalmologia mantido.

Dra. Fernanda Lima - Endocrinologia | CRM-SP 54321" | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11506-3\", \"display\": \"Progress note\"}]},
    \"subject\": {\"reference\": \"Patient/maria-001\"},
    \"date\": \"2026-04-19T10:00:00Z\",
    \"author\": [{\"display\": \"Dra. Fernanda Lima - Endocrinologia\"}],
    \"description\": \"Retorno 30 dias - melhora parcial, adicionar Glicazida + Sinvastatina\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Retorno 30 dias - melhora parcial, adicionar Glicazida + Sinvastatina"

########################################
# JOAO OLIVEIRA (joao-002)
# ICC descompensada - UTI - 2 dias
########################################
echo ""
echo "--- Joao Oliveira (joao-002) ---"

# --- Dia 1 08h: Evolucao medica admissao ---
NOTE=$(echo -n "EVOLUCAO MEDICA - UTI CARDIOLOGICA
Data: 19/03/2026 | Hora: 08:00 | Admissao UTI

Paciente: Joao Oliveira, 71 anos, masculino. Admitido ha 2h por insuficiencia cardiaca congestiva descompensada.

Queixa principal: Dispneia intensa em repouso, ortopneia, edema progressivo de MMII ha 5 dias.

Historia da molestia atual: Paciente com ICC cronica conhecida (FE previa 30%), fibrilacao atrial permanente em uso de Carvedilol e Furosemida oral. Refere piora progressiva da dispneia nos ultimos 5 dias, com ortopneia (usa 3 travesseiros), dispneia paroxistica noturna e edema de MMII que atingiu joelhos. Nega fator precipitante identificado (relata adesao ao tratamento). Esposa refere que ha 2 semanas apresentou infeccao de vias aereas superiores.

Exame fisico na admissao:
- Estado geral: mau, taquidispneico, cianose perioral leve.
- Glasgow 15, ansioso e agitado por dispneia.
- PA: 90/60 mmHg | FC: 112 bpm (irregular - FA) | SpO2: 88% em ar ambiente | FR: 32 irpm
- Ausculta cardiaca: ritmo irregular (FA), bulhas hipofonadas, sem sopros audíveis.
- Ausculta pulmonar: crepitacoes bibasais ate terco medio (edema pulmonar agudo).
- Abdome: hepatomegalia dolorosa (+3 cm abaixo do rebordo costal), ascite leve.
- MMII: edema bilateral ate joelhos, ++/4+, fovea positiva.
- Jugular: ingurgitamento jugular a 45 graus.

Exames complementares admissao:
- BNP: 1850 pg/mL (elevado - ICC descompensada grave)
- Troponina I: 0,08 ng/mL (leve elevacao - estresse miocardico)
- Creatinina: 2,1 mg/dL | Ureia: 68 mg/dL (IRA sobre DRC estagio 3)
- Na: 131 mEq/L (hiponatremia diluicional) | K: 5,3 mEq/L
- Rx torax: cardiomegalia, infiltrado pulmonar bilateral, linhas B de Kerley.
- ECG: fibrilacao atrial com resposta ventricular 112 bpm, sem isquemia aguda.

Diagnostico: ICC NYHA IV agudamente descompensada + Edema pulmonar agudo cardiogenico + FA com resposta ventricular acelerada + IRA estagio 2 (KDIGO)

Conduta imediata:
- Decubito elevado 45 graus, restricao hidrica 1000 mL/24h.
- O2 por cateter nasal 5L/min (meta SpO2 > 92%).
- Furosemida EV 80 mg em bolus, seguido de infusao continua 10 mg/h.
- Dobutamina 5 mcg/kg/min em bomba de infusao continua (suporte inotropico).
- Suspender Furosemida oral e Carvedilol temporariamente.
- Monitoracao continua: ECG, SpO2, PA invasiva a avaliar.
- Balanco hidrico horario, diurese horaria.
- Acesso venoso central em veia jugular interna direita.
- Ecocardiograma transtorácico urgente solicitado.
- Avaliacao de anticoagulacao para FA (CHA2DS2-VASc a calcular).

Prognostico: reservado. Paciente em estado critico. Familia orientada.

Dr. Ricardo Mendes - Cardiologia | CRM-SP 78901" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO MEDICA - UTI CARDIOLOGICA
Data: 19/03/2026 | Hora: 08:00 | Admissao UTI

Paciente: Joao Oliveira, 71 anos, masculino. Admitido ha 2h por insuficiencia cardiaca congestiva descompensada.

Queixa principal: Dispneia intensa em repouso, ortopneia, edema progressivo de MMII ha 5 dias." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11506-3\", \"display\": \"Progress note\"}]},
    \"subject\": {\"reference\": \"Patient/joao-002\"},
    \"date\": \"2026-03-19T08:00:00Z\",
    \"author\": [{\"display\": \"Dr. Ricardo Mendes - Cardiologia\"}],
    \"description\": \"Dia 1 08h - Evolucao medica admissao UTI - ICC NYHA IV\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Dia 1 08h - Evolucao medica admissao UTI - ICC NYHA IV"

# --- Dia 1 08h30: Evolucao enfermagem admissao ---
NOTE=$(echo -n "EVOLUCAO DE ENFERMAGEM - UTI CARDIOLOGICA
Data: 19/03/2026 | Hora: 08:30 | Admissao

Paciente: Joao Oliveira, 71 anos. Admitido por ICC descompensada grave.

Avaliacao de enfermagem na admissao:
- Nivel de consciencia: Glasgow 15 (AO4, RV5, RM6). Orientado em tempo e espaco.
- Estado geral: taquidispneico, ansioso, posicao ortopneica, cianose perioral leve.
- PA: 90/60 mmHg | FC: 112 bpm (irregular) | SpO2: 88% | FR: 32 irpm | Tax: 36,8 C
- Peso aferido: 82,5 kg (peso seco estimado 76 kg - excesso de 6,5 kg em fluidos).

Avaliacao por sistemas:
- Respiratorio: dispneia intensa em repouso, uso de musculatura acessoria, crepitacoes bibasais. O2 iniciado a 5L/min por cateter nasal.
- Cardiovascular: ritmo irregular (FA), TEC 3 segundos, extremidades frias.
- Edema: MMII bilateral ate joelhos, ++/4+, fovea positiva. Escroto com edema leve.
- Renal: sonda vesical de demora instalada para controle rigoroso de diurese.
- Gastrointestinal: abdome distendido, hepatomegalia palpavel.
- Tegumentar: pele palida, sudoreica, turgor preservado.
- Acesso venoso: cateter venoso central instalado em veia jugular interna direita, 2 lumens - confirmado por RX (pendente).

Cuidados de enfermagem realizados:
- Decubito elevado 45 graus mantido.
- Monitorizacao continua instalada: ECG continuo, SpO2, PA nao invasiva 1/1h.
- Furosemida EV 80 mg administrada conforme prescricao.
- Dobutamina 5 mcg/kg/min iniciada em bomba de infusao (solucao: 250 mg/250 mL SF 0,9%).
- Restricao hidrica 1000 mL/24h orientada e controlada.
- Dieta zero por enquanto, aguardando estabilizacao hemodinamica.
- Escala de Braden: 14 pontos (risco moderado para lesao por pressao) - colchao pneumatico solicitado.
- Familiar orientado sobre estado critico do paciente.

Balanco hidrico parcial (08:00-08:30): entrada 80 mL / saida 0 mL (aguardando efeito furosemida).

Enf. Lucia Ferreira - COREN-SP 123456" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO DE ENFERMAGEM - UTI CARDIOLOGICA
Data: 19/03/2026 | Hora: 08:30 | Admissao

Paciente: Joao Oliveira, 71 anos. Admitido por ICC descompensada grave." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"28651-8\", \"display\": \"Nurse notes\"}]},
    \"subject\": {\"reference\": \"Patient/joao-002\"},
    \"date\": \"2026-03-19T08:30:00Z\",
    \"author\": [{\"display\": \"Enf. Lucia Ferreira\"}],
    \"description\": \"Dia 1 08h30 - Evolucao enfermagem admissao UTI\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Dia 1 08h30 - Evolucao enfermagem admissao UTI"

# --- Dia 1 14h: Evolucao medica tarde ---
NOTE=$(echo -n "EVOLUCAO MEDICA - UTI CARDIOLOGICA
Data: 19/03/2026 | Hora: 14:00 | Evolucao tarde

Paciente: Joao Oliveira, 71 anos. 6 horas de internacao na UTI.

Evolucao: Paciente apresenta resposta diuretica parcial ao tratamento instituido. Mantém dispneia em repouso, porem com leve melhora subjetiva em relacao a admissao. Ainda ansioso, mas mais cooperativo.

Dados vitais atuais:
- PA: 95/62 mmHg | FC: 105 bpm (FA persistente) | SpO2: 91% (O2 3L/min) | FR: 26 irpm | Tax: 37,1 C

Balanco hidrico 08h-14h:
- Diurese: 400 mL em 6 horas (resposta parcial - meta > 200 mL/h)
- Entrada: 480 mL (infusoes + medicacoes)
- Balanco parcial: -80 mL (insuficiente)

Avaliacao:
- Resposta diuretica aquém do esperado. Optado por manter infusao continua de Furosemida 10 mg/h.
- Dobutamina mantida a 5 mcg/kg/min - PA em limite inferior aceitavel.
- SpO2 com discreta melhora (88 → 91%) com reducao do O2 para 3L/min.
- FA: avaliar anticoagulacao apos estabilizacao hemodinamica (CHA2DS2-VASc = 4).
- Aguardando resultado do ecocardiograma transtorácico.
- Potassio 5,3 mEq/L - suspender suplementacao, monitorar com furosemida.
- Funcao renal em acompanhamento: creatinina 2,1 - risco de piora com diureticos.

Conduta:
- Manter Furosemida EV infusao continua 10 mg/h.
- Manter Dobutamina 5 mcg/kg/min.
- Meta diuretica: > 100 mL/h nas proximas 6 horas.
- Repetir eletrolitos e funcao renal as 20h.
- Reavaliar necessidade de VNI se SpO2 nao melhorar.
- Discutir anticoagulacao com equipe amanha.

Dr. Ricardo Mendes - Cardiologia | CRM-SP 78901" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO MEDICA - UTI CARDIOLOGICA
Data: 19/03/2026 | Hora: 14:00

Resposta diuretica parcial. Dobutamina mantida." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11506-3\", \"display\": \"Progress note\"}]},
    \"subject\": {\"reference\": \"Patient/joao-002\"},
    \"date\": \"2026-03-19T14:00:00Z\",
    \"author\": [{\"display\": \"Dr. Ricardo Mendes - Cardiologia\"}],
    \"description\": \"Dia 1 14h - Evolucao medica tarde - resposta diuretica parcial\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Dia 1 14h - Evolucao medica tarde - resposta diuretica parcial"

# --- Dia 1 20h: Evolucao enfermagem noite ---
NOTE=$(echo -n "EVOLUCAO DE ENFERMAGEM - UTI CARDIOLOGICA
Data: 19/03/2026 | Hora: 20:00 | Plantao noturno

Paciente: Joao Oliveira, 71 anos. ICC descompensada - 12h de UTI.

Avaliacao de enfermagem:
- Nivel de consciencia: Glasgow 15. Paciente mais calmo, menos ansioso que na admissao.
- PA: 98/65 mmHg | FC: 98 bpm (FA persistente) | SpO2: 92% (O2 3L/min) | FR: 22 irpm | Tax: 36,9 C
- Estado geral: regularmente, ainda com dispneia leve em repouso, melhora em relacao a manha.

Evolucao por sistemas:
- Respiratorio: crepitacoes bibasais ainda presentes, porem menos extensas. Dispneia em melhora progressiva. O2 reduzido de 5L para 3L/min.
- Cardiovascular: PA em progressiva melhora, extremidades menos frias, TEC 2,5 segundos.
- Renal: diurese satisfatoria nas ultimas horas.
- Edema: MMII com edema ++/4+ (sem alteracao significativa ainda).
- Gastrointestinal: dieta liquida iniciada as 18h - aceitou bem, sem vomitos.
- Tegumentar: sem lesoes por pressao, colchao pneumatico instalado.

Balanco hidrico 08h-20h (12 horas):
- Diurese total: 800 mL
- Entrada total: 1200 mL (infusoes + alimentacao)
- Balanco parcial: -800 mL (negativo - bom sinal de descongestao)

Infusoes em andamento:
- Furosemida: 10 mg/h em bomba continua.
- Dobutamina: 5 mcg/kg/min em bomba continua.
- Sem intercorrencias com acessos vasculares.

Intercorrencias: Nenhuma no plantao. Familiar visitou as 18h - orientado sobre evolucao estavel porem critica.

Proximo controle: PA e SpO2 a cada hora, diurese horaria.

Enf. Patricia Santos - COREN-SP 234567" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO DE ENFERMAGEM - UTI CARDIOLOGICA
Data: 19/03/2026 | Hora: 20:00

Balanco hidrico -800mL. SpO2 92% O2 3L/min. Dieta aceita." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"28651-8\", \"display\": \"Nurse notes\"}]},
    \"subject\": {\"reference\": \"Patient/joao-002\"},
    \"date\": \"2026-03-19T20:00:00Z\",
    \"author\": [{\"display\": \"Enf. Patricia Santos\"}],
    \"description\": \"Dia 1 20h - Evolucao enfermagem noite - balanco -800mL\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Dia 1 20h - Evolucao enfermagem noite - balanco -800mL"

# --- Dia 2 08h: Evolucao medica manha ---
NOTE=$(echo -n "EVOLUCAO MEDICA - UTI CARDIOLOGICA
Data: 20/03/2026 | Hora: 08:00 | 2o dia de internacao

Paciente: Joao Oliveira, 71 anos. ICC descompensada - 24h de UTI.

Evolucao: Melhora clinica significativa em relacao a admissao. Paciente referindo reducao importante da dispneia, conseguiu dormir em decubito de 30 graus (antes nao tolerava menos de 45). Ansiedade reduzida.

Dados vitais atuais:
- PA: 100/65 mmHg | FC: 88 bpm (FA persistente, porem com melhor controle de FC) | SpO2: 94% em ar ambiente | FR: 18 irpm | Tax: 36,6 C

Balanco hidrico 24h (19/03 08h - 20/03 08h):
- Diurese total: 1800 mL
- Entrada total: 1500 mL
- Balanco 24h: -1200 mL (negativo satisfatorio)
- Peso atual: 80,5 kg (reducao de 2 kg em 24h - descongestao em andamento)

Exames laboratoriais controle (20/03 06h):
- BNP: 980 pg/mL (queda de 1850 → 980 - melhora significativa, ainda elevado)
- Creatinina: 2,3 mg/dL (leve piora - cardiorenal syndrome monitorada)
- Na: 133 mEq/L (leve melhora) | K: 4,8 mEq/L
- Troponina I: 0,06 ng/mL (reducao - sem isquemia ativa)

Exame fisico:
- Ausculta pulmonar: crepitacoes bibasais reduzidas (apenas base direita).
- Edema MMII: +/4+ (melhora significativa de ++/4+).
- Jugular: ingurgitamento reduzido.
- Abdome: hepatomegalia persistente, menos dolorosa.

Avaliacao e conduta:
- ICC: melhora clinica e laboratorial evidente. Iniciar desmame de Dobutamina gradualmente.
- Reducao de Dobutamina: de 5 para 3,75 mcg/kg/min - reavaliar tolerancia em 6h.
- SpO2 94% em ar ambiente - retirada do O2 suplementar.
- Manter Furosemida EV infusao continua 10 mg/h.
- Ecocardiograma transtorácico realizado - aguardando laudo formal.
- Reavaliar reintroducao de Carvedilol em baixa dose se PA se mantiver > 100 mmHg.
- Discussao com cardiologia: possibilidade de dispositivo (CDI/TRC) apos estabilizacao.

Dr. Ricardo Mendes - Cardiologia | CRM-SP 78901" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO MEDICA - UTI CARDIOLOGICA
Data: 20/03/2026 | Hora: 08:00

Melhora significativa. BNP 980. Desmame dobutamina iniciado." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11506-3\", \"display\": \"Progress note\"}]},
    \"subject\": {\"reference\": \"Patient/joao-002\"},
    \"date\": \"2026-03-20T08:00:00Z\",
    \"author\": [{\"display\": \"Dr. Ricardo Mendes - Cardiologia\"}],
    \"description\": \"Dia 2 08h - Melhora significativa, BNP 980, desmame dobutamina\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Dia 2 08h - Melhora significativa, BNP 980, desmame dobutamina"

# --- Dia 2 08h30: Evolucao enfermagem manha ---
NOTE=$(echo -n "EVOLUCAO DE ENFERMAGEM - UTI CARDIOLOGICA
Data: 20/03/2026 | Hora: 08:30 | 2o dia - Manha

Paciente: Joao Oliveira, 71 anos. ICC descompensada - 24h internado.

Avaliacao de enfermagem - manha:
- Nivel de consciencia: Glasgow 15. Paciente calmo, colaborativo, comunicativo.
- PA: 100/65 mmHg | FC: 88 bpm | SpO2: 94% ar ambiente | FR: 18 irpm | Tax: 36,5 C
- Estado geral: regular a bom. Melhora progressiva evidente.

Evolucao clinica de enfermagem:
- Respiratorio: sem O2 suplementar desde as 07h. SpO2 mantendo 93-94% em ar ambiente. Sem uso de musculatura acessoria. Ausculta com melhora das crepitacoes.
- Cardiovascular: PA e FC mais estaveis. Extremidades aquecidas, TEC 2 segundos.
- Mobilidade: paciente sentado na cama espontaneamente desde as 07h30. Deambulou ate o banheiro com auxilio de 1 profissional - tolerou bem, sem desconforto.
- Peso: 80,5 kg (reducao de 2 kg em relacao a admissao de 82,5 kg).
- Edema MMII: +/4+ (melhora expressiva de ++/4+ na admissao).
- Renal: diurese mantida, sonda vesical funcionante, debito adequado.
- Nutricao: aceita dieta pastosa sem restricoes desde ontem a noite. Apetite melhorando.

Balanco hidrico 24h (fechado as 08h):
- Diurese 24h: 1800 mL
- Entrada 24h: 1500 mL
- Balanco 24h: -1200 mL (descongestao satisfatoria)

Infusoes em andamento:
- Furosemida: 10 mg/h (mantida).
- Dobutamina: reduzida para 3,75 mcg/kg/min conforme prescricao medica.

Cuidados:
- Fisioterapia solicitada para inicio de exercicios respiratorios e mobilizacao.
- Escala de Braden: 17 (risco leve) - sem lesoes por pressao.
- Acesso venoso central sem sinais de infeccao ou obstrucao.

Enf. Lucia Ferreira - COREN-SP 123456" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO DE ENFERMAGEM - UTI CARDIOLOGICA
Data: 20/03/2026 | Hora: 08:30

Paciente sentado. Deambulou ao banheiro. Peso 80,5kg. Balanco -1200mL." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"28651-8\", \"display\": \"Nurse notes\"}]},
    \"subject\": {\"reference\": \"Patient/joao-002\"},
    \"date\": \"2026-03-20T08:30:00Z\",
    \"author\": [{\"display\": \"Enf. Lucia Ferreira\"}],
    \"description\": \"Dia 2 08h30 - Paciente deambulou, peso 80,5kg, balanco -1200mL\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Dia 2 08h30 - Paciente deambulou, peso 80,5kg, balanco -1200mL"

# --- Dia 2 14h: Evolucao medica tarde - eco ---
NOTE=$(echo -n "EVOLUCAO MEDICA - UTI CARDIOLOGICA
Data: 20/03/2026 | Hora: 14:00 | 2o dia - Tarde

Paciente: Joao Oliveira, 71 anos. ICC descompensada - 30h de UTI.

Evolucao: Paciente mantém melhora progressiva. Sem novos sintomas. Tolerou reducao de Dobutamina de 5 para 3,75 mcg/kg/min sem instabilidade hemodinamica.

Dados vitais:
- PA: 108/70 mmHg | FC: 85 bpm (FA) | SpO2: 95% ar ambiente | FR: 17 irpm

Resultado do ecocardiograma transtorácico (20/03/2026):
- Fracao de ejecao do VE (Simpson biplano): 25% (disfuncao sistolica grave)
- Padrao de enchimento mitral: grau III (disfuncao diastolica grave)
- Insuficiencia mitral: moderada (area de orificio efetivo 0,3 cm2)
- VE dilatado (DDVE 68 mm) com hipocinesia difusa
- Hipertensao pulmonar estimada: PSAP 48 mmHg
- Funcao diastolica VD: preservada
- Sem derrame pericardico significativo

Avaliacao e conduta:
- FE 25% confirma ICC com FE reduzida grave (ICFEr). Indicacao de otimizacao de TMBO (terapia medicamentosa baseada em evidencias).
- Insuficiencia mitral moderada: provavelmente funcional por dilatacao do VE. Reavaliacao apos descompressao.
- Reintroducao de Carvedilol 3,125 mg 2x/dia iniciada (PA permitindo).
- Desmame gradual de Dobutamina: reducao para 2,5 mcg/kg/min agora. Meta: suspensao em 24-48h se PA estavel.
- Manter Furosemida EV: reduzir para 5 mg/h (balanco ja satisfatorio).
- Discutir com equipe: indicacao de dispositivo (CDI para prevencao de morte subita - FE 25%) apos alta e estabilizacao ambulatorial.
- Anticoagulacao: iniciar Heparina nao fracionada 5000 UI SC 8/8h para FA (CHA2DS2-VASc = 4 - alto risco tromboembolico). Transicao para Warfarina ou NOAC apos alta.
- Prognostico: melhora clinica, ainda reservado a medio prazo pela gravidade da FE.

Dr. Ricardo Mendes - Cardiologia | CRM-SP 78901" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO MEDICA - UTI CARDIOLOGICA
Data: 20/03/2026 | Hora: 14:00

Eco: FE 25%, IM moderada. Carvedilol reintroduzido. Desmame dobutamina." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11506-3\", \"display\": \"Progress note\"}]},
    \"subject\": {\"reference\": \"Patient/joao-002\"},
    \"date\": \"2026-03-20T14:00:00Z\",
    \"author\": [{\"display\": \"Dr. Ricardo Mendes - Cardiologia\"}],
    \"description\": \"Dia 2 14h - Eco FE 25%, IM moderada, desmame dobutamina\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Dia 2 14h - Eco FE 25%, IM moderada, desmame dobutamina"

# --- Dia 2 20h: Evolucao enfermagem noite ---
NOTE=$(echo -n "EVOLUCAO DE ENFERMAGEM - UTI CARDIOLOGICA
Data: 20/03/2026 | Hora: 20:00 | 2o dia - Plantao noturno

Paciente: Joao Oliveira, 71 anos. ICC descompensada - 36h de UTI.

Avaliacao de enfermagem - noite:
- Nivel de consciencia: Glasgow 15. Paciente calmo, cooperativo, conversando normalmente.
- PA: 110/72 mmHg | FC: 82 bpm (FA) | SpO2: 95% ar ambiente | FR: 16 irpm | Tax: 36,4 C
- Estado geral: regular a bom. Melhora progressiva mantida.

Evolucao clinica:
- Respiratorio: sem O2 suplementar. SpO2 95% em ar ambiente. Sem dispneia em repouso. Ausculta com murmuro vesicular presente bilateralmente, crepitacoes leves em base direita apenas.
- Cardiovascular: PA em melhora progressiva (90→98→100→108→110 mmHg sistolica). Ritmo irregular (FA). Extremidades aquecidas.
- Edema MMII: +/4+ mantido (melhora sustentada desde a admissao).
- Renal: diurese adequada. Sonda vesical funcionante.
- Nutricao: dieta geral aceita plenamente. Sem nauseas ou vomitos.
- Mobilidade: paciente deambulou ate o corredor com auxilio as 19h.

Infusoes em andamento:
- Dobutamina: 2,5 mcg/kg/min (reduzida de 3,75 conforme prescricao).
- Furosemida: 5 mg/h (reducao conforme balanco satisfatorio).
- Carvedilol 3,125 mg VO - primeira dose administrada as 20h - tolerada sem hipotensao.
- Heparina SC 5000 UI - administrada as 20h.

Balanco hidrico parcial (08h-20h):
- Diurese: 900 mL
- Entrada: 800 mL
- Balanco parcial: -100 mL (proximo ao equilibrio - adequado para esta fase)

Intercorrencias: nenhuma. Familiar presente, orientado sobre melhora clinica do paciente.
Paciente com alta perspectiva de transferencia para enfermaria cardio em 24-48h.

Enf. Patricia Santos - COREN-SP 234567" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO DE ENFERMAGEM - UTI CARDIOLOGICA
Data: 20/03/2026 | Hora: 20:00

Dobutamina 2,5. SpO2 95% AA. Dieta aceita. Deambulou no corredor." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"28651-8\", \"display\": \"Nurse notes\"}]},
    \"subject\": {\"reference\": \"Patient/joao-002\"},
    \"date\": \"2026-03-20T20:00:00Z\",
    \"author\": [{\"display\": \"Enf. Patricia Santos\"}],
    \"description\": \"Dia 2 20h - Dobutamina 2.5, SpO2 95% AA, dieta aceita\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Dia 2 20h - Dobutamina 2.5, SpO2 95% AA, dieta aceita"

# --- Sinais vitais seriais Joao (Observations) ---
echo "  -> Carregando sinais vitais seriais (Joao)..."

# Pesos
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T08:30:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "29463-7", "display": "Body weight"}]},
    "valueQuantity": {"value": 82.5, "unit": "kg", "system": "http://unitsofmeasure.org", "code": "kg"}
  }' > /dev/null && echo "Observation: Peso Dia 1 82.5 kg"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T08:30:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "29463-7", "display": "Body weight"}]},
    "valueQuantity": {"value": 80.5, "unit": "kg", "system": "http://unitsofmeasure.org", "code": "kg"}
  }' > /dev/null && echo "Observation: Peso Dia 2 80.5 kg"

# Dia 1 08h vitais
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T08:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 90, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 60, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA Dia 1 08h 90/60"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T08:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 112, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC Dia 1 08h 112"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T08:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 88, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 Dia 1 08h 88%"

# Dia 1 14h vitais
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T14:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 95, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 62, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA Dia 1 14h 95/62"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T14:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 105, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC Dia 1 14h 105"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T14:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 91, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 Dia 1 14h 91%"

# Dia 1 20h vitais
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T20:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 98, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 65, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA Dia 1 20h 98/65"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T20:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 98, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC Dia 1 20h 98"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T20:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 92, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 Dia 1 20h 92%"

# Dia 2 02h vitais
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T02:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 100, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 65, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA Dia 2 02h 100/65"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T02:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 95, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC Dia 2 02h 95"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T02:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 93, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 Dia 2 02h 93%"

# Dia 2 08h vitais
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T08:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 105, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 68, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA Dia 2 08h 105/68"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T08:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 88, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC Dia 2 08h 88"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T08:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 94, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 Dia 2 08h 94%"

# Dia 2 14h vitais
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T14:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 108, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 70, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA Dia 2 14h 108/70"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T14:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 85, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC Dia 2 14h 85"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T14:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Lucia Ferreira"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 95, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 Dia 2 14h 95%"

# Dia 2 20h vitais
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T20:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "85354-9", "display": "Blood pressure panel"}]},
    "component": [
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8480-6", "display": "Systolic blood pressure"}]}, "valueQuantity": {"value": 110, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}},
      {"code": {"coding": [{"system": "http://loinc.org", "code": "8462-4", "display": "Diastolic blood pressure"}]}, "valueQuantity": {"value": 72, "unit": "mmHg", "system": "http://unitsofmeasure.org", "code": "mm[Hg]"}}
    ]
  }' > /dev/null && echo "Observation: PA Dia 2 20h 110/72"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T20:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 82, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC Dia 2 20h 82"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-20T20:00:00Z",
    "subject": {"reference": "Patient/joao-002"},
    "performer": [{"display": "Enf. Patricia Santos"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 95, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 Dia 2 20h 95%"

########################################
# ANA COSTA (ana-003)
# Pronto-socorro - Asma + Pneumonia
########################################
echo ""
echo "--- Ana Costa (ana-003) ---"

# --- Triagem ---
NOTE=$(echo -n "TRIAGEM - PRONTO-SOCORRO
Data: 19/03/2026 | Hora: 14:00 | Classificacao de Risco Manchester

Paciente: Ana Costa, 35 anos, feminino. Chegou ao PS acompanhada de mae.

Queixa principal: Falta de ar progressiva e febre ha 2 dias. Piora importante nas ultimas 4 horas.

Historia resumida pelo enfermeiro de triagem:
Paciente refere dispneia progressiva iniciada ha 2 dias, associada a febre (medicou com dipirona em casa, sem alívio completo), tosse produtiva com secrecao amarelada e dor toracica pleurítica a direita. Historico de asma bronquica desde a infancia, em uso de Formoterol + Budesonida inalatorio. Relata que nao estava usando o corticoide inalatorio regularmente ha 3 semanas. Nega tabagismo. Sem alergias medicamentosas conhecidas. Ultima crise de asma ha 8 meses (necessitou pronto-socorro, nao necessitou internacao).

Sinais vitais na triagem:
- PA: 118/76 mmHg | FC: 108 bpm | FR: 28 irpm | Tax: 38,7 C | SpO2: 91% ar ambiente
- Peso estimado: 62 kg

Exame dirigido na triagem:
- Paciente em desconforto moderado, falando em frases curtas.
- Uso leve de musculatura acessoria (esternocleidomastoideo).
- Sibilos expiratórios bilaterais audíveis sem estetoscopio.
- Taquipneia evidente.

Classificacao Manchester: LARANJA (urgente)
Discriminador utilizado: Dispneia moderada com SpO2 < 92% e febre.
Tempo alvo para atendimento medico: 10 minutos.

Encaminhada para sala de urgencia.

Enf. Marcos Silva - Triagem | COREN-SP 345678" | base64 -w0 2>/dev/null || echo -n "TRIAGEM - PRONTO-SOCORRO
Data: 19/03/2026 | Hora: 14:00

Falta de ar + febre 2 dias. Asma. SpO2 91%. FR 28. Febre 38,7C. Manchester LARANJA." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"34878-9\", \"display\": \"Emergency medicine Note\"}]},
    \"subject\": {\"reference\": \"Patient/ana-003\"},
    \"date\": \"2026-03-19T14:00:00Z\",
    \"author\": [{\"display\": \"Enf. Marcos Silva - Triagem\"}],
    \"description\": \"Triagem Manchester LARANJA - dispneia + febre, asma, SpO2 91%\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Triagem Manchester LARANJA - dispneia + febre, asma, SpO2 91%"

# --- Avaliacao medica 14h30 ---
NOTE=$(echo -n "EVOLUCAO MEDICA - PRONTO-SOCORRO
Data: 19/03/2026 | Hora: 14:30 | Avaliacao medica inicial

Paciente: Ana Costa, 35 anos, feminino. Triada como LARANJA pela enfermagem.

Queixa: Dispneia progressiva + febre ha 2 dias. Historico de asma bronquica.

Historia clinica complementar: Paciente relata que iniciou quadro ha 2 dias com tosse seca que evoluiu para produtiva (escarro amarelo-esverdeado), febre (aferida em casa 38,9 C), calafrios e dor toracica pleurítica em hemitorax direito. Dispneia progressiva, hoje com dificuldade para falar em frases completas. Refere nao ter usado corticoide inalatorio (Budesonida) regularmente ha 3 semanas por falta do medicamento. Usou salbutamol inalatorio em casa 3x hoje, com melhora parcial e transitoria.

Exame fisico:
- Estado geral: moderado, taquidispneica, falando em frases curtas, ansiosa.
- PA: 122/78 mmHg | FC: 108 bpm | FR: 28 irpm | Tax: 38,6 C | SpO2: 91% ar ambiente
- Ausculta pulmonar: sibilos expiratórios difusos bilaterais + estertores crepitantes em base direita (sugestivo de consolidacao).
- Ausculta cardiaca: ritmo regular em 2 tempos, sem sopros, taquicardia.
- Abdome: sem alteracoes.
- MMII: sem edemas.

Exames complementares solicitados e resultados:
- Peak flow: 180 L/min (valor previsto para idade/altura: ~420 L/min = 43% do previsto - crise grave)
- SpO2: 91% em ar ambiente
- Rx torax (digital, ja disponivel): hiperinsuflacao pulmonar bilateral + infiltrado alveolar em lobo inferior direito - compativel com pneumonia.
- Hemograma: leucocitos 15.200/uL (neutrofilia 82%) | Hb 13,2 g/dL | plaquetas 298.000/uL
- PCR: 89 mg/L (elevado)
- Gasometria arterial: pH 7,41 | pO2 62 mmHg | pCO2 36 mmHg | HCO3 23 | SatO2 91%

Hipoteses diagnosticas:
1. Crise de asma grave (peak flow 43% do previsto, uso de musculatura acessoria, SpO2 < 92%)
2. Pneumonia bacteriana adquirida na comunidade - lobo inferior direito (febre, escarro purulento, infiltrado radiologico)
3. Fator precipitante da crise: infeccao respiratoria + abandono de corticoide inalatorio

Conduta imediata:
- O2 suplementar por mascara de Venturi 40% (meta SpO2 > 94%).
- Nebulizacao com Salbutamol 5 mg + Ipratropio 0,5 mg em SF 0,9% - ja iniciada.
- Acesso venoso periferico calibroso instalado.
- Metilprednisolona 125 mg EV em bolus (corticoide sistemico para crise de asma grave).
- Amoxicilina + Clavulanato 1,2g EV (antibiotico para pneumonia adquirida na comunidade).
- Monitoracao continua: ECG, SpO2, PA.
- Reavaliar peak flow e SpO2 apos 30 minutos de broncodilatacao.
- Solicitar vaga em observacao do PS.

Criterios para internacao: SpO2 < 92% apos 2 nebulizacoes, peak flow < 50% previsto, necessidade de O2 continuo.

Dr. Carlos Souza - Emergencia | CRM-SP 67890" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO MEDICA - PRONTO-SOCORRO
Data: 19/03/2026 | Hora: 14:30

Asma grave + pneumonia. Peak flow 180 (43%). Nebulizacao + corticoide EV + antibiotico." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11506-3\", \"display\": \"Progress note\"}]},
    \"subject\": {\"reference\": \"Patient/ana-003\"},
    \"date\": \"2026-03-19T14:30:00Z\",
    \"author\": [{\"display\": \"Dr. Carlos Souza - Emergencia\"}],
    \"description\": \"Avaliacao medica PS - asma grave + pneumonia, peak flow 180\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Avaliacao medica PS - asma grave + pneumonia, peak flow 180"

# --- Evolucao enfermagem 15h ---
NOTE=$(echo -n "EVOLUCAO DE ENFERMAGEM - PRONTO-SOCORRO
Data: 19/03/2026 | Hora: 15:00 | Apos nebulizacao

Paciente: Ana Costa, 35 anos, feminino. Crise de asma grave + pneumonia.

Avaliacao de enfermagem apos nebulizacao:
- Nivel de consciencia: alerta, orientada, colaborativa.
- PA: 118/74 mmHg | FC: 98 bpm | FR: 24 irpm | Tax: 38,3 C
- SpO2: 94% (melhora de 91% pre-nebulizacao para 94% apos)
- O2 por mascara de Venturi 40% mantido.

Procedimentos realizados:
- Nebulizacao com Salbutamol 5 mg + Ipratropio 0,5 mg realizada em 15 minutos. Paciente tolerou bem. Refere melhora significativa da dispneia apos nebulizacao.
- Acesso venoso periferico instalado em veia antecubital esquerda (jelco 18G) - permeavelidade confirmada.
- Metilprednisolona 125 mg EV administrada (bolus em 5 minutos) as 14h35.
- Amoxicilina + Clavulanato 1,2g EV administrada (infusao em 30 minutos, iniciada as 14h40).
- Coleta de gasometria arterial realizada em arteria radial direita (sem intercorrencias).
- Coleta de hemograma e PCR realizada.

Avaliacao pos-nebulizacao:
- Sibilos: reduzidos (antes difusos, agora apenas em tercos medios bilaterais).
- Uso de musculatura acessoria: reduzido.
- Paciente consegue falar em frases mais longas.
- Tosse produtiva presente, escarro amarelado.

Orientacoes fornecidas:
- Paciente orientada a manter repouso, nao realizar esforcos.
- Orientada sobre importancia de uso regular dos inaladores (especialmente corticoide).
- Solicitado peak flow de controle em 15 minutos.

Proximo controle: PA, SpO2, FR em 30 minutos. Reavaliar necessidade de segunda nebulizacao.

Enf. Julia Andrade - COREN-SP 456789" | base64 -w0 2>/dev/null || echo -n "EVOLUCAO DE ENFERMAGEM - PRONTO-SOCORRO
Data: 19/03/2026 | Hora: 15:00

Nebulizacao realizada. SpO2 91 -> 94%. Medicacoes administradas. Acesso venoso." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"28651-8\", \"display\": \"Nurse notes\"}]},
    \"subject\": {\"reference\": \"Patient/ana-003\"},
    \"date\": \"2026-03-19T15:00:00Z\",
    \"author\": [{\"display\": \"Enf. Julia Andrade\"}],
    \"description\": \"Evolucao enfermagem - nebulizacao, SpO2 91->94%, medicacoes EV\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Evolucao enfermagem - nebulizacao, SpO2 91->94%, medicacoes EV"

# --- Reavaliacao medica 16h30 ---
NOTE=$(echo -n "REAVALIACAO MEDICA - PRONTO-SOCORRO
Data: 19/03/2026 | Hora: 16:30 | 2 horas apos tratamento inicial

Paciente: Ana Costa, 35 anos, feminino. Crise de asma grave + pneumonia - reavaliacao.

Evolucao apos 2 horas de tratamento:
Paciente apresenta melhora clinica progressiva e satisfatoria. Refere reducao significativa da dispneia - consegue falar em frases completas, sem interrupcoes. Ainda com tosse produtiva, escarro amarelado. Febre persistente, porem menor que na admissao.

Sinais vitais atuais:
- PA: 120/76 mmHg | FC: 88 bpm | FR: 20 irpm | Tax: 38,1 C | SpO2: 94% (O2 Venturi 35%)

Exame fisico reavaliacao:
- Estado geral: regular, melhora evidente em relacao a admissao. Nao mais taquidispneica em repouso.
- Ausculta pulmonar: sibilos reduzidos (apenas base direita), crepitacoes em base direita persistentes (pneumonia).
- Sem uso de musculatura acessoria em repouso.
- FC normalizada em relacao a admissao (108 → 88 bpm).

Peak flow pos-tratamento (16h30): 280 L/min (antes 180 L/min = melhora de 55%)
- Melhora de 43% para 67% do previsto (420 L/min) - ainda reduzido, porem com resposta adequada ao tratamento.

Avaliacao:
- Resposta ao tratamento: boa resposta broncodilatadora (peak flow 180 → 280 L/min).
- Criterios de alta imediata NAO atingidos: peak flow ainda < 75% do previsto, pneumonia necessita antibioticoterapia e acompanhamento.
- Criterios de internacao NAO presentes: SpO2 > 92% com O2 suplementar, melhora clinica objetiva.
- Decisao: observacao no PS por 4-6 horas adicionais. Se mantiver melhora, alta hospitalar com medicacoes orais e retorno em 48h.

Plano de alta (se mantiver melhora):
- Prednisolona 40 mg VO 1x/dia por 5 dias.
- Amoxicilina + Clavulanato 875 mg VO 12/12h por 7 dias.
- Retomar Formoterol + Budesonida inalatorio regularmente (2x/dia).
- Salbutamol inalatorio de resgate: 2 jatos se dispneia.
- Retorno ao PS se: piora da dispneia, SpO2 < 92%, febre > 39 C persistente.
- Consulta ambulatorial de pneumologia/alergologia em 7 dias para seguimento.
- Orientar sobre importancia da adesao ao corticoide inalatorio para prevencao de crises.

Dr. Carlos Souza - Emergencia | CRM-SP 67890" | base64 -w0 2>/dev/null || echo -n "REAVALIACAO MEDICA - PRONTO-SOCORRO
Data: 19/03/2026 | Hora: 16:30

Melhora apos 2h. FR 20. SpO2 94%. Peak flow 280 (67%). Observacao no PS." | base64)

curl -s -X POST "$FHIR_URL/DocumentReference" \
  -H "Content-Type: application/fhir+json" \
  -d "{
    \"resourceType\": \"DocumentReference\",
    \"status\": \"current\",
    \"type\": {\"coding\": [{\"system\": \"http://loinc.org\", \"code\": \"11506-3\", \"display\": \"Progress note\"}]},
    \"subject\": {\"reference\": \"Patient/ana-003\"},
    \"date\": \"2026-03-19T16:30:00Z\",
    \"author\": [{\"display\": \"Dr. Carlos Souza - Emergencia\"}],
    \"description\": \"Reavaliacao medica 2h - melhora, peak flow 280, observacao PS\",
    \"content\": [{\"attachment\": {\"contentType\": \"text/plain\", \"data\": \"$NOTE\"}}]
  }" > /dev/null && echo "DocumentReference: Reavaliacao medica 2h - melhora, peak flow 280, observacao PS"

# --- Sinais vitais seriais Ana (Observations) ---
echo "  -> Carregando sinais vitais seriais (Ana)..."

# Post-nebulizacao 15h
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T15:00:00Z",
    "subject": {"reference": "Patient/ana-003"},
    "performer": [{"display": "Enf. Julia Andrade"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 94, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 pos-nebulizacao 94%"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T15:00:00Z",
    "subject": {"reference": "Patient/ana-003"},
    "performer": [{"display": "Enf. Julia Andrade"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "9279-1", "display": "Respiratory rate"}]},
    "valueQuantity": {"value": 24, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FR pos-nebulizacao 24"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T15:00:00Z",
    "subject": {"reference": "Patient/ana-003"},
    "performer": [{"display": "Enf. Julia Andrade"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 98, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC pos-nebulizacao 98"

# Peak flow pos-broncodilatador 15h15
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T15:15:00Z",
    "subject": {"reference": "Patient/ana-003"},
    "performer": [{"display": "Enf. Julia Andrade"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "19935-6", "display": "Peak expiratory flow rate"}]},
    "valueQuantity": {"value": 280, "unit": "L/min", "system": "http://unitsofmeasure.org", "code": "L/min"}
  }' > /dev/null && echo "Observation: Peak flow pos-broncodilatador 280 L/min"

# Reavaliacao 16h30
curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T16:30:00Z",
    "subject": {"reference": "Patient/ana-003"},
    "performer": [{"display": "Dr. Carlos Souza - Emergencia"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "2708-6", "display": "Oxygen saturation"}]},
    "valueQuantity": {"value": 94, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"}
  }' > /dev/null && echo "Observation: SpO2 reavaliacao 94%"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T16:30:00Z",
    "subject": {"reference": "Patient/ana-003"},
    "performer": [{"display": "Dr. Carlos Souza - Emergencia"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "9279-1", "display": "Respiratory rate"}]},
    "valueQuantity": {"value": 20, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FR reavaliacao 20"

curl -s -X POST "$FHIR_URL/Observation" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
    "effectiveDateTime": "2026-03-19T16:30:00Z",
    "subject": {"reference": "Patient/ana-003"},
    "performer": [{"display": "Dr. Carlos Souza - Emergencia"}],
    "code": {"coding": [{"system": "http://loinc.org", "code": "8867-4", "display": "Heart rate"}]},
    "valueQuantity": {"value": 88, "unit": "/min", "system": "http://unitsofmeasure.org", "code": "/min"}
  }' > /dev/null && echo "Observation: FC reavaliacao 88"

echo ""
echo "=========================================="
echo "  EVOLUCOES CLINICAS CARREGADAS!"
echo "  - Maria Santos: 2 DocumentReferences"
echo "  - Joao Oliveira: 8 DocumentReferences + 23 Observations (sinais vitais seriais)"
echo "  - Ana Costa:    4 DocumentReferences + 7 Observations (sinais vitais PS)"
echo "=========================================="
