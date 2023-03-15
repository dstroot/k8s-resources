# Recipe: Redis

Redis is an open source (BSD licensed), in-memory data structure store, used as database, cache and message broker.

### Considerations

In general I am a bit old school and prefer to run data persistence / management applications outside of Kubernetes.  They generally already have various types of high availability built in, and they also tend to require very specific kernel tuning and storage to run optimally.   

Redis falls into this category.  It has it's own clustering and high availability functionality. In addition it requires very specific kernel parameters.  

This recipe will deploy Redis in a very simple manner but will leverage the capabilities of Kubernetes for a reasonably available service.  We will run a single instance of Redis backed by persistent storage using both RDB and AOF data persistence models.  If Redis were to crash under this configuration at most one second of writes could be lost and Kubernetes will automatically restart Redis.

### Data Persistence

We need to use persistent storage for the disk that Redis will use. For example on Google you can easily create a persistent disk with this command:

```
$ gcloud compute disks create --size 10GB redis-master
```

Redis offers two types of data persistence, RDB and AOF. The general indication is that you should use both persistence methods if you want a degree of data safety comparable to what PostgreSQL can provide you.

#### RDB

* RDB is a very compact single-file point-in-time representation of your Redis data. RDB files are perfect for backups and disaster recovery. For instance you may want to archive your RDB files every hour for the latest 24 hours, and to save an RDB snapshot every day for 30 days. This allows you to easily restore different versions of the data set in case of disasters.
* RDB allows faster restarts with big datasets compared to AOF.

#### AOF

* Using AOF Redis is much more durable: you can have different fsync policies such as fsync every second, or fsync at every query. With the default policy of fsync every second write performance is still great and you can only lose one second worth of writes.
* The AOF log is an append only log, so there are no seeks, nor corruption problems if there is a power outage. Even if the log ends with an half-written command for some reason (disk full or other reasons) the redis-check-aof tool is able to fix it easily.

### Kubernetes Versions

Tested on version 1.3.2

# Ingredients

Recommendations:
* When available we prefer the use of official images.
* Always use specified versions
* Use the smallest image possible (generally the alpine variant.)

Official Image: [Redis](https://hub.docker.com/_/redis/)

Example:

```
- name: redis
  image: redis:3.2.1-alpine
```

# Preparation

### Prerequisites

This recipe assumes that you have a Kubernetes cluster installed and running, and that you have installed the `kubectl` command line tool somewhere in your path.

You can also test this using `minikube` if you have it installed locally.





https://clusterhq.com/2016/02/11/kubernetes-redis-cluster/

https://cloud.google.com/container-engine/docs/tutorials/guestbook

kubectl exec -t -i redis-master-3143533083-9torc redis-cli


## Configuring Redis Docker Hosts

http://serverfault.com/questions/271380/how-can-i-increase-the-value-of-somaxconn
https://github.com/kubernetes/kubernetes/issues/5095
https://www.techandme.se/performance-tips-for-redis-cache-server/
http://redis.io/topics/admin
https://github.com/kubernetes/kubernetes/pull/27180
https://github.com/kubernetes/kubernetes/pull/26057
https://github.com/sttts/kubernetes/blob/05912e7e2eec208f38ac8af6bff9704f55d24587/docs/proposals/sysctl.md


WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.

Check this value ssh into the GCE hosts and use this command: `cat /proc/sys/net/core/somaxconn`

To change it use `sudo /sbin/sysctl -w net.core.somaxconn=1024` and edit sysctl.conf to make it permanent.

```
cd /etc
sudo nano sysctl.conf
```

and add `net.core.somaxconn = 1024` to bottom of sysctl.conf then save it (cntl x, y)


WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' as root, and add it to your /etc/rc.local in order to retain the setting after a reboot. Redis must be restarted after THP is disabled.

Make sure to disable Linux kernel feature transparent huge pages, it will affect greatly both memory usage and latency in a negative way. This is accomplished with the following command: echo never > /sys/kernel/mm/transparent_hugepage/enabled.

`sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled`

```
sudo su -
sudo /sbin/sysctl -w net.core.somaxconn=1024
sudo echo 1024 > /proc/sys/net/core/somaxconn
```

Add vm.overcommit_memory = 1 to /etc/sysctl.conf and then reboot or run the command sysctl vm.overcommit_memory=1 for this to take effect immediately.

`/sbin/sysctl vm.overcommit_memory=1`


```
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# added the following two lines
echo never > /sys/kernel/mm/transparent_hugepage/enabled
sysctl -w net.core.somaxconn=1024

[ -x /sbin/initctl ] && initctl emit --no-wait google-rc-local-has-run || true
exit 0
```






## Reliable, Scalable Redis on Kubernetes

The following document describes the deployment of a reliable, multi-node Redis on Kubernetes.  It deploys a master with replicated slaves, as well as replicated redis sentinels which are use for health checking and failover.

### Prerequisites

This example assumes that you have a Kubernetes cluster installed and running, and that you have installed the ```kubectl``` command line tool somewhere in your path.  Please see the [getting started](../../../docs/getting-started-guides/) for installation instructions for your platform.

### A note for the impatient

This is a somewhat long tutorial.  If you want to jump straight to the "do it now" commands, please see the [tl; dr](#tl-dr) at the end.

### Turning up an initial master/sentinel pod.

A [_Pod_](../../../docs/user-guide/pods.md) is one or more containers that _must_ be scheduled onto the same host.  All containers in a pod share a network namespace, and may optionally share mounted volumes.

We will used the shared network namespace to bootstrap our Redis cluster.  In particular, the very first sentinel needs to know how to find the master (subsequent sentinels just ask the first sentinel).  Because all containers in a Pod share a network namespace, the sentinel can simply look at ```$(hostname -i):6379```.

Here is the config for the initial master and sentinel pod: [redis-master.yaml](redis-master.yaml)


Create this master as follows:

```sh
kubectl create -f examples/storage/redis/redis-master.yaml
```

### Turning up a sentinel service

In Kubernetes a [_Service_](../../../docs/user-guide/services.md) describes a set of Pods that perform the same task.  For example, the set of nodes in a Cassandra cluster, or even the single node we created above.  An important use for a Service is to create a load balancer which distributes traffic across members of the set.  But a _Service_ can also be used as a standing query which makes a dynamically changing set of Pods (or the single Pod we've already created) available via the Kubernetes API.

In Redis, we will use a Kubernetes Service to provide a discoverable endpoints for the Redis sentinels in the cluster.  From the sentinels Redis clients can find the master, and then the slaves and other relevant info for the cluster.  This enables new members to join the cluster when failures occur.

Here is the definition of the sentinel service: [redis-sentinel-service.yaml](redis-sentinel-service.yaml)

Create this service:

```sh
kubectl create -f examples/storage/redis/redis-sentinel-service.yaml
```

### Turning up replicated redis servers

So far, what we have done is pretty manual, and not very fault-tolerant.  If the ```redis-master``` pod that we previously created is destroyed for some reason (e.g. a machine dying) our Redis service goes away with it.

In Kubernetes a [_Replication Controller_](../../../docs/user-guide/replication-controller.md) is responsible for replicating sets of identical pods.  Like a _Service_ it has a selector query which identifies the members of it's set.  Unlike a _Service_ it also has a desired number of replicas, and it will create or delete _Pods_ to ensure that the number of _Pods_ matches up with it's desired state.

Replication Controllers will "adopt" existing pods that match their selector query, so let's create a Replication Controller with a single replica to adopt our existing Redis server. Here is the replication controller config: [redis-controller.yaml](redis-controller.yaml)

The bulk of this controller config is actually identical to the redis-master pod definition above.  It forms the template or "cookie cutter" that defines what it means to be a member of this set.

Create this controller:

```sh
kubectl create -f examples/storage/redis/redis-controller.yaml
```

We'll do the same thing for the sentinel.  Here is the controller config: [redis-sentinel-controller.yaml](redis-sentinel-controller.yaml)

We create it as follows:

```sh
kubectl create -f examples/storage/redis/redis-sentinel-controller.yaml
```

### Scale our replicated pods

Initially creating those pods didn't actually do anything, since we only asked for one sentinel and one redis server, and they already existed, nothing changed.  Now we will add more replicas:

```sh
kubectl scale rc redis --replicas=3
```

```sh
kubectl scale rc redis-sentinel --replicas=3
```

This will create two additional replicas of the redis server and two additional replicas of the redis sentinel.

Unlike our original redis-master pod, these pods exist independently, and they use the ```redis-sentinel-service``` that we defined above to discover and join the cluster.

### Delete our manual pod

The final step in the cluster turn up is to delete the original redis-master pod that we created manually.  While it was useful for bootstrapping discovery in the cluster, we really don't want the lifespan of our sentinel to be tied to the lifespan of one of our redis servers, and now that we have a successful, replicated redis sentinel service up and running, the binding is unnecessary.

Delete the master as follows:

```sh
kubectl delete pods redis-master
```

Now let's take a close look at what happens after this pod is deleted.  There are three things that happen:

  1. The redis replication controller notices that its desired state is 3 replicas, but there are currently only 2 replicas, and so it creates a new redis server to bring the replica count back up to 3
  2. The redis-sentinel replication controller likewise notices the missing sentinel, and also creates a new sentinel.
  3. The redis sentinels themselves, realize that the master has disappeared from the cluster, and begin the election procedure for selecting a new master.  They perform this election and selection, and chose one of the existing redis server replicas to be the new master.

### Conclusion

At this point we now have a reliable, scalable Redis installation.  By scaling the replication controller for redis servers, we can increase or decrease the number of read-slaves in our cluster.  Likewise, if failures occur, the redis-sentinels will perform master election and select a new master.

**NOTE:** since redis 3.2 some security measures (bind to 127.0.0.1 and `--protected-mode`) are enabled by default. Please read about this in http://antirez.com/news/96


### tl; dr

For those of you who are impatient, here is the summary of commands we ran in this tutorial:

```
# Create a bootstrap master
kubectl create -f examples/storage/redis/redis-master.yaml

# Create a service to track the sentinels
kubectl create -f examples/storage/redis/redis-sentinel-service.yaml

# Create a replication controller for redis servers
kubectl create -f examples/storage/redis/redis-controller.yaml

# Create a replication controller for redis sentinels
kubectl create -f examples/storage/redis/redis-sentinel-controller.yaml

# Scale both replication controllers
kubectl scale rc redis --replicas=3
kubectl scale rc redis-sentinel --replicas=3

# Delete the original master pod
kubectl delete pods redis-master
```
