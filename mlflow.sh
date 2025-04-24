# Pre-reqs:

sudo yum install -y swig python3-devel

# Executando local

python3 -m venv mlflow
source mlflow/bin/activate
pip install mlflow
mlflow server --host 0.0.0.0 --port 8089 &

# Executando com docker
# docker run -it --name mlflow -p 8089:5000 -d bitnami/mlflow:2.22.0
docker run -it -v ${PWD}/mlops/exemplo:/opt/nb -p 8889:8888 -d mfeurer/auto-sklearn:master /bin/bash -c "mkdir -p /opt/nb && jupyter notebook --notebook-dir=/opt/nb --ip='0.0.0.0' --port=8888 --no-browser --allow-root"

IP=$(curl -s checkip.amazonaws.com)

echo ""
echo ""
echo "Config OK"
echo ""
echo ""
echo "URLs do projeto:"
echo ""
echo " - MLFLOW UI                : http://$IP:8089"
