#!/usr/bin/python3

# Copyright (C) 2019, MariaDB Corporation
# Executes infrastructure tests for a given cluster

import os, sys, time, importlib
import kubernetes.client
from kubernetes import config
from kubernetes.client import CoreV1Api
from kubernetes.stream import stream
import mysql.connector as mariadb
import helper_functions


DB_NAME = 'test'
NAMESPACE = 'testing'
COLUMNSTORE_TIMEOUT = 120 #seconds
SERVER_TIMEOUT = 120 #seconds


def checkAndSetEnvironmentVariablesAsGlobalVariables(variableName):
    # Check if the environment variable variableName is set
    if os.environ.get(variableName) is not None and os.environ.get(variableName) != "":
        globals()[variableName] = os.environ.get(variableName)
    else:
        print("error: environment variable " + variableName + " not set")
        sys.exit(666)


def init():
    # Set passed environment variables as global variables
    for variable in ["MARIADB_CLUSTER","MARIADB_HOST","MARIADB_USER","MARIADB_PASSWORD"]:
        checkAndSetEnvironmentVariablesAsGlobalVariables(variable)
    
    # Load the kubectl config and initialize the API
    config.load_incluster_config()
    global v1
    v1 = CoreV1Api()
    
    # Get k8s topology information about the cluster to test
    global serverPods
    serverPods = v1.list_namespaced_pod(NAMESPACE, watch=False, label_selector="mariadb=%s,server.mariadb" % (MARIADB_CLUSTER,))
    global maxScalePods
    maxScalePods = v1.list_namespaced_pod(NAMESPACE, watch=False, label_selector="mariadb=%s,maxscale.mariadb" % (MARIADB_CLUSTER,))
    global umPods
    umPods = v1.list_namespaced_pod(NAMESPACE, watch=False, label_selector="mariadb=%s,um.mariadb" % (MARIADB_CLUSTER,))
    global pmPods
    pmPods = v1.list_namespaced_pod(NAMESPACE, watch=False, label_selector="mariadb=%s,pm.mariadb" % (MARIADB_CLUSTER,))
    global topology
    global system
    global MARIADB_PORT
    if len(umPods.items) > 0 and len(pmPods.items) > 0:
        system = "columnstore"
        MARIADB_PORT = 3306
        if umPods.items[0].metadata.name == "%s-mdb-cs-single-0" % (MARIADB_CLUSTER,):
            topology = "columnstore-standalone"
        else:
            topology = "columnstore"
    elif len(serverPods.items) > 0 and len(maxScalePods.items) > 0:
        system = "server"
        MARIADB_PORT = 4006
        if serverPods.items[0].metadata.name == "%s-mdb-galera-0" % (MARIADB_CLUSTER,):
            topology = "galera"
        else:
            topology = "masterslave"
    elif len(serverPods.items) == 1 and len(maxScalePods.items) == 0:
        system = "server"
        topology = "standalone"
        MARIADB_PORT = 3306
    else:
        print("error: no valid topology could be found in namespace %s.\nserver pods found: %d\nmaxscale pods found: %d\ncolumnstore um pods found: %d\ncolumnstore pm pods found: %d" % (NAMESPACE,len(serverPods.items),len(maxScalePods.items),len(umPods.items),len(pmPods.items)))
        sys.exit(666)
    
    # Wait for the database to be active
    if system == "columnstore":
        helper_functions.waitForColumnStoreActive(umPods.items[0], v1, MARIADB_CLUSTER, COLUMNSTORE_TIMEOUT)
    else:
        helper_functions.waitForServerActive(serverPods.items[0], v1, MARIADB_USER, MARIADB_PASSWORD, MARIADB_HOST, MARIADB_PORT, SERVER_TIMEOUT)
    print("")
    
    # Get a SQL connection, and prepare the test database
    error = False
    try:
        conn = mariadb.connect(user=MARIADB_USER, password=MARIADB_PASSWORD, host=MARIADB_HOST, port=MARIADB_PORT)
        cursor = conn.cursor()
        cursor.execute("DROP DATABASE IF EXISTS %s" % (DB_NAME,))
        cursor.execute("CREATE DATABASE IF NOT EXISTS %s" % (DB_NAME,))
    except Exception as e:
        print("error: could not prepare test database '%s'\n%s" % (DB_NAME,e))
        error = True
    finally:
        try:
            if cursor: cursor.close()
            if conn: conn.close()
        except Exception:
            pass
    if error:
        sys.exit(666)


def executeTests():
    failedTests = []
    numberOfTests = 0
    testDirectories = ["global",system]
    testPath = os.path.dirname(os.path.realpath(__file__))
    for testDirectory in testDirectories:
        sys.path.append(os.path.join(testPath,testDirectory))
        print("Executing tests from directory: %s" % (testDirectory,))
        for file in os.listdir(os.path.join(testPath,testDirectory)):
            if file.endswith('.py'):
                numberOfTests += 1
                failed = executeTest(file)
                if failed:
                    failedTests.append("%s/%s" % (testDirectory,file))
                print("")
        sys.path.remove(os.path.join(testPath,testDirectory))
        print("")
    
    print("%d tests failed out of %d" %(len(failedTests),numberOfTests))
    if len(failedTests) > 0:
        print("\nfailed tests:")
        for t in failedTests:
            print("- %s" % (t,))
    
    return len(failedTests)


def executeTest(testFile):
    failed = False
    print("Executing test from file: %s" % (testFile,))
    try:
        testModule = importlib.import_module(testFile[:-3])
        importlib.reload(testModule)
        test = testModule.Test(MARIADB_CLUSTER,MARIADB_HOST,MARIADB_PORT,MARIADB_USER,MARIADB_PASSWORD,DB_NAME,NAMESPACE,COLUMNSTORE_TIMEOUT,SERVER_TIMEOUT,v1,serverPods,maxScalePods,umPods,pmPods,topology,system)
        failed = test.execute()
    except Exception as e:
        print("error: %s" % (e,))
        failed = True
    
    if failed:
        print("Test %s failed" % (testFile,))
    else:
        print("Test %s succeeded" % (testFile,))
    return failed


def cleanup():
    error = False
    try:
        conn = mariadb.connect(user=MARIADB_USER, password=MARIADB_PASSWORD, host=MARIADB_HOST, database=DB_NAME, port=MARIADB_PORT)
        cursor = conn.cursor()
        cursor.execute("DROP DATABASE IF EXISTS %s" % (DB_NAME,))
        cursor.execute("CREATE DATABASE IF NOT EXISTS %s" % (DB_NAME,))
    except Exception as e:
        print("error: could not clean up the test database '%s'\n%s" % (DB_NAME,e))
        error = True
    finally:
        try:
            if cursor: cursor.close()
            if conn: conn.close()
        except Exception:
            pass
    if error:
        sys.exit(666)


def main():
    init()
    numberOfErrors = executeTests()
    if numberOfErrors == 0:
        cleanup()
    sys.exit(numberOfErrors)


# Execute main function that executes the test suite
if __name__ == '__main__':
    main()
