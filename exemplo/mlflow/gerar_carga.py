"""
Gerador de carga para o servico de MENTORIA (BONUS LLM - etapa B2).

Envia alunos do dataset para POST /mentoria, marcando cada requisicao com uma "janela"
(tag no trace do MLflow). Depois o notebook 4 compara as janelas para detectar drift.

Modos:
  normal        -> amostra aleatoria do dataset (mesma distribuicao do treino)  janela=baseline
  drift-entrada -> so alunos com notas baixas e muitas faltas (populacao mudou)  janela=drift_entrada
  drift-saida   -> alunos normais, mas outro modelo de LLM (o sistema mudou)     janela=drift_saida

Uso:
  python gerar_carga.py normal 10
  docker compose -f ~/mlops/exemplo/llm/docker-compose.yml --profile carga run --rm carga drift-entrada 10
"""
import os
import sys
import time

import pandas as pd
import requests

MENTORIA_URL = os.getenv("MENTORIA_URL", "http://mentoria:5000")
MODELO_ALTERNATIVO = os.getenv("LLM_MODELO_ALTERNATIVO", "qwen2.5:0.5b")
FEATURES = [
    "REPROVACOES_MAT_1", "REPROVACOES_MAT_2", "REPROVACOES_MAT_3", "REPROVACOES_MAT_4",
    "NOTA_MAT_1", "NOTA_MAT_2", "NOTA_MAT_3", "NOTA_MAT_4",
    "INGLES", "H_AULA_PRES", "TAREFAS_ONLINE", "FALTAS",
]


def carregar_alunos():
    """curso_ml.csv (dados tratados no notebook 1) + NOME do curso.csv, para testar o mascaramento de PII."""
    tratado = pd.read_csv("curso_ml.csv", encoding="utf-8-sig")
    nomes = pd.read_csv("curso.csv", usecols=["MATRICULA", "NOME"])
    return tratado.merge(nomes, on="MATRICULA", how="left")


def selecionar(df, modo, n, semente):
    if modo == "drift-entrada":
        df = df[(df["REPROVACOES_MAT_1"] > 0) & (df["FALTAS"] >= 6)]
    return df.sample(n=min(n, len(df)), random_state=semente)


def main():
    modo = sys.argv[1] if len(sys.argv) > 1 else "normal"
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 10
    if modo not in ("normal", "drift-entrada", "drift-saida"):
        sys.exit(f"modo invalido: {modo}")
    janela = {"normal": "baseline", "drift-entrada": "drift_entrada", "drift-saida": "drift_saida"}[modo]

    alunos = selecionar(carregar_alunos(), modo, n, semente=int(time.time()) % 1000)
    print(f"Enviando {len(alunos)} alunos para {MENTORIA_URL}/mentoria (janela={janela})")
    for i, (_, linha) in enumerate(alunos.iterrows(), 1):
        aluno = {f: float(linha[f]) for f in FEATURES}
        aluno["NOME"], aluno["MATRICULA"] = str(linha["NOME"]), int(linha["MATRICULA"])
        corpo = {"aluno": aluno, "janela": janela}
        if modo == "drift-saida":
            corpo.update(modelo=MODELO_ALTERNATIVO, temperatura=1.0)
        t = time.time()
        try:
            r = requests.post(f"{MENTORIA_URL}/mentoria", json=corpo, timeout=300).json()
            print(f"[{i}/{len(alunos)}] {r['perfil']:<12} {time.time() - t:5.1f}s  {r['tokens_saida']} tokens  ({r['modelo']})")
        except Exception as erro:
            print(f"[{i}/{len(alunos)}] ERRO: {erro}")
    print("Fim. Veja os traces no MLflow: experimento 'LLM Mentoria'.")


if __name__ == "__main__":
    main()
