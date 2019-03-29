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

set -e
MCSDIR=/usr/local/mariadb/columnstore
MCSBINDIR=$MCSDIR/mysql/bin
# file used to track / record initialization and prevent subsequent rerun
FLAG="$MCSDIR/etc/container-initialized"
# /usr/local/mariadb/columnstore/mysql/bin/mysql -h 127.0.0.1 "select 1"
if [ -e $FLAG ] && [ -e ${MSCBINDIR}/mcsadmin]; then
    #Container already initialized
    # check system status
    ${MSCBINDIR}/mcsadmin getSystemStatus | tail -n +9 | grep System | grep -v "System and Module statuses" | grep -q 'System.*ACTIVE'
    ${MSCBINDIR}/mysql -h 127.0.0.1 "select 1"
    exit 0
fi


