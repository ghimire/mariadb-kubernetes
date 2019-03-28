#!/bin/bash

set -e
if [[ "$(docker images -q $1:$2 2> /dev/null)" == "" ]]; then
	docker build . -t $1:$2
else
	echo "Image already available locally"
fi
