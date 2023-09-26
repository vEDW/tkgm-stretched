#!/bin/bash
SCALE=4

kubectx
for  ((idx=1; idx <= SCALE; idx++)); do
    kubectl create ns test-$idx
    kubectl apply -n test-$idx -f demo-app.yaml
done

kubectl get po,svc,pvc -A | grep test