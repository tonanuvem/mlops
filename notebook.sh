#!/bin/bash

echo "Executando Jupyter Notebook para análise e ML dos dados"
echo ""
echo ""

# dir=`pwd`; dir="$(dirname "$dir")"; echo $dir;
# dir="$(pwd)"; echo $dir;
#  -v "$dir"/mlops/exemplo:/home/jovyan/work -d jupyter/scipy-notebook \

docker run -it --name automl -v ${PWD}/mlops/exemplo/mlflow:/opt/nb -p 8789:8888 -d mfeurer/auto-sklearn:master /bin/bash -c "mkdir -p /opt/nb && jupyter notebook --notebook-dir=/opt/nb --ip='0.0.0.0' --port=8888 --no-browser --allow-root"

IP=$(curl -s checkip.amazonaws.com)
echo "Aguardando TOKEN (geralmente 1 min)"
while [ "$(docker logs automl | grep token | grep 127. | grep NotebookApp | wc -l)" != "1" ]; do
  printf "."
  sleep 1
done
echo "Token Pronto."
TOKEN=$(docker logs automl | grep token | grep 127. | grep NotebookApp | sed -n 's/.*?token=\([a-f0-9]*\).*/\1/p')

echo ""
echo ""
echo "Config OK"
echo ""
echo ""
echo "URLs do projeto:"
echo ""
echo " - JUPYTER AUTO ML          : http://$IP:8789/?token=$TOKEN"
echo ""
echo ""
