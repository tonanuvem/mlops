kubectl get pv | grep fiap
VOL=$(kubectl get pv | grep fiap | awk '{print $1}' | xargs echo)

PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $PX_POD -n kube-system -- /opt/pwx/bin/pxctl volume list
kubectl exec -it $PX_POD -n kube-system -- /opt/pwx/bin/pxctl volume inspect $VOL
