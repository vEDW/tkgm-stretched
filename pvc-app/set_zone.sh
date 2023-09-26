#!/bin/bash
DEMOAPP=$(yq e statefulset-topology-aware.yaml)
DEMOAPP=$(echo "${DEMOAPP}" | yq e '.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[].matchExpressions[].values = null' -)
ZONES=$(kubectl get nodes -o json |jq -r '.items[].metadata.labels."failure-domain.beta.kubernetes.io/zone"' | sort | uniq)
for ZONE in $ZONES; do
    DEMOAPP=$(echo "${DEMOAPP}" | yq e '.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[].matchExpressions[].values += ["'"$ZONE"'"]' -)
done
echo "${DEMOAPP}" > demo-app.yaml
yq e demo-app.yaml