python3 -m venv mlflow

source mlflow/bin/activate

pip install mlflow

mlflow server --host 0.0.0.0 --port 8089 &
IP=$(curl -s checkip.amazonaws.com)

echo ""
echo ""
echo "Config OK"
echo ""
echo ""
echo "URLs do projeto:"
echo ""
echo " - MLFLOW UI                : http://$IP:8089"
