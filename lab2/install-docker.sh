#!/bin/bash

if [[ $(id -u) != 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

apt-get update
apt-get upgrade -y

apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common \
bash-completion

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

apt-mark hold docker-ce docker-ce-cli containerd.io
usermod -aG docker $USER

tee /etc/docker/daemon.json << EOF >/dev/null
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
