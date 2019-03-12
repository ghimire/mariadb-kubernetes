#!/bin/sh

if [[ "$CLUSTER_TOPOLOGY" == "standalone" ]]; then
    URL=$RELEASE_NAME-mdb-ms-0.$RELEASE_NAME-mariadb
elif [[ "$CLUSTER_TOPOLOGY" == "masterslave" ]]; then
    URL=$RELEASE_NAME-mdb-ms-0.$RELEASE_NAME-mdb-clust
elif [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
    URL=$RELEASE_NAME-mdb-galera-0.$RELEASE_NAME-mdb-clust
fi

BACKUP_DIR=backup-$RELEASE_NAME-`date +%Y%m%d-%H%M%S`

data='{}'
encoded_data=`echo -n "$data" | iconv -t utf-8`

encoded_secret=`iconv -t utf-8 /etc/hmac-secret/hmac-secret`

signature=`echo -n "$encoded_data" | openssl dgst -sha256 -hmac "$encoded_secret" -binary`

b64_signature=`echo -n "$signature" | openssl enc -base64`

curl -X PUT \
    "http://$URL/backup?targetDirectory=$BACKUP_DIR" \
    -d "$encoded_data" \
    -H 'Content-Type: application/json' \
    -H "Signature: $b64_signature"
