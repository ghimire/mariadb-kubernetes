#!/usr/bin/bash
# Copyright (C) 2018, MariaDB Corporation
#
# Starts and initializes a MariaDB columnstore instance

MASTER_HOST="<<MASTER_HOST>>"
ADMIN_USERNAME="<<ADMIN_USERNAME>>"
ADMIN_PASSWORD="<<ADMIN_PASSWORD>>"
REPLICATION_USERNAME="<<REPLICATION_USERNAME>>"
REPLICATION_PASSWORD="<<REPLICATION_PASSWORD>>"
RELEASE_NAME="<<RELEASE_NAME>>"
CLUSTER_ID="<<CLUSTER_ID>>"
export MARIADB_CS_DEBUG="<<MARIADB_CS_DEBUG>>"
export MAX_TRIES=60
#Get last digit of the hostname
MY_HOSTNAME=$(hostname)
SPLIT_HOST=(${MY_HOSTNAME//-/ }); 
CONT_INDEX=${SPLIT_HOST[(${#SPLIT_HOST[@]}-1)]}
MY_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '-------------------------'
    echo 'Start CS Module Container'
    echo '-------------------------'
    echo 'IP:'$MY_IP
    #set -x
fi

cp /mnt/config-map/02_load_bookstore_data.sh /docker-entrypoint-initdb.d/01_load_bookstore_data.sh

bash /mnt/config-map/sshd/run &
bash /mnt/config-map/cs_init.sh &
exec /usr/sbin/runsvdir-start

echo "Defaulted to sleep something is wrong"
sleep 3600