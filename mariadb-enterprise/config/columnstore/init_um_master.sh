#!/bin/bash
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


MASTER_HOST="<<MASTER_HOST>>"
ADMIN_USERNAME="<<ADMIN_USERNAME>>"
ADMIN_PASSWORD="<<ADMIN_PASSWORD>>"
REPLICATION_USERNAME="<<REPLICATION_USERNAME>>"
REPLICATION_PASSWORD="<<REPLICATION_PASSWORD>>"
RELEASE_NAME="<<RELEASE_NAME>>"
CLUSTER_ID="<<CLUSTER_ID>>"
MARIADB_CS_DEBUG="<<MARIADB_CS_DEBUG>>"

MCSDIR=/usr/local/mariadb/columnstore
export MCSDIR
# file used to track / record initialization and prevent subsequent rerun
FLAG="$MCSDIR/etc/container-initialized"
# directory which can contain sql, sql.gz, and sh scripts that will be run
# after successful initialization.
INITDIR=/docker-entrypoint-initdb.d
POST_REP_CMD=''
MCSDIR=/usr/local/mariadb/columnstore
mysql=( $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot )

# hack to ensure server-id is set to unique value per vm because my.cnf is
# not in a good location for a volume
SERVER_ID=$(hostname -i | cut -d "." -f 4)
SERVER_SUBNET=$(hostname -i | cut -d "." -f 1-3 -s)
sed -i "s/server-id =.*/server-id = $SERVER_ID/" /usr/local/mariadb/columnstore/mysql/my.cnf

function run_tests(){
        if [  -f "/mnt/config-map/test_cs.sh" ]; then
            CUR_DIR=`pwd`
            cd /mnt/config-map/
            bash ./test_cs.sh
            cd $CUR_DIR
        fi
}

function continuous_test(){
    while true; do
        sleep 5
        $MCSDIR/bin/mcsadmin getSystemInfo
        sleep 5
        run_tests
    done
}

function print_info(){
        $MCSDIR/bin/mcsadmin getSoftwareInfo
        $MCSDIR/bin/mcsadmin getSystemMemory
}

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
    echo "Done."
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

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '------------------------'
    echo 'Starting UM Master      '
    echo '------------------------'
    #set -x
fi


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
    run_tests    
    exit 0
fi
echo "Initializing container at $(date) - waiting for ProcMon to start"
wait_for_procmon

echo "Waiting for columnstore to start before running post install files"
ATTEMPT=1
# wait for mcsadmin getSystemStatus to show active
STATUS=$($MCSDIR/bin/mcsadmin getSystemStatus | tail -n +9 | grep System | grep -v "System and Module statuses")
if [ ! -z $MARIADB_CS_DEBUG ]; then
    echo ""
    echo "wait_for_columnstore_active($ATTEMPT/$MAX_TRIES): getSystemStatus: $STATUS"
else
    echo "."
fi
echo "$STATUS" | grep -q 'System.*ACTIVE'
while [ 1 -eq $? ] && [ $ATTEMPT -le $MAX_TRIES ]; do
    sleep 5
    ATTEMPT=$(($ATTEMPT+1))
    STATUS=$($MCSDIR/bin/mcsadmin getSystemStatus | tail -n +9 | grep System | grep -v "System and Module statuses")
    if [ ! -z $MARIADB_CS_DEBUG ]; then
        echo "wait_for_columnstore_active($ATTEMPT/$MAX_TRIES): getSystemStatus: $STATUS"
    else
        echo "."
    fi
    echo "$STATUS" | grep -q 'System.*ACTIVE'
done
echo "Done."
if [ $ATTEMPT -ge $MAX_TRIES ]; then
    echo "ERROR: ColumnStore did not start after $MAX_TRIES attempts"
    exit 1
fi

# during install the system status can be active but the cs system catalog
# is still being created, so wait for this to complete. This will first
# check that mysqld is running and this is a UM. If this is run from UM2
# or greater it will succeed if the standard error preventing DDL from
# running is reported.
MYSQLDS_RUNNING=$(ps -ef | grep -v grep | grep mysqld | wc -l)
if [ $MYSQLDS_RUNNING -gt 0 ]; then
    echo "Waiting for system catalog to be fully created"
    ATTEMPT=1
    TEST_TABLE="columnstore_info.mcs_wait_test_$RANDOM"
    mysql=( $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot )
    # if [ ! -z "$ROOT_PASSWORD" ]; then
    #   #mysql+=( -p"${ROOT_PASSWORD}" )
    #   export MYSQL_PWD=${ROOT_PASSWORD}
    # fi

    STATUS=$("${mysql[@]}" -e "create table $TEST_TABLE(i tinyint) engine=columnstore;" 2>&1)
    while [ 1 -eq $? ] && [ $ATTEMPT -le $MAX_TRIES ]; do
        if [ ! -z $MARIADB_CS_DEBUG ]; then
            echo "wait_for_columnstore_active($ATTEMPT/$MAX_TRIES): create table test error: $STATUS"
        else 
            echo "."
        fi
        echo "$STATUS" | grep -q "DML and DDL statements for Columnstore tables can only be run from the replication master."
        if [ 0 -eq $? ]; then
            echo "Assuming system ready due to expected non UM1 DDL error: $STATUS"
            exit 0
        fi
        sleep 2
        ATTEMPT=$(($ATTEMPT+1))
        STATUS=$("${mysql[@]}" -e "create table $TEST_TABLE(i tinyint) engine=columnstore;" 2>&1)
    done
    echo "Done"
    "${mysql[@]}" -e "drop table if exists $TEST_TABLE;"
    if [ $ATTEMPT -ge $MAX_TRIES ]; then
        echo "ERROR: ColumnStore not ready for use after $MAX_TRIES attempts, last status: $STATUS"
        exit 1
    else
        echo "System ready"
    fi
fi

# sh /usr/sbin/wait_for_columnstore_active 2>&1
# if [ 1 -eq $? ]; then
#     # exit now if columnstore did not start
#     echo "ERROR: ColumnStore did not start so custom install files not run."
#     exit 1
# fi



MYSQLDS_RUNNING=$(ps -ef | grep -v grep | grep mysqld | wc -l)

if [ $MYSQLDS_RUNNING -gt 0 ]; then
    if [ ! -z "$MARIADB_RANDOM_ROOT_PASSWORD" ]; then
        export MARIADB_ROOT_PASSWORD="$(pwgen -1 32)"
        GENERATED_ROOT=$MARIADB_ROOT_PASSWORD
    fi

    if [ ! -z $MARIADB_CS_DEBUG ]; then
        "${mysql[@]}" -e "SET GLOBAL log_output = 'TABLE';"
        "${mysql[@]}" -e "SET GLOBAL general_log = 'ON';"
    fi
    
    POST_REP_CMD_NO_ROOT+="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MARIADB_ROOT_PASSWORD}'); "           
    POST_REP_CMD+="GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ; "
    #TODO: Create root 
    # create root user, default listens from anywhere
    if [[ -z "$MARIADB_ROOT_HOST" ]] ; then 
        MARIADB_ROOT_HOST='%'
    fi
    # if [ ! -z "$MARIADB_ROOT_HOST" -a "$MARIADB_ROOT_HOST" != 'localhost' ]; then
    #     POST_REP_CMD+="CREATE USER IF NOT EXISTS 'root'@'${MARIADB_ROOT_HOST}' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}' ; "
    #     POST_REP_CMD+="GRANT ALL ON *.* TO 'root'@'${MARIADB_ROOT_HOST}' WITH GRANT OPTION ; "
    # fi
    # POST_REP_CMD+="DROP DATABASE IF EXISTS test ; "
    # POST_REP_CMD+="FLUSH PRIVILEGES ; "
    
    
    # TODO: PArk those for now 
    # Create custom database if specified. CS_DATABASE for backward compat
    # MARIADB_DATABASE="${MARIADB_DATABASE:-$CS_DATABASE}"
    # if [ ! -z "$MARIADB_DATABASE" ]; then
    #         POST_REP_CMD+="CREATE DATABASE IF NOT EXISTS \`$MARIADB_DATABASE\`; "
    # fi

    # if [ "$MARIADB_USER" -a "$MARIADB_PASSWORD" ]; then
    #     POST_REP_CMD+="CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD' ; "
    #     POST_REP_CMD+="GRANT CREATE TEMPORARY TABLES ON infinidb_vtable.* to '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD' ; "
    #     if [ "$MARIADB_DATABASE" ]; then
    #         POST_REP_CMD+="GRANT ALL ON \`$MARIADB_DATABASE\`.* TO '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD' ; "
    #     fi
    # fi
fi
#TODO: Call /usr/sbin/cs_post_init.sh here

CUSTOM_INSTALL_FILES=$(ls $INITDIR/*.{sql,sql.gz,sh} -la 2>/dev/null | wc -l)
echo "$CUSTOM_INSTALL_FILES custom files"
export WRK_DIR=`pwd`
# check for any custom post install sql or shell scripts to run in INITDIR
if [ 0 -eq $CUSTOM_INSTALL_FILES ]; then
    echo "No custom post install files to run at $(date)"
else
    echo "Executing custom post install files at $(date)"
    cd /docker-entrypoint-initdb.d/
    for f in $(ls $INITDIR/); do
        if [[ $f == *.sql ]];then
            echo "Run $f at $(date)"
            "${mysql[@]}" -vvv < $f 2>&1
            if [ 1 -eq $? ]; then
                echo "Script $f failed, aborting setup"
                exit 1
            fi
        elif [[ $f == *.sql.gz ]];then
            echo "Run $f at $(date)"
            zcat $f | "${mysql[@]}" -vvv  2>&1
            if [ 1 -eq $? ]; then
                echo "Script $f failed, aborting setup"
                exit 1
            fi
        elif [[ $f == *.sh ]]; then
            chmod 755 $f
            echo "Run $f at $(date)"
                /bin/sh $f 2>&1
            if [ 1 -eq $? ]; then
                echo "Script $f failed, aborting setup"
                exit 1
            fi
        fi;
    done;
    #TODO: revise this after everything else is working
    # #Tighten the security
    # users_to_be_dropped=$("${mysql[@]}" -r -s -N -e "SELECT CONCAT(\"DROP USER IF EXISTS '\",User,\"'@'\", Host,\"';\") FROM mysql.user WHERE (Password='' AND User NOT IN ('mysql.sys', 'mysqlxsys','root')) OR (User='root' AND Password='' AND NOT (Host LIKE '$SERVER_SUBNET.%' OR  Host='localhost'));"| tr '\n' ' ')
    # execute_sql "$users_to_be_dropped"
fi
cd $WRK_DIR

#TODO: Revise this after everything else is working
# execute_sql "$POST_REP_CMD_NO_ROOT"
# if [ ! -z "$MARIADB_ROOT_PASSWORD" ]; then
#     mysql+=( -p"${MARIADB_ROOT_PASSWORD}" )
# fi
# execute_sql "$POST_REP_CMD"

unset $MARIADB_ROOT_PASSWORD
if [ ! -z $GENERATED_ROOT ]; then
    echo "Generated MariaDB root password is: $GENERATED_ROOT"
fi
echo "Container initialization complete at $(date)"
touch $FLAG

unset MYSQL_PWD
# if [ ! -z $MARIADB_CS_DEBUG ]; then
#     continuous_test
# fi
print_info
run_tests

exit 0;
