# https://azure.github.io/kubeflow-aks/main/docs/deployment-options/vanilla-installation/
# https://azure.github.io/kubeflow-aks/main/docs/deployment-options/custom-password-tls/
# https://github.com/kubeflow/manifests/tree/14c0f9abe70c4d0ce3e021a5839a7cdd54dc572d#install-individual-components
# grep -Rnw '/path/to/somewhere/' -e 'string procurada'
# grep -Rnw . -e 'kvAppName'

#echo "Clonando o repo: kubeflow-aks"
git clone --recurse-submodules https://github.com/Azure/kubeflow-aks.git
cd kubeflow-aks

# Deploy Kubeflow without TLS using Default Password

cd manifests/
git checkout v1.7-branch
cd ..
cp -a deployments/vanilla manifests/vanilla
cd manifests/
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
alias kustomize="$(pwd)/kustomize"

# Maneiras de rodar o Kubeflow:
# 1) rodar todos os componentes, precisa ter bastante cpu e memoria
#while ! ./kustomize build vanilla | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

# 2) criar yaml para depois rodar todos os componentes, precisa ter bastante cpu e memoria
#./kustomize build vanilla > kubeflow_vanilla.yaml
#kubectl apply -f kubeflow_vanilla.yaml

# 3) rodar somente alguns componentes para econmicar cpu e memoria
kustomize build common/oidc-authservice/base | kubectl apply -f -
kustomize build common/kubeflow-namespace/base | kubectl apply -f -
kustomize build common/kubeflow-roles/base | kubectl apply -f -
kustomize build common/istio-1-16/kubeflow-istio-resources/base | kubectl apply -f -
kustomize build apps/centraldashboard/upstream/overlays/kserve | kubectl apply -f -
kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -
kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -
kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -
kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -
kustomize build common/user-namespace/base | kubectl apply -f -

# https://stackoverflow.com/questions/76793434/kubeflow-jupyter-notebook-error-could-not-find-csrf-cookie-xsrf-token-in-the-req
# https://github.com/kubeflow/manifests/issues/2225
# solution that adding : - name: APP_SECURE_COOKIES <--> value: "false"
kubectl set env deploy jupyter-web-app-deployment -n kubeflow APP_SECURE_COOKIES=false
kubectl get deploy jupyter-web-app-deployment -n kubeflow -o jsonpath='{.spec.template.spec.containers[].env[4]}'


#echo "Verificando os pods em execução dos namespaces."
#kubectl get pods -n cert-manager
#kubectl get pods -n istio-system
#kubectl get pods -n auth
#kubectl get pods -n knative-eventing
#kubectl get pods -n knative-serving
#kubectl get pods -n kubeflow
#kubectl get pods -n kubeflow-user-example-com

#echo "Verificando os Gateways criados (Ingress)."
#kubectl get gateway -n kubeflow

#echo "Verificando os Virtual Services criados."
#kubectl get destinationrule -n kubeflow

#echo "Verificando os Virtual Services criados."
#kubectl get destinationrule -n kubeflow


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
echo "INGRESS_LoadBalancer = $INGRESS_DOMAIN"

# Warning: It is important that you restart the dex pod by running the command below. If you don’t any previous password 
# (including the default password 12341234 if not changed) will be used from the time the Service is exposed via LoadBalancer until the time this command is run or the dex is otherwise restarted.
kubectl rollout restart deployment dex -n auth

echo " > Acessar o UI do Kubeflow"
echo ""
echo " -- "
echo ""
# Acesso ao Kubeflow
echo " Acessar Kubeflow: http://$INGRESS_DOMAIN"
echo "    login = user@example.com"
echo "    pass  = 12341234"
echo ""
echo ""
echo "Pronto."

