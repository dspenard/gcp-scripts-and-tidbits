kubectl get computeurlmap.compute.cnrm.cloud.google.com/echo-app-url-map -n cc-negs-test2-ns -o yaml > urlmap-status.yaml
# kubectl get computefirewall.compute.cnrm.cloud.google.com/fw-echo-app-allow-health-checks -n cc-negs-test2-ns -o yaml > fw-status.yaml
kubectl get computehealthcheck.compute.cnrm.cloud.google.com/echo-app-backend-healthcheck -n cc-negs-test2-ns -o yaml > healthcheck-status.yaml
kubectl get computebackendservice.compute.cnrm.cloud.google.com/echo-app-backend-service -n cc-negs-test2-ns -o yaml > backend-status.yaml
kubectl get computenetworkendpointgroup.compute.cnrm.cloud.google.com/echo-app-network-endpoint-group-1 -n cc-negs-test2-ns -o yaml > neg1-status.yaml
kubectl get computenetworkendpointgroup.compute.cnrm.cloud.google.com/echo-app-network-endpoint-group-2 -n cc-negs-test2-ns -o yaml > neg2-status.yaml

kubectl get service cc-negs-test2-svc -n cc-negs-test2-ns -o yaml > service-status.yaml

