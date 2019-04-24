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

# load backup
if [[ ! "$RESTORE_FROM_FOLDER" == "" ]]; then
    mkdir /backup_local
    cp -a /backup-storage/$RESTORE_FROM_FOLDER/* /backup_local
    # chown -R mysql:mysql /backup_local
fi

if [ -f /usr/local/bin/entrypoint.sh ]; then
   ENTRYPOINT=/usr/local/bin/entrypoint.sh
else
   ENTRYPOINT=/usr/local/bin/docker-entrypoint.sh
fi

export USER=mysql

if [[ "$CLUSTER_TOPOLOGY" == "standalone" ]] || [[ "$CLUSTER_TOPOLOGY" == "masterslave" ]]; then
    # fire up the instance
    $ENTRYPOINT --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync --extra-port=3307 --extra_max_connections=1
elif [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
    MASTER_HOST=$(cat /mnt/config-map/master)

    cp /mnt/config-map/galera.cnf /etc/mysql/mariadb.conf.d/galera.cnf

    # fire up the instance
    if [[ "$MASTER_HOST" == "localhost" ]]; then
        # clean old galera state
        if [[ -f /var/lib/mysql/grastate.dat ]]; then
            rm -rf /var/lib/mysql/grastate.dat
        fi

        $ENTRYPOINT --wsrep-new-cluster --wsrep-node-address=${DWAPI_PODIP} --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync --extra-port=3307 --extra_max_connections=1
    else
        # prevent initialization, it is going to sync anyway
        export SKIP_INITIALIZATION=1
        if [ ! -d /var/lib/mysql/mysql ]; then
            mkdir -p /var/lib/mysql/mysql
        fi

        $ENTRYPOINT --wsrep-node-address=${DWAPI_PODIP} --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync --extra-port=3307 --extra_max_connections=1
    fi
fi
