#!/bin/bash

cd ~
mkdir bin
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
mv kubectl bin/kubectl
chmod +x ~/bin/kubectl

~/bin/kubectl completion bash | tee ~/.bash_completion > /dev/null
echo 'alias k=kubectl' | tee ~/.bash_aliases > /dev/null
echo 'complete -F __start_kubectl k' | tee -a ~/.bash_aliases > /dev/null
