#!/bin/bash
# Copyright (c) 2018-2019 MariaDB Corporation Ab
# 
# Use of this software is governed by the Business Source License included
# in the LICENSE.TXT file and at www.mariadb.com/bsl11.
#
# Change Date: 2022-04-01
# 
# On the date above, in accordance with the Business Source License, use
# of this software will be governed by version 2 or later of the General
# Public License.

# file used to track / record initialization and prevent subsequent rerun
MCSDIR=/usr/local/mariadb/columnstore
FLAG="$MCSDIR/etc/container-initialized"
# directory which can contain sql, sql.gz, and sh scripts that will be run
# after successful initialization.
INITDIR=/docker-entrypoint-initdb.d
POST_REP_CMD=''

mysql=( $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot )

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '------------------------'
    echo 'Starting UM Slave       '
    echo '------------------------'
    #set -x
fi

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

# wait for the ProcMon process to start
wait_for_procmon()
{
    ps -e | grep ProcMon
    while [ 1 -eq $? ]; do
        sleep 1
        ps -e | grep ProcMon
    done
}

execute_sql()
{
        IFS=';' read -r -a cmds <<< "$1"
        for cmd in "${cmds[@]}"
            do
                if [[ -n "${cmd// /}" ]]; then 
                    if [ ! -z $MARIADB_CS_DEBUG ]; then
                        echo "> $cmd;"
                    fi
                    "${mysql[@]}" -e "$cmd;"
                fi
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

# Initialize CS only once.
if [ -e $FLAG ]; then
    echo "Container already initialized at $(date)"
    exit 0
fi
#TODO: Call /usr/sbin/cs_post_init.sh here
unset $MARIADB_ROOT_PASSWORD
if [ ! -z $GENERATED_ROOT ]; then
    echo "Generated MariaDB root password is: $GENERATED_ROOT"
fi
echo "Container initialization complete at $(date)"
touch $FLAG

exit 0;
