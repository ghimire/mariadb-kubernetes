#!/bin/bash
# Copyright (C) 2018, MariaDB Corporation
#

MASTER_HOST="<<MASTER_HOST>>"
ADMIN_USERNAME="<<ADMIN_USERNAME>>"
ADMIN_PASSWORD="<<ADMIN_PASSWORD>>"
REPLICATION_USERNAME="<<REPLICATION_USERNAME>>"
REPLICATION_PASSWORD="<<REPLICATION_PASSWORD>>"
RELEASE_NAME="<<RELEASE_NAME>>"
CLUSTER_ID="<<CLUSTER_ID>>"
MARIADB_CS_DEBUG="<<MARIADB_CS_DEBUG>>"

MCSDIR=/usr/local/mariadb/columnstore
# file used to track / record initialization and prevent subsequent rerun
FLAG="$MCSDIR/etc/container-initialized"
# file used to track / record backup and prevent subsequent rerun
RESTORE_FLAG="$MCSDIR/etc/backup-restored"
# directory which can contain sql, sql.gz, and sh scripts that will be run
# after successful initialization.
INITDIR=/docker-entrypoint-initdb.d
POST_REP_CMD=''

mysql=( $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot )

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo "------------------"
    echo "Starting PM Module"
    echo "------------------"
    #set -x
fi

# wait for the ProcMon process to start
wait_for_procmon()
{
    ps -e | grep ProcMon
    while [ 1 -eq $? ]; do
        sleep 1
        ps -e | grep ProcMon
    done
}

# hack to ensure server-id is set to unique value per vm because my.cnf is
# not in a good location for a volume
SERVER_ID=$(hostname -i | cut -d "." -f 4)
SERVER_SUBNET=$(hostname -i | cut -d "." -f 1-3 -s)
sed -i "s/server-id =.*/server-id = $SERVER_ID/" /usr/local/mariadb/columnstore/mysql/my.cnf

# hack to make master-dist rsync.sh script do nothing as it fails otherwise
# in non distributed on windows and mac (occasionally on ubuntu).
# Replicating the db directories is a no-op here anyway
mv /usr/local/mariadb/columnstore/bin/rsync.sh /usr/local/mariadb/columnstore/bin/rsync.sh.bkp
touch /usr/local/mariadb/columnstore/bin/rsync.sh
chmod a+x /usr/local/mariadb/columnstore/bin/rsync.sh

# hack to specify user env var as this is sometimes relied on to detect
# root vs non root install
export USER=root

# Change set restored flag on first run
if [[ ! "$RESTORE_FROM_FOLDER" == "" ]] && [ ! -e $RESTORE_FLAG ]; then
    touch $RESTORE_FLAG
fi

# Initialize CS only once.
if [ -e $FLAG ]; then
    echo "Container already initialized at $(date)"
    exit 0
fi

# wait for ProcMon to startup
echo "Initializing container at $(date) - waiting for ProcMon to start"
wait_for_procmon

echo "Container initialization complete at $(date)"
touch $FLAG

exit 0;