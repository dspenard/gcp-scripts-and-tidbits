#!/usr/bin/env bash

set -o allexport
source dev.env
set +o allexport
env


# create config connector
cat > configconnector.yaml << EOF
# configconnector.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnector
metadata:
  # the name is restricted to ensure that there is only one
  # ConfigConnector instance installed in your cluster
  name: configconnector.core.cnrm.cloud.google.com
spec:
  mode: cluster
  googleServiceAccount: "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
EOF


kubectl apply -f configconnector.yaml

sleep 10


# create namespace
kubectl create ns $NAMESPACE


# annotate namespace for config connector
kubectl annotate namespace \
    $NAMESPACE cnrm.cloud.google.com/project-id=${PROJECT_ID}


# # list config connector CRDs
# # kubectl get crds --selector cnrm.cloud.google.com/managed-by-kcc=true

# # describe CRD
# # kubectl describe crd storagebuckets.storage.cnrm.cloud.google.com
