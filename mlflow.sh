# Pre-reqs:

# sudo yum install -y swig python3-devel

# Executando local

python3 -m venv mlflow
source mlflow/bin/activate
pip install mlflow
mlflow server --host 0.0.0.0 --port 8089 &

# Executando com docker
# docker run -it --name mlflow -p 8089:5000 -d bitnami/mlflow:2.22.0

echo ""
echo ""
echo "Config OK"
echo ""
echo ""
echo "URLs do projeto:"
echo ""
echo " - MLFLOW UI                : http://$IP:8089"
echo ""
