# sudo minikube start --vm-driver=none --kubernetes-version=v1.17.11

git clone https://github.com/kubeflow/kfserving.git

# instalar no kubeflow

cd kfserving
TAG=v0.4.0
kubectl apply -f ./install/$TAG/kfserving.yaml
cd ..

# caso nao tenha instalado o kubeflow (instala do zero)

#cd kfserving && ./hack/quick_install.sh
#export INGRESS_HOST=$(curl -s checkip.amazonaws.com)
#export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
