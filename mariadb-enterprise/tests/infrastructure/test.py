#!/usr/bin/python3

# Copyright (C) 2019, MariaDB Corporation
# Executes infrastructure tests for a given cluster

import sys, time
import kubernetes.client
from kubernetes import config
from kubernetes.client import CoreV1Api
from kubernetes.stream import stream

def init():
    # Check command line parameter
    if len(sys.argv) < 2:
        print("error: %s MARIADB_CLUSTER" % (sys.argv[0],))
        sys.exit(1)
    global MARIADB_CLUSTER
    MARIADB_CLUSTER=sys.argv[1]
    
    # Load the kubectl config and initialize the API
    config.load_kube_config()
    global v1
    v1 = CoreV1Api() 


def determineTopology():
    serverPods = v1.list_pod_for_all_namespaces(watch=False, label_selector="mariadb=%s,server.mariadb" % (MARIADB_CLUSTER,))
    maxScalePods = v1.list_pod_for_all_namespaces(watch=False, label_selector="mariadb=%s,maxscale.mariadb" % (MARIADB_CLUSTER,))
    umPods = v1.list_pod_for_all_namespaces(watch=False, label_selector="mariadb=%s,um.mariadb" % (MARIADB_CLUSTER,))
    pmPods = v1.list_pod_for_all_namespaces(watch=False, label_selector="mariadb=%s,pm.mariadb" % (MARIADB_CLUSTER,))
    if len(umPods.items) > 0 and len(pmPods.items) > 0:
        return "cs"
    elif len(serverPods.items) > 0 and len(maxScalePods.items) > 0:
        return "server"
    else:
        print("error: no valid topology could be found.\nserver pods found: %d\nmaxscale pods found: %d\ncolumnstore um pods found: %d\ncolumnstore pm pods found: %d" % (len(serverPods.items),len(maxScalePods.items),len(umPods.items),len(pmPods.items)))
        sys.exit(1)


def waitForColumnStoreActive(umPod):
    print("waiting for the UM pod to be active")
    i = 0
    while i < 60:
        resp = v1.read_namespaced_pod(name=umPod.metadata.name, namespace=umPod.metadata.namespace)
        print(resp)
        if resp.status.phase == 'Running':
            break
        time.sleep(1)
        i += 1
    if i >= 60:
        print("error: um pod timed out")
        sys.exit(2)
    print("um pod active")
    i = 0
    exec_command = [ '/usr/local/mariadb/columnstore/bin/mcsadmin', 'getSystemStatus' ]
    while i < 120:
        resp = stream(v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, container='columnstore-module-um', stderr=True, stdin=False, stdout=True, tty=False)
        if 'System        ACTIVE' in resp:
            break
        time.sleep(1)
        i += 1
    if i >= 120:
        print("error: ColumnStore system start timed out")
        sys.exit(2)
    print("ColumnStore system active")


def testStatefulSet():
    umPods = v1.list_pod_for_all_namespaces(watch=False, label_selector="mariadb=%s,um.mariadb" % (MARIADB_CLUSTER,))
    pmPods = v1.list_pod_for_all_namespaces(watch=False, label_selector="mariadb=%s,pm.mariadb" % (MARIADB_CLUSTER,))
    umPod = umPods.items[0]
    waitForColumnStoreActive(umPod)
     
    # Create a sample table
    exec_command = [ '/usr/local/mariadb/columnstore/mysql/bin/mysql', '--defaults-extra-file=/usr/local/mariadb/columnstore/mysql/my.cnf', '-u root', '-e CREATE TABLE IF NOT EXISTS tmp1 (i int) engine=columnstore', 'test' ]
    stream(v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, container='columnstore-module-um', stderr=True, stdin=False, stdout=True, tty=False)
    exec_command = [ '/usr/local/mariadb/columnstore/mysql/bin/mysql', '--defaults-extra-file=/usr/local/mariadb/columnstore/mysql/my.cnf', '-u root', '-e INSERT INTO tmp1 VALUES (42)', 'test' ]
    stream(v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, container='columnstore-module-um', stderr=True, stdin=False, stdout=True, tty=False)
    
    # Restart all nodes
    print("terminating ColumnStore pods")
    for pmPod in pmPods.items:
        v1.delete_namespaced_pod(pmPod.metadata.name, pmPod.metadata.namespace, body=kubernetes.client.V1DeleteOptions())
    for umPod in umPods.items:
        v1.delete_namespaced_pod(umPod.metadata.name, umPod.metadata.namespace, body=kubernetes.client.V1DeleteOptions())
    
    # Verify that the content is still available
    time.sleep(30)
    umPods = v1.list_pod_for_all_namespaces(watch=False, label_selector="mariadb=%s,um.mariadb" % (MARIADB_CLUSTER,))
    umPod = umPods.items[0]
    waitForColumnStoreActive(umPod)
    exec_command = [ '/usr/local/mariadb/columnstore/mysql/bin/mysql', '--defaults-extra-file=/usr/local/mariadb/columnstore/mysql/my.cnf', '-u root', '-e SELECT * FROM tmp1', 'test' ]
    resp = stream(v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, container='columnstore-module-um', stderr=True, stdin=False, stdout=True, tty=False)
    if '42' not in resp:
        print("error: the injected value of 42 was not found in the restartet ColumnStore cluster table test.tmp1")
        sys.exit(2)


def main():
    # Initialize the test construct
    init()
    topology = determineTopology()
    if topology == "cs":
        testStatefulSet()


# Execute main function if started from shell
if __name__ == '__main__':
    main()
