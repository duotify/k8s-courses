#!/bin/bash

cd ~
mkdir bin
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
mv kubectl bin/kubectl
chmod +x ~/bin/kubectl

~/bin/kubectl completion bash | tee ~/.bash_completion
echo 'alias k=kubectl' | tee -a ~/.bash_aliases
