#!/usr/bin/bash
# Copyright (c) 2018-2019 MariaDB Corporation Ab
# 
# Use of this software is governed by the Business Source License included
# in the LICENSE.TXT file and at www.mariadb.com/bsl11.
#
# Change Date: 2023-04-01
# 
# On the date above, in accordance with the Business Source License, use
# of this software will be governed by version 3 or later of the General
# Public License.
#
# Starts and initializes a MariaDB master or slave instance
set -ex

# get server id from hostname, it will have the format <something>-<id>
[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}
if [[ "$ENABLE_LOGS" == "1" ]]; then
    chown -R mysql:mysql /var/log/mysql/
    cp /mnt/config-map/mariadb-log.cnf /etc/mysql/conf.d/server-log.cnf
fi
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
