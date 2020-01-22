#!/bin/bash

read -p "Enter your Docker username: " DOCKER_USER
read -s -p "Enter your Docker password: " DOCKER_PASS

docker login --username "$DOCKER_USER" -p "$DOCKER_PASS"


for i in $(find -maxdepth 1 -type d -printf '%P\n')
do
	echo "Pushing image helloworld-$i:"
	docker tag helloworld-$i $DOCKER_USER/helloworld-$i
	docker push $DOCKER_USER/helloworld-$i
	echo ""
done
