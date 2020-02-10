#!/bin/bash

POD_CIDR=172.30.0.0
POD_CIDR_WITH_MASK=172.30.0.0/16

if [[ $(id -u) != 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

kubeadm init --pod-network-cidr=$POD_CIDR_WITH_MASK | tee ./kubeadm_init.log

if [[ ! -z $SUDO_USER ]]; then
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u $SUDO_USER):$(id -g $SUDO_USER) $HOME/.kube/config
else
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
fi

# Option 1 - Calico (IPIP)

curl -s -O https://docs.projectcalico.org/v3.8/manifests/calico.yaml
sed -i "s/192.168.0.0/$POD_CIDR/g" calico.yaml
kubectl apply -f calico.yaml

# Option 2 - WeaveNet (VXLAN)

#sudo tee /etc/sysctl.d/50-k8s.conf << EOF >/dev/null
#net.bridge.bridge-nf-call-iptables = 1
#EOF
#sudo sysctl -p

#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=$POD_CIDR"
