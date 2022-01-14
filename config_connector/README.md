## Config Connector

https://cloud.google.com/config-connector/docs/overview

Demo scripts for spinning up a GKE cluster and building resources via Config Connector.

gke-conf-conn-storage-bucket.sh
- create a simple 3 node cluster with workload identity and config connector enabled
- create service account and set the workload identity policy binding
- creates K8s custom resources for the config connector and storage bucket
