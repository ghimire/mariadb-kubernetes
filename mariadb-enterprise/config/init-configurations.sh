#!/bin/bash
# Copyright (C) 2018, MariaDB Corporation
#
# This script customizes templates based on the parameters passed to a command-line tool
# the path to the target directory needs to be passed as first argument

function expand_templates() {
    sed -e "s/<<MASTER_HOST>>/${MASTER_HOST}/g" \
        -e "s/<<ADMIN_USERNAME>>/${ADMIN_USER}/g" \
        -e "s/<<ADMIN_PASSWORD>>/${ADMIN_PWD}/g" \
        -e "s/<<REPLICATION_USERNAME>>/${REPL_USER}/g" \
        -e "s/<<REPLICATION_PASSWORD>>/${REPL_PWD}/g" \
        -e "s/<<RELEASE_NAME>>/${RELEASE_NAME}/g" \
        -e "s/<<CLUSTER_ID>>/${CLUSTER_ID}/g" \
        $1
}

set -ex
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# APPLICATION=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 1)
# ENVIRONMENT=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 2)
ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
REPL_USER=$(cat /mnt/secrets/repl-username)
REPL_PWD=$(cat /mnt/secrets/repl-password)
DB_HOST="$(hostname -f | cut -d '.' -f 1).$(hostname -f | cut -d '.' -f 2)"

if [ "$1" == "maxscale" ]; then
    # ensure we replace with a configurations that will fail
    MASTER_HOST="should-not-be-used-here"
    expand_templates /mnt/config-template/maxscale.cnf >> /etc/maxscale-cfg/maxscale.cnf
else
    cp /mnt/config-template/start-mariadb-instance.sh /mnt/config-map
    cp /mnt/config-template/backup-save.sh /mnt/config-map
    # if this is not a maxscale instance, make sure to ask maxscale who is the master
    MASTER_HOST=$(cat /mnt/config-map/master)
    if [[ ! -d /var/lib/mysql/mysql ]]; then
        if [[ ! "$RESTORE_FROM_FOLDER" == "" ]]; then
            # restore backup
            cp /mnt/config-template/backup-restore.sh /docker-entrypoint-initdb.d/
        fi

        if [[ "$MASTER_HOST" == "localhost" ]]; then
            # this is the master and it's the first run, ensure maxscale user is initialized
            expand_templates /mnt/config-template/users.sql >> /docker-entrypoint-initdb.d/init.sql
            if [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
                expand_templates /mnt/config-template/galera.cnf >> /mnt/config-map/galera.cnf
                sed -r -i "s/<<CLUSTER_ADDRESS>>/$(hostname -i)/" /mnt/config-map/galera.cnf
            fi
        else
            # a first run on a slave
            # mysqldump -h $MASTER_HOST -u $REPL_USER -p$REPL_PWD --all-databases -A -Y --add-drop-database --add-drop-table --add-drop-trigger --allow-keywords --compact --master-data --lock-all-tables -F --flush-privileges --gtid -Q > /docker-entrypoint-initdb.d/slave.sql
            if [[ "$CLUSTER_TOPOLOGY" == "standalone" ]] || [[ "$CLUSTER_TOPOLOGY" == "masterslave" ]]; then
                expand_templates /mnt/config-template/replication.sql >> /docker-entrypoint-initdb.d/init.sql
            elif [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
                expand_templates /mnt/config-template/galera.cnf >> /mnt/config-map/galera.cnf
                sed -r -i "s/<<CLUSTER_ADDRESS>>/$MASTER_HOST/" /mnt/config-map/galera.cnf
            fi
        fi
    fi
fi
