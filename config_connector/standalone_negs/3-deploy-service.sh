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


# create echo app deployment
kubectl create deployment echo --image=k8s.gcr.io/echoserver:1.4 -n $NAMESPACE

# scale to 3 replicas
kubectl scale deployment echo --replicas 3 -n $NAMESPACE

# expose deployment with ClusterIP (for external access)
# https://cloud.google.com/kubernetes-engine/docs/how-to/standalone-neg#service_types
#
# note that this will create a NEG named neg-test-conf-conn-negs with network endpoints for the 3 zones,
# and then this NEG will be tied to a backend service via config connector later on
cat > service.yaml << EOF
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE_NAME
  namespace: $NAMESPACE
  annotations:
    cloud.google.com/neg: '{"exposed_ports": {"80":{"name": "$NEG_NAME"}}}'
  labels:
    app: echo
spec:
  type: ClusterIP
  selector:
    app: echo
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
EOF


kubectl apply -f service.yaml
