#!/bin/bash

for i in $(find -maxdepth 1 -type d -printf '%P\n')
do
	echo "Building image helloworld-$i:"
	docker build -t helloworld-$i ./$i >/dev/null
done
