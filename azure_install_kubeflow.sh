# https://azure.github.io/kubeflow-aks/main/docs/deployment-options/vanilla-installation/
# https://azure.github.io/kubeflow-aks/main/docs/deployment-options/custom-password-tls/
# https://github.com/kubeflow/manifests/tree/14c0f9abe70c4d0ce3e021a5839a7cdd54dc572d#install-individual-components
# https://kserve.github.io/website/latest/
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
# Cert-manager
kustomize build common/cert-manager/cert-manager/base | kubectl apply -f -
kubectl wait --for=condition=ready pod -l 'app in (cert-manager,webhook)' --timeout=180s -n cert-manager
kustomize build common/cert-manager/kubeflow-issuer/base | kubectl apply -f -
# Istio
kustomize build common/istio-1-16/istio-crds/base | kubectl apply -f -
kustomize build common/istio-1-16/istio-namespace/base | kubectl apply -f -
kustomize build common/istio-1-16/istio-install/base | kubectl apply -f -
# Dex
kustomize build common/dex/overlays/istio | kubectl apply -f -
# OIDC Auth
kustomize build common/oidc-authservice/base | kubectl apply -f -
# Kubeflow Namespace
kustomize build common/kubeflow-namespace/base | kubectl apply -f -
# Kubeflow Roles
kustomize build common/kubeflow-roles/base | kubectl apply -f -
# Kubeflow Istio Resources
kustomize build common/istio-1-16/kubeflow-istio-resources/base | kubectl apply -f -
# Central Dashboard
kustomize build apps/centraldashboard/upstream/overlays/kserve | kubectl apply -f -
# Admission Webhook
kustomize build apps/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -
# Notebooks
kustomize build apps/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -
kustomize build apps/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -
# Profiles + KFAM
kustomize build apps/profiles/upstream/overlays/kubeflow | kubectl apply -f -
# Volumes Web App
kustomize build apps/volumes-web-app/upstream/overlays/istio | kubectl apply -f -
# User Namespace
kustomize build common/user-namespace/base | kubectl apply -f -

# [OPCIONAL] Kubeflow Pipelines
kustomize build apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | awk '!/well-defined/' | kubectl apply -f -


# [OPCIONAL] Knative
#kustomize build common/knative/knative-serving/overlays/gateways | kubectl apply -f -
#kustomize build common/istio-1-16/cluster-local-gateway/base | kubectl apply -f -
#kustomize build common/knative/knative-eventing/base | kubectl apply -f -
# [OPCIONAL] KServe (usa um pouco mais de memoria)
#kustomize build contrib/kserve/kserve | kubectl apply -f -
#kustomize build contrib/kserve/models-web-app/overlays/kubeflow | kubectl apply -f -
#kubectl get cm config-domain --namespace knative-serving 
# [OPCIONAL] Katlib (usa bastante memoria, não rodar esse componentes)
#kustomize build apps/katib/upstream/installs/katib-with-kubeflow | kubectl apply -f -
# [OPCIONAL] Tensorboard
#kustomize build apps/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -
#kustomize build apps/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -
# OPCIONAL] Training Operator
#kustomize build apps/training-operator/upstream/overlays/kubeflow | kubectl apply -f -


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
echo "Verificando o uso de cpu e memorias dos nodes"
echo ""
kubectl describe nodes | grep % | grep "cpu\|memory"
echo ""
echo "INGRESS_LoadBalancer = $INGRESS_DOMAIN"

# Warning: It is important that you restart the dex pod by running the command below. If you don’t any previous password 
# (including the default password 12341234 if not changed) will be used from the time the Service is exposed via LoadBalancer until the time this command is run or the dex is otherwise restarted.
kubectl rollout restart deployment dex -n auth

echo " > Acessar o UI do Kubeflow"
echo ""
# Acesso ao Kubeflow
echo " -- "
echo " Acessar Kubeflow: http://$INGRESS_DOMAIN"
echo ""
echo "    login = user@example.com"
echo "    pass  = 12341234"
echo " -- "
echo ""
echo "Pronto."

