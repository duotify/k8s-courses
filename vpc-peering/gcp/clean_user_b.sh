#!/bin/bash

if [[ -z $MY_PROJECT_ID ]]; then
  echo "project id not set"
  exit 1
fi

gcloud config set project $MY_PROJECT_ID
gcloud config set compute/region asia-east1
gcloud config set compute/zone asia-east1-b

gcloud compute instances delete k8s-node02 -q
gcloud compute networks peerings delete peer-to-node01 --network k8snet -q
gcloud compute firewall-rules delete k8snet-allow-common -q
gcloud compute firewall-rules delete k8snet-allow-internal -q
gcloud compute networks subnets delete k8snet-asiaeast1 -q
gcloud compute networks delete k8snet -q
