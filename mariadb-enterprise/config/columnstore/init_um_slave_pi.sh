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

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '------------------------------'
    echo 'Starting UM Slave Post Install'
    echo '------------------------------'
    #set -x
fi
MCSDIR=/usr/local/mariadb/columnstore
mysql=( $MCSDIR/mysql/bin/mysql --defaults-extra-file=$MCSDIR/mysql/my.cnf -uroot )
#TODO: configure those IP adresses
${mysql[@]} - e "grant all on *.* to root@10.5.0.1;";
${mysql[@]} - e "grant all on *.* to root@10.5.0.2;";
