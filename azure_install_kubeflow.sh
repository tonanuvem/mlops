# https://azure.github.io/kubeflow-aks/main/docs/deployment-options/vanilla-installation/
# grep -Rnw '/path/to/somewhere/' -e 'string procurada'
# grep -Rnw . -e 'kvAppName'

#echo "Clonando o repo: kubeflow-aks"
git clone --recurse-submodules https://github.com/Azure/kubeflow-aks.git
cd kubeflow-aks

# Cluster já criado durante o LAB -- Pular essa etapa...
#SIGNEDINUSER=$(az ad signed-in-user show --query id --out tsv)
#RGNAME=kubeflow
#az group create -n $RGNAME -l eastus
# Building a complete Kubernetes operational environment is hard work! AKS Construction dramatically accelerates this work
# https://learn.microsoft.com/pt-br/azure/azure-resource-manager/bicep/overview?tabs=bicep
#echo "Criando o Cluster AKS para executar o Kubeflow"
#DEP=$(az deployment group create -g $RGNAME --parameters signedinuser=$SIGNEDINUSER kubernetesVersion="1.28.0" -f main.bicep -o json)
#echo $DEP > kubeflow_DEP.json
# para recuperar o valor do json (comando abaixo):
# export DEP=$(cat kubeflow_DEP.json)
#KVNAME=$(echo $DEP | jq -r '.properties.outputs.kvAppName.value')
#AKSCLUSTER="fiapaks"
#AKSCLUSTER=$(echo $DEP | jq -r '.properties.outputs.aksClusterName.value')
#TENANTID=$(az account show --query tenantId -o tsv)
#ACRNAME=$(az acr list -g $RGNAME --query "[0].name"  -o tsv)
# Install kubelogin and log into the cluster 
#az aks get-credentials --resource-group $RGNAME --name $AKSCLUSTER
#kubelogin convert-kubeconfig -l azurecli

# Deploy Kubeflow without TLS using Default Password

cd manifests/
git checkout v1.7-branch
cd ..
cp -a deployments/vanilla manifests/vanilla
cd manifests/
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

while ! ./kustomize build vanilla | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
#./kustomize build vanilla > kubeflow_vanilla.yaml
#kubectl apply -f kubeflow_vanilla.yaml

echo "Verificando os pods em execução dos namespaces."

kubectl get pods -n cert-manager
kubectl get pods -n istio-system
kubectl get pods -n auth
kubectl get pods -n knative-eventing
kubectl get pods -n knative-serving
kubectl get pods -n kubeflow
kubectl get pods -n kubeflow-user-example-com

echo "Verificando os Gateways criados (Ingress)."

kubectl get gateway -n kubeflow

echo "Verificando os Virtual Services criados."

kubectl get destinationrule -n kubeflow

echo "Verificando os Virtual Services criados."

kubectl get destinationrule -n kubeflow

echo " > Acessar o UI do Kubeflow"
kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "LoadBalancer"}}'

echo "Verificando se o PROFILE está RUNNING : $ kubectl get pod -n kubeflow | grep profile"
echo "Aguardando profiles-deployment (geralmente 4 min): "
while [ "$(kubectl get pod -n kubeflow | grep profiles-deployment | grep Running | wc -l)" != "1" ]; do
  printf "."
  sleep 1
done

# Aguardando o IP Externo
echo ""
echo "Aguardando o IP Externo do Gateway (Ingress)"
while [ $(kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{ .status.loadBalancer.ingress[].ip }'| wc -m) = '0' ]; do { printf .; sleep 1; } done
export INGRESS_DOMAIN=$(kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{ .status.loadBalancer.ingress[].ip }')
echo ""
echo "INGRESS_DOMAIN = $INGRESS_DOMAIN"

# Warning: It is important that you restart the dex pod by running the command below. If you don’t any previous password 
# (including the default password 12341234 if not changed) will be used from the time the Service is exposed via LoadBalancer until the time this command is run or the dex is otherwise restarted.
kubectl rollout restart deployment dex -n auth

user@example.com and the default password is 12341234

echo ""
echo " -- "
echo ""
# Acesso ao Kubeflow
echo " Acessar Istio Kiali: http://$INGRESS_DOMAIN"
echo "    login = user@example.com"
echo "    pass  = 12341234"
echo ""
echo ""
echo "Pronto."




### FIM (a parte abaixo nao é necessária, pois já são criadas todas as rotas no istio

# Utilizar o objeto Gateway (Ingress) para limitar o uso dos IPs publicos
# https://istio.io/latest/docs/tasks/observability/gateways/#option-2-insecure-access-http

# 1. Apply the following configuration to expose Grafana:
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: centraldashboard-kubeflow-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http-centraldashboard-kubeflow
      protocol: HTTP
    hosts:
    - "kubeflow.${INGRESS_DOMAIN}"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: centraldashboard-kubeflow-vs
  namespace: istio-system
spec:
  hosts:
  - "kubeflow.${INGRESS_DOMAIN}"
  gateways:
  - centraldashboard-kubeflow-gateway-gateway
  http:
  - route:
    - destination:
        host: centraldashboard-kubeflow
        port:
          number: 80
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: centraldashboard-kubeflow
  namespace: istio-system
spec:
  host: centraldashboard.kubeflow.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
---
EOF

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# 2. Apply the following configuration to expose Kiali:
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kiali-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http-kiali
      protocol: HTTP
    hosts:
    - "kiali.${INGRESS_DOMAIN}"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kiali-vs
  namespace: istio-system
spec:
  hosts:
  - "kiali.${INGRESS_DOMAIN}"
  gateways:
  - kiali-gateway
  http:
  - route:
    - destination:
        host: kiali
        port:
          number: 20001
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: kiali
  namespace: istio-system
spec:
  host: kiali
  trafficPolicy:
    tls:
      mode: DISABLE
---
EOF

#sh ~/kubeflow/update_domain.sh # atualiza o dominio do Knative
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-domain
  namespace: knative-serving
data:
  # These are example settings of domain.
  # example.org will be used for routes having app=prod.
  ${INGRESS_DOMAIN}.nip.io: |
    selector:
      app: prod
  # Default value for domain, for routes that does not have app=prod labels.
  # Although it will match all routes, it is the least-specific rule so it
  # will only be used if no other domain matches.
  ${INGRESS_DOMAIN}.nip.io: ""
EOF

