#!/usr/bin/env bash

set -o allexport
source dev.env
set +o allexport
env


# # create echo app deployment
kubectl create deployment echo --image=k8s.gcr.io/echoserver:1.4 -n $NAMESPACE

# # scale to 3 replicas
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
