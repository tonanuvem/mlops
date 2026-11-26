#!/bin/bash
# BONUS LLM: sobe o pipeline com LLM (Ollama) + LLMOps no MLflow 3.
#
# Uso:  cd ~ && bash mlops/llm.sh
#
# O que este script faz:
#   1. para o container automl (libera CPU e RAM para o LLM)
#   2. prepara o classificador da Etapa 2 para rodar dentro do docker-compose
#   3. faz backup do MLflow das etapas anteriores e migra os dados para o MLflow 3
#   4. sobe o docker-compose (classificador, mlflow, ollama, llm-notebook, mentoria)
#   5. imprime as URLs

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE="docker compose -f $DIR/exemplo/llm/docker-compose.yml"

passo() { echo ""; echo "==> $*"; }

# 1. automl --------------------------------------------------------------------
passo "1/5 Parando o Jupyter AutoML (automl)"
if docker ps --format '{{.Names}}' | grep -qx automl; then
  CPU=$(docker stats --no-stream --format '{{.CPUPerc}}' automl | tr -d '%' | cut -d. -f1)
  if [ "${CPU:-0}" -gt 50 ]; then
    echo "ATENCAO: o automl esta usando ${CPU}% de CPU: parece que um treinamento AutoML ainda esta rodando."
    read -r -p "Parar mesmo assim? [s/N] " RESP </dev/tty || RESP=n
    case "$RESP" in s|S) ;; *) echo "Cancelado. Aguarde o treinamento terminar e rode o script de novo."; exit 1 ;; esac
  fi
  docker stop automl >/dev/null
  echo "automl parado (para voltar a usar: docker start automl)"
else
  echo "automl nao esta rodando."
fi

# 2. classificador --------------------------------------------------------------
passo "2/5 Preparando o classificador (Etapa 2)"
if ! docker image inspect ml-perfil-aluno-custom-model >/dev/null 2>&1; then
  if [ ! -f "$DIR/exemplo/mlflow/model.joblib" ]; then
    echo "ERRO: model.joblib nao encontrado. Execute antes o notebook 1_treinamento.ipynb."; exit 1
  fi
  cp "$DIR/exemplo/mlflow/model.joblib" "$DIR/exemplo/deploy/"
  echo "Imagem da Etapa 2 nao encontrada: o compose vai construi-la com o seu model.joblib."
fi
for c in classificador mlflow; do
  if docker ps -a --format '{{.Names}}' | grep -qx "$c"; then
    docker rm -f "$c" >/dev/null && echo "container '$c' criado manualmente foi removido (o compose recria)"
  fi
done

# 3. MLflow ---------------------------------------------------------------------
passo "3/5 Migrando o MLflow para a versao 3 (com os experimentos das etapas anteriores)"
if pgrep -f "mlflow server" >/dev/null; then
  pkill -f "mlflow server" || true
  for i in $(seq 1 15); do pgrep -f "mlflow server" >/dev/null || break; sleep 1; done
  echo "MLflow 2 (processo no host) encerrado."
fi
if [ -d "$DIR/mlruns" ] && [ ! -f "$DIR/mlflow.db" ]; then
  BKP="$DIR/backup-mlflow-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$BKP" -C "$DIR" mlruns $( [ -d "$DIR/mlartifacts" ] && echo mlartifacts )
  echo "Backup: $BKP"
  $COMPOSE run --rm --no-deps mlflow \
    mlflow migrate-filestore --source /mlops/mlruns --target sqlite:////mlops/mlflow.db 2>&1 | grep -E "experiments|runs |registered_models|model_versions" || true
  echo "Dados migrados para $DIR/mlflow.db (a pasta mlruns/ foi mantida)."
elif [ -f "$DIR/mlflow.db" ]; then
  echo "mlflow.db ja existe: migracao ja feita."
else
  echo "Nenhum experimento anterior (mlruns/) encontrado: o MLflow 3 comeca vazio."
fi
mkdir -p "$DIR/mlartifacts"
# os notebooks do container automl rodavam como root; o novo Jupyter roda como usuario 1000
sudo chown -R 1000:1000 "$DIR/exemplo/mlflow" 2>/dev/null || true

# 4. compose --------------------------------------------------------------------
passo "4/5 Subindo o docker-compose (primeira vez: 3 a 5 min para baixar imagens e modelos)"
$COMPOSE up -d

# 5. URLs -----------------------------------------------------------------------
passo "5/5 Pronto"
$COMPOSE ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
IP=$(curl -s checkip.amazonaws.com)
echo ""
echo "URLs do BONUS LLM:"
echo ""
echo " - JUPYTER LLM (notebooks 3 e 4) : http://$IP:8790     (senha: admin)"
echo " - MLFLOW 3                      : http://$IP:8089"
echo " - CLASSIFICADOR (Etapa 2)       : http://$IP:32000"
echo " - MENTORIA (classificador + LLM): http://$IP:32001"
echo ""
free -h | awk 'NR==1 || /Mem/'
echo ""
echo "Para remover tudo o que o lab criou: bash mlops/remove.sh"
