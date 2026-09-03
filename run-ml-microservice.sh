cd mlops/exemplo/deploy && cp ../mlflow/model.joblib . 

# ls -lh

# cat predict.py

# cat Dockerfile

docker build -t ml-perfil-aluno-custom-model .

docker run --name classificador -p 32000:5000 -d ml-perfil-aluno-custom-model

cd ~ 

echo ""
echo "URL de acesso do Microservice com Machine Learning:"
echo ""
echo http://$(curl -s checkip.amazonaws.com):32000
echo ""
echo "   Senha: admin"
echo ""
