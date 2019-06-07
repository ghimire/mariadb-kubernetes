# MariaDB Kubernetes 

This repository provides a HelmChart for deploying MariaDB in Kubernetes clusters.  It is optimized to support multiple topologies, including MariaDB Server with MaxScale in replication and cluster environments for transactional workloads, as well as MariaDB ColumnStore for analytical workloads.

> **Note**: MariaDB Kubernetes is an early-access release.  It is strongly recommended that you *not* use this release in production environments.  We are currently testing it for stability with a few customers.  Contact MariaDB Corporation for production support.


## Download

In order to use MariaDB Kubernetes, clone the repository onto your system using Git or the download link:


```
$ git clone https://github.com/mariadb-corporation/mariadb-kubernetes
```

Then use Helm to install MariaDB Kubernetes in your cluster:

```
$ helm install mariadb-enterprise/ --name my_cluster
```


## Documentation

For complete documentation of the MariaDB Kubernetes, its installation, configuration, and usage, see the [MariaDB Knowledge Base](http://mariadb.com/kb/en/library/kubernetes).
