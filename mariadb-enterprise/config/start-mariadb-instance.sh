#!/usr/bin/bash
# Copyright (C) 2018, MariaDB Corporation
#
# Starts and initializes a MariaDB master or slave instance
set -ex

# get server id from hostname, it will have the format <something>-<id>
[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

# load backup
if [[ ! "$RESTORE_FROM_FOLDER" == "" ]]; then
    mkdir /backup_local
    cp -a /backup-storage/$RESTORE_FROM_FOLDER/* /backup_local
    chown -R mysql:mysql /backup_local
fi

if [[ "$CLUSTER_TOPOLOGY" == "standalone" ]] || [[ "$CLUSTER_TOPOLOGY" == "masterslave" ]]; then
    # fire up the instance
    /usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync --extra-port=3307 --extra_max_connections=1
elif [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
    MASTER_HOST=$(cat /mnt/config-map/master)

    cp /mnt/config-map/galera.cnf /etc/mysql/mariadb.conf.d/galera.cnf

    # fire up the instance
    if [[ "$MASTER_HOST" == "localhost" ]]; then
        /usr/local/bin/docker-entrypoint.sh mysqld  --wsrep-new-cluster --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync --extra-port=3307 --extra_max_connections=1 --wsrep-node-address=${DWAPI_PODIP}
    else
        /usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync --extra-port=3307 --extra_max_connections=1 --wsrep-node-address=${DWAPI_PODIP}
    fi
fi
