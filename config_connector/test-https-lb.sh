#!/usr/bin/env bash

# ref: https://cloud.google.com/config-connector/docs/how-to/getting-started

# NOTE: Confirm all script settings before trying to run as-is, and ensure no resource name collisions
# will occur with any existing resources in your project.  If you find it beneficial to run in pieces,
# simply leave the export statements in place and comment/uncomment other segments appropriately for
# each subsequent run of the script.


export MY_PREFIX="test-http-lb"  # just a prefix to help with unique names such as with buckets

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_USER=$(gcloud config get-value core/account)  # current user
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export IDNS=${PROJECT_ID}.svc.id.goog  # workload identity domain

export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"
export CLUSTER_NAME="cc-negs-test2"

export CC_SA_NAME="cc-negs-test2-sa"
export CC_NAMESPACE="cc-negs-test2-ns" 
export NETWORK_NAME="default"

export DOMAIN="dspenard.com"

# env


# # confirm installing in correct project
# while true; do
#     read -p "Create Cluster ${CLUSTER_NAME} with Config Connector on project ${PROJECT_ID} as user ${PROJECT_USER} (y/n)? " -n 1 -r yn
#     echo
#     case $yn in
#         [Yy]* ) break;;
#         [Nn]* ) exit;;
#         * ) echo "Please answer yes or no.";;
#     esac
# done


# # enable APIs
# gcloud services enable compute.googleapis.com \
#     container.googleapis.com \
#     logging.googleapis.com \
#     stackdriver.googleapis.com \
#     cloudresourcemanager.googleapis.com \
#     iamcredentials.googleapis.com


# # create cluster with config connector
# # - set appropriate version or leave blank to use the most recent version
# # - workload-pool must be set in order to enable the ConfigConnector addon
# gcloud container --project $PROJECT_ID clusters create $CLUSTER_NAME \
#     --region $GCP_REGION \
#     --no-enable-basic-auth \
#     --cluster-version "1.20.11-gke.1300" \
#     --release-channel "stable" \
#     --machine-type "e2-medium" \
#     --image-type "COS" \
#     --disk-type "pd-standard" \
#     --disk-size "100" \
#     --metadata disable-legacy-endpoints=true \
#     --scopes "https://www.googleapis.com/auth/cloud-platform" \
#     --preemptible \
#     --num-nodes "1" \
#     --enable-stackdriver-kubernetes \
#     --enable-ip-alias \
#     --network "projects/${PROJECT_ID}/global/networks/default" \
#     --subnetwork "projects/${PROJECT_ID}/regions/${GCP_REGION}/subnetworks/default" \
#     --default-max-pods-per-node "110" \
#     --enable-autoscaling --min-nodes "0" --max-nodes "3" \
#     # --enable-master-authorized-networks --master-authorized-networks 174.45.73.139/32 \
#     --addons HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS,ConfigConnector \
#     --enable-autoupgrade --enable-autorepair \
#     --max-surge-upgrade 2 --max-unavailable-upgrade 1 \
#     --workload-pool $IDNS \
#     --enable-shielded-nodes \
#     --shielded-secure-boot

# gcloud container clusters create $CLUSTER_NAME \
#         --project $PROJECT_ID \
#         --region $GCP_REGION \
#         --release-channel "stable" \
#         --machine-type "e2-medium" \
#         --num-nodes "1" \
#         --enable-ip-alias \
#         --enable-stackdriver-kubernetes \
#         --addons HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS,ConfigConnector \
#         --workload-pool $IDNS

# # create config connector identity
# # ref: https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall#identity
# gcloud iam service-accounts create $CC_SA_NAME


# # grant service account desired role (owner | editor)
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#     --member="serviceAccount:${CC_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
#     --role="roles/editor"


# # grant service account workload identity policy binding
# gcloud iam service-accounts add-iam-policy-binding \
#     ${CC_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
#     --member="serviceAccount:${PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
#     --role="roles/iam.workloadIdentityUser"


###############################

# # create config connector
# cat > configconnector.yaml << EOF
# # configconnector.yaml
# apiVersion: core.cnrm.cloud.google.com/v1beta1
# kind: ConfigConnector
# metadata:
#   # the name is restricted to ensure that there is only one
#   # ConfigConnector instance installed in your cluster
#   name: configconnector.core.cnrm.cloud.google.com
# spec:
#   mode: cluster
#   googleServiceAccount: "${CC_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
# EOF


# kubectl apply -f configconnector.yaml

# sleep 10


# # create namespace
# kubectl create ns $CC_NAMESPACE


# # annotate namespace for config connector
# kubectl annotate namespace \
#     $CC_NAMESPACE cnrm.cloud.google.com/project-id=${PROJECT_ID}


# # list config connector CRDs
# # kubectl get crds --selector cnrm.cloud.google.com/managed-by-kcc=true


# # describe CRD
# # kubectl describe crd storagebuckets.storage.cnrm.cloud.google.com



# ###############################

# # create namespace
# # kubectl create ns $CC_NAMESPACE

# # create echo deployment
# kubectl create deployment echo --image=k8s.gcr.io/echoserver:1.4 -n $CC_NAMESPACE

# # scale to 3 replicas
# kubectl scale deployment echo --replicas 3 -n $CC_NAMESPACE

# # expose deployment with ClusterIP (for external access)
# # https://cloud.google.com/kubernetes-engine/docs/how-to/standalone-neg#service_types
# cat > service.yaml << EOF
# # service.yaml
# apiVersion: v1
# kind: Service
# metadata:
#   name: cc-negs-test2-svc
#   namespace: $CC_NAMESPACE
#   annotations:
#     cloud.google.com/neg: '{"exposed_ports": {"80":{}}}'
#     #networking.gke.io/load-balancer-type: "Internal"
#   labels:
#     app: echo
# spec:
#   type: ClusterIP
#   selector:
#     app: echo
#   ports:
#   - port: 80
#     targetPort: 8080
#     protocol: TCP
# EOF

# kubectl apply -f service.yaml



###############################
# this will be done with config connector

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

###############################



# reserve static IP
# gcloud compute addresses create ${CC_NAMESPACE}-static \
#     --ip-version=IPV4 \
#     --global


# # assign static IP to DNS
export STATIC_IP=$(gcloud compute addresses describe ${CC_NAMESPACE}-static --global --format="value(address)")

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
# gcloud beta compute ssl-certificates create ${CC_NAMESPACE}-cert \
#     --domains "${CC_NAMESPACE}.${DOMAIN}"


## ran these after the URL map was set up with config connector
#
# create target HTTPS proxy
gcloud compute target-https-proxies create ${CC_NAMESPACE}-https-proxy \
    --ssl-certificates=${CC_NAMESPACE}-cert \
    --url-map=echo-app-url-map
    # --url-map=${CC_NAMESPACE}-url-map
#
# create forwarding rule
gcloud compute forwarding-rules create ${CC_NAMESPACE}-fw-rule \
    --target-https-proxy=${CC_NAMESPACE}-https-proxy \
    --global \
    --ports=443 \
    --address=${CC_NAMESPACE}-static


# ###############################

# # verify cert (may take 10-20 minutes)
# gcloud beta compute ssl-certificates describe ${CC_NAMESPACE}-cert




###############################
# this will be done with config connector

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

# # verify backend is healthy
# gcloud compute backend-services get-health \
#     --global backend-service-${CC_NAMESPACE}

