## **Exemplo das informações no Dashboard:**

![Alt Text](dashboard_superset.jpeg)

# kubeflow

Rodando Kubeflow com o Minikube: https://www.kubeflow.org/docs/started/workstation/minikube-linux/

Rodando KFServing com KNative: https://github.com/kubeflow/kfserving

Config Dominio com 'sed' & 'kubectl apply --filename config-domain.yaml: https://knative.dev/v0.15-docs/serving/using-a-custom-domain/

Videos Kubecon : https://github.com/cloudyuga/kubecon19-eu

Katacoda exemplos : https://katacoda.com/kubeflow/

Deploy: https://github.com/kubeflow/kfserving/tree/master/docs/samples/sklearn
http://www.pattersonconsultingtn.com/blog/deploying_huggingface_with_kfserving.html
https://mlinproduction.com/docker-for-ml-part-4/
https://github.com/kubeflow/kfserving/tree/master/docs/samples/custom/

Erro: Warning  FailedCreate  12s (x13 over 33s)  statefulset-controller  create Pod nb2-0 in StatefulSet nb2 failed error: Internal error occurred: failed calling webhook "inferenceservice.kfserving-webhook-server.pod-mutator": Post "https://kfserving-webhook-server-service.kubeflow.svc:443/mutate-pods?timeout=30s": x509: certificate relies on legacy Common Name field, use SANs or temporarily enable Common Name matching with GODEBUG=x509ignoreCN=0

Solução: kubectl label namespace fiap serving.kubeflow.org/inferenceservice=disabled --overwrite

Fonte: 

> https://github.com/kubeflow/kubeflow/issues/4763

> https://github.com/kubeflow/kfserving/blob/master/docs/DEVELOPER_GUIDE.md#troubleshooting
