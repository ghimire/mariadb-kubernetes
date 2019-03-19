# Infrastructure test framework

You can add your own infrastructure tests to the sub-directories of this directory.

Tests in the folder `global` are executed for both Server and ColumnStore systems. Tests in the folder `server` are only executed against MariaDB Server clusters and tests in the folder `columnstore` are only executed against MariaDB ColumnStore systems.

## Adding your own Tests

Tests need to inherit the `TestTemplate` from `helper_functions.py` and need to define the `execute` method and return a boolean value if the test failed or not.

Following variables will be inherited from the `TestTemplate` and be ready to use:

| Variable                  | Description                                                                                                                     |
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| self.MARIADB_CLUSTER      | The cluster release name that is going to be tested                                                                             |
| self.MARIADB_HOST         | The hostname of the MariaDB SQL service endpoint                                                                                |
| self.MARIADB_PORT         | The port of the MariaDB SQL service endpoint                                                                                    |
| self.MARIADB_USER         | The username to connect to the MariaDB SQL service endpoint                                                                     |
| self.MARIADB_PASSWORD     | The password to authenticate above's username against the MariaDB SQL service endpoint                                          |
| self.DB_NAME              | The default database name that is used for testing                                                                              |
| self.NAMESPACE            | The namespace in which the target cluster is executed                                                                           |
| self.COLUMNSTORE_TIMEOUT  | Timeout in seconds / retries for MariaDB ColumnStore clusters                                                                   |
| self.SERVER_TIMEOUT       | Timeout in seconds / retries for MariaDB Server clusters                                                                        |
| self.v1                   | Kubernetes Python API endpoint to interact with nodes of `SELF.NAMESPACE`                                                       |
| self.serverPods           | V1PodList of all server pods detected in the cluster                                                                            |
| self.maxScalePods         | V1PodList of all maxscale pods detected in the cluster                                                                          |
| self.umPods               | V1PodList of all um pods detected in the cluster                                                                                |
| self.pmPods               | V1PodList of all pm pods detected in the cluster                                                                                |
| self.topology             | Determined topology of the cluster (i.e. masterslave, galera, standalone, columnstore or columnstore-standalone)                |
| self.system               | Determined system of the cluster (i.e. server or columnstore)                                                                   |
