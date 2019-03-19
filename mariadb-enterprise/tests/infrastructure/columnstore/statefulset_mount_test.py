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
        
        # verify if ColumnStore is standalone or cluster
        umPod = self.umPods.items[0]
        helper_functions.waitForColumnStoreActive(umPod,self.v1,self.MARIADB_CLUSTER,self.COLUMNSTORE_TIMEOUT)
        if umPod.metadata.name == 'my-test-mdb-cs-single-0':
            container = 'columnstore-module-pm'
        else:
            container = 'columnstore-module-um'
        
        # Create a sample table
        print("injecting data into ColumnStore")
        exec_command = [ '/usr/local/mariadb/columnstore/mysql/bin/mysql', '--defaults-extra-file=/usr/local/mariadb/columnstore/mysql/my.cnf', '-u', 'root', '-e', 'CREATE TABLE IF NOT EXISTS tmp1 (v varchar(8)) engine=columnstore', 'test' ]
        stream(self.v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, container=container, stderr=True, stdin=False, stdout=True, tty=False)
        exec_command = [ '/usr/local/mariadb/columnstore/mysql/bin/mysql', '--defaults-extra-file=/usr/local/mariadb/columnstore/mysql/my.cnf', '-u', 'root', '-e', 'INSERT INTO tmp1 VALUES ("fortytwo")', 'test' ]
        stream(self.v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, container=container, stderr=True, stdin=False, stdout=True, tty=False)
        
        # Restart all nodes
        print("terminating ColumnStore pods")
        for umPod in self.umPods.items:
            self.v1.delete_namespaced_pod(umPod.metadata.name, umPod.metadata.namespace, body=kubernetes.client.V1DeleteOptions(), grace_period_seconds=0)
        for pmPod in self.pmPods.items:
            self.v1.delete_namespaced_pod(pmPod.metadata.name, pmPod.metadata.namespace, body=kubernetes.client.V1DeleteOptions(), grace_period_seconds=0)
        
        # Verify that the content is still available
        helper_functions.waitForColumnStoreActive(umPod,self.v1,self.MARIADB_CLUSTER,self.COLUMNSTORE_TIMEOUT)
        print("validating injected data")
        exec_command = [ '/usr/local/mariadb/columnstore/mysql/bin/mysql', '--defaults-extra-file=/usr/local/mariadb/columnstore/mysql/my.cnf', '-u', 'root', '-e', 'SELECT * FROM tmp1', 'test' ]
        resp = stream(self.v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, container=container, stderr=True, stdin=False, stdout=True, tty=False)
        if 'fortytwo' not in resp:
            print(resp)
            print("error: the injected value of 'fortytwo' was not found in the restartet ColumnStore cluster table test.tmp1")
            failed = True
        print("StatefulSet test passed")
        
        return failed
