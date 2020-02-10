#!/bin/bash

if [[ $(id -u) != 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl

apt-mark hold kubelet kubeadm kubectl
kubectl completion bash | tee /etc/bash_completion.d/kubectl >/dev/null
kubectl completion bash | sed 's/kubectl/k/g' | tee /etc/bash_completion.d/k >/dev/null
kubeadm completion bash | tee /etc/bash_completion.d/kubeadm >/dev/null
crictl completion bash | tee /etc/bash_completion.d/crictl >/dev/null
echo 'alias k=kubectl' | tee /etc/profile.d/alias.sh
