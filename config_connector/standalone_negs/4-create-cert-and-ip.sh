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


# reserve static IP
gcloud compute addresses create ${NAMESPACE}-static \
    --ip-version=IPV4 \
    --global


# assign static IP to DNS
export STATIC_IP=$(gcloud compute addresses describe ${NAMESPACE}-static --global --format="value(address)")

# confirm assigned IP to DNS to continue
while true; do
    read -p "Did you create DNS record for ${DOMAIN} with ${STATIC_IP}? " -n 1 -r yn
    echo
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# create managed SSL cert
gcloud beta compute ssl-certificates create ${NAMESPACE}-cert \
    --domains "${NAMESPACE}.${DOMAIN}"
