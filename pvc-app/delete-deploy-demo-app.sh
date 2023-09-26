#!/bin/bash
SCALE=4

kubectx
for  ((idx=1; idx <= SCALE; idx++)); do
    kubectl delete ns test-$idx
done

kubectl get po,svc,pvc -A | grep test