# https://github.com/kubeflow/kfserving/tree/master/python/sklearnserver
# rodar direto : 
#  python -m sklearnserver --model_dir . --model_name svm
# rodar no docker :
#  docker build -t fiapimgskl -f sklearn.Dockerfile .
#  docker run --name fiapskl --rm -p 8081:8080 fiapsklearnserver -d

FROM python:3.7-slim

COPY sklearnserver sklearnserver
COPY kfserving kfserving

RUN pip install --upgrade pip && pip install -e ./kfserving
RUN pip install -e ./sklearnserver
COPY third_party third_party
COPY sklearnserver/model.joblib /tmp/models/model.joblib
ENTRYPOINT ["python", "-m", "sklearnserver",  "--model_dir", "/tmp/models/model.joblib", "--model_name", "modelo"]
