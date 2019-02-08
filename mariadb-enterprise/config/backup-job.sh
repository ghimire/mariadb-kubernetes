#!/bin/bash

if [[ "$CLUSTER_TOPOLOGY" == "standalone" ]]; then
    URL=$RELEASE_NAME-mdb-ms-0.$RELEASE_NAME-mariadb
elif [[ "$CLUSTER_TOPOLOGY" == "masterslave" ]]; then
    URL=$RELEASE_NAME-mdb-ms-0.$RELEASE_NAME-mdb-clust
elif [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
    URL=$RELEASE_NAME-mdb-galera-0.$RELEASE_NAME-mdb-clust
fi

BACKUP_DIR=backup-$RELEASE_NAME-$(date +%Y-%m-%d-%H-%M-%S)

curl -X PUT \
    "http://$URL/backup?targetDirectory=$BACKUP_DIR" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'cache-control: no-cache'
