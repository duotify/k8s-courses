#!/bin/bash
#
#  Filename: prep-linux-node.sh
#  Author: peihua@miniasp.com
#  Date: 2020/7/30
#
#  Usage: Prep for Docker and Kubernetes installation
#  Notes:
#    1. Configure and check the variables before you execute the script
#    2. This script is compatible with Flannel cni
#

# Stop script when error occurs (exit code != 0)
set -o errexit

# -------------- Variables -------------- #

# This Kubernetes package version will be installed 
declare -r K8S_VERSION=1.18.6-00
# Docker version is hard coded in section "install docker"
#   Head there if a different version is intended to install
declare -r _DOCKER_VERSION=19.03.12

# POD_CIDR and CLUSTER_CIDR should not have conflict with
#   your current conf
declare -r POD_CIDR=10.244.0.0/16
declare -r CLUSTER_CIDR=10.96.0.0/12
declare -r NODE_CIDR=

# -------------- Start Script -------------- #

### Load helper functions ###

scriptpath=$(dirname $0)
if [[ -f "$scriptpath/_helper.sh" ]]; then
  . $scriptpath/_helper.sh
else
  echo "Error: helper function not found." >&2
  exit 1
fi

CURRENT_SECTION=init

### Check if the user is root ###

if [[ $(id -u) != 0 ]]
then
  err "please be root to continue."
fi

### Install tools ###

start_section "installing tools"

if ! command -v apt-get >/dev/null ; then
  err "command apt-get not found. Are you using Ubuntu?"
fi

apt-get update -y > /dev/null
apt-get install -y -qq \
  openssh-server \
  vim \
  curl \
  wget \
  git \
  bash-completion \
  > /dev/null

end_section "installing tools"

### Tuning Kernel Options ###

start_section "tuning kernel"

echo net.bridge.bridge-nf-call-iptables=1 > /etc/sysctl.d/50-k8s.conf
sysctl -p > /dev/null

end_section "tuning kernel"

### Disable swap ###

start_section "disable swap"

swapoff -a
sed -i '/swap/ s/^/#/' /etc/fstab

end_section "disable swap"

### Install Docker ###

start_section "install docker"

# Add docker package repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /dev/null
apt-get update -y > /dev/null

# Install docker
apt-get install -y \
  docker-ce=5:19.03.12~3-0~ubuntu-bionic \
  docker-ce-cli=5:19.03.12~3-0~ubuntu-bionic \
  containerd.io=1.2.13-2 \
  > /dev/null

apt-mark hold docker-ce docker-ce-cli containerd.io > /dev/null

# Configure docker daemon
tee /etc/docker/daemon.json > /dev/null << EOF 
{
  "bridge": "none",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "10"
  },
  "live-restore": true,
  "max-concurrent-downloads": 10
}
EOF

systemctl daemon-reload
systemctl restart docker

end_section "install docker"

### Install kubernetes tools and daemon ###

start_section "install kubernetes"

# Add kubernetes package repo
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update -y > /dev/null

# Install kubernetes
apt-get install -y \
  kubelet=$K8S_VERSION \
  kubeadm=$K8S_VERSION \
  kubectl=$K8S_VERSION \
  > /dev/null
apt-mark hold kubelet kubeadm kubectl > /dev/null

# Configure bash-completion and alias
kubectl completion bash > /etc/bash_completion.d/kubectl
kubectl completion bash | sed 's/kubectl/k/g' > /etc/bash_completion.d/k
kubeadm completion bash > /etc/bash_completion.d/kubeadm
crictl completion bash > /etc/bash_completion.d/crictl 
echo 'alias k=kubectl' > /etc/profile.d/alias.sh

end_section "install kubernetes"

# -------------- End Script -------------- #

ok "Completed preparing linux node"
ok "Ready for creating or joining cluster"
