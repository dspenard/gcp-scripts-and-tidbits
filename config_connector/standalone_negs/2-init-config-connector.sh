#!/usr/bin/env bash

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_USER=$(gcloud config get-value core/account)  # current user
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export WORKLOAD_ID=${PROJECT_ID}.svc.id.goog  # workload identity domain

export NETWORK_NAME="default"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"

export CLUSTER_NAME="test-conf-conn-negs"
export SA_NAME="test-conf-conn-negs-sa"
export NAMESPACE="test-conf-conn-negs"
export SERVICE_NAME="test-conf-conn-negs-service"
export NEG_NAME="neg-test-conf-conn-negs"

export DOMAIN="dspenard.com"


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
