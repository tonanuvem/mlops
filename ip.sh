export INGRESS_HOST=$(curl -s checkip.amazonaws.com)
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
echo "Acessar o UI do Kubeflow:"
echo $INGRESS_HOST:$INGRESS_PORT
