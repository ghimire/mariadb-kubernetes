# Global tests executed for every topology

| Test                        | Description                                                                                                                            |
+-----------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
| statefulset_mount_test      | Tests if database values are stored persistently in StatefulSets by creating a validation table, injecting some data, restarting       |
|                             | all cluster nodes, and verifiying that the injected data is still accessible. Unfortunately, currently columnstore and galera clusters |
|                             | aren't able to handle a complete node outage and won't recover from it. Therefore, this test currently fails on those topologies.      |
+-----------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
|                             |                                                                                                                                        |