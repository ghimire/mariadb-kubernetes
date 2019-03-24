-- Copyright (c) 2018-2019 MariaDB Corporation Ab
-- 
-- Use of this software is governed by the Business Source License included
-- in the LICENSE.TXT file and at www.mariadb.com/bsl11.
--
-- Change Date: 2022-04-01
-- 
-- On the date above, in accordance with the Business Source License, use
-- of this software will be governed by version 2 or later of the General
-- Public License.

{{- if or (eq .Values.mariadb.cluster.topology "standalone") (eq .Values.mariadb.cluster.topology "masterslave") }}
RESET MASTER;
{{- end }}

CREATE USER '<<REPLICATION_USERNAME>>'@'127.0.0.1' IDENTIFIED BY '<<REPLICATION_PASSWORD>>';
CREATE USER '<<REPLICATION_USERNAME>>'@'%' IDENTIFIED BY '<<REPLICATION_PASSWORD>>';
GRANT ALL ON *.* TO '<<REPLICATION_USERNAME>>'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL ON *.* TO '<<REPLICATION_USERNAME>>'@'%' WITH GRANT OPTION;

CREATE USER '<<ADMIN_USERNAME>>'@'127.0.0.1' IDENTIFIED BY '<<ADMIN_PASSWORD>>';
CREATE USER '<<ADMIN_USERNAME>>'@'%' IDENTIFIED BY '<<ADMIN_PASSWORD>>';
GRANT ALL ON *.* TO '<<ADMIN_USERNAME>>'@'127.0.0.1' WITH GRANT OPTION;
GRANT ALL ON *.* TO '<<ADMIN_USERNAME>>'@'%' WITH GRANT OPTION;

SET GLOBAL max_connections=10000;
SET GLOBAL gtid_strict_mode=ON;
