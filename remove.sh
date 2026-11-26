#!/bin/bash
# Remove TUDO o que o LAB de MLOps pode ter criado nesta VM:
# containers, imagens, volumes (inclusive os modelos do Ollama), processos e arquivos gerados.
#
# Uso:  bash mlops/remove.sh        (pede confirmacao)
#       bash mlops/remove.sh -y     (sem confirmacao)
#
# Nao mexe em nada que nao seja do lab (outros containers, apache, node, etc.).

DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE="docker compose -f $DIR/exemplo/llm/docker-compose.yml -p mlops-llm"

CONTAINERS="automl classificador jupyter mlflow"
IMAGENS="ml-perfil-aluno-custom-model mfeurer/auto-sklearn:master jupyter/scipy-notebook bitnami/mlflow:2.22.0
ollama/ollama:0.40.18 ghcr.io/mlflow/mlflow:v3.18.0 mlops-llm-mentoria mlops-llm-llm-notebook mlops-llm-carga
quay.io/jupyter/minimal-notebook:python-3.12 python:3.12-slim python:3.8-slim"
ARQUIVOS="mlflow mlruns mlartifacts mlflow.db backup-mlflow-*.tar.gz exemplo/mlflow/curso_ml.csv
exemplo/mlflow/model.joblib exemplo/deploy/model.joblib exemplo/mlflow/.ipynb_checkpoints exemplo/mlflow/mlruns"

echo "Este script vai remover do LAB de MLOps:"
echo "  - docker-compose do bonus LLM (containers, rede e VOLUMES, inclusive os modelos do Ollama)"
echo "  - containers: $CONTAINERS"
echo "  - imagens do lab (auto-sklearn, classificador, MLflow, Ollama, Jupyter...)"
echo "  - o processo 'mlflow server' do host"
echo "  - arquivos gerados em $DIR: venv do MLflow, experimentos (mlruns, mlartifacts, mlflow.db),"
echo "    backups, curso_ml.csv, model.joblib e checkpoints"
echo "  - as saidas dos notebooks (voltam ao estado original do git)"
echo "  - cache de build do docker"
echo ""
echo "ATENCAO: nao da para desfazer. Os experimentos e modelos treinados serao apagados."
if [ "$1" != "-y" ]; then
  read -r -p "Confirma? [s/N] " RESP </dev/tty || RESP=n
  case "$RESP" in s|S) ;; *) echo "Cancelado."; exit 0 ;; esac
fi

ANTES=$(df --output=used -B1 / | tail -1)
echo ""
echo "==> docker compose down (containers, rede, volumes, imagens construidas)"
[ -f "$DIR/exemplo/llm/docker-compose.yml" ] && $COMPOSE --profile carga down -v --remove-orphans --rmi local 2>&1 | tail -3 || true

echo "==> containers criados manualmente"
for c in $CONTAINERS; do docker rm -f "$c" >/dev/null 2>&1 && echo "  removido: $c"; done

echo "==> volumes que sobraram do compose"
for v in $(docker volume ls -q --filter label=com.docker.compose.project=mlops-llm); do
  docker volume rm "$v" >/dev/null 2>&1 && echo "  removido: $v"
done

echo "==> imagens"
for i in $IMAGENS; do docker rmi "$i" >/dev/null 2>&1 && echo "  removida: $i"; done

echo "==> processo do MLflow no host"
pkill -f "mlflow server|mlflow.server:app" 2>/dev/null && echo "  mlflow server encerrado" || echo "  nenhum"

echo "==> arquivos gerados"
cd "$DIR" || exit 1
for a in $ARQUIVOS; do
  for f in $a; do [ -e "$f" ] && sudo rm -rf "$f" && echo "  removido: $f"; done
done
git -C "$DIR" checkout -- exemplo/mlflow/*.ipynb 2>/dev/null && echo "  notebooks restaurados"

echo "==> cache de build do docker"
docker builder prune -f 2>/dev/null | tail -1

DEPOIS=$(df --output=used -B1 / | tail -1)
echo ""
echo "Espaco liberado: $(( (ANTES - DEPOIS) / 1024 / 1024 )) MB"
echo "Para apagar tambem o repositorio: rm -rf $DIR"
