#!/bin/bash
# escape image name for sed
img=$( echo "$2" | sed -e 's/\//\\\//g' )
pod="$1-$3"
nfs-server-ip="$4"

# delete existing resource (if any)
if kubectl delete pod "${pod}" 2> /dev/null; then
	while kubectl get pods "${pod}" >/dev/null 2>/dev/null; do
		echo -n "."
		sleep 1 
	done
	echo ""
fi

cd ssb-cs-tests/
# create new resource
sed -e "s/\$(MARIADB_CLUSTER)/$1/g" -e "s/\$(IMAGE)/${img}/g" -e "s/\$(POD_NAME)/${pod}/g" -e "s/\$(NFS_SERVER_IP)/$nfs-server/g" build/ssb-pod.yaml > pod.yaml
#exit 0
kubectl create -f pod.yaml --validate=false 
rm  pod.yaml
