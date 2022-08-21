# DIFFs: retirado local-path-storage.yaml, pois usa portworx & testar depois a versao kfctl_k8s_istio.v1.1.0.yaml
#
# sudo minikube start --vm-driver=none --kubernetes-version=v1.17.11
# kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
curl -fsSL https://github.com/kubeflow/kfctl/releases/download/v1.1.0/kfctl_v1.1.0-0-g9a3621e_linux.tar.gz  -o kfctl.tar.gz
tar -zxvf kfctl.tar.gz && export PATH=$PWD:$PATH && export KF_NAME=Kubeflow && export BASE_DIR=. && export KF_DIR=${BASE_DIR}/${KF_NAME}
#export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.1-branch/kfdef/kfctl_k8s_istio.v1.1.0.yaml"
export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.0-branch/kfdef/kfctl_k8s_istio.v1.0.2.yaml"
mkdir -p ${KF_DIR} && cd ${KF_DIR}
kfctl apply -V -f ${CONFIG_URI}
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
