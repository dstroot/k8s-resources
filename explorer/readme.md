# Recipe: Explorer

Explorer is a little container for examining the runtime environment Kubernetes produces for your pods.

Currently, you can look at:

* The environment variables to make sure kubernetes is doing what you expect.
* The filesystem to make sure the mounted volumes and files are also what you expect.
* Perform DNS lookups, to see how DNS works.

### Kubernetes Versions

Tested on version 1.3.2 - 1.3.6

## Ingredients

Recommendations:
* When available we prefer the use of official images.
* Always use specified versions
* Use the smallest image possible (generally the alpine variant.)

Official Image: N/A

## Preparation

### Prerequisites

This recipe assumes that you have a Kubernetes cluster installed and running, and that you have installed the `kubectl` command line tool somewhere in your path.

You can also test this using `minikube` if you have it installed locally.

### Starting an Explorer pod.

Create a pod as follows:

```sh
kubectl create -f explorer.yaml
```


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
