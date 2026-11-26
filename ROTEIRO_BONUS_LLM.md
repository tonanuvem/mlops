# BÔNUS: LLM & LLMOPS (OBSERVABILIDADE, QUALIDADE E DRIFT)

> Texto para a seção BÔNUS do roteiro (docx), depois do **BONUS: AUTOML & MLFLOW**.
> Pré-requisitos: notebook `1_treinamento.ipynb` executado (gera o `model.joblib`), Etapa 2 (imagem do classificador)
> e bônus AutoML & MLflow (experimentos no MLflow). Tempo total estimado: **60 a 70 min**.

## Responder antes de começar

- Um modelo de Machine Learning prevê o **perfil** do aluno. Como transformar essa previsão em algo útil para o coordenador?
- Para o modelo de classificação, o MLflow mostrou a **acurácia**. Que métrica usar quando a saída é um **texto**?

---

## PARTE 1: LLM INTEGRADO AO PIPELINE (≈ 25 min)

### 1. Subir o ambiente do bônus

```bash
cd ~ && bash mlops/llm.sh
```

O script:
- para o Jupyter AutoML (`automl`) para liberar CPU e memória;
- faz backup dos experimentos do MLflow e migra os dados para o **MLflow 3**;
- sobe o **docker-compose** com 5 serviços e baixa os modelos de LLM.

… demora em torno de **3 a 5 min** na primeira vez …

Ao final, o script mostra as URLs:

| Serviço | Porta |
|---|---|
| Jupyter LLM (notebooks 3 e 4), senha `admin` | 8790 |
| MLflow 3 | 8089 |
| Classificador (Etapa 2) | 32000 |
| Mentoria (classificador + LLM) | 32001 |

### 2. Analisar o docker-compose

```bash
cat mlops/exemplo/llm/docker-compose.yml
docker compose -f mlops/exemplo/llm/docker-compose.yml ps
```

Responder:
- Quantos serviços existem? Qual deles **não** fica rodando? Por quê?
- Quais serviços dependem de quais (`depends_on`)?
- O classificador é o mesmo da Etapa 2? Como o serviço `mentoria` o encontra na rede?
- Por que o serviço `ollama` tem um limite de memória?

### 3. Verificar o MLflow 3

Acessar a porta **8089** e confirmar que o **Experimento MODELO CURSO** (bônus anterior) continua lá, com os mesmos modelos.

### 4. Executar o notebook `3_llm_pipeline.ipynb`

Abrir o Jupyter LLM (porta **8790**) e o arquivo `3_llm_pipeline.ipynb`. Analisar o exemplo:
- qual o objetivo pretendido?
- qual o papel do **modelo de ML clássico** e qual o papel do **LLM**?
- quais dados são **pessoais** e onde eles são removidos?

Executar as células (… em torno de **3 min** …) e responder:
- Quanto tempo o LLM leva para responder em CPU? Quantos tokens por segundo?
- O texto da primeira versão do prompt respeitou o pedido? Ele **inventou** algum dado?

### 5. Verificar o prompt no MLflow

No MLflow, aba **Prompts** → `mentoria`: ver a versão 1, o template e o alias `producao`.

### 6. Testar o microsserviço de mentoria pelo terminal

```bash
curl -s http://localhost:32001/ | python3 -m json.tool
curl -s -X POST http://localhost:32001/mentoria -H "Content-Type: application/json" \
  -d '{"aluno": {"NOME": "Fulano", "MATRICULA": 1, "REPROVACOES_MAT_1": 1, "REPROVACOES_MAT_2": 1,
       "REPROVACOES_MAT_3": 1, "REPROVACOES_MAT_4": 1, "NOTA_MAT_1": 4.3, "NOTA_MAT_2": 4.0, "NOTA_MAT_3": 3.1,
       "NOTA_MAT_4": 4.9, "INGLES": 0, "H_AULA_PRES": 3, "TAREFAS_ONLINE": 4, "FALTAS": 3}}' | python3 -m json.tool
```

Responder:
- Por que não deixar o LLM classificar o aluno sozinho?
- Qual a vantagem de o serviço carregar o prompt do MLflow em vez de tê-lo fixo no código?

---

## PARTE 2: LLMOPS: OBSERVABILIDADE, QUALIDADE E DRIFT (≈ 35 min)

### 7. Executar o notebook `4_llmops_observabilidade.ipynb`

Abrir o arquivo e executar **uma parte por vez**, acompanhando o MLflow em outra aba.

#### Parte A: Tracing (≈ 5 min)

Após as primeiras células, abrir no MLflow: **Experiments → LLM Mentoria → Traces**.

Responder:
- Quais spans aparecem em cada trace? Qual etapa consome mais tempo?
- O nome do aluno aparece em algum lugar do trace? Por quê?
- Qual seria o custo de gerar recomendações para 20 mil alunos com um provedor pago?
- Com o "raciocínio" do modelo ligado, para onde vão os tokens? O que acontece com o tempo de resposta?

#### Parte B: Qualidade das respostas (≈ 8 min)

O notebook avalia o prompt **v1** com 4 avaliadores (*scorers*), cria o prompt **v2** e compara os dois.

Verificar no MLflow: **Avaliacao Prompt Mentoria → runs `prompt v1` e `prompt v2` → aba Evaluations**.

Responder:
- Em quais critérios o v2 melhorou? Piorou em algum?
- Que outro avaliador você criaria?
- Depois de promover o v2 (alias `producao`), o serviço precisou ser reiniciado?

#### Parte C: Drift detection (≈ 15 min)

O notebook gera 3 janelas de tráfego:

| Janela | O que muda |
|---|---|
| `baseline` | nada (referência) |
| `drift_entrada` | só alunos com reprovação e muitas faltas (a **população** mudou) |
| `drift_saida` | outro modelo de LLM, menor (o **sistema** mudou) |

Verificar no MLflow: **Monitoramento LLM → selecionar os 2 runs → Compare**.

Responder:
- Na janela `drift_entrada`, o LLM piorou ou foi a população que mudou? Qual métrica mostra isso?
- Na janela `drift_saida` ninguém mexeu nos dados. O que denunciou a troca de modelo?
- Quais alertas você mandaria para o time de plantão? Quais iriam só para um relatório?

---

## Informação adicional

- O mesmo código funciona com provedores pagos (OpenAI, Bedrock via gateway etc.): só muda a URL (`OPENAI_BASE_URL`).
- O MLflow 3 junta, no mesmo lugar, os **modelos de ML**, os **prompts**, os **traces** e as **avaliações** do LLM.

Mais informações:
- https://mlflow.org/docs/latest/genai/
- https://github.com/ollama/ollama

## Remover o ambiente do lab

```bash
bash mlops/remove.sh
```

Remove containers, imagens, volumes (inclusive os modelos do Ollama), o MLflow e os arquivos gerados pelo lab.
