# Aguardando o IP Externo
echo ""
echo "Aguardando o IP Externo do Gateway (Ingress)"
while [ $(kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{ .status.loadBalancer.ingress[].ip }'| wc -m) = '0' ]; do { printf .; sleep 1; } done
export INGRESS_DOMAIN=$(kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{ .status.loadBalancer.ingress[].ip }').nip.io
echo ""
echo "INGRESS_DOMAIN = $INGRESS_DOMAIN"

kubectl apply -f https://raw.githubusercontent.com/tonanuvem/mlops/main/exemplo/deploy/deploy_svc_ml_azure.yaml

# 1. Apply the following configuration to expose ML:
cat <<EOF | kubectl apply -f -
---
kind: Service
apiVersion: v1
metadata:
  name: ml-service
spec:
  selector:
    app: fiapml
  ports:
    - protocol: "TCP"
      port: 5000
      targetPort: 5000
      #nodePort: 32000
  type: ClusterIP
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: recomendacao-gateway
  #namespace: fiap
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http-recomendacao
      protocol: HTTP
    hosts:
    - "recomendacao.${INGRESS_DOMAIN}"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: recomendacao-vs
  #namespace: fiap
spec:
  hosts:
  - "recomendacao.${INGRESS_DOMAIN}"
  gateways:
  - recomendacao-gateway
  http:
  - route:
    - destination:
        host: ml-service
        port:
          number: 5000
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: recomendacao
  #namespace: fiap
spec:
  host: ml-service
  trafficPolicy:
    tls:
      mode: DISABLE
EOF

echo ""
echo "Aguardando a execução de Recomendação ML"
while [ $(kubectl get pod -A grep ml-deployment | grep Running | wc -l) != '5' ]; do { printf .; sleep 1; } done
echo ""
echo "Acessar : http://recomendacao.$INGRESS_DOMAIN"
echo ""
echo ""
