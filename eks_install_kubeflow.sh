#echo "Digite suas credenciais da AWS: (finalizar escrevendo FIM)"
#mkdir ~/.aws/

# configurar regiao aws
#cat >> ~/.aws/config << FIM
#[default]
#region=us-west-2
#output=json
#FIM

# inserir credenciais
#cat >> ~/.aws/credentials << FIM

#aws eks --region us-east-1 update-kubeconfig --name eksfiap

# Installation pre-reqs
# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
# aws-iam-authenticator
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
sudo cp aws-iam-authenticator /usr/local/bin/

curl -fsSL https://github.com/kubeflow/kfctl/releases/download/v1.1.0/kfctl_v1.1.0-0-g9a3621e_linux.tar.gz  -o kfctl.tar.gz
tar -zxvf kfctl.tar.gz && export PATH=$PWD:$PATH && export KF_NAME=Kubeflow && export BASE_DIR=. && export KF_DIR=${BASE_DIR}/${KF_NAME}
#export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.1-branch/kfdef/kfctl_k8s_istio.v1.1.0.yaml"
#export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.0-branch/kfdef/kfctl_k8s_istio.v1.0.2.yaml"
#mkdir -p ${KF_DIR} && cd ${KF_DIR}

# wget -O kfctl_aws.yaml $CONFIG_URI
export AWS_CLUSTER_NAME=eksfiap
# mkdir ${AWS_CLUSTER_NAME} && cd ${AWS_CLUSTER_NAME}
   
# kfctl apply -V -f ${CONFIG_URI}
kfctl apply -V -f eks_kfctl_aws.yaml

echo " $ kubectl get pod --all-namespaces"
kubectl get pod --all-namespaces
echo " > Acessar o UI do Kubeflow"
export INGRESS_HOST=$(curl -s checkip.amazonaws.com)
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
echo "Verificando se o PROFILE está RUNNING : $ kubectl get pod -n kubeflow | grep profile"
echo "Aguardando profiles-deployment (geralmente 4 min): "
while [ "$(kubectl get pod -n kubeflow | grep profile | grep Running | wc -l)" != "1" ]; do
  printf "."
  sleep 1
done
sh ~/kubeflow/update_domain.sh # atualiza o dominio do Knative
echo "Pronto."
echo " $ kubectl get pod -n kubeflow | grep profile"
kubectl get pod -n kubeflow | grep profile
echo "Acessar: http://$INGRESS_HOST:$INGRESS_PORT"
echo "Verificar os pods existentes : $ kubectl get pod --all-namespaces"
