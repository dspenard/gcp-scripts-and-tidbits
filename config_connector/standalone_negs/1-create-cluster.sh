#!/usr/bin/env bash

# NOTE: Confirm all scripts before trying to run as-is, and ensure no resource name collisions
# will occur with any existing resources in your project.  Make sure you set the current project
# and you are authorized in the CLI first.

set -o allexport
source dev.env
set +o allexport
env


# confirm installing in correct project
while true; do
    read -p "Create Cluster ${CLUSTER_NAME} with Config Connector on project ${PROJECT_ID} as user ${PROJECT_USER} (y/n)? " -n 1 -r yn
    echo
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


# enable APIs
gcloud services enable compute.googleapis.com \
    container.googleapis.com \
    logging.googleapis.com \
    stackdriver.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iamcredentials.googleapis.com


# create cluster with config connector enabled, and most settings as their defaults
# - set appropriate version or leave blank to use the most recent version
# - workload-pool must be set in order to enable the ConfigConnector addon
gcloud container clusters create $CLUSTER_NAME \
        --project $PROJECT_ID \
        --region $GCP_REGION \
        --release-channel "stable" \
        --machine-type "e2-medium" \
        --num-nodes "1" \
        --enable-ip-alias \
        --enable-stackdriver-kubernetes \
        --addons HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS,ConfigConnector \
        --workload-pool $WORKLOAD_ID


# create config connector identity
# ref: https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall#identity
gcloud iam service-accounts create $SA_NAME


# grant service account desired role (owner | editor)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/editor"


# grant service account workload identity policy binding
gcloud iam service-accounts add-iam-policy-binding \
    ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
    --role="roles/iam.workloadIdentityUser"
