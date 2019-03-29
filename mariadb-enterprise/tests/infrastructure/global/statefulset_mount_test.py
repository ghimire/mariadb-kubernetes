# Copyright (C) 2019, MariaDB Corporation
# Infrastructure test that tests if StatefulSets that hold the database storage are mounted correctly

import os, sys
import kubernetes.client
from kubernetes.client import CoreV1Api
from kubernetes.stream import stream
import mysql.connector as mariadb
sys.path.append(os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))),".."))
import helper_functions


class Test(helper_functions.TestTemplate):
    def execute(self):
        failed = False
        
        # Create a sample table and inject data
        print("injecting data into table stateful_set_test")
        conn = mariadb.connect(user=self.MARIADB_USER, password=self.MARIADB_PASSWORD, host=self.MARIADB_HOST, database=self.DB_NAME, port=self.MARIADB_PORT)
        cursor = conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS stateful_set_test")
        if self.system == "columnstore":
            cursor.execute("CREATE TABLE IF NOT EXISTS stateful_set_test (v VARCHAR(8)) ENGINE=COLUMNSTORE")
        else:
            cursor.execute("CREATE TABLE IF NOT EXISTS stateful_set_test (v varchar(8))")
        cursor.execute("INSERT INTO stateful_set_test VALUES ('fortytwo')")
        conn.commit()
        cursor.execute("SELECT COUNT(*) cnt FROM stateful_set_test WHERE v='fortytwo'")
        row = cursor.fetchone()
        if row is None or row[0] == 0:
            print("error: the value of 'fortytwo' was not found in table %s.stateful_set_test after the injection" % (self.system, self.topology, self.DB_NAME,))
        cursor.close()
        conn.close()
        
        # Restart all nodes
        print("terminating pods")
        if self.system == "columnstore":
            for umPod in self.umPods.items:
                self.v1.delete_namespaced_pod(umPod.metadata.name, umPod.metadata.namespace, body=kubernetes.client.V1DeleteOptions(), grace_period_seconds=0)
            for pmPod in self.pmPods.items:
                self.v1.delete_namespaced_pod(pmPod.metadata.name, pmPod.metadata.namespace, body=kubernetes.client.V1DeleteOptions(), grace_period_seconds=0)
        else:
            for serverPod in self.serverPods.items:
                self.v1.delete_namespaced_pod(serverPod.metadata.name, serverPod.metadata.namespace, body=kubernetes.client.V1DeleteOptions(), grace_period_seconds=0)
        
        # Wait until the system is active after restart
        if self.system == "columnstore":
            helper_functions.waitForColumnStoreActive(self.umPods.items[0],self.v1,self.MARIADB_CLUSTER,self.COLUMNSTORE_TIMEOUT)
        else:
            helper_functions.waitForServerActive(self.serverPods.items[0],self.v1,self.MARIADB_USER,self.MARIADB_PASSWORD,self.MARIADB_HOST,self.MARIADB_PORT,self.SERVER_TIMEOUT)
        
        # Verify that the content is still available
        print("validating injected data")
        conn = mariadb.connect(user=self.MARIADB_USER, password=self.MARIADB_PASSWORD, host=self.MARIADB_HOST, database=self.DB_NAME, port=self.MARIADB_PORT)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) cnt FROM stateful_set_test WHERE v='fortytwo'")
        row = cursor.fetchone()
        if row is None or row[0] == 0:
            print("error: the injected value of 'fortytwo' was not found in the restartet %s %s topology table %s.stateful_set_test" % (self.system, self.topology, self.DB_NAME,))
            failed = True
        cursor.close()
        conn.close()
        
        return failed
