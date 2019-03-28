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
#
# This script customizes templates based on the parameters passed to a command-line tool
# the path to the target directory needs to be passed as first argument
#
#
#The following environment variables can be utilized to configure behavior:
# MARIADB_ROOT_PASSWORD : specify the password for the root user
# MARIADB_ALLOW_EMPTY_PASSWORD : allow empty password for the root user
# MARIADB_RANDOM_ROOT_PASSWORD : generate a random password for the root user (output to logs). Note: This option takes precedence over MARIADB_ROOT_PASSWORD.
# MARIADB_INITDB_SKIP_TZINFO : skip timezone setup
# MARIADB_ROOT_HOST : host for root user, defaults to '%'
# MARIADB_DATABASE : create a database with this name
# MARIADB_USER : create a user with this name, with all privileges on MARIADB_DATABASE if specified
# MARIADB_PASSWORD : password for above user
# MARIADB_CS_POSTCFG_INPUT : override input values for postConfigure. The default value in the Dockerfile will start up a single server deployment. If the environment variable is empty then postConfigure will not be run and the container will just run the ColumnStore service process ProcMon.
# MARIADB_CS_NUM_BLOCKS_PCT - If set uses this amount of physical memory to utilize for disk block caching. Explicit amounts need to be suffixed with M or G. Will override the default setting of 1024M from Dockerfile.
# MARIADB_CS_TOTAL_UM_MEMORY - If set uses this amount of physical memory to utilize for joins, intermediate results and set operations on the UM. Explicit amounts need to be suffixed with M or G. Will override the default setting of 256M from Dockerfile.
# MARIADB_DROP_LOCAL_USERS : Drop anonymous local users, useful for removing this on non um1 um containers.



function check_true(){
    if [ ! "$1" == "True" ] && [ ! "$1" == "true" ] && [ ! "$1" == "1" ]; then
        echo ""
    else
        echo 1
    fi
}

ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
REPL_USER=$(cat /mnt/secrets/repl-username)
REPL_PWD=$(cat /mnt/secrets/repl-password)
DB_HOST="$(hostname -f | cut -d '.' -f 1).$(hostname -f | cut -d '.' -f 2)"
export MARIADB_CS_DEBUG=$(check_true {{ .Values.mariadb.debug }})
RELEASE_NAME={{ .Release.Name }}
#Get last digit of the hostname
MY_HOSTNAME=$(hostname)
SPLIT_HOST=(${MY_HOSTNAME//-/ }); 
CONT_INDEX=${SPLIT_HOST[(${#SPLIT_HOST[@]}-1)]}

MY_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

function expand_templates() {
    sed -e "s/<<MASTER_HOST>>/${MASTER_HOST}/g" \
        -e "s/<<ADMIN_USERNAME>>/${ADMIN_USER}/g" \
        -e "s/<<ADMIN_PASSWORD>>/${ADMIN_PWD}/g" \
        -e "s/<<REPLICATION_USERNAME>>/${REPL_USER}/g" \
        -e "s/<<REPLICATION_PASSWORD>>/${REPL_PWD}/g" \
        -e "s/<<RELEASE_NAME>>/${RELEASE_NAME}/g" \
        -e "s/<<CLUSTER_ID>>/${CLUSTER_ID}/g" \
        -e "s/<<MARIADB_CS_DEBUG>>/${MARIADB_CS_DEBUG}/g" \
        -e "s/<<MARIADB_CS_USE_FQDN>>/${MARIADB_CS_USE_FQDN}/g" \
        -e "s/<<MARIADB_CS_NUM_BLOCKS_PCT>>/${MARIADB_CS_NUM_BLOCKS_PCT}/g" \
        -e "s/<<MARIADB_CS_TOTAL_UM_MEMORY>>/${MARIADB_CS_TOTAL_UM_MEMORY}/g" \
        $1
}

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '------------------------'
    echo 'Init CS Single Node'
    echo '------------------------'
    echo 'IP:'$MY_IP
    #set -x
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

expand_templates /mnt/config-template/start-mariadb-instance.sh >> /mnt/config-map/start-mariadb-instance.sh

if [[ ! -z $MARIADB_CS_DEBUG ]]; then
    echo "Init Columnstore"
    echo "$MARIADB_CS_NODE:$MARIADB_CS_MASTER"
    echo "Columnstore Init"
    echo "-----------------"
fi

# initialize users on the first run of a UM
if [[ ! -d /usr/local/mariadb/columnstore/mysql/db/mysql ]]; then
    # it's the first run, ensure maxscale user is initialized
    expand_templates /mnt/config-template/users.sql >> /docker-entrypoint-initdb.d/01-init.sql
fi

expand_templates /mnt/config-template/init_singlenode.sh >> /mnt/config-map/cs_init.sh
{{- if .Values.mariadb.columnstore.test}}
expand_templates /mnt/config-template/test_cs.sh >> /mnt/config-map/test_cs.sh
expand_templates /mnt/config-template/initdb.sql >> /mnt/config-map/initdb.sql
{{- end }}
{{- if .Values.mariadb.columnstore.sandbox}}
expand_templates /mnt/config-template/02_load_bookstore_data.sh >> /mnt/config-map/02_load_bookstore_data.sh
{{- end }}
