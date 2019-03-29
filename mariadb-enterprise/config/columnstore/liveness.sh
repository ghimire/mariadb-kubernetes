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
# file used to track / record initialization and prevent subsequent rerun
FLAG="$MCSDIR/etc/container-initialized"

if [ -e ${MCSDIR}/bin/mcsadmin ]; then
    #Container already initialized
    # check system status
    ${MCSDIR}/bin/mcsadmin getSystemStatus
else
    exit 0
fi