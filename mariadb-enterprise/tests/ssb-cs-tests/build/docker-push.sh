#!/bin/bash
if [[ "$(docker image pull $1:$2 > /dev/null 2> /dev/null && echo $?)" == "0" ]]; then
	echo "Image already available on remote repo"
else
	set -e
	docker push $1:$2
fi
