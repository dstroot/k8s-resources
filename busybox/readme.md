To get into the box:

`kubectl exec -it busybox-pod-name -- /bin/sh`


https://kubernetes.io/docs/user-guide/debugging-pods-and-replication-controllers/

NOTE
----

Every time you write something to container's filesystem, it activates copy on write strategy.

A new storage layer is created using a storage driver (devicemapper, overlayfs or others). In case of active usage, it can put a lot of load on storage drivers, especially in case of Devicemapper or BTRFS.

**Make sure your containers write data only to volumes.** You can use tmpfs for small (as tmpfs stores everything in memory) temporary files:
