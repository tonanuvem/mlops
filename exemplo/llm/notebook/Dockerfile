# Jupyter para o BONUS LLM: Python 3.12 + MLflow 3 + cliente OpenAI (aponta para o Ollama)
# O container automl (auto-sklearn) fica preso no Python 3.8 e nao suporta essas bibliotecas.
FROM quay.io/jupyter/minimal-notebook:python-3.12
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
