# Pre-reqs:

# sudo yum install -y swig python3-devel

# Executando local

python3 -m venv mlflow
source mlflow/bin/activate
pip install mlflow==2.22.0
# pip install "anyio<4.0.0" mlflow

export MLFLOW_SERVER_ALLOWED_ORIGINS="*"
export MLFLOW_SERVER_CORRECT_ORIGIN_HEADER="true"
mlflow server --host 0.0.0.0 --port 8089 & # versao 2
# mlflow server --host 0.0.0.0 --port 8089 --allowed-hosts "*" & # versao 3

sleep 1

# Executando com docker
# docker run -it --name mlflow -p 8089:5000 -d bitnami/mlflow:2.22.0

IP=$(curl -s checkip.amazonaws.com)

echo ""
echo ""
echo "Config OK"
echo ""
echo ""
echo "URLs do projeto:"
echo ""
echo " - MLFLOW UI                : http://$IP:8089"
echo ""
