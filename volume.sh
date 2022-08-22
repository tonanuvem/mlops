echo ""
echo "Informações sobre PERSISTENT VOLUME CLAIM (PVC) no Cluster:"
kubectl get pvc -n fiap
echo "---"
echo "Informações sobre PERSISTENT VOLUME (PV) no Cluster:"
kubectl get pv | grep fiap
echo "---"
VOL=$(kubectl get pv | grep fiap | awk '{print $1}' | xargs echo)
PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
echo ""
echo "Detalhe do PERSISTENT VOLUME (PV), informando quem é o STORAGE CLASS (SC) usado:"
kubectl describe pv $VOL
#kubectl exec -it $PX_POD -n kube-system -- /opt/pwx/bin/pxctl volume list
echo "---"
echo "Informações sobre o DISCO GERENCIADO pelo portworx::"
echo ""
kubectl exec -it $PX_POD -n kube-system -- /opt/pwx/bin/pxctl volume inspect $VOL
