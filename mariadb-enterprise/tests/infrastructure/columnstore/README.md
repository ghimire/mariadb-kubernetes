# Tests executed for MariaDB ColumnStore topologies

| Test                        | Description                                                                                                                            |
+-----------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
| statefulset_mount_test      | Tests if database values are stored persistently in StatefulSets by creating a validation table, injecting some data, restarting       |
|                             | all columnstore nodes, and verifiying that the injected data is still accessible. Unfortunately, ColumnStore tends to not recover      |
|                             | from complete node outages. Therefore, it is possible that the test fails and the ColumnStore cluster is in a non-useable state after  |
|                             | the test.                                                                                                                              |
+-----------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
|                             |                                                                                                                                        |