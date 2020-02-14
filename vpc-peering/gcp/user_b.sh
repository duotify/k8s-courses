#!/bin/bash

if [[ -z $MY_PROJECT_ID ]]; then
  echo "project id not set"
  exit 1
fi

if [[ -z $PEER_PROJECT_ID ]]; then
  echo "project id not set"
  exit 1
fi

gcloud config set project $MY_PROJECT_ID
gcloud config set compute/region asia-east1
gcloud config set compute/zone asia-east1-b

gcloud compute networks create k8snet \
--subnet-mode custom

gcloud compute networks subnets create k8snet-asiaeast1 \
--network k8snet \
--range 10.0.2.0/24

gcloud compute firewall-rules create k8snet-allow-common \
--network k8snet \
--allow icmp,tcp:22,tcp:6443,tcp:30000-32767

gcloud compute firewall-rules create k8snet-allow-k8s-internal \
--network k8snet \
--allow all \
--source-ranges 172.30.0.0/16,10.96.0.0/12

gcloud compute firewall-rules create k8snet-allow-internal \
--network k8snet \
--allow all \
--source-ranges 10.0.1.0/24,10.0.2.0/24

gcloud compute instances create k8s-node02 \
--zone=asia-east1-b \
--machine-type=n1-standard-2 \
--subnet=k8snet-asiaeast1 \
--image=ubuntu-1804-bionic-v20200129a \
--image-project=ubuntu-os-cloud \
--boot-disk-size=30GB \
--boot-disk-type=pd-standard \
--boot-disk-device-name=k8s-node01 \
--can-ip-forward

gcloud compute networks peerings create peer-to-node01 \
--network k8snet \
--peer-project $PEER_PROJECT_ID \
--peer-network k8snet \
--auto-create-routes
