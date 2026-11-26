"""
Microsservico de MENTORIA (BONUS LLM)

Fluxo de cada requisicao POST /mentoria:
  1. mascarar_pii   -> remove NOME e MATRICULA ANTES de qualquer log/trace
  2. classificar    -> chama o classificador da Etapa 2 (http://classificador:5000/predict)
  3. gerar_texto    -> envia features + perfil ao LLM (Ollama, API compativel com OpenAI)

Tudo e registrado no MLflow (aba Traces do experimento "LLM Mentoria").
O prompt vem do MLflow Prompt Registry (PROMPT_URI, ex.: prompts:/mentoria@producao).
"""
import os
import time

import mlflow
import requests
from flask import Flask, jsonify, request
from openai import OpenAI

MLFLOW_URI = os.getenv("MLFLOW_TRACKING_URI", "http://mlflow:5000")
CLASSIFICADOR_URL = os.getenv("CLASSIFICADOR_URL", "http://classificador:5000")
LLM_MODELO = os.getenv("LLM_MODELO", "qwen3:1.7b")
PROMPT_URI = os.getenv("PROMPT_URI", "prompts:/mentoria@producao")
EXPERIMENTO = os.getenv("EXPERIMENTO", "LLM Mentoria")
MAX_TOKENS = int(os.getenv("MAX_TOKENS", "250"))

# Mesma ordem de features usada no treinamento (notebook 1) e no predict.py
FEATURES = [
    "REPROVACOES_MAT_1", "REPROVACOES_MAT_2", "REPROVACOES_MAT_3", "REPROVACOES_MAT_4",
    "NOTA_MAT_1", "NOTA_MAT_2", "NOTA_MAT_3", "NOTA_MAT_4",
    "INGLES", "H_AULA_PRES", "TAREFAS_ONLINE", "FALTAS",
]
CAMPOS_PII = ["NOME", "MATRICULA"]

# Prompt usado enquanto o aluno ainda nao registrou o seu no Prompt Registry
PROMPT_PADRAO = [
    {"role": "system", "content": (
        "Você é um coordenador pedagógico. Escreva em português do Brasil uma recomendação "
        "de mentoria curta para o aluno, citando o perfil previsto e sugerindo 2 ações concretas.")},
    {"role": "user", "content": "Perfil previsto: {{perfil}}\nDados do aluno: {{dados}}"},
]

mlflow.set_tracking_uri(MLFLOW_URI)
mlflow.set_experiment(EXPERIMENTO)
mlflow.openai.autolog()          # cada chamada ao LLM vira um span com prompt, resposta e tokens
llm = OpenAI()                    # usa OPENAI_BASE_URL / OPENAI_API_KEY do ambiente

_cache = {"prompt": None, "lido_em": 0.0}


def carregar_prompt():
    """Le o prompt do Registry a cada 20 s: promover outra versao (alias) nao exige restart."""
    if _cache["prompt"] is not None and time.time() - _cache["lido_em"] < 20:
        return _cache["prompt"]
    try:
        p = mlflow.genai.load_prompt(PROMPT_URI)
        prompt = {"template": p.template, "versao": f"{p.name} v{p.version}"}
    except Exception:
        prompt = {"template": PROMPT_PADRAO, "versao": "padrao (sem registro)"}
    _cache.update(prompt=prompt, lido_em=time.time())
    return prompt


def mascarar_pii(aluno):
    """Remove dados pessoais. Roda FORA do trace: se rodasse dentro, o NOME iria para o MLflow."""
    removidos = [c for c in CAMPOS_PII if c in aluno]
    limpo = {k: v for k, v in aluno.items() if k not in CAMPOS_PII}
    return limpo, removidos


@mlflow.trace(name="classificar", span_type="TOOL")
def classificar(aluno):
    valores = [aluno[f] for f in FEATURES]
    r = requests.post(f"{CLASSIFICADOR_URL}/predict",
                      json={"fields": FEATURES, "values": valores}, timeout=10)
    r.raise_for_status()
    return r.json()["_PERFIL_CALCULADO"]


def formatar(template, **variaveis):
    """Substitui {{variavel}} em cada mensagem do template (formato do MLflow Prompt Registry)."""
    def sub(texto):
        for k, v in variaveis.items():
            texto = texto.replace("{{" + k + "}}", str(v)).replace("{{ " + k + " }}", str(v))
        return texto
    if isinstance(template, str):
        return [{"role": "user", "content": sub(template)}]
    return [{"role": m["role"], "content": sub(m["content"])} for m in template]


@mlflow.trace(name="mentoria", span_type="CHAIN")
def pipeline(aluno, modelo, temperatura, raciocinio, janela, pii_removido):
    perfil = classificar(aluno)
    prompt = carregar_prompt()
    dados = ", ".join(f"{k}={aluno[k]}" for k in FEATURES)
    mensagens = formatar(prompt["template"], perfil=perfil, dados=dados)

    extra = {} if raciocinio else {"reasoning_effort": "none"}   # modelos qwen3 "pensam" por padrao
    inicio = time.time()
    resp = llm.chat.completions.create(model=modelo, messages=mensagens, temperature=temperatura,
                                       max_tokens=MAX_TOKENS, extra_body=extra)
    latencia = time.time() - inicio
    texto = (resp.choices[0].message.content or "").strip()

    # tags permitem filtrar e comparar janelas de tempo, modelos e versoes de prompt (drift)
    mlflow.update_current_trace(tags={
        "perfil": perfil, "modelo": modelo, "prompt_versao": prompt["versao"],
        "janela": janela, "raciocinio": str(raciocinio), "pii_removido": ",".join(pii_removido) or "-",
    })
    uso = resp.usage
    return {
        "perfil": perfil,
        "recomendacao": texto,
        "modelo": modelo,
        "prompt_versao": prompt["versao"],
        "tokens_entrada": uso.prompt_tokens if uso else None,
        "tokens_saida": uso.completion_tokens if uso else None,
        "latencia_llm_s": round(latencia, 2),
        "trace_id": mlflow.get_active_trace_id(),
    }


app = Flask(__name__)


@app.post("/mentoria")
def mentoria():
    corpo = request.get_json(force=True)
    aluno = corpo.get("aluno", corpo)
    faltando = [f for f in FEATURES if f not in aluno]
    if faltando:
        return jsonify({"erro": f"campos faltando: {faltando}"}), 400

    aluno_limpo, removidos = mascarar_pii(aluno)
    saida = pipeline(
        aluno_limpo,
        modelo=corpo.get("modelo", LLM_MODELO),
        temperatura=float(corpo.get("temperatura", 0.3)),
        raciocinio=bool(corpo.get("raciocinio", False)),
        janela=corpo.get("janela", "manual"),
        pii_removido=removidos,
    )
    saida["pii_removido"] = removidos
    return jsonify(saida)


EXEMPLO = {"NOME": "Fulano de Tal", "MATRICULA": 513949,
           "REPROVACOES_MAT_1": 1, "REPROVACOES_MAT_2": 1, "REPROVACOES_MAT_3": 1, "REPROVACOES_MAT_4": 1,
           "NOTA_MAT_1": 4.3, "NOTA_MAT_2": 4.0, "NOTA_MAT_3": 3.1, "NOTA_MAT_4": 4.9,
           "INGLES": 0, "H_AULA_PRES": 3, "TAREFAS_ONLINE": 4, "FALTAS": 3}


@app.get("/")
def home():
    return jsonify({
        "servico": "mentoria (classificador + LLM)",
        "uso": "POST /mentoria com o JSON do aluno",
        "modelo_padrao": LLM_MODELO,
        "prompt": carregar_prompt()["versao"],
        "exemplo": EXEMPLO,
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
