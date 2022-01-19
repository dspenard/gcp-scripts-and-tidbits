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


## run this after the URL map was set up with config connector
#
# create target HTTPS proxy
gcloud compute target-https-proxies create ${NAMESPACE}-https-proxy \
    --ssl-certificates=${NAMESPACE}-cert \
    --url-map=test-conf-conn-url-map
    # --url-map=${NAMESPACE}-url-map
#
# create forwarding rule
gcloud compute forwarding-rules create ${NAMESPACE}-fw-rule \
    --target-https-proxy=${NAMESPACE}-https-proxy \
    --global \
    --ports=443 \
    --address=${NAMESPACE}-static




# todo add some curls and some simple test scripts
#
# # verify backend is healthy
# gcloud compute backend-services get-health \
#     --global backend-service-${NAMESPACE}

