export INGRESS_HOST=$(curl checkip.amazonaws.com)
export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
echo $INGRESS_DOMAIN
sed -i 's|nip.io|'$INGRESS_DOMAIN'|' ~/kubeflow/config-domain.yaml
kubectl apply --filename ~/mlops/config-domain.yaml
