#!/bin/bash

echo "Aguardando profiles-deployment (geralmente 4 min): 2/2 Running"
while [ "$(kubectl get pod -n kubeflow | grep profile | grep Running | wc -l)" != "1" ]; do
  printf "."
  sleep 1
done
echo "Pronto."
echo " $ kubectl get pod -n kubeflow | grep profile"
kubectl get pod -n kubeflow | grep profile
curl checkip.amazonaws.com
