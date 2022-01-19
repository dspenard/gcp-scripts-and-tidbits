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



# double-check backend-service.yaml file before running
kubectl apply -f backend-service.yaml -n $NAMESPACE

# dump statuses to files as a reference
kubectl get computeurlmap.compute.cnrm.cloud.google.com/test-conf-conn-url-map -n test-conf-conn-negs -o yaml > urlmap-status.yaml
kubectl get computehealthcheck.compute.cnrm.cloud.google.com/test-conf-conn-backend-healthcheck -n test-conf-conn-negs -o yaml > healthcheck-status.yaml
kubectl get computebackendservice.compute.cnrm.cloud.google.com/test-conf-conn-backend-service -n test-conf-conn-negs -o yaml > backend-status.yaml
kubectl get service test-conf-conn-negs-service -n test-conf-conn-negs -o yaml > service-status.yaml




###############################
# this will be done via config connector 
#
# these scripts need some TLC and will probably not run as-is
# and are left here just as a reference

# # create health check
# gcloud compute health-checks create http health-check-${CC_NAMESPACE} \
#     --use-serving-port \
#     --request-path="/healthz"

# # create backend service
# gcloud compute backend-services create backend-service-default \
#     --global
# gcloud compute backend-services create backend-service-${CC_NAMESPACE} \
#     --global \
#     --health-checks health-check-${CC_NAMESPACE}

# # create URL map
# gcloud compute url-maps create ${CC_NAMESPACE}-url-map \
#     --global \
#     --default-service backend-service-default
# sleep 10

# # add path rules to URL map
# gcloud compute url-maps add-path-matcher ${CC_NAMESPACE}-url-map \
#     --global \
#     --path-matcher-name=${CC_NAMESPACE}-matcher \
#     --default-service=backend-service-default \
#     --backend-service-path-rules="/echo/*=backend-service-${CC_NAMESPACE}"




# # get provisioned NEG (note neg name and zones)
# export NEG_NAME=$(kubectl get svc cc-negs-test2-svc -n $CC_NAMESPACE -o jsonpath="{.metadata.annotations.cloud\.google\.com/neg-status}" | jq '.network_endpoint_groups | {name: .["80"]}' | jq .name -r)

# # add NEG to backend service for each zone
# kubectl get svc cc-negs-test2-svc -n $CC_NAMESPACE -o jsonpath="{.metadata.annotations.cloud\.google\.com/neg-status}" \
#     | jq '.zones | {name: .[]}' | jq .name \
#     | xargs -I {} gcloud compute backend-services add-backend backend-service-${CC_NAMESPACE} \
#         --global \
#         --network-endpoint-group $NEG_NAME \
#         --network-endpoint-group-zone={} \
#         --balancing-mode=RATE \
#         --max-rate-per-endpoint=100

# # create firewall rules for health checks
# gcloud compute firewall-rules create fw-allow-health-checks \
#     --network=$NETWORK_NAME \
#     --action=ALLOW \
#     --direction=INGRESS \
#     --source-ranges=35.191.0.0/16,130.211.0.0/22 \
#     --rules=tcp
###############################
