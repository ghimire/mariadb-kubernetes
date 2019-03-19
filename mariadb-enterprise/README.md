# MariaDB Kubernetes MaxScale Master Slave using StatefulSets

## Overview

This directory contains kubernetes stateful set scripts to install a 3 node master slave cluster fronted by an Active/Passive pair of MaxScale nodes. The cluster can be deployed using helm or alternatively using shell / powershell kubectl wrapper scripts. The scripts should be considered alpha quality at this stage and is not recommended for production deployments.  

## Local Kubernetes Installations

The scripts can be deployed against a cloud kubernetes deployment such as Google Kubernetes Engine or alternatively using one of several local vm based kubernetes frameworks such as minikube for Windows and Mac or microk8s for Ubuntu / Linux.

### Installing microk8s on Ubuntu

**microk8s** is a lightweight kubernetes install that can be installed using the cross platform snap utility but most optimally on Ubuntu.

The following steps will install microk8s, helm, and configure it for dns, dashboard, and storage:

```sh
sudo snap install microk8s --beta --classic
sudo snap install helm --classic
sudo snap install kubectl --classic
microk8s.enable dns dashboard storage
helm init
```

After installation the kubernetes dashboard application may be accessed at:
http://localhost:8080/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

### Installing minikube on Windows 10

- If you are running Windows 10 Professional enable Hyper-V virtualization. For other versions install VirtualBox as the virtualization software.
- Download minikube for windows from: https://github.com/kubernetes/minikube/releases and rename to minikube.exe and add to a directory in your path.
- Download kubectl and add to the same directory, using the latest link here:https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl
- Download helm and tiller and add to the same directory: https://github.com/helm/helm/releases
- If you are utilizing Hyper-V, create an external switch in hyper-v virtual switch manager named ExternalSwitch configured to use external networking.

To initialize minikube for VirtualBox:

```sh
minikube start
```

To initialize minikube for Hyper-V:

```sh
minikube start --vm-driver hyperv --hyperv-virtual-switch "ExternalSwitch"
```

After installation the kubernetes dashboard application may be accessed by running:

```sh
minikube dashboard
```

To initialize helm:

```sh
helm init
```

### Installing minikube on MacOS X (High Sierra)

#### Install Homebrew

Homebrew is a external package manager for OSX it is required for the installation of some of the components below.(Homebrew is not the only way to install those for more information refer to [Other ways to install k8s](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-macports-on-macos)

Open your Terminal app. Press cmd+space and type terminal.app

Type the following command in the terminal window.

```$ /usr/bin/ruby -e “$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)”```

This will start Homebrew installation (Xcode Command Line Tools are a dependency which will be installed or updated in the process).

#### Install Hypervisor

A hypervisor is required for the Kubectl to work on OSX. the popular options are  VirtualBox or VMware Fusion, or HyperKit. This guide will do the installations with VirtualBox

##### VirtualBox

Download the [VirtualBox for OSX](https://download.virtualbox.org/virtualbox/5.2.18/VirtualBox-5.2.18-124319-OSX.dmg) package and follow the instructions. OSX may require allowing this package in security & privacy section.

![Allow button location](screen1.jpg)

[Other Install Options](https://www.virtualbox.org/wiki/Downloads)

#### Install Kubernetes command-line tool (kubectl)

Install kubectl by typing the following Homebrew command in a terminal window.

```$ brew install kubernetes-cli```

#### Install Minikube

Install minikube by typing the following Homebrew command in a terminal window.

```bash
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

You can also use another version of [minikube](https://github.com/kubernetes/minikube/releases).

#### Start Minikube

Minikube can be started using the following command

```sh
minikube start
```

To stop the cluster use:

```sh
minikube stop
```

## Running the Master Slave plus MaxScale Cluster

### Installation Prerequisites

It is highly advisable to have an NFS server set up in order to use the backup and restore functionality provided. Here is a simple NFS server example running in Kubernetes that can be used for testing. For production, an NFS server that doesn't live in Kubernetes might be a better approach.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nfs-test
  labels:
    app: nfs-test
spec:
  containers:
  - name: nfs
    image: itsthenetwork/nfs-server-alpine
    env:
    - name: SHARED_DIRECTORY
      value: /nfs
    volumeMounts:
    - name: data
      mountPath: /nfs
    securityContext:
      privileged: true
  volumes:
  - name: data
    emptyDir: {}
```

To use the above code, save it in an `.yaml` file (for example `nfs-test.yaml`). Then run the following command:

```sh
  kubectl create -f nfs-test.yaml
```

You can then find the NFS server's IP by running

```sh
  kubectl describe pod nfs-test
```

### Installing the Cluster with Helm

Helm provides a simple means of installation and is the *recommended* approach. To install the cluster, run the below command, specifying your own unique release name (<release-name>). The <release-name> is also used as a prefix for all objects in Kubernetes related to the installed release:

```sh
helm install . --name <release-name>
```

To review installed releases:

```sh
helm list
```

To remove a helm release:

- if just you want to delete the cluster (You can't use the same cluster `<release-name>` in the future)

  ```sh
  helm delete <release-name>
  ```

- if you want to delete the cluster and delete it's name from the Helm cache (this will allow you to reuse the same `<release-name>` again)

  ```sh
  helm delete <release-name> --purge
  ```

The cluster topology can be specified by changing the `mariadb.cluster.topology` value in the `values.yaml` file or directly overriding it when running the `helm` command:

- with NFS connection (allows to perform backup in the future)

  ```sh
  helm install . --name <release-name> --set mariadb.cluster.topology=masterslave --set mariadb.server.backup.nfs.server=<NFS_SERVER_IP>
  ```

- without NFS connection (the build in backup functionality can't be used)

  ```sh
  helm install . --name <release-name> --set mariadb.cluster.topology=masterslave
  ```

Possible values are `masterslave`, `standalone` and `galera`. Default is `masterslave`.  
Any value in the `values.yaml` file can be overridden this way.  

## Parameterization

The following list of parameters can be used with the helm chart by either modifying the file `values.xml` or through the command line switch `--set <parameter name>=<value>`:

| Parameter                                  | Default                  | Description                                                                                                         |
|--------------------------------------------|--------------------------|---------------------------------------------------------------------------------------------------------------------|
| _Global for the cluster_                                                                                                                                                                    |
| mariadb.cluster.id                         | null                     | A generated unique ID of the cluster (used as a label on all artefacts) for discovery in multi-tenant environments. |
| Mariadb.cluster.topology                   | masterslave              | The type of cluster to create, one of: masterslave, galera, standalone, columnstore, columnstore-standalone  |
| mariadb.cluster.labels                     | null                     | An associative array of custom labels in format name:value added to the cluster endpoint                            |
| mariadb.cluster.annotations                | null                     | An associative array of custom annotations added to each pod in the topology                                        |
| _Server instances_                         |                          |                                                                                                                     |
| mariadb.server.users.admin.username        | admin                    | MariaDB admin user                                                                                                  |
| mariadb.server.users.admin.password        | 5LVTpbGE2cGFtw69         | MariaDB admin password                                                                                              |
| mariadb.server.users.replication.username  | repl                     | Replication user name                                                                                                |
| mariadb.server.users.replication.password  | 5LVTpbGE2cGFtw69         | Replication user password                                                                                           |
| mariadb.server.storage.class               | null                     | Storage class specification of data volume                                                                          |
| mariadb.server.storage.size                | 256Mi                    | Size of data volume                                                                                                 |
| mariadb.server.replicas                    | 3                        | Number of server instances in Master/Slave and Galera topologies. Fixed at 1 in Standalone topology.                |
| mariadb.server.image                       | mariadb/server:10.3      | Name of Docker image for MariaDB Server                                                                             |
| mariadb.server.port                        | 3306                     | TCP/IP port on which each MariaDB Server instance exposes a SQL interface.                                          |
| mariadb.server.labels                      | null                     | An associative array of custom labels in format name:value added to Server pods only                                |
| mariadb.server.annotations                 | null                     | An associative array of custom annotations in format name:value added to Server pods only                           |
| mariadb.server.resources.requests.cpu      | null                     | The requested share of CPU for each Server pod                                                                      |
| mariadb.server.resources.requests.memory   | null                     | The requested memory for each Server pod                                                                            |
| mariadb.server.resources.limits.cpu        | null                     | The maximum share of CPU for each Server pod                                                                        |
| mariadb.server.resources.limits.memory     | null                     | The maximum share of memory for each Server pod                                                                     |
| mariadb.server.backup.nfs.server           | null                     | Backup NFS server host                                                                                              |
| mariadb.server.backup.nfs.path             | /                        | Backup NFS server path to mount                                                                                     |
| mariadb.server.backup.nfs.restoreFrom      | null                     | Subdirectory to use to restore the database on initial startup                                                      |
| _MaxScale instances_                       |                          |                                                                                                                     |
| mariadb.maxscale.image                     | mariadb/maxscale:2.2     | Name of Docker image for MaxScale                                                                                   |
| mariadb.maxscale.ports.readonly            | 4008                     | TCP/IP port on which the cluster instance exposes a read-only SQL interface through a service endpoint.             |
| mariadb.maxscale.ports.readwrite           | 4006                     | TCP/IP port on which the cluster instance exposes a read-write SQL interface through a service endpoint.            |
| mariadb.maxscale.labels                    | null                     | An associative array of custom labels in format name:value added to MaxScale pods only                              |
| mariadb.maxscale.annotations               | null                     | An associative array of custom annotations in format name:value added to MaxScale pods only                         |
| mariadb.maxscale.replicas                  | 2                        | Number of MaxScale instances in Master/Slave and Galera topologies.                                                 |
| mariadb.maxscale.resources.requests.cpu    | null                     | The requested share of CPU for each MaxScale pod                                                                    |
| mariadb.maxscale.resources.requests.memory | null                     | The requested memory for each MaxScale pod                                                                          |
| mariadb.maxscale.resources.limits.cpu      | null                     | The maximum share of CPU for each MaxScale pod                                                                      |
| mariadb.maxscale.resources.limits.memory   | null                     | The maximum share of memory for each MaxScale pod                                                                   |
| *StateStore instances*                     |                          |                                                                                                                     |
| mariadb.statestore.image                   | mariadb/statestore:0.0.3 | Name of Docker image for MariaDB StateStore                                                                         |
| *Columnstore instances*                    |                          |                                                                                                                     |
| mariadb.columnstore.image                  | nastybuff/cs:1.2.3       | Name of Docker image for MariaDB Columnstore                                                                         |
| mariadb.columnstore.numBlocksPct           | 1024М                    | Amount of physical memory to utilize for disk block caching                                                   |
| mariadb.columnstore.totalUmMemory          | 1G                       | Amount of physical memory to utilize for joins, intermediate results and set operations on the UM         |
| mariadb.columnstore.um.replicas            | 1                        | Number of Columnstore UM instances in columnstore topology                                                  |
| mariadb.columnstore.pm.replicas            | 3                        | Number of Columnstore PM instances in columnstore topology                                                  |

Refer to https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container for the definition of resource requests and limits.

## Supported topologies

The following topologies are currently supported:

* Standalone: a single MariaDB Server instance;
* Master/Slave: 1 master MariaDB Server instance replicated to 2 slave MariaDB instances, fronted by 2 MaxScale instances in a load-balanced configuration. MaxScale provides automated failover for the master. The number of running MariaDB Server instances can be managed at runtime;
* Galera: 3 MariaDB instances in a Master/Master replication configuration (Galera cluster), fronted by 2 MaxScale instances in a load-balanced configuration. The number of running MariaDB Server instances can be managed at runtime;
* Columnstore-Standalone: a single MariaDB ColumnStore instance with 1 UM and 1 PM running on the same pod;
* Columnstore: MariaDB ColumnStore with 1 UM and 3 PMs running on separate pods.

## Using the cluster

To access the MaxScale node locally, follow the below steps:

1)find the ip address of the service:

```sh
kubectl get services
```

The output will look something like:

```sh
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
kubernetes      ClusterIP   10.152.183.1     <none>        443/TCP             40m
<release-name>-mariadb     ClusterIP   10.152.183.135   <none>        4006/TCP,4008/TCP   28m
<release-name>-mdb-clust   ClusterIP   None             <none>        3306/TCP            28m
<release-name>-mdb-state   ClusterIP   10.152.183.129   <none>        80/TCP              28m
```

Use the `ClusterIP` for `<release-name>-mariadb` as the host to connect to. The following ports are mapped to the local host in `Master/Slave` and `Galera` topologies:

- 4006: MaxScale ReadWrite Listener
- 4008: MaxScale ReadOnly Listener

and for `Standalone`, `Columnstore` and `Columnstore-standalone` topologies:

- 3306: MariaDB Server

2) get mysql shell connected to the cluster 
(the user and password comes from the helm chart `values.yaml`):

```sh
kubectl exec -it <release-name>-mdb-ms-0 -- mysql -uadmin -p5LVTpbGE2cGFtw69 -P4006 -h <ClusterIP>
kubectl exec -it <release-name>-mdb-ms-0 -- mysql -uadmin -p5LVTpbGE2cGFtw69 -P4008 -h <ClusterIP>
```

Applications deployed in the same namespace in Kubernetes can also access the cluster using the hostname `<release-name>-mariadb`. This is the only connectivity option available for a headless service.

## Using the Backup/Restore functionality

You can backup an already running cluster or initialize a new cluster with an existing backup. Only the Master/Slave, Galera, and Standalone topologies are currently supported.

### Backup

#### Backup Prerequisites

You need a running MariaDB cluster connected to an NFS server.  
The `Installation Prerequisites` and `Installing the Cluster with Helm` sections contain more information about this.

#### Backup procedure

run in terminal

```sh
kubectl exec -it <name_of_the_pod_to_backup> -- bash /mnt/config-map/backup-save.sh
```

Near the start of the log you can find the name of the folder where your backup will be stored on the NFS server. The format is `backup-<pod-name>-<backup_date>`.

### Restore

You can use an existing backup and load it when starting a new cluster. Restoring always creates a new cluster. Restoring into a running cluster is not possible.

#### Restore Prerequisites

- an existing backup located in an NFS volume

#### Restore procedure

1. Change these values in the values.yaml file:
    - `mariadb.server.backup.restoreFrom` should point to the exact directory containing the backup.
    - `mariadb.server.backup.nfs.server` should be the IP of hostname of the NFS server
    - `mariadb.server.backup.nfs.path` should be the NFS mount point (optional, default is `"/"`)
2. Start the cluster as you would normally using
    ```sh
    helm install .
    ```
3. The above as a single command:
    ```sh
    helm install . --name <release-name> --set mariadb.server.backup.restoreFrom=<backup_path> --set mariadb.server.backup.nfs.server=<nfs_server_ip> --set mariadb.server.backup.nfs.path=<nfs_mount_point>
    ```

## Running Sanity Test, infrastructure tests and Benchmark tests

The `tests` folder contains support for running sanity-level deployment tests, based on the mysql-test framework (https://mariadb.com/kb/en/library/mysqltest/), and benchmarking, based on sysbench (https://github.com/akopytov/sysbench/tree/1.0), against an existing MariaDB cluster in Kubernetes. It also includes a framework for infrastructure tests to simulate infrastructure failures like node outages. Tests can be run using the Unix `make` command.

### Pre-requisites

In order to be able to execute the `make` command for running a test or a benchmark, the following tools must be installed:

* make
* docker (v17+)
* kubernetes client (v1.9+), configured to access the Kubernetes cluster where MariaDB will runs as cluster admin

Note: before running `make`, ensure that a MariaDB cluster must be created and is in an operational state.
Note: Sanity tests and benchmarks should only be run against clusters that have at least 5GB of storage available (option `--set mariadb.server.storage.size=5Gi` on the `helm install` command line).
Note: Infrastructure tests require to be executed in the `testing` namespace with a k8s service account `tester` bound to the (RBAC) role of `admin` in the regarding namespace.

### Running a Sanity Test

The sanity test loads a simulated Bookstore database (refer to https://github.com/mariadb-corporation/mariadb-server-docker/blob/master/tx_sandbox/labs.md for details) and runs a number of pre-defined aggregation queries to verify that results are as expected. In order to run a sanity-level deployment test, execute the following command:

```$ make test MARIADB_CLUSTER=<release-name>```

This will build a docker image, push it into the remote Docker repo and create a pod named `<release-name>-sanity-test` that will connect to an existing MariaDB cluster named `<release-name>` and will execute the test framwork. You can track the progress of the test run by running:

```$ kubectl logs <release-name>-sanity-test -f``` 

### Running the Infrastructure Test

The infrastructure test executes the tests deposited in `infrastructure/global` for every deployed cluster, and specific tests for MariaDB Server and MariaDB ColumnStore clusters respectively from `infrastructure/server` or `infrastructure/columnstore`. Details about those tests can be found in the README.md of these directories. The infrastructure test requires the cluster to test to be started in the `testing` namespace. In order to execute the infrastructure test, execute the following command:

```$ make infrastructure-test MARIADB_CLUSTER=<release-name>```

This will build a docker image, push it into the remote Docker repo and create a pod named `<release-name>-infrastructure-test` that will connect to an existing MariaDB cluster named `<release-name>` and will execute the test framwork. You can track the progress of the test run by running:

```$ kubectl logs <release-name>-Infrastructure-test -f``` 

### Running a Benchmark

The benchmark test runs a standard `sysbench` OLTP workload with 20 tables and 100,000 rows each that executes a mix of 90% reads (point, range, and aggregate SELECTs) to 10% writes (INSERTs, UPDATEs and DELETEs) in 16 concurrent threads. In order to run a benchmark, execute the following command:

```$ make benchmark MARIADB_CLUSTER=<release-name>```

This will build a docker image, push it into a remote repo and create a pod named `<release-name>-sysbench-test` that will connect to an existing MariaDB cluster named `<release-name>` and will execute sysbench. You can track the progress by running:

```$ kubectl logs <release-name>-sysbench-test -f```

You can optionally specify the number of threads by adding `THREADS=<number of threads>` (by default `<number of threads>`=16) on the `make` command line.

### Parameters

The following parameters can be used to alter the behaviors of `make`, by adding them to the command line in the format `<parameter>=<value>`:

| Parameter                                  | Default                  | Description                                                                                                         |
|--------------------------------------------|--------------------------|---------------------------------------------------------------------------------------------------------------------|
| DOCKER_REPO                                | gcr.io/dbaas-development | The remote Docker repo from which your Kubernetes cluster will pull images.                                         |
| MARIADB_CLUSTER                            | sa-test                  | The name of an existing MariaDB cluster on Kubernetes to be tested or benchmarked                                  |
| THREADS                                    | 16                       | Number of concurrent connections that will be used while running the benchmark.                                    |
