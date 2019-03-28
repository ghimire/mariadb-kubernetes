# Copyright (C) 2019, MariaDB Corporation
# Helper functions for the test suite

import time
import kubernetes.client
from kubernetes import config
from kubernetes.client import CoreV1Api
from kubernetes.stream import stream
import mysql.connector as mariadb

class TestTemplate():
    
    def __init__(self, MARIADB_CLUSTER, MARIADB_HOST, MARIADB_PORT, MARIADB_USER, MARIADB_PASSWORD, DB_NAME, NAMESPACE, COLUMNSTORE_TIMEOUT, SERVER_TIMEOUT, v1, serverPods, maxScalePods, umPods, pmPods, topology, system):
        self.MARIADB_CLUSTER = MARIADB_CLUSTER
        self.MARIADB_HOST = MARIADB_HOST
        self.MARIADB_PORT = MARIADB_PORT
        self.MARIADB_USER = MARIADB_USER
        self.MARIADB_PASSWORD = MARIADB_PASSWORD
        self.DB_NAME = DB_NAME
        self.NAMESPACE = NAMESPACE
        self.COLUMNSTORE_TIMEOUT = COLUMNSTORE_TIMEOUT
        self.SERVER_TIMEOUT = SERVER_TIMEOUT
        self.v1 = v1
        self.serverPods = serverPods
        self.maxScalePods = maxScalePods
        self.umPods = umPods
        self.pmPods = pmPods
        self.topology = topology
        self.system = system


def waitForPodActive(pod, v1, TIMEOUT):
    print("waiting for the pod " + pod.metadata.name + " to be active")
    i = 0
    while i < TIMEOUT:
        try:
            resp = v1.read_namespaced_pod(name=pod.metadata.name, namespace=pod.metadata.namespace)
            if resp.status.phase == 'Running' and resp.metadata.deletion_timestamp == None:
                break
            time.sleep(1)
            i += 1
        except:
            time.sleep(1)
            i += 1
    if i >= TIMEOUT:
        raise Exception("pod " + pod.metadata.name  + " timed out")
    print("pod " + pod.metadata.name + " active")


def waitForServerActive(serverPod, v1, MARIADB_USER, MARIADB_PASSWORD, MARIADB_HOST, MARIADB_PORT, SERVER_TIMEOUT):
    waitForPodActive(serverPod, v1, SERVER_TIMEOUT)
    print("waiting for the Server system to be active")
    i = 0
    brk = False
    while i < SERVER_TIMEOUT:
        try:
            conn = mariadb.connect(user=MARIADB_USER, password=MARIADB_PASSWORD, host=MARIADB_HOST, port=MARIADB_PORT)
            cursor = conn.cursor()
            cursor.execute("SELECT 42")
            row = cursor.fetchone()
            if row is not None and row[0] == 42:
                brk = True
            if brk:
                try:
                    if cursor: cursor.close()
                    if conn: conn.close()
                except Exception:
                    pass
                break
            time.sleep(1)
            i += 1
        except:
            time.sleep(1)
            i += 1
    if i >= SERVER_TIMEOUT:
        raise Exception("Server system start timed out")
    print("Server system active")


def waitForColumnStoreActive(umPod, v1, MARIADB_CLUSTER, COLUMNSTORE_TIMEOUT):
    waitForPodActive(umPod, v1, COLUMNSTORE_TIMEOUT)
    print("waiting for the ColumnStore system to be active")
    i = 0
    exec_command = [ '/usr/local/mariadb/columnstore/bin/mcsadmin', 'getSystemStatus' ]
    while i < COLUMNSTORE_TIMEOUT:
        try:
            if umPod.metadata.name == "%s-mdb-cs-single-0" % (MARIADB_CLUSTER,):
               resp = stream(v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, stderr=True, stdin=False, stdout=True, tty=False)
            else:
               resp = stream(v1.connect_get_namespaced_pod_exec, umPod.metadata.name, umPod.metadata.namespace, command=exec_command, container='columnstore-module-um', stderr=True, stdin=False, stdout=True, tty=False)
            if 'System        ACTIVE' in resp:
                break
            time.sleep(1)
            i += 1
        except:
            time.sleep(1)
            i += 1
    if i >= COLUMNSTORE_TIMEOUT:
        raise Exception("ColumnStore system start timed out")
    print("ColumnStore system active")
